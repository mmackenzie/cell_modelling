%% BMS vs Local Model SOC Comparison Script
clear; clc;

% --- CONFIGURATION ---
startTimeOffset = 0; % Start simulation x seconds into the log
delayAdjust = 0; % Shift current by x seconds
% ---------------------

% 1. Load Data
[file, path] = uigetfile('*.mat', 'Select BMS Data File');
if isequal(file, 0); return; end
dataStruct = load(fullfile(path, file)); 

% 2. Extract Timestamps (Raw)
time0_raw = findData(dataStruct, 'DGM0_timestamps');
time8_raw = findData(dataStruct, 'DGM8_timestamps');  % temperature and voltage
time9_raw = findData(dataStruct, 'DGM9_timestamps');  % current
time13_raw = findData(dataStruct, 'DGM13_timestamps');  % cell voltages 1-5
time14_raw = findData(dataStruct, 'DGM14_timestamps');  % cell voltages 6-10
time15_raw = findData(dataStruct, 'DGM15_timestamps');  % cell voltages 11-12
time23_raw = findData(dataStruct, 'DGM23_timestamps');  % cell SOC 1-6
time24_raw = findData(dataStruct, 'DGM24_timestamps');  % cell SOC 7-12
time26_raw = findData(dataStruct, 'DGM26_timestamps');  % cell SOH 1-6
time27_raw = findData(dataStruct, 'DGM27_timestamps');  % cell SOH 7-12

% Normalize to start at 0
BMS_time0_full = (time0_raw - time0_raw(1))';
BMS_time8_full = (time8_raw - time8_raw(1))';
BMS_time9_full = (time9_raw - time9_raw(1))';
BMS_time13_full = (time13_raw - time13_raw(1))';
BMS_time14_full = (time14_raw - time14_raw(1))';
BMS_time15_full = (time15_raw - time15_raw(1))';
BMS_time23_full = (time23_raw - time23_raw(1))';
BMS_time24_full = (time24_raw - time24_raw(1))';
BMS_time26_full = (time26_raw - time26_raw(1))';
BMS_time27_full = (time27_raw - time27_raw(1))';

% 3. Crop and Shift Data
% Helper to get indices and shifted time
cropShift = @(t_vec, startT) find(t_vec >= startT);

idx0 = cropShift(BMS_time0_full, startTimeOffset);
idx8 = cropShift(BMS_time8_full, startTimeOffset);
idx9 = cropShift(BMS_time9_full, startTimeOffset);
idx13 = cropShift(BMS_time13_full, startTimeOffset);
idx14 = cropShift(BMS_time14_full, startTimeOffset);
idx15 = cropShift(BMS_time15_full, startTimeOffset);
idx23 = cropShift(BMS_time23_full, startTimeOffset);
idx24 = cropShift(BMS_time24_full, startTimeOffset);
idx26 = cropShift(BMS_time26_full, startTimeOffset);
idx27 = cropShift(BMS_time27_full, startTimeOffset);

% Shifted time vectors (starting at 0 for Simulink)
BMS_time0 = BMS_time0_full(idx0) - startTimeOffset;
BMS_time8 = BMS_time8_full(idx8) - startTimeOffset;  % temperature
BMS_time9 = BMS_time9_full(idx9) - startTimeOffset + delayAdjust;  % current
BMS_time13 = BMS_time13_full(idx13) - startTimeOffset;  % cell voltages 1-5
BMS_time14 = BMS_time14_full(idx14) - startTimeOffset;  % cell voltages 6-10
BMS_time15 = BMS_time15_full(idx15) - startTimeOffset;  % cell voltages 11-12
BMS_time23 = BMS_time23_full(idx23) - startTimeOffset;  % cell SOC 1-6
BMS_time24 = BMS_time24_full(idx24) - startTimeOffset;  % cell SOC 7-12
BMS_time26 = BMS_time26_full(idx26) - startTimeOffset;  % cell SOH 1-6
BMS_time27 = BMS_time27_full(idx27) - startTimeOffset;  % cell SOH 7-12

% 4. Prepare Simulink Inputs (using cropped indices)
% --- Current ---
curr_val_raw = findData(dataStruct, 'current_meas_1');
curr_val = curr_val_raw(idx9);
BMS_batt_current = timeseries(curr_val', BMS_time9);

% --- Voltages (Cells 1-12) ---
arrays = {idx13, idx14, idx15};
lengths = cellfun(@length, arrays);
[~, min_idx] = min(lengths);
cell_voltage_idx = arrays{min_idx};

arrays = {BMS_time13, BMS_time14, BMS_time15};
lengths = cellfun(@length, arrays);
[~, min_idx] = min(lengths);
cell_voltage_time = arrays{min_idx};

v_mat_full = zeros(length(cell_voltage_time), 12);
for i = 1:12
    data = findData(dataStruct, sprintf('cell_voltage_meas_%d', i));
    v_mat_full(:,i) = data(1:length(cell_voltage_time))';
end
v_mat = v_mat_full(cell_voltage_idx, :);
BMS_cell_voltages = timeseries(v_mat, cell_voltage_time);

% --- Temperatures ---
temp_val_raw = findData(dataStruct, 'temp_meas_1');
temp_val = temp_val_raw(idx8);
BMS_cell_temperatures = timeseries(temp_val' * 10, BMS_time8);

% % --- Total Battery Voltage ---
% hv_val_raw = findData(dataStruct, 'hv_meas_1');
% hv_val = hv_val_raw(idx2);
% BMS_batt_voltage = timeseries(hv_val', BMS_time2);

% --- SOC ---
arrays = {idx23, idx24};
lengths = cellfun(@length, arrays);
[~, min_idx] = min(lengths);
soc_idx = arrays{min_idx};

arrays = {BMS_time23, BMS_time24};
lengths = cellfun(@length, arrays);
[~, min_idx] = min(lengths);
soc_time = arrays{min_idx};

soc_mat_full = zeros(length(soc_time), 12);
for i = 1:12
    data = findData(dataStruct, sprintf('cell_soc_%d', i));
    soc_mat_full(:,i) = data(1:length(soc_time))';
end
soc_mat = soc_mat_full(soc_idx, :) / 0.8 - 10;
BMS_SOC = timeseries(soc_mat, soc_time);

% --- SOH ---
arrays = {idx26, idx27};
lengths = cellfun(@length, arrays);
[~, min_idx] = min(lengths);
soh_idx = arrays{min_idx};

arrays = {BMS_time26, BMS_time27};
lengths = cellfun(@length, arrays);
[~, min_idx] = min(lengths);
soh_time = arrays{min_idx};

soh_mat_full = zeros(length(soh_time), 12);
for i = 1:12
    data = findData(dataStruct, sprintf('cell_soh_%d', i));
    soh_mat_full(:,i) = data(1:length(soh_time))';
end
soh_mat = soh_mat_full(soh_idx, :) * 1.25;
BMS_SOH = timeseries(soh_mat, soh_time);

% 5. Run Simulink Model
modelName = 'BMS_test_SOC_SOH_multi_cell';
fprintf('Running simulation from t=%ds offset: %s...\n', startTimeOffset, modelName);
out = sim(modelName);

% 6. Plotting Results
figure('Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
tlo = tiledlayout(4, 1, 'TileSpacing', 'compact');
colors = lines(12);

% --- TOP PLOT: Current ---
nexttile;
plot(BMS_time9, curr_val, 'r', 'LineWidth', 1.5);
ylabel('Current (A)'); grid on;
title(sprintf('BMS Current (Starting from %ds Offset)', startTimeOffset));

% --- PLOT: Voltages ---
nexttile; hold on;
for i = 1:12
    plot(cell_voltage_time, v_mat(:,i), 'Color', colors(i,:));
end
ylabel('Voltage (V)'); grid on;
title('BMS Cell Voltages');

% --- PLOT: SOC Comparison ---
nexttile; hold on;
t_local = out.soc_local.Time;
soc_local_data = squeeze(out.soc_local.Data)';

for i = 1:12
    % Local Model (Solid)
    plot(t_local, soc_local_data(:,i)*100, '-', 'Color', colors(i,:), 'LineWidth', 1.5);
    
    % BMS Reported (Dashed)
    plot(soc_time, soc_mat(:, i), '--', 'Color', colors(i,:)*0.7, 'LineWidth', 1);
end
ylabel('SOC (%)'); xlabel('Time since Simulation Start (s)'); grid on;
title('SOC Comparison: Local EKF (Solid) vs BMS (Dashed)');

% --- PLOT: SOH Comparison ---
nexttile; hold on;
t_local = out.soh_local.Time;
soh_local_data = squeeze(out.soh_local.Data)';

for i = 1:12
    % Local Model (Solid)
    plot(t_local, soh_local_data(:,i)*100, '-', 'Color', colors(i,:), 'LineWidth', 1.5);
    
    % BMS Reported (Dashed)
    plot(soh_time, soh_mat(:, i), '--', 'Color', colors(i,:)*0.7, 'LineWidth', 1);
end
ylabel('SOH (%)'); xlabel('Time since Simulation Start (s)'); grid on;
title('SOH Comparison: Local (Solid) vs BMS (Dashed)');

% Legend and Linkage
hl = line(nan, nan, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 1.5);
hb = line(nan, nan, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 1);
legend([hl, hb], {'Local', 'BMS Reported'}, 'Location', 'northeastoutside');
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