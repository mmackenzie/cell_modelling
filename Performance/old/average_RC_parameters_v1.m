clear; close all; clc;

params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\Updated params';

temperature = 10;
load(fullfile(params_path, sprintf("all_params_%ddegC.mat", temperature)));

R1_charge_all(sum(table2array(R1_charge_all), 2) == 0, :) = [];
C1_charge_all(sum(table2array(C1_charge_all), 2) == 0, :) = [];
R2_charge_all(sum(table2array(R2_charge_all), 2) == 0, :) = [];
C2_charge_all(sum(table2array(C2_charge_all), 2) == 0, :) = [];
R3_charge_all(sum(table2array(R3_charge_all), 2) == 0, :) = [];
C3_charge_all(sum(table2array(C3_charge_all), 2) == 0, :) = [];
R1_discharge_all(sum(table2array(R1_discharge_all), 2) == 0, :) = [];
C1_discharge_all(sum(table2array(C1_discharge_all), 2) == 0, :) = [];
R2_discharge_all(sum(table2array(R2_discharge_all), 2) == 0, :) = [];
C2_discharge_all(sum(table2array(C2_discharge_all), 2) == 0, :) = [];
R3_discharge_all(sum(table2array(R3_discharge_all), 2) == 0, :) = [];
C3_discharge_all(sum(table2array(C3_discharge_all), 2) == 0, :) = [];

tau1_charge_all = table(C1_charge_all.SOC, R1_charge_all.R .* C1_charge_all.C, 'VariableNames', {'SOC', 'tau'});
tau2_charge_all = table(C2_charge_all.SOC, R2_charge_all.R .* C2_charge_all.C, 'VariableNames', {'SOC', 'tau'});
tau3_charge_all = table(C3_charge_all.SOC, R3_charge_all.R .* C3_charge_all.C, 'VariableNames', {'SOC', 'tau'});
tau1_discharge_all = table(C1_discharge_all.SOC, R1_discharge_all.R .* C1_discharge_all.C, 'VariableNames', {'SOC', 'tau'});
tau2_discharge_all = table(C2_discharge_all.SOC, R2_discharge_all.R .* C2_discharge_all.C, 'VariableNames', {'SOC', 'tau'});
tau3_discharge_all = table(C3_discharge_all.SOC, R3_discharge_all.R .* C3_discharge_all.C, 'VariableNames', {'SOC', 'tau'});


% Filter away unreasonable R2 and R3
% rows_to_drop = R2_all.R <= 0.00005;
% R2_all(rows_to_drop, :) = [];
% C2_all(rows_to_drop, :) = [];
% tau2_all(rows_to_drop, :) = [];
rows_to_drop = R3_all.R >= 0.0005;
R3_all(rows_to_drop, :) = [];
C3_all(rows_to_drop, :) = [];
tau3_all(rows_to_drop, :) = [];

% Filter away unreasonable tau2 and tau3
rows_to_drop = tau1_all.tau >= 30;
R1_all(rows_to_drop, :) = [];
C1_all(rows_to_drop, :) = [];
tau1_all(rows_to_drop, :) = [];
rows_to_drop = tau2_all.tau >= 300;
R2_all(rows_to_drop, :) = [];
C2_all(rows_to_drop, :) = [];
tau2_all(rows_to_drop, :) = [];
rows_to_drop = tau3_all.tau >= 3000;
R3_all(rows_to_drop, :) = [];
C3_all(rows_to_drop, :) = [];
tau3_all(rows_to_drop, :) = [];
rows_to_drop = tau3_all.tau <= 50;
R3_all(rows_to_drop, :) = [];
C3_all(rows_to_drop, :) = [];
tau3_all(rows_to_drop, :) = [];

% Hampel filter parameters
windowSize = 10; % Number of data points to include in each window
threshold = 2; % Threshold for identifying outliers in terms of median absolute deviation (MAD)

% Initialize output for every 5% SOC from 0 to 100
SOC_output = (0:0.05:1)';
R1_filtered_avg = nan(length(SOC_output), 1);
R2_filtered_avg = nan(length(SOC_output), 1);
R3_filtered_avg = nan(length(SOC_output), 1);
C1_filtered_avg = nan(length(SOC_output), 1);
C2_filtered_avg = nan(length(SOC_output), 1);
C3_filtered_avg = nan(length(SOC_output), 1);

R1_upper_bound = nan(length(SOC_output), 1);
R2_upper_bound = nan(length(SOC_output), 1);
R3_upper_bound = nan(length(SOC_output), 1);
C1_upper_bound = nan(length(SOC_output), 1);
C2_upper_bound = nan(length(SOC_output), 1);
C3_upper_bound = nan(length(SOC_output), 1);

R1_lower_bound = nan(length(SOC_output), 1);
R2_lower_bound = nan(length(SOC_output), 1);
R3_lower_bound = nan(length(SOC_output), 1);
C1_lower_bound = nan(length(SOC_output), 1);
C2_lower_bound = nan(length(SOC_output), 1);
C3_lower_bound = nan(length(SOC_output), 1);

for j = 1:length(SOC_output)
    current_SOC = SOC_output(j);
    SOC_start = max(0, current_SOC - 0.05);
    SOC_end = min(1, current_SOC + 0.05);

    % Filter the data, remove outliers, then compute average
    % R1
    indices = (R1_all.SOC >= SOC_start) & (R1_all.SOC <= SOC_end);
    current_data = R1_all.R(indices);
    % Apply Hampel filtering within the current SOC range
    if ~isempty(current_data)
        [filtered_data, outliers] = hampel(current_data, windowSize, threshold);
        if ~isempty(filtered_data)
            R1_filtered_avg(j) = mean(filtered_data);
            median_y = movmedian(current_data, windowSize);
            mad = movmad(current_data, windowSize);
            R1_upper_bound(j) = mean(median_y) + threshold * mean(mad);
            R1_lower_bound(j) = mean(median_y) - threshold * mean(mad);
        end
    end

    % R2
    indices = (R2_all.SOC >= SOC_start) & (R2_all.SOC <= SOC_end);
    current_data = R2_all.R(indices);
    if ~isempty(current_data)
        [filtered_data, ~] = hampel(current_data, windowSize, threshold);
        if ~isempty(filtered_data)
            R2_filtered_avg(j) = mean(filtered_data);
            median_y = movmedian(current_data, windowSize);
            mad = movmad(current_data, windowSize);
            R2_upper_bound(j) = mean(median_y) + threshold * mean(mad);
            R2_lower_bound(j) = mean(median_y) - threshold * mean(mad);
        end
    end

    % R3
    indices = (R3_all.SOC >= SOC_start) & (R3_all.SOC <= SOC_end);
    current_data = R3_all.R(indices);
    if ~isempty(current_data)
        [filtered_data, ~] = hampel(current_data, windowSize, threshold);
        if ~isempty(filtered_data)
            R3_filtered_avg(j) = mean(filtered_data);
            median_y = movmedian(current_data, windowSize);
            mad = movmad(current_data, windowSize);
            R3_upper_bound(j) = mean(median_y) + threshold * mean(mad);
            R3_lower_bound(j) = mean(median_y) - threshold * mean(mad);
        end
    end

    % C1
    indices = (C1_all.SOC >= SOC_start) & (C1_all.SOC <= SOC_end);
    current_data = C1_all.C(indices);
    if ~isempty(current_data)
        [filtered_data, ~] = hampel(current_data, windowSize, threshold);
        if ~isempty(filtered_data)
            C1_filtered_avg(j) = mean(filtered_data);
            median_y = movmedian(current_data, windowSize);
            mad = movmad(current_data, windowSize);
            C1_upper_bound(j) = mean(median_y) + threshold * mean(mad);
            C1_lower_bound(j) = mean(median_y) - threshold * mean(mad);
        end
    end

    % C2
    indices = (C2_all.SOC >= SOC_start) & (C2_all.SOC <= SOC_end);
    current_data = C2_all.C(indices);
    if ~isempty(current_data)
        [filtered_data, ~] = hampel(current_data, windowSize, threshold);
        if ~isempty(filtered_data)
            C2_filtered_avg(j) = mean(filtered_data);
            median_y = movmedian(current_data, windowSize);
            mad = movmad(current_data, windowSize);
            C2_upper_bound(j) = mean(median_y) + threshold * mean(mad);
            C2_lower_bound(j) = mean(median_y) - threshold * mean(mad);
        end
    end

    % C3
    indices = (C3_all.SOC >= SOC_start) & (C3_all.SOC <= SOC_end);
    current_data = C3_all.C(indices);
    if ~isempty(current_data)
        [filtered_data, ~] = hampel(current_data, windowSize, threshold);
        if ~isempty(filtered_data)
            C3_filtered_avg(j) = mean(filtered_data);
            median_y = movmedian(current_data, windowSize);
            mad = movmad(current_data, windowSize);
            C3_upper_bound(j) = mean(median_y) + threshold * mean(mad);
            C3_lower_bound(j) = mean(median_y) - threshold * mean(mad);
        end
    end

end

R1_filtered_avg = fillmissing(R1_filtered_avg, 'linear', 1, 'EndValues', 'nearest');
R2_filtered_avg = fillmissing(R2_filtered_avg, 'linear', 1, 'EndValues', 'nearest');
R3_filtered_avg = fillmissing(R3_filtered_avg, 'linear', 1, 'EndValues', 'nearest');
C1_filtered_avg = fillmissing(C1_filtered_avg, 'linear', 1, 'EndValues', 'nearest');
C2_filtered_avg = fillmissing(C2_filtered_avg, 'linear', 1, 'EndValues', 'nearest');
C3_filtered_avg = fillmissing(C3_filtered_avg, 'linear', 1, 'EndValues', 'nearest');
R1_upper_bound = fillmissing(R1_upper_bound, 'linear', 1, 'EndValues', 'nearest');
R1_lower_bound = fillmissing(R1_lower_bound, 'linear', 1, 'EndValues', 'nearest');
R2_upper_bound = fillmissing(R2_upper_bound, 'linear', 1, 'EndValues', 'nearest');
R2_lower_bound = fillmissing(R2_lower_bound, 'linear', 1, 'EndValues', 'nearest');
R3_upper_bound = fillmissing(R3_upper_bound, 'linear', 1, 'EndValues', 'nearest');
R3_lower_bound = fillmissing(R3_lower_bound, 'linear', 1, 'EndValues', 'nearest');
C1_upper_bound = fillmissing(C1_upper_bound, 'linear', 1, 'EndValues', 'nearest');
C1_lower_bound = fillmissing(C1_lower_bound, 'linear', 1, 'EndValues', 'nearest');
C2_upper_bound = fillmissing(C2_upper_bound, 'linear', 1, 'EndValues', 'nearest');
C2_lower_bound = fillmissing(C2_lower_bound, 'linear', 1, 'EndValues', 'nearest');
C3_upper_bound = fillmissing(C3_upper_bound, 'linear', 1, 'EndValues', 'nearest');
C3_lower_bound = fillmissing(C3_lower_bound, 'linear', 1, 'EndValues', 'nearest');
tau1_upper_bound = R1_upper_bound .* C1_upper_bound;
tau1_lower_bound = R1_lower_bound .* C1_lower_bound;
tau2_upper_bound = R2_upper_bound .* C2_upper_bound;
tau2_lower_bound = R2_lower_bound .* C2_lower_bound;
tau3_upper_bound = R3_upper_bound .* C3_upper_bound;
tau3_lower_bound = R3_lower_bound .* C3_lower_bound;

% Create an output table
R1_output = table(SOC_output, R1_filtered_avg, 'VariableNames', {'SOC', 'R'});
R2_output = table(SOC_output, R2_filtered_avg, 'VariableNames', {'SOC', 'R'});
R3_output = table(SOC_output, R3_filtered_avg, 'VariableNames', {'SOC', 'R'});
C1_output = table(SOC_output, C1_filtered_avg, 'VariableNames', {'SOC', 'C'});
C2_output = table(SOC_output, C2_filtered_avg, 'VariableNames', {'SOC', 'C'});
C3_output = table(SOC_output, C3_filtered_avg, 'VariableNames', {'SOC', 'C'});
tau1_output = table(SOC_output, R1_filtered_avg .* C1_filtered_avg, 'VariableNames', {'SOC', 'tau'});
tau2_output = table(SOC_output, R2_filtered_avg .* C2_filtered_avg, 'VariableNames', {'SOC', 'tau'});
tau3_output = table(SOC_output, R3_filtered_avg .* C3_filtered_avg, 'VariableNames', {'SOC', 'tau'});

save(fullfile(params_path, sprintf('all_params_averaged_%ddegC.mat', temperature)), "R1_output", "R2_output", "R3_output", "C1_output", "C2_output", "C3_output");


figure;
subplot(2, 3, 1);
hold on;
scatter(R1_all.SOC, R1_all.R, 'black');
plot(R1_output.SOC, R1_output.R, 'red', 'LineWidth', 2);
fill([SOC_output; flip(SOC_output)], [R1_upper_bound; flip(R1_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
title('R1');

subplot(2, 3, 2);
hold on;
scatter(R2_all.SOC, R2_all.R, 'black');
plot(R2_output.SOC, R2_output.R, 'red', 'LineWidth', 2);
fill([SOC_output; flip(SOC_output)], [R2_upper_bound; flip(R2_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
title('R2');

subplot(2, 3, 3);
hold on;
scatter(R3_all.SOC, R3_all.R, 'black');
plot(R3_output.SOC, R3_output.R, 'red', 'LineWidth', 2);
fill([SOC_output; flip(SOC_output)], [R3_upper_bound; flip(R3_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
title('R3');

subplot(2, 3, 4);
hold on;
scatter(tau1_all.SOC, tau1_all.tau, 'black');
plot(tau1_output.SOC, tau1_output.tau, 'red', 'LineWidth', 2);
fill([SOC_output; flip(SOC_output)], [tau1_upper_bound; flip(tau1_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Time constant (s)')
title('tau1');

subplot(2, 3, 5);
hold on;
scatter(tau2_all.SOC, tau2_all.tau, 'black');
plot(tau2_output.SOC, tau2_output.tau, 'red', 'LineWidth', 2);
fill([SOC_output; flip(SOC_output)], [tau2_upper_bound; flip(tau2_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Time constant (s)')
title('tau2');

subplot(2, 3, 6);
hold on;
scatter(tau3_all.SOC, tau3_all.tau, 'black');
plot(tau3_output.SOC, tau3_output.tau, 'red', 'LineWidth', 2);
fill([SOC_output; flip(SOC_output)], [tau3_upper_bound; flip(tau3_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Time constant (s)')
title('tau3');

saveas(gcf, fullfile(params_path, sprintf('RC_averaging_%d.png', temperature)));

% figure;
% hold on;
% scatter(C1_all.SOC, C1_all.C, 'black');
% plot(C1_output.SOC, C1_output.C, 'red');
% xlabel('SOC (%)')
% ylabel('Capacitance (F)')
% title('C1');
% legend();
% 
% figure;
% hold on;
% scatter(C2_all.SOC, C2_all.C, 'black');
% plot(C2_output.SOC, C2_output.C, 'red');
% xlabel('SOC (%)')
% ylabel('Capacitance (F)')
% title('C2');
% legend();
% 
% figure;
% hold on;
% scatter(C3_all.SOC, C3_all.C, 'black');
% plot(C3_output.SOC, C3_output.C, 'red');
% xlabel('SOC (%)')
% ylabel('Capacitance (F)')
% title('C3');
% legend();
