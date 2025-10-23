function model_params = fit_degradation_models(storage_data, cycling_data)
%   Fits unified degradation models for calendar & cycling ageing
%   Returns model_params struct with calibrated coefficients
%   Performs quality checks (plots + RMSE + R²)

    R = 8.314; % J/mol/K
    %% ---- Calendar ageing fit ---- %%
    t_all = []; SOC_all = []; T_all = []; Q_all = [];
    fnames = fieldnames(storage_data);
    for i = 1:numel(fnames)
        d = storage_data.(fnames{i});
        t_all   = [t_all; d.day(:)];
        % SOC_all = [SOC_all; d.soc(:)];
        T_all   = [T_all; d.temperature * ones(size(d.day))];
        Q_all   = [Q_all; d.relative_capacity(:)];
    end
    
    % Model: Q_loss = k_cal * exp(-Ea/(R*T)) * sqrt(t)
    f_cal = @(p, x) ...
        p(1) .* exp(-p(2) ./ (R * (x(:,2) + 273))) .* sqrt(x(:,1));
    
    p0 = [1e-3, 20000]; % initial guess [k_cal, Ea]
    lb = [0, 0];
    ub = [Inf, Inf];
    
    opts = optimoptions('lsqcurvefit', 'TolFun', 1e-10, 'TolX', 1e-10);
    p_cal = lsqcurvefit(f_cal, p0, [t_all T_all], 1 - Q_all, lb, ub, opts);
    
    % Predictions
    Qloss_pred = f_cal(p_cal,[t_all T_all]);
    Q_pred = 100 - Qloss_pred;
    
    % Goodness of fit
    rmse_cal = sqrt(mean((Q_pred - Q_all).^2));
    R2_cal = 1 - sum((Q_pred - Q_all).^2)/sum((Q_all-mean(Q_all)).^2);
    
    % Plot
    figure; scatter(Q_all,Q_pred,'filled');
    xlabel('Measured Rel. Capacity'); ylabel('Model Prediction');
    title(sprintf('Calendar Ageing Fit: RMSE=%.4f, R²=%.3f',rmse_cal,R2_cal));
    grid on; axis equal; xlim([0.6 1]); ylim([0.6 1]);
    
    %% ------------------------
    % Cycling ageing fit
    %% ------------------------
    N_all = []; T_all = []; Q_all = []; DoD_all = []; Cr_all = [];
    fnames = fieldnames(cycling_data);
    for i = 1:numel(fnames)
        d = cycling_data.(fnames{i});
        N_all = [N_all; d.cycle(:)];
        T_all = [T_all; d.temperature(:)];
        Q_all = [Q_all; d.relative_capacity(:)];
        % placeholders (later replace with real values)
        DoD_all = [DoD_all; ones(size(d.cycle))];
        Cr_all  = [Cr_all; ones(size(d.cycle))];
    end
    
    % Model: Q_loss = k_cyc * (b0 + b1*DoD) * (c0 + c1*C) * exp(-Ea/(R*T)) * N
    f_cyc = @(p,N,DoD,C,T) ...
        p(1).*(p(2)+p(3).*DoD).*(p(4)+p(5).*C).*exp(-p(6)./(R*(T+273))).*N;
    
    p0 = [1e-4, 1, 0, 1, 0, 20000]; % [k_cyc, b0, b1, c0, c1, Ea]
    lb = [0, -Inf, -Inf, -Inf, -Inf, 0];
    ub = [Inf, Inf, Inf, Inf, Inf, Inf];
    
    p_cyc = lsqcurvefit(@(p,x) f_cyc(p,x(:,1),x(:,2),x(:,3),x(:,4)), p0, ...
        [N_all DoD_all Cr_all T_all], 1 - Q_all, lb, ub, opts);
    
    % Predictions
    Qloss_pred = f_cyc(p_cyc,[N_all DoD_all Cr_all T_all]);
    Q_pred = 1 - Qloss_pred;
    
    % Goodness of fit
    rmse_cyc = sqrt(mean((Q_pred - Q_all).^2));
    R2_cyc = 1 - sum((Q_pred - Q_all).^2)/sum((Q_all-mean(Q_all)).^2);
    
    % Plot
    figure; scatter(Q_all,Q_pred,'filled');
    xlabel('Measured Rel. Capacity'); ylabel('Model Prediction');
    title(sprintf('Cycling Ageing Fit: RMSE=%.4f, R²=%.3f',rmse_cyc,R2_cyc));
    grid on; axis equal; xlim([0.6 1]); ylim([0.6 1]);
    
    %% ------------------------
    % Save results
    %% ------------------------
    model_params.calendar.params = p_cal;
    model_params.calendar.rmse   = rmse_cal;
    model_params.calendar.R2     = R2_cal;
    
    model_params.cycling.params  = p_cyc;
    model_params.cycling.rmse    = rmse_cyc;
    model_params.cycling.R2      = R2_cyc;
end
