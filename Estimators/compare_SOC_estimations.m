%% BMS vs Local Model SOC Comparison Script
clear; clc; close all;

% --- CONFIGURATION ---
startTimeOffset = 20; % Start simulation x seconds into the log
delayAdjust = -0.6; % Shift current by x seconds
% ---------------------

% 1. Load Data
[file, path] = uigetfile('*.mat', 'Select BMS Data File');
if isequal(file, 0); return; end
dataStruct = load(fullfile(path, file)); 

% 2. Extract Timestamps (Raw)
time0_raw = findData(dataStruct, 'DGM0_timestamps');
time4_raw = findData(dataStruct, 'DGM4_timestamps');
time13_raw = findData(dataStruct, 'DGM13_timestamps');
time24_raw = findData(dataStruct, 'DGM24_timestamps');

% Normalize to start at 0
BMS_time1_full = (time0_raw - time0_raw(1))';
BMS_time2_full = (time4_raw - time4_raw(1))';
BMS_time3_full = (time13_raw - time13_raw(1))';
BMS_time4_full = (time24_raw - time24_raw(1))';

% 3. Crop and Shift Data
% Helper to get indices and shifted time
cropShift = @(t_vec, startT) find(t_vec >= startT);

idx1 = cropShift(BMS_time1_full, startTimeOffset);
idx2 = cropShift(BMS_time2_full, startTimeOffset);
idx3 = cropShift(BMS_time3_full, startTimeOffset);
idx4 = cropShift(BMS_time4_full, startTimeOffset);

% Shifted time vectors (starting at 0 for Simulink)
BMS_time1 = BMS_time1_full(idx1) - startTimeOffset;
BMS_time2 = BMS_time2_full(idx2) - startTimeOffset + delayAdjust;
BMS_time3 = BMS_time3_full(idx3) - startTimeOffset;
BMS_time4 = BMS_time4_full(idx4) - startTimeOffset;

% 4. Prepare Simulink Inputs (using cropped indices)
% --- Current ---
curr_val_raw = findData(dataStruct, 'current_meas_1');
curr_val = curr_val_raw(idx2);
BMS_batt_current = timeseries(curr_val', BMS_time2);

% --- Voltages (Cells 1-12) ---
v_mat_full = zeros(length(BMS_time3_full), 12);
for i = 1:12
    v_mat_full(:,i) = findData(dataStruct, sprintf('cell_voltage_meas_%d', i))';
end
v_mat = v_mat_full(idx3, :);
BMS_cell_voltages = timeseries(v_mat, BMS_time3);

% --- Temperatures ---
temp_val_raw = findData(dataStruct, 'temp_meas_1');
temp_val = temp_val_raw(idx2);
BMS_cell_temperatures = timeseries(temp_val' * 10, BMS_time2);

% --- Total Battery Voltage ---
hv_val_raw = findData(dataStruct, 'hv_meas_1');
hv_val = hv_val_raw(idx2);
BMS_batt_voltage = timeseries(hv_val', BMS_time2);

% --- SOH ---
SOH_vals = [0 ones(1,12); 3600 ones(1,12)];
SOH = timeseries(SOH_vals(:, 2:end), SOH_vals(:, 1));

% 5. Run Simulink Model
modelName = 'BMS_test_SOC_multi_cell';
fprintf('Running simulation from t=%ds offset: %s...\n', startTimeOffset, modelName);
out = sim(modelName);

% 6. Plotting Results
figure('Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
tlo = tiledlayout(3, 1, 'TileSpacing', 'compact');
colors = lines(12);

% --- TOP PLOT: Current ---
nexttile;
plot(BMS_time2, curr_val, 'r', 'LineWidth', 1.5);
ylabel('Current (A)'); grid on;
title(sprintf('BMS Current (Starting from %ds Offset)', startTimeOffset));

% --- MIDDLE PLOT: Voltages ---
nexttile; hold on;
for i = 1:12
    plot(BMS_time3, v_mat(:,i), 'Color', colors(i,:));
end
ylabel('Voltage (V)'); grid on;
title('BMS Cell Voltages');

% --- BOTTOM PLOT: SOC Comparison ---
nexttile; hold on;
t_local = out.soc_local.Time;
soc_local_data = out.soc_local.Data;

for i = 1:12
    % Local Model (Solid)
    plot(t_local, soc_local_data(:,i)*100, '-', 'Color', colors(i,:), 'LineWidth', 1.5);
    
    % BMS Reported (Dashed) - Must also be cropped/shifted to align
    bms_soc_full = findData(dataStruct, sprintf('cell_soc_%d', i));
    bms_soc_val = bms_soc_full(idx4); 
    plot(BMS_time4, bms_soc_val, '--', 'Color', colors(i,:)*0.7, 'LineWidth', 1);
end
ylabel('SOC (%)'); xlabel('Time since Simulation Start (s)'); grid on;
title('SOC Comparison: Local EKF (Solid) vs BMS (Dashed)');

% Legend and Linkage
hl = line(nan, nan, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 1.5);
hb = line(nan, nan, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);
legend([hl, hb], {'Local EKF', 'BMS Reported'}, 'Location', 'northeastoutside');
linkaxes(findobj(gcf, 'Type', 'axes'), 'x');

%% --- HELPER FUNCTION ---
function val = findData(s, suffix)
    allNames = fieldnames(s);
    matchIdx = find(endsWith(allNames, suffix, 'IgnoreCase', true));
    if isempty(matchIdx)
        error('Error: Could not find any variable ending in "%s" in the loaded file.', suffix);
    end
    val = s.(allNames{matchIdx(1)});
end