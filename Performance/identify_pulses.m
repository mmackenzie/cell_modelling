%% Initialise variables

clear; close all;

% Load HPPC test data (time, current, voltage)
test_temperature = 45;
capacity = 115.8;
% test_path = sprintf('C:\\Users\\mmackenzie\\Documents\\CMT_test_data\\CATL_140.9Ah\\%ddegC', temperature);
input_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\01_Results\03_HPPC\';
params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\Updated params';
filename = sprintf('ME-ITE-250223-04_HPPC@%doC', test_temperature);
file_path = fullfile(input_folder, sprintf('%d', test_temperature), sprintf('%s.xlsx', filename));
output = fullfile(params_path, sprintf('%s.mat', filename));

threshold = 0.5;  % Threshold for detecting a pulse (small current changes are noise)
adjust_current = false;  % Adjust the current inside a pulse if the current values don't seem to properly match the voltage
tolerance = 0.5;  % Tolerance for detecting constant current pulses

%% Read data
sheet_names = sheetnames(file_path);
electrical_sheet = sheet_names(contains(sheet_names, 'Detail_') & ~contains(sheet_names, 'Temp'));
electrical_data = readtable(file_path, 'Sheet', electrical_sheet{1});
temperature_sheet = sheet_names(contains(sheet_names, 'DetailTemp'));
temperature_data = readtable(file_path, 'Sheet', temperature_sheet{1});

voltage = electrical_data.Voltage_V_;
current = electrical_data.Current_A_;
temperature = temperature_data.Aux_CHTU1T__C_;

% Convert relative time strings to duration
rel_time = duration(electrical_data.RelativeTime_h_min_s_ms_, 'InputFormat', 'hh:mm:ss.SSS');

% Loop through and find when relative time resets
time = zeros(size(rel_time));
offset = 0;
for i = 2:length(rel_time)
    if rel_time(i) < rel_time(i - 1)
        offset = time(i - 1) + 0.1;  % Carry on from previous time value
    end
    time(i) = seconds(rel_time(i)) + offset;
end

%% Analyse discharge portion

% --- Identify discharge segments ---
discharge_idx = current < 0;
discharge_diff = diff([0; discharge_idx; 0]);
start_indices = find(discharge_diff == 1);
end_indices = find(discharge_diff == -1) - 1;

data = array2table([time, current, voltage, temperature], 'VariableNames', {'time', 'current', 'voltage', 'temperature'});

% Import excel with OCV
ocv_data = readmatrix(fullfile(params_path, 'OCV.xlsx'), Sheet='Averaged');
OCV.SOC = ocv_data(2:end, 1);
OCV.T = ocv_data(1, 2:end);
OCV.V = ocv_data(2:end, 2:end);

% Detect pulse starts and stops by checking where current changes
pulse_regions = abs(data.current) > threshold;  % Regions where current is above the threshold
pulse_transitions = diff([0; pulse_regions; 0]);  % +1 for start, -1 for stop
pulse_starts = find(pulse_transitions == 1);  % Indices where pulse starts
pulse_stops = find(pulse_transitions == -1) - 1;  % Indices where pulse stops

% SOC estimation based on coulomb counting
% data.SOC = NaN(height(data), 1);
% data.SOC(pulse_starts(2) - 1) = interp1(OCV.V(:, find(OCV.T == temperature)), OCV.SOC, data.Voltage_V_(pulse_starts(2) - 1));
% for i = (pulse_starts(2)):height(data)
%     data.SOC(i) = data.SOC(i-1) + data.Current_A_(i) * (data.TestTime_s_(i) - data.TestTime_s_(i-1)) / 3600 / capacity.Capacity(capacity.Temperature == temperature);
% end

% Separate the pulses that have constant current
pulse_data = struct();
pulse_counter = 0;
for i = 1:length(pulse_starts)
    start_idx = pulse_starts(i);
    stop_idx = pulse_stops(i);

    if start_idx == 1 || stop_idx == height(data)  % if it's the first charging pulse or the last pulse without a relaxation
        continue
    end
    if abs(data.current(start_idx - 1)) < threshold && abs(data.current(stop_idx + 1)) < threshold
        % Extract the current for this pulse
        pulse_current = data.current(start_idx:stop_idx);
        median_pulse_current = median(pulse_current);

        % Check if the current is constant with allowance for one deviation
        deviation_count = sum(abs(pulse_current - median_pulse_current) > tolerance);

        % Allow 3 time steps with deviation from constant current
        if deviation_count <= 3
            pulse_counter = pulse_counter + 1;

            % Extend stop_idx to include the complete relaxation period after the pulse
            % The relaxation period is when the current stays at zero after the pulse.
            relaxation_end_idx = stop_idx + 1;
            while relaxation_end_idx < length(data.current) && abs(data.current(relaxation_end_idx)) < threshold
                relaxation_end_idx = relaxation_end_idx + 1;
            end
            relaxation_end_idx = relaxation_end_idx - 1;

            soc_start = interp1(OCV.V(:, find(OCV.T == test_temperature)), OCV.SOC, data.voltage(start_idx - 1));
            soc_end = interp1(OCV.V(:, find(OCV.T == test_temperature)), OCV.SOC, data.voltage(relaxation_end_idx));
        
            % Extract the time, current, voltage, and soc data for each pulse
            pulse_data(pulse_counter).time = data.time(start_idx-1:relaxation_end_idx);
            pulse_data(pulse_counter).time_reset = pulse_data(pulse_counter).time - pulse_data(pulse_counter).time(1);
            pulse_data(pulse_counter).current = data.current(start_idx-1:relaxation_end_idx);
            pulse_data(pulse_counter).voltage = data.voltage(start_idx-1:relaxation_end_idx);
            pulse_data(pulse_counter).soc = linspace(soc_start, soc_end, length(pulse_data(pulse_counter).time))';
            pulse_data(pulse_counter).avg_soc = mean([soc_start, soc_end]);
            pulse_data(pulse_counter).median_current = median_pulse_current;

            % Extract the key indices for each pulse
            pulse_data(pulse_counter).pulse_start1_idx = 1;
            threshold_current = 0.99 * abs(median_pulse_current);
            pulse_data(pulse_counter).pulse_start2_idx = find(abs(pulse_data(pulse_counter).current) >= threshold_current, 1, 'first');
            pulse_data(pulse_counter).pulse_end_idx = find(abs(pulse_data(pulse_counter).current) >= threshold_current, 1, 'last');
            pulse_data(pulse_counter).relaxation_start_idx = find(abs(pulse_data(pulse_counter).current(2:end)) < threshold, 1, 'first') + 1;
            pulse_data(pulse_counter).relaxation_end_idx = relaxation_end_idx - start_idx + 2;
            pulse_data(pulse_counter).pulse_duration = pulse_data(pulse_counter).time_reset(pulse_data(pulse_counter).pulse_end_idx) - pulse_data(pulse_counter).time_reset(pulse_data(pulse_counter).pulse_start2_idx);
            pulse_data(pulse_counter).relaxation_duration = pulse_data(pulse_counter).time_reset(pulse_data(pulse_counter).relaxation_end_idx) - pulse_data(pulse_counter).time_reset(pulse_data(pulse_counter).relaxation_start_idx);

            % Extract the 10, 18 and 30s DCIR for each pulse
            idx_10s = find(pulse_data(pulse_counter).time_reset == 10);
            idx_18s = find(pulse_data(pulse_counter).time_reset == 18);
            idx_30s = find(pulse_data(pulse_counter).time_reset == 30);
            voltage_10s = pulse_data(pulse_counter).voltage(idx_10s);
            voltage_18s = pulse_data(pulse_counter).voltage(idx_18s);
            voltage_30s = pulse_data(pulse_counter).voltage(idx_30s);
            ocv_10s = interp1(OCV.SOC, OCV.V(:, find(OCV.T == test_temperature)), pulse_data(pulse_counter).soc(idx_10s));
            ocv_18s = interp1(OCV.SOC, OCV.V(:, find(OCV.T == test_temperature)), pulse_data(pulse_counter).soc(idx_18s));
            ocv_30s = interp1(OCV.SOC, OCV.V(:, find(OCV.T == test_temperature)), pulse_data(pulse_counter).soc(idx_30s));
            pulse_data(pulse_counter).DCIR_10s = abs((voltage_10s - ocv_10s) / median_pulse_current);
            pulse_data(pulse_counter).DCIR_18s = abs((voltage_18s - ocv_18s) / median_pulse_current);
            pulse_data(pulse_counter).DCIR_30s = abs((voltage_30s - ocv_30s) / median_pulse_current);

            if adjust_current == true
                % Calculate the voltage drop at the first two steps after pulse start
                voltageDropStep1 = pulse_data(pulse_counter).voltage(1) - pulse_data(pulse_counter).voltage(2);
                voltageDropStep2 = pulse_data(pulse_counter).voltage(1) - pulse_data(pulse_counter).voltage(pulse_data(pulse_counter).pulse_start2_idx);
                
                % Check if the first voltage drop is 80% of the second voltage drop
                if abs(voltageDropStep1) >= 0.8 * abs(voltageDropStep2)
                    % Set the current at the first step to the current at the next step
                    pulse_data(pulse_counter).current(2:pulse_data(pulse_counter).pulse_start2_idx - 1) = median_pulse_current;
                end
            end
        end
    end
end

% Plot all the pulses
figure('Position', [200, 200, 900, 600]);
hold on;
for i = 1:pulse_counter
    plot(pulse_data(i).time, pulse_data(i).voltage, 'DisplayName', ['Pulse ' num2str(i)], 'LineWidth', 2);
end
xlabel('Time (s)');
ylabel('Voltage (V)');
title('Constant Current Pulses from HPPC Test');
legend show;
% saveas(gcf, fullfile(test_path, 'constant_current_pulses.png'));
hold off;

% save(output, "pulse_data");

fields_to_export = {'avg_soc', 'median_current', 'pulse_duration', 'DCIR_10s', 'DCIR_18s', 'DCIR_30s'};
T = struct2table(pulse_data);
T_selected = T(:, fields_to_export);
writetable(T_selected, fullfile('C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\02_Analysis\02_Comparison_to_Gotion_data', 'DCIR_comparison.xlsx'), Sheet='45degC_04');
