function model_params = fit_degradation_models(storage_data, cycling_data)
%   Fits unified degradation models for calendar & cycling ageing
%   Returns model_params struct with calibrated coefficients
%   Performs quality checks (plots + RMSE + R²)

    R = 8.314; % J/(mol*K)
    SOC_ref = 100; % reference SOC for exponential term
    
    %% --- Calendar ageing fit --- %%
    t_all = []; SOC_all = []; T_all = []; Q_all = [];
    fnames = fieldnames(storage_data);
    for i = 1:numel(fnames)
        d = storage_data.(fnames{i});
        t_all   = [t_all; d.day(:)];
        T_all   = [T_all; d.temperature * ones(size(d.day))];
        Q_all   = [Q_all; d.relative_capacity(:)];
        SOC_all = [SOC_all; d.soc * ones(size(d.day))];
    end
    
    % Model: Q_loss = k_cal * exp(-Ea/(R*T)) * exp(b*(SOC-SOC_ref)) * t^0.6
    f_cal = @(p, x) ...
        p(1) .* exp(-p(2) ./ (R * (x(:,2) + 273.15))) .* ...
        exp(p(3) .* (x(:,3) - SOC_ref)) .* ...
        x(:,1) .^ 0.6;
    
    % initial guess [k_cal, Ea, b]
    p0 = [10000, 10000, 0.01]; 
    lb = [p0(1) * 0.01, p0(2) * 0.01, 0];
    ub = [p0(1) * 100, p0(2) * 100,  1];
    
    opts = optimoptions('lsqcurvefit', 'TolFun', 1e-10, 'TolX', 1e-10);
    p_cal = lsqcurvefit(f_cal, p0, [t_all T_all SOC_all], 100 - Q_all, lb, ub, opts);
    
    % Predictions
    Qloss_pred = f_cal(p_cal,[t_all T_all SOC_all]);
    Q_pred = 100 - Qloss_pred;
    
    % Goodness of fit
    rmse_cal = sqrt(mean((Q_pred - Q_all) .^ 2));
    R2_cal = 1 - sum((Q_pred - Q_all) .^ 2) / sum((Q_all - mean(Q_all)) .^ 2);
    
    % Plot points against each other
    figure; hold on;
    scatter(Q_all, Q_pred, 'filled');
    plot([0 100], [0 100], 'k--', 'LineWidth', 2)
    xlabel('Measured relative capacity'); ylabel('Model prediction');
    title(sprintf('Calendar ageing fit: RMSE=%.2f, R²=%.2f', rmse_cal, R2_cal));
    grid on; axis equal;
    xlim([90 100]); ylim([90 100]);

    % Plot 5 years of extrapolation
    t_extrap = (0:1:5*365)';
    figure; hold on;
    defaultColours = get(groot, 'defaultAxesColorOrder');
    colours = defaultColours(1:5, :);
    for i = 1:numel(fnames)
        d = storage_data.(fnames{i});
        plot(d.day / 365, d.relative_capacity, '*', 'Color', colours(i, :), ...
            'DisplayName', sprintf('%d°C - measured', d.temperature), 'MarkerSize', 10)
        plot(t_extrap / 365, 100 - f_cal(p_cal, [t_extrap d.temperature*ones(size(t_extrap)) d.soc(1)*ones(size(t_extrap))]), ...
            '--', 'Color', colours(i, :), 'DisplayName', sprintf('%d°C - estimated', d.temperature), 'LineWidth', 1.5)
    end
    xlabel('Years'); ylabel('Relative capacity');
    title('Measured vs extrapolated storage data');
    grid on; ylim([70 100]);
    legend();

    % --- Plot SOC effect (diagnostic) ---
    SOC_range = (0:10:100)'; % 0 to 100% SOC
    soc_multiplier = exp(p_cal(3) .* (SOC_range - SOC_ref));
    
    figure; plot(SOC_range, soc_multiplier, 'LineWidth', 2);
    xlabel('SOC (%)'); ylabel('SOC multiplier');
    title(sprintf('Fitted SOC Effect (b = %.2f)', p_cal(3)));
    grid on;

    % --- Extrapolation plot with SOC effect ---
    t_extrap = (0:30:5*365)'; % up to 5 years
    SOC_levels = [10, 30, 50, 70, 90, 100]; % Example SOC levels
    T_plot = 25; % Fixed reference temperature (25°C)
    
    figure; hold on;
    colors = lines(numel(SOC_levels));
    for i = 1:numel(SOC_levels)
        SOC_val = SOC_levels(i);
        Qloss_SOC = f_cal(p_cal, [t_extrap T_plot*ones(size(t_extrap)) SOC_val*ones(size(t_extrap))]);
        Q_pred_SOC = 100 - Qloss_SOC;
        plot(t_extrap/365, Q_pred_SOC, 'Color', colors(i,:), 'LineWidth', 1.5, ...
            'DisplayName', sprintf('SOC = %d%%', SOC_val));
    end
    xlabel('Years'); ylabel('Relative capacity (%)');
    title(sprintf('Calendar ageing at %d°C as a function of SOC', T_plot));
    grid on;
    ylim([70 100]);
    legend('Location', 'best');

    
    %% --- Cycling ageing fit --- %%
    N_all = []; T_all = []; Q_all = [];
    fnames = fieldnames(cycling_data);
    for i = 1:numel(fnames)
        d = cycling_data.(fnames{i});
        N_all = [N_all; d.cycle(:)];
        T_all = [T_all; d.temperature(:) * ones(size(d.cycle))];
        Q_all = [Q_all; d.relative_capacity(:)];
    end
    
    % Model: Q_loss = k_cyc * exp(-Ea/(R*T)) * N^0.8
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
    figure; hold on;
    scatter(Q_all, Q_pred, 'filled');
    plot([0 100], [0 100], 'k--', 'LineWidth', 2);
    xlabel('Measured relative capacity'); ylabel('Model prediction');
    title(sprintf('Cycling ageing fit: RMSE=%.2f, R²=%.2f', rmse_cyc, R2_cyc));
    grid on; axis equal; xlim([80 100]); ylim([80 100]);

    % Plot 2000 cycles of extrapolation
    N_extrap = (0:100:3000)';
    figure; hold on;
    defaultColours = get(groot, 'defaultAxesColorOrder');
    colours = defaultColours(1:5, :);
    for i = 1:numel(fnames)
        d = cycling_data.(fnames{i});
        plot(d.cycle, d.relative_capacity, '*', 'Color', colours(i, :), ...
            'DisplayName', sprintf('%d°C - Measured', d.temperature), 'MarkerSize', 10)
        plot(N_extrap, 100 - f_cyc(p_cyc, [N_extrap d.temperature * ones(size(N_extrap))]), ...
            '--', 'Color', colours(i, :), 'DisplayName', sprintf('%d°C - Estimated', d.temperature), 'LineWidth', 1.5)
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
