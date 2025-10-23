clear; close all; clc;

params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\Updated params';
temperature = 0;
SOC_output = (0:0.05:1)';

load(fullfile(params_path, sprintf("all_params_%ddegC.mat", temperature)));

tau1_charge_all = table(C1_charge_all.SOC, R1_charge_all.R .* C1_charge_all.C, R1_charge_all.std .* C1_charge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});
tau2_charge_all = table(C2_charge_all.SOC, R2_charge_all.R .* C2_charge_all.C, R2_charge_all.std .* C2_charge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});
tau3_charge_all = table(C3_charge_all.SOC, R3_charge_all.R .* C3_charge_all.C, R3_charge_all.std .* C3_charge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});
tau1_discharge_all = table(C1_discharge_all.SOC, R1_discharge_all.R .* C1_discharge_all.C, R1_discharge_all.std .* C1_discharge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});
tau2_discharge_all = table(C2_discharge_all.SOC, R2_discharge_all.R .* C2_discharge_all.C, R2_discharge_all.std .* C2_discharge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});
tau3_discharge_all = table(C3_discharge_all.SOC, R3_discharge_all.R .* C3_discharge_all.C, R3_discharge_all.std .* C3_discharge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});

[R1_charge_averaged, R1_charge_lb, R1_charge_ub] = average_parameters(SOC_output, R1_charge_all, 'R');
[C1_charge_averaged, C1_charge_lb, C1_charge_ub] = average_parameters(SOC_output, C1_charge_all, 'C');
[R2_charge_averaged, R2_charge_lb, R2_charge_ub] = average_parameters(SOC_output, R2_charge_all, 'R');
[C2_charge_averaged, C2_charge_lb, C2_charge_ub] = average_parameters(SOC_output, C2_charge_all, 'C');
[R3_charge_averaged, R3_charge_lb, R3_charge_ub] = average_parameters(SOC_output, R3_charge_all, 'R');
[C3_charge_averaged, C3_charge_lb, C3_charge_ub] = average_parameters(SOC_output, C3_charge_all, 'C');
[R1_discharge_averaged, R1_discharge_lb, R1_discharge_ub] = average_parameters(SOC_output, R1_discharge_all, 'R');
[C1_discharge_averaged, C1_discharge_lb, C1_discharge_ub] = average_parameters(SOC_output, C1_discharge_all, 'C');
[R2_discharge_averaged, R2_discharge_lb, R2_discharge_ub] = average_parameters(SOC_output, R2_discharge_all, 'R');
[C2_discharge_averaged, C2_discharge_lb, C2_discharge_ub] = average_parameters(SOC_output, C2_discharge_all, 'C');
[R3_discharge_averaged, R3_discharge_lb, R3_discharge_ub] = average_parameters(SOC_output, R3_discharge_all, 'R');
[C3_discharge_averaged, C3_discharge_lb, C3_discharge_ub] = average_parameters(SOC_output, C3_discharge_all, 'C');
tau1_charge_averaged = R1_charge_averaged .* C1_charge_averaged;
tau2_charge_averaged = R2_charge_averaged .* C2_charge_averaged;
tau3_charge_averaged = R3_charge_averaged .* C3_charge_averaged;
tau1_discharge_averaged = R1_discharge_averaged .* C1_discharge_averaged;
tau2_discharge_averaged = R2_discharge_averaged .* C2_discharge_averaged;
tau3_discharge_averaged = R3_discharge_averaged .* C3_discharge_averaged;

R1_charge_averaged_and_smoothened = smooth_outliers(R1_charge_averaged);
C1_charge_averaged_and_smoothened = smooth_outliers(C1_charge_averaged);
R2_charge_averaged_and_smoothened = smooth_outliers(R2_charge_averaged);
C2_charge_averaged_and_smoothened = smooth_outliers(C2_charge_averaged);
R3_charge_averaged_and_smoothened = smooth_outliers(R3_charge_averaged);
C3_charge_averaged_and_smoothened = smooth_outliers(C3_charge_averaged);
R1_discharge_averaged_and_smoothened = smooth_outliers(R1_discharge_averaged);
C1_discharge_averaged_and_smoothened = smooth_outliers(C1_discharge_averaged);
R2_discharge_averaged_and_smoothened = smooth_outliers(R2_discharge_averaged);
C2_discharge_averaged_and_smoothened = smooth_outliers(C2_discharge_averaged);
R3_discharge_averaged_and_smoothened = smooth_outliers(R3_discharge_averaged);
C3_discharge_averaged_and_smoothened = smooth_outliers(C3_discharge_averaged);

tau1_charge_averaged_and_smoothened = R1_charge_averaged_and_smoothened .* C1_charge_averaged_and_smoothened;
tau2_charge_averaged_and_smoothened = R2_charge_averaged_and_smoothened .* C2_charge_averaged_and_smoothened;
tau3_charge_averaged_and_smoothened = R3_charge_averaged_and_smoothened .* C3_charge_averaged_and_smoothened;
tau1_discharge_averaged_and_smoothened = R1_discharge_averaged_and_smoothened .* C1_discharge_averaged_and_smoothened;
tau2_discharge_averaged_and_smoothened = R2_discharge_averaged_and_smoothened .* C2_discharge_averaged_and_smoothened;
tau3_discharge_averaged_and_smoothened = R3_discharge_averaged_and_smoothened .* C3_discharge_averaged_and_smoothened;

[R1_discharge_averaged_and_smoothened, R2_discharge_averaged_and_smoothened, R3_discharge_averaged_and_smoothened, ...
    C1_discharge_averaged_and_smoothened, C2_discharge_averaged_and_smoothened, C3_discharge_averaged_and_smoothened] = extrapolate_low_soc_rc_values(...
    R1_discharge_averaged_and_smoothened, R2_discharge_averaged_and_smoothened, R3_discharge_averaged_and_smoothened, ...
    tau1_discharge_averaged_and_smoothened, tau2_discharge_averaged_and_smoothened, tau3_discharge_averaged_and_smoothened, ...
    temperature);

tau1_charge_averaged_and_smoothened = R1_charge_averaged_and_smoothened .* C1_charge_averaged_and_smoothened;
tau2_charge_averaged_and_smoothened = R2_charge_averaged_and_smoothened .* C2_charge_averaged_and_smoothened;
tau3_charge_averaged_and_smoothened = R3_charge_averaged_and_smoothened .* C3_charge_averaged_and_smoothened;
tau1_discharge_averaged_and_smoothened = R1_discharge_averaged_and_smoothened .* C1_discharge_averaged_and_smoothened;
tau2_discharge_averaged_and_smoothened = R2_discharge_averaged_and_smoothened .* C2_discharge_averaged_and_smoothened;
tau3_discharge_averaged_and_smoothened = R3_discharge_averaged_and_smoothened .* C3_discharge_averaged_and_smoothened;

R1_charge = table(SOC_output, R1_charge_averaged_and_smoothened, 'VariableNames', {'SOC', 'R'});
R2_charge = table(SOC_output, R2_charge_averaged_and_smoothened, 'VariableNames', {'SOC', 'R'});
R3_charge = table(SOC_output, R3_charge_averaged_and_smoothened, 'VariableNames', {'SOC', 'R'});
C1_charge = table(SOC_output, C1_charge_averaged_and_smoothened, 'VariableNames', {'SOC', 'C'});
C2_charge = table(SOC_output, C2_charge_averaged_and_smoothened, 'VariableNames', {'SOC', 'C'});
C3_charge = table(SOC_output, C3_charge_averaged_and_smoothened, 'VariableNames', {'SOC', 'C'});
R1_discharge = table(SOC_output, R1_discharge_averaged_and_smoothened, 'VariableNames', {'SOC', 'R'});
R2_discharge = table(SOC_output, R2_discharge_averaged_and_smoothened, 'VariableNames', {'SOC', 'R'});
R3_discharge = table(SOC_output, R3_discharge_averaged_and_smoothened, 'VariableNames', {'SOC', 'R'});
C1_discharge = table(SOC_output, C1_discharge_averaged_and_smoothened, 'VariableNames', {'SOC', 'C'});
C2_discharge = table(SOC_output, C2_discharge_averaged_and_smoothened, 'VariableNames', {'SOC', 'C'});
C3_discharge = table(SOC_output, C3_discharge_averaged_and_smoothened, 'VariableNames', {'SOC', 'C'});

save(fullfile(params_path, sprintf('all_params_averaged_%ddegC.mat', temperature)), "R1_charge", "R2_charge", "R3_charge", ...
    "C1_charge", "C2_charge", "C3_charge", ...
    "R1_discharge", "R2_discharge", "R3_discharge", ...
    "C1_discharge", "C2_discharge", "C3_discharge");

raw = readmatrix(fullfile(params_path, 'RC_params.xlsx'));
temperature_column = raw(2:end, 1);
row_index = find(temperature_column == temperature) + 1;  % Add 1 for header offset
if isempty(row_index)
    error('Temperature %d not found in column A of the Excel file.', temperature);
end
target_column = 'B';
target_range = sprintf('%s%d', target_column, row_index);
writematrix(R1_charge.R', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'R1_charge', 'Range', target_range);
writematrix(C1_charge.C', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'C1_charge', 'Range', target_range);
writematrix(R2_charge.R', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'R2_charge', 'Range', target_range);
writematrix(C2_charge.C', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'C2_charge', 'Range', target_range);
writematrix(R3_charge.R', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'R3_charge', 'Range', target_range);
writematrix(C3_charge.C', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'C3_charge', 'Range', target_range);
writematrix(R1_discharge.R', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'R1_discharge', 'Range', target_range);
writematrix(C1_discharge.C', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'C1_discharge', 'Range', target_range);
writematrix(R2_discharge.R', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'R2_discharge', 'Range', target_range);
writematrix(C2_discharge.C', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'C2_discharge', 'Range', target_range);
writematrix(R3_discharge.R', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'R3_discharge', 'Range', target_range);
writematrix(C3_discharge.C', fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'C3_discharge', 'Range', target_range);

f1 = figure(Position=[50 50 1200 700]);
subplot(2, 3, 1);
hold on;
scatter(R1_discharge_all.SOC, R1_discharge_all.R, 'black');
plot(SOC_output, R1_discharge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, R1_discharge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R1 discharge');

subplot(2, 3, 2);
hold on;
scatter(R2_discharge_all.SOC, R2_discharge_all.R, 'black');
plot(SOC_output, R2_discharge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, R2_discharge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R2 discharge');

subplot(2, 3, 3);
hold on;
scatter(R3_discharge_all.SOC, R3_discharge_all.R, 'black');
plot(SOC_output, R3_discharge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, R3_discharge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R3 discharge');

subplot(2, 3, 4);
hold on;
scatter(tau1_discharge_all.SOC, tau1_discharge_all.tau, 'black');
plot(SOC_output, tau1_discharge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, tau1_discharge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Time constant (s)')
xlim([0 1]);
ylim([0 30]);
title('tau1 discharge');

subplot(2, 3, 5);
hold on;
scatter(tau2_discharge_all.SOC, tau2_discharge_all.tau, 'black');
plot(SOC_output, tau2_discharge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, tau2_discharge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Time constant (s)')
xlim([0 1]);
ylim([0 300]);
title('tau2 discharge');

subplot(2, 3, 6);
hold on;
scatter(tau3_discharge_all.SOC, tau3_discharge_all.tau, 'black');
plot(SOC_output, tau3_discharge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, tau3_discharge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Time constant (s)')
xlim([0 1]);
ylim([0 3000]);
title('tau3 discharge');
saveas(gcf, fullfile(params_path, sprintf('RC_averaging_discharge_%d.png', temperature)));

f2 = figure(Position=[50 50 1200 700]);
subplot(2, 3, 1);
hold on;
scatter(R1_charge_all.SOC, R1_charge_all.R, 'black');
plot(SOC_output, R1_charge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, R1_charge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R1 charge');

subplot(2, 3, 2);
hold on;
scatter(R2_charge_all.SOC, R2_charge_all.R, 'black');
plot(SOC_output, R2_charge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, R2_charge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R2 charge');

subplot(2, 3, 3);
hold on;
scatter(R3_charge_all.SOC, R3_charge_all.R, 'black');
plot(SOC_output, R3_charge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, R3_charge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R3 charge');

subplot(2, 3, 4);
hold on;
scatter(tau1_charge_all.SOC, tau1_charge_all.tau, 'black');
plot(SOC_output, tau1_charge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, tau1_charge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Time constant (s)')
xlim([0 1]);
ylim([0 30]);
title('tau1 charge');

subplot(2, 3, 5);
hold on;
scatter(tau2_charge_all.SOC, tau2_charge_all.tau, 'black');
plot(SOC_output, tau2_charge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, tau2_charge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Time constant (s)')
xlim([0 1]);
ylim([0 300]);
title('tau2 charge');

subplot(2, 3, 6);
hold on;
scatter(tau3_charge_all.SOC, tau3_charge_all.tau, 'black');
plot(SOC_output, tau3_charge_averaged, 'red', 'LineWidth', 2);
plot(SOC_output, tau3_charge_averaged_and_smoothened, 'green', 'LineWidth', 2);
xlabel('SOC (%)')
ylabel('Time constant (s)')
xlim([0 1]);
ylim([0 3000]);
title('tau3 charge');
saveas(gcf, fullfile(params_path, sprintf('RC_averaging_charge_%d.png', temperature)));

function [parameter_output, parameter_lower_bound, parameter_upper_bound] = average_parameters(SOC_target, parameter_input, type)
    parameter_output = nan(length(SOC_target), 1);
    parameter_upper_bound = nan(length(SOC_target), 1);
    parameter_lower_bound = nan(length(SOC_target), 1);
    for i = 1:length(SOC_target)
        current_SOC = SOC_target(i);
        SOC_start = current_SOC - 0.05;
        SOC_end = current_SOC + 0.05;

        % Extract values in SOC range
        indices = (parameter_input.SOC >= SOC_start) & (parameter_input.SOC <= SOC_end);
        if type == 'R'
            data = parameter_input.R(indices);
        elseif type == 'C'
            data = parameter_input.C(indices);
        else
            disp('Wrong type chosen in average_parameters')
        end
        
        std = parameter_input.std(indices);
        
        % Ensure no zero or NaN std values (which would blow up weights)
        valid = ~isnan(data) & ~isnan(std) & (std > 0);
        data = data(valid);
        std = std(valid);
        
        if ~isempty(data)
            % Compute weights as inverse variance (more confident = more weight)
            weights = 1 ./ std .^ 2;
        
            % Weighted average
            parameter_output(i) = sum(weights .* data) / sum(weights);
        
            % Optional: Compute weighted median bounds (for confidence intervals)
            weighted_mean = parameter_output(i);
            weighted_std = sqrt(1 / sum(weights));  % Approximate std of weighted mean
            parameter_upper_bound(i) = weighted_mean + 3 * weighted_std;
            parameter_lower_bound(i) = weighted_mean - 3 * weighted_std;
        end
    end
end

function smoothed = smooth_outliers(values)
    smoothed = values;
    n = length(values);
    x = (1:n)';
    is_outlier = false(n, 1);

    % Handle first value (SOC = 0)
    if values(1) > 5 * values(2) || values(1) < 0.2 * values(2)
        smoothed(1) = values(2);  % Replace with next value
    end
    % Handle last value (SOC = 100%)
    if values(end) > 5 * values(end-1) || values(end) < 0.2 * values(end-1)
        smoothed(end) = values(end-1);  % Replace with previous value
    end

    % Handle interior values (SOC = 5% to 95%)
    for i = 2:length(values)-1
        prev = values(i-1);
        next = values(i+1);
        avg_adjacent = (prev + next) / 2;

        if values(i) > 2 * max(prev, next) || values(i) < 0.5 * min(prev, next)
            % smoothed(i) = avg_adjacent;
            is_outlier(i) = true;
        end
    end

    for i = 2:length(values)-2
        prev = values(i-1);
        next = values(i+2);
        avg_adjacent = (prev + next) / 2;

        if values(i) > 2 * max(prev, next) && values(i+1) > 2 * max(prev, next)
            is_outlier(i) = true;
            is_outlier(i+1) = true;
        end
    end

    valid_idx = ~is_outlier;
    outlier_idx = is_outlier;

    if any(outlier_idx)
        smoothed(outlier_idx) = spline(x(valid_idx), smoothed(valid_idx), x(outlier_idx));
    end
end

function [R1, R2, R3, C1, C2, C3] = extrapolate_low_soc_rc_values(R1, R2, R3, tau1, tau2, tau3, temperature)
    % Define nested map of temperature → (SOC step → [R1_scale, R2_scale, R3_scale])
    scale_map = containers.Map;
    C1 = tau1 ./ R1;
    C2 = tau2 ./ R2;
    C3 = tau3 ./ R3;

    % --- Scaling factors for each temperature ---
    scale_map(string(0)) = containers.Map( ...
        {'15_10', '10_5', '5_0'}, ...
        {[1.1, 1.5, 6], [1.4, 2, 10], [1.8, 3, 10]} ...
    );

    scale_map(string(10)) = containers.Map( ...
        {'15_10', '10_5', '5_0'}, ...
        {[1.1, 1.2, 3], [1.2, 1.8, 5], [1.4, 3, 5]} ...
    );

    scale_map(string(25)) = containers.Map( ...
        {'15_10', '10_5', '5_0'}, ...
        {[1.1, 1.2, 1.3], [1.2, 1.4, 1.5], [1.3, 1.6, 2]} ...
    );

    scale_map(string(45)) = containers.Map( ...
        {'15_10', '10_5', '5_0'}, ...
        {[1.05, 1.05, 1.1], [1.1, 1.2, 1.4], [1.2, 1.6, 1.8]} ...
    );

    % --- Check if temperature is valid ---
    if ~isKey(scale_map, string(temperature))
        error('Temperature %d°C not found in scaling map.', temperature);
    end

    soc_scaling = scale_map(string(temperature));

    % --- Extrapolate from 20% to 15% SOC (index 5 → 4) ---
    if isKey(soc_scaling, '20_15')
        s = soc_scaling('20_15');
        R1(4) = R1(5) * s(1);
        R2(4) = R2(5) * s(2);
        R3(4) = R3(5) * s(3);
        C1(4) = tau1(4) / R1(4);
        C2(4) = tau2(4) / R2(4);
        C3(4) = tau3(4) / R3(4);
    end
    
    % --- Extrapolate from 15% to 10% SOC (index 4 → 3) ---
    if isKey(soc_scaling, '15_10')
        s = soc_scaling('15_10');
        R1(3) = R1(4) * s(1);
        R2(3) = R2(4) * s(2);
        R3(3) = R3(4) * s(3);
        C1(3) = tau1(3) / R1(3);
        C2(3) = tau2(3) / R2(3);
        C3(3) = tau3(3) / R3(3);
    end

    % --- Extrapolate from 10% to 5% SOC (index 3 → 2) ---
    if isKey(soc_scaling, '10_5')
        s = soc_scaling('10_5');
        R1(2) = R1(3) * s(1);
        R2(2) = R2(3) * s(2);
        R3(2) = R3(3) * s(3);
        tau1(2) = tau1(3);
        tau2(2) = tau2(3);
        tau3(2) = tau3(3);
        C1(2) = tau1(2) / R1(2);
        C2(2) = tau2(2) / R2(2);
        C3(2) = tau3(2) / R3(2);
    end

    % --- Extrapolate from 5% to 0% SOC (index 2 → 1) ---
    if isKey(soc_scaling, '5_0')
        s = soc_scaling('5_0');
        R1(1) = R1(2) * s(1);
        R2(1) = R2(2) * s(2);
        R3(1) = R3(2) * s(3);
        tau1(1) = tau1(2);
        tau2(1) = tau2(2);
        tau3(1) = tau3(2);
        C1(1) = tau1(1) / R1(1);
        C2(1) = tau2(1) / R2(1);
        C3(1) = tau3(1) / R3(1);
    end
end
