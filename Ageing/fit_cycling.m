function cycling_model = fit_cycling(cycling_data, R)
    % Collect data
    N_all = []; T_all = []; Q_all = []; % DoD_all = []; Cr_all = [];
    fnames = fieldnames(cycling_data);
    for i = 1:numel(fnames)
        d = cycling_data.(fnames{i});
        N_all   = [N_all; d.cycle(:)];
        T_all   = [T_all; d.temperature * ones(size(d.cycle))];
        Q_all   = [Q_all; d.relative_capacity(:)];
        % Placeholder for DoD & C-rate for the time-being
        % DoD_all = [DoD_all; 1 * ones(size(d.cycle))]; 
        % Cr_all  = [Cr_all; 1 * ones(size(d.cycle))]; 
    end

    % Use shared extrapolation function
    % f_cyc = @(p, x) extrapolate_cycling(p, x(:,1), x(:,2), x(:,3), x(:,4), R);
    f_cyc = @(p, x) extrapolate_cycling(p, x(:,1), x(:,2), R);

    % Initial guess and bounds
    % p0 = [1e-4, 15000, 0.5, 0.5]; % [k_cyc, Ea, b_DoD, b_Cr]
    % lb = [0, 0, 0, 0];
    % ub = [Inf, Inf, 2, 2];
    p0 = [1, 10000];  % [k_cyc, Ea]
    lb = [p0(1) * 0.01, p0(2) * 0.01];
    ub = [p0(1) * 100, p0(2) * 100];

    % Fit
    opts = optimoptions('lsqcurvefit', 'Display', 'off', 'TolFun', 1e-10, 'TolX', 1e-10);
    % p = lsqcurvefit(f_cyc, p0, [N_all T_all DoD_all Cr_all], 100 - Q_all, lb, ub, opts);
    p = lsqcurvefit(f_cyc, p0, [N_all T_all], 100 - Q_all, lb, ub, opts);

    % Predictions
    % Qloss_pred = f_cyc(p, [N_all T_all DoD_all Cr_all]);
    Qloss_pred = f_cyc(p, [N_all T_all]);
    Q_pred = 100 - Qloss_pred;

    % Goodness of fit
    rmse = sqrt(mean((Q_pred - Q_all).^2));
    R2 = 1 - sum((Q_pred - Q_all).^2) / sum((Q_all - mean(Q_all)).^2);

    % Pack results
    cycling_model.params = p;
    cycling_model.rmse   = rmse;
    cycling_model.R2     = R2;

    % Plot
    Plotting.plot_fit(Q_all, Q_pred, 'Cycling ageing', rmse, R2);
    Plotting.plot_cycling_extrapolation(cycling_data, p, f_cyc);
end
