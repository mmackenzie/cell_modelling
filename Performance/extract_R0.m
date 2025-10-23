clear; close all; clc;

pulse_data_path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\02_Analysis\03_Pulse_data';
params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\Updated params';

% Parameters
capacity = 115.8;
temperatures = [0, 10, 25, 45];
zero_threshold = 0.05;  % Define the threshold below which current is considered zero
tolerance = 0.01;       % Tolerance for small current fluctuations
min_dt_R0 = 0.29;          % Minimum time for measuring R0
max_dt_R0 = 0.4;           % Maximum time for measuring R0
min_R0_c_rate = 0.5;
target_soc = 0:0.05:1;
pulse_duration_threshold = 20;  % Less than this the pulses will be ignored

R0_output_charge = array2table(NaN(length(temperatures), length(target_soc)), 'VariableNames', string(target_soc), 'RowNames', string(temperatures));
R0_output_discharge = array2table(NaN(length(temperatures), length(target_soc)), 'VariableNames', string(target_soc), 'RowNames', string(temperatures));
for temperature = temperatures
    mat_files = dir(fullfile(pulse_data_path, string(temperature), '*.mat'));

    R0_filtered_charge = [];
    R0_filtered_discharge = [];

    for j = 1:length(mat_files)
        load(fullfile(pulse_data_path, string(temperature), mat_files(j).name));

        for i = 1:length(pulse_data)
            if pulse_data(i).soc(1) > 1
                pulse_data(i).soc = pulse_data(i).soc / 100;
            end

            if pulse_data(i).pulse_duration < pulse_duration_threshold
                continue;
            end

            idx_R0_start = find(pulse_data(i).time_reset >= min_dt_R0, 1);
            idx_R0_end = find(pulse_data(i).time_reset >= (min_dt_R0 + pulse_data(i).time_reset(pulse_data(i).pulse_end_idx)), 1);
            if isempty(idx_R0_start) || isempty(idx_R0_end), continue; end

            U_start1 = pulse_data(i).voltage(pulse_data(i).pulse_start1_idx);
            U_start2 = pulse_data(i).voltage(idx_R0_start);
            U_end1 = pulse_data(i).voltage(pulse_data(i).pulse_end_idx);
            U_end2 = pulse_data(i).voltage(idx_R0_end);

            I_pulse = abs(pulse_data(i).median_current);
            c_rate = I_pulse / capacity;
            if c_rate < min_R0_c_rate, continue; end

            soc_start = pulse_data(i).soc(pulse_data(i).pulse_start1_idx);
            soc_end = pulse_data(i).soc(pulse_data(i).pulse_end_idx);
            dt_start = pulse_data(i).time(idx_R0_start) - pulse_data(i).time(pulse_data(i).pulse_start1_idx);
            dt_end = pulse_data(i).time(idx_R0_end) - pulse_data(i).time(pulse_data(i).pulse_end_idx);

            R0_start = abs(U_start2 - U_start1) / I_pulse;
            R0_end = abs(U_end2 - U_end1) / I_pulse;

            if pulse_data(i).median_current > 0  % Charging
                R0_filtered_charge = [R0_filtered_charge; [soc_start, R0_start, dt_start, c_rate]; [soc_end, R0_end, dt_end, c_rate]];
            else  % Discharging
                R0_filtered_discharge = [R0_filtered_discharge; [soc_start, R0_start, dt_start, c_rate]; [soc_end, R0_end, dt_end, c_rate]];
            end
        end
    end

    % Convert to table with appropriate variable names
    R0_filtered_charge = array2table(R0_filtered_charge, 'VariableNames', {'SOC', 'R0', 'dt', 'c_rate'});
    R0_filtered_discharge = array2table(R0_filtered_discharge, 'VariableNames', {'SOC', 'R0', 'dt', 'c_rate'});

    % Calculate and save results
    R0_output_charge{string(temperature), :} = compute_filtered_avg_R0(R0_filtered_charge, target_soc);
    R0_output_discharge{string(temperature), :} = compute_filtered_avg_R0(R0_filtered_discharge, target_soc);

    % Plotting
    figure('Position', [200, 200, 900, 600]); hold on;
    scatter(R0_filtered_charge.SOC, R0_filtered_charge.R0, 'r', 'DisplayName', 'Charge');
    scatter(R0_filtered_discharge.SOC, R0_filtered_discharge.R0, 'b', 'DisplayName', 'Discharge');
    plot(target_soc, R0_output_charge{string(temperature), :}, 'k-', 'DisplayName', 'Charge - filtered and averaged', 'LineWidth', 2)
    plot(target_soc, R0_output_discharge{string(temperature), :}, 'k--', 'DisplayName', 'Discharge - filtered and averaged', 'LineWidth', 2)
    legend('Location', 'best'); grid on;
    xlim([0 1]); xlabel('SOC (-)'); ylabel('Resistance (Ohms)');
    title(sprintf('R0 vs SOC at %d°C', temperature));
    saveas(gcf, fullfile(params_path, sprintf('R0_averaging_%ddegC.png', temperature)));
end

% Helper function to compute robust filtered R0 by SOC bin
function R0_avg = compute_filtered_avg_R0(R0_data, target_soc)
    R0_avg = NaN(1, length(target_soc));
    for k = 1:length(target_soc)
        lb = target_soc(k) - 0.05;
        ub = target_soc(k) + 0.05;
        idx = R0_data.SOC >= lb & R0_data.SOC <= ub;
        R0_bin = R0_data.R0(idx);

        if isempty(R0_bin), continue; end

        med = median(R0_bin);
        abs_deviation = abs(R0_bin - med);
        mad_val = median(abs_deviation);  % Manual MAD

        % Use 3*MAD rule to exclude outliers
        inlier = abs(R0_bin - med) <= 3 * mad_val;

        R0_filtered_bin = R0_bin(inlier);
        if ~isempty(R0_filtered_bin)
            R0_avg(k) = mean(R0_filtered_bin);
        end
    end
end

writetable(R0_output_charge, fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'R0_charge', 'WriteRowNames', true);
writetable(R0_output_discharge, fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'R0_discharge', 'WriteRowNames', true);
