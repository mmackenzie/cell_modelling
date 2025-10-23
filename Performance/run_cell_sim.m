% clear; close all;

capacity = 115.8;

input_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Meridian\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\01_Results\01_Capacity\45 ºC';
output_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Meridian\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\02_Analysis\04_Model_validation';
filename = 'ME-ITE-250223-04_CapacityTest_45oC.xlsx';
case_name = 'Capacity, 45degC';
params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\Updated params';
prev_params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah';
params_file = 'RC_params.xlsx';
prev_params_file = 'RC_params_gotion.xlsx';

%% Read data
electrical_sheet = sheetnames(fullfile(input_folder, filename));
electrical_sheet = electrical_sheet(contains(electrical_sheet, 'Detail_') & ~contains(electrical_sheet, 'Temp'));
electrical_data = readtable(fullfile(input_folder, filename), 'Sheet', electrical_sheet{1});

temperature_sheet = sheetnames(fullfile(input_folder, filename));
temperature_sheet = temperature_sheet(contains(temperature_sheet, 'DetailTemp'));
temperature_data = readtable(fullfile(input_folder, filename), 'Sheet', temperature_sheet{1});

actual_voltage = electrical_data.Voltage_V_;
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
stop_time = time(end);

current_ts = timeseries(current, time);
voltage_ts = timeseries(actual_voltage, time);
temperature_ts = timeseries(temperature, time);

figure('Position', [100, 100, 600, 350]);
yyaxis left;
plot(time, current, '-b', 'LineWidth', 2);
ylabel('Current (A)');
yyaxis right;
plot(time, actual_voltage, '-r', 'LineWidth', 2);
ylabel('Voltage (V)');
xlabel('Time (s)');
legend('Current', 'Voltage');

%% Load OCV & RC parameters - updated model
data = readmatrix(fullfile(params_path, 'OCV.xlsx'), 'Sheet', 'Averaged');
OCV_SOC = data(2:end, 1);
OCV_T = data(1, 2:end);
OCV_V = data(2:end, 2:end);

data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R0_discharge');
RC_SOC = data(1, 2:end);
RC_T = data(2:end, 1);
R0d = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R1_discharge');
R1d = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R2_discharge');
R2d = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R3_discharge');
R3d = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C1_discharge');
C1d = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C2_discharge');
C2d = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C3_discharge');
C3d = data(2:end, 2:end);

data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R0_charge');
R0c = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R1_charge');
R1c = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R2_charge');
R2c = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R3_charge');
R3c = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C1_charge');
C1c = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C2_charge');
C2c = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C3_charge');
C3c = data(2:end, 2:end);

% Run sim
soc_in = interp1(OCV_V(:, 3), OCV_SOC, actual_voltage(1));
if isnan(soc_in)
    soc_in = 1;
end
simOut = sim('cell_EC_model', 'SrcWorkspace', 'base');
time_updated = simOut.tout;
sim_voltage = reshape(simOut.sim_voltage, [length(simOut.sim_voltage), 1]);
sim_voltage_interp = interp1(time_updated, sim_voltage, time, 'linear');
voltage_error = sim_voltage_interp - actual_voltage;

%% Load OCV & RC parameters - previous model
% data = readmatrix(fullfile(prev_params_path, 'OCV_Averaged.xlsx'));
% OCV_SOC = data(2:end, 1);
% OCV_T = data(1, 2:end);
% OCV_V = data(2:end, 2:end);
% 
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'R0d');
% RC_SOC = data(1, 2:end);
% RC_T = data(2:end, 1);
% R0d = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'R1d');
% R1d = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'R2d');
% R2d = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'R3d');
% R3d = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'C1d');
% C1d = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'C2d');
% C2d = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'C3d');
% C3d = data(2:end, 2:end);
% 
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'R0c');
% R0c = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'R1c');
% R1c = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'R2c');
% R2c = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'R3c');
% R3c = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'C1c');
% C1c = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'C2c');
% C2c = data(2:end, 2:end);
% data = readmatrix(fullfile(prev_params_path, prev_params_file), 'Sheet', 'C3c');
% C3c = data(2:end, 2:end);
% 
% % Run sim
% soc_in = interp1(OCV_V(:, 3), OCV_SOC, actual_voltage(1));
% if isnan(soc_in)
%     soc_in = 1;
% end
% simOut = sim('cell_EC_model', 'SrcWorkspace', 'base');
% sim_voltage_prev = reshape(simOut.sim_voltage, [length(simOut.sim_voltage), 1]);
% sim_voltage_prev_interp = interp1(simOut.tout, sim_voltage_prev, time, 'linear');
% voltage_error_prev = sim_voltage_prev_interp - actual_voltage;

%% Plots
figure('Position', [200, 200, 900, 600]);
subplot(2, 1, 1);
hold on;
plot(time, actual_voltage, 'DisplayName', 'Test', 'LineWidth', 2);
plot(time_updated, sim_voltage, 'DisplayName', 'Updated model', 'LineWidth', 2);
% plot(simOut.tout, sim_voltage_prev, 'DisplayName', 'Previous model', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Voltage (V)');
title(case_name)
xlim([0 stop_time]);
ylim([2.5 4.5]);
legend('Location', 'best');
grid on;
grid minor;
set(gca, 'Position', [0.08, 0.46, 0.85, 0.49]);

subplot(2, 1, 2);
hold on;
plot(time, voltage_error*1000, 'k-', 'DisplayName', 'Updated model', 'LineWidth', 2);
% plot(time, voltage_error_prev*1000, '-', 'DisplayName', 'Previous model', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Voltage Error (mV)');
ylim([-50 50]);
legend('Location', 'best');
grid on;
grid minor;
set(gca, 'Position', [0.08, 0.08, 0.85, 0.25]);

saveas(gcf, fullfile(output_folder, sprintf('%s.png', case_name)));

figure
xlabel('Time (s)');
ylabel('SOC (%)');
plot(simOut.tout, simOut.sim_soc.Data * 100, 'LineWidth', 2);
legend();
