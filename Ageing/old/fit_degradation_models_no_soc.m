function model_params = fit_degradation_models(storage_data, cycling_data)
%   Fits unified degradation models for calendar & cycling ageing
%   Returns model_params struct with calibrated coefficients
%   Performs quality checks (plots + RMSE + R²)

    R = 8.314; % J/(mol*K)
    %% --- Calendar ageing fit --- %%
    t_all = []; SOC_all = []; T_all = []; Q_all = [];
    fnames = fieldnames(storage_data);
    for i = 1:numel(fnames)
        d = storage_data.(fnames{i});
        t_all   = [t_all; d.day(:)];
        T_all   = [T_all; d.temperature * ones(size(d.day))];
        Q_all   = [Q_all; d.relative_capacity(:)];
        % SOC_all = [SOC_all; d.soc(:)];
    end
    
    % Original: Q_loss = k_cal * exp(-Ea/(R*T)) * sqrt(t)
    % Model: Q_loss = k_cal * exp(-Ea/(R*T)) * sqrt(t)
    f_cal = @(p, x) ...
        p(1) .* exp(-p(2) ./ (R * (x(:,2) + 273))) .* x(:,1) .^ 0.6;
    
    p0 = [10000, 10000]; % initial guess [k_cal, Ea]
    lb = [p0(1)*0.01, p0(2)*0.01];
    ub = [p0(1)*100, p0(2)*100];
    
    opts = optimoptions('lsqcurvefit', 'TolFun', 1e-10, 'TolX', 1e-10);
    p_cal = lsqcurvefit(f_cal, p0, [t_all T_all], 100 - Q_all, lb, ub, opts);
    
    % Predictions
    Qloss_pred = f_cal(p_cal,[t_all T_all]);
    Q_pred = 100 - Qloss_pred;
    
    % Goodness of fit
    rmse_cal = sqrt(mean((Q_pred - Q_all) .^ 2));
    R2_cal = 1 - sum((Q_pred - Q_all) .^ 2) / sum((Q_all - mean(Q_all)) .^ 2);
    
    % Plot points against each other
    figure; scatter(Q_all, Q_pred, 'filled');
    xlabel('Measured Rel. Capacity'); ylabel('Model Prediction');
    title(sprintf('Calendar Ageing Fit: RMSE=%.4f, R²=%.3f', rmse_cal, R2_cal));
    grid on; axis equal; xlim([90 100]); ylim([90 100]);

    % Plot 5 years of extrapolation
    t_extrap = (0:1:5*365)';
    figure; hold on;
    defaultColours = get(groot, 'defaultAxesColorOrder');
    colours = defaultColours(1:5, :);
    for i = 1:numel(fnames)
        d = storage_data.(fnames{i});
        plot(d.day / 365, d.relative_capacity, '*', 'Color', colours(i, :), 'DisplayName', sprintf('%d°C - Measured', d.temperature), 'MarkerSize', 10)
        plot(t_extrap / 365, 100 - f_cal(p_cal, [t_extrap d.temperature * ones(size(t_extrap))]), '--', 'Color', colours(i, :), 'DisplayName', sprintf('%d°C - Estimated', d.temperature), 'LineWidth', 1.5)
    end
    % plot(t_extrap / 365, 100 - f_cal(p_cal, [t_extrap 27 * ones(size(t_extrap))]), '--', 'Color', colours(4, :), 'DisplayName', '27°C - Estimated', 'LineWidth', 1.5)
    % plot(t_extrap / 365, 100 - f_cal(p_cal, [t_extrap 45 * ones(size(t_extrap))]), '--', 'Color', colours(5, :), 'DisplayName', '45°C - Estimated', 'LineWidth', 1.5)
    xlabel('Years'); ylabel('Relative capacity');
    title('Measured vs extrapolated storage data');
    grid on; ylim([70 100]);
    legend();
    
    %% --- Cycling ageing fit --- %%
    N_all = []; T_all = []; Q_all = []; DoD_all = []; Cr_all = [];
    fnames = fieldnames(cycling_data);
    for i = 1:numel(fnames)
        d = cycling_data.(fnames{i});
        N_all = [N_all; d.cycle(:)];
        T_all = [T_all; d.temperature(:) * ones(size(d.cycle))];
        Q_all = [Q_all; d.relative_capacity(:)];
        % DoD_all = [DoD_all; ones(size(d.cycle))];
        % Cr_all  = [Cr_all; ones(size(d.cycle))];
    end
    
    % Model: Q_loss = k_cyc * (b0 + b1*DoD) * (c0 + c1*C) * exp(-Ea/(R*T)) * N
    % Model: Q_loss = k_cyc * exp(-Ea/(R*T)) * N
    f_cyc = @(p, x) p(1) .* exp(-p(2) ./ (R * ((x(:,2) + 273)))) .* x(:,1) .^ 0.8;
    
    p0 = [1, 10000];
    lb = [p0(1) * 0.01, p0(2) * 0.01];
    ub = [p0(1) * 100, p0(2) * 100];
    
    opts = optimoptions('lsqcurvefit', 'TolFun', 1e-10, 'TolX', 1e-10);
    p_cyc = lsqcurvefit(f_cyc, p0, [N_all T_all], 100 - Q_all, lb, ub, opts);
    
    % Predictions
    Qloss_pred = f_cyc(p_cyc,[N_all T_all]);
    Q_pred = 100 - Qloss_pred;
    
    % Goodness of fit
    rmse_cyc = sqrt(mean((Q_pred - Q_all) .^ 2));
    R2_cyc = 1 - sum((Q_pred - Q_all) .^ 2) / sum((Q_all - mean(Q_all)) .^ 2);
    
    % Plot
    figure; scatter(Q_all,Q_pred,'filled');
    xlabel('Measured Rel. Capacity'); ylabel('Model Prediction');
    title(sprintf('Cycling Ageing Fit: RMSE=%.4f, R²=%.3f', rmse_cyc, R2_cyc));
    grid on; axis equal; xlim([80 100]); ylim([80 100]);

    % Plot 2000 cycles of extrapolation
    N_extrap = (0:100:3000)';
    figure; hold on;
    defaultColours = get(groot, 'defaultAxesColorOrder');
    colours = defaultColours(1:5, :);
    for i = 1:numel(fnames)
        d = cycling_data.(fnames{i});
        plot(d.cycle, d.relative_capacity, '*', 'Color', colours(i, :), 'DisplayName', sprintf('%d°C - Measured', d.temperature), 'MarkerSize', 10)
        plot(N_extrap, 100 - f_cyc(p_cyc, [N_extrap d.temperature * ones(size(N_extrap))]), '--', 'Color', colours(i, :), 'DisplayName', sprintf('%d°C - Estimated', d.temperature), 'LineWidth', 1.5)
    end
    xlabel('Cycles'); ylabel('Relative capacity');
    title('Measured vs extrapolated cycling data');
    grid on; ylim([70 100]);
    legend();
    
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
