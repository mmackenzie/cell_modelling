function calendar_model = fit_calendar(storage_data, R, SOC_ref)
    % Collect data
    t_all = []; SOC_all = []; T_all = []; Q_all = [];
    fnames = fieldnames(storage_data);
    for i = 1:numel(fnames)
        d = storage_data.(fnames{i});
        t_all = [t_all; d.day(:)];
        SOC_all = [SOC_all; d.soc * ones(size(d.day))];
        T_all = [T_all; d.temperature * ones(size(d.day))];
        Q_all = [Q_all; d.relative_capacity(:)];
    end

    % Use shared extrapolation function
    f_cal = @(p, x) extrapolate_calendar(p, x(:,1), x(:,2), x(:,3), R, SOC_ref);

    % Initial guess and bounds
    p0 = [10000, 10000, 0.01]; % [k_cal, Ea, k_SOC]
    lb = [p0(1) * 0.01, p0(2) * 0.01, 0];
    ub = [p0(1) * 100, p0(2) * 100,  1];

    % Fit
    opts = optimoptions('lsqcurvefit', 'Display', 'off', 'TolFun', 1e-10, 'TolX', 1e-10);
    p = lsqcurvefit(f_cal, p0, [t_all T_all SOC_all], 100 - Q_all, lb, ub, opts);

    % Predictions
    Qloss_pred = f_cal(p,[t_all T_all SOC_all]);
    Q_pred = 100 - Qloss_pred;

    % Goodness of fit
    rmse = sqrt(mean((Q_pred - Q_all).^2));
    R2 = 1 - sum((Q_pred - Q_all).^2) / sum((Q_all - mean(Q_all)).^2);

    % Pack results
    calendar_model.params = p;
    calendar_model.rmse   = rmse;
    calendar_model.R2     = R2;

    % Plot
    Plotting.plot_fit(Q_all, Q_pred, 'Calendar ageing', rmse, R2);
    Plotting.plot_calendar_extrapolation(storage_data, p, f_cal);
    Plotting.plot_calendar_soc_dependency(p, f_cal, SOC_ref);
end
