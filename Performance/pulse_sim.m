clear; clc; close all;

%% Input
temperature = 0;
temperature_idx = 2;
test_path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Meridian\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\02_Analysis\03_Pulse_data';
params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\Updated params';
cell_capacity = 115.8;

mat_files = dir(fullfile(test_path, string(temperature), '*.mat'));
load(fullfile(mat_files(2).folder, mat_files(2).name));

ocv_data = readmatrix(fullfile(params_path, 'OCV.xlsx'), Sheet='Averaged');
OCV.SOC = ocv_data(2:end, 1);
OCV.T = ocv_data(1, 2:end);
OCV.V = ocv_data(2:end, 2:end);
data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='R0_charge');
R0_charge.SOC = data(1, 2:end);
R0_charge.T = data(2:end, 1);
R0_charge.R = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='R0_discharge');
R0_discharge.SOC = data(1, 2:end);
R0_discharge.T = data(2:end, 1);
R0_discharge.R = data(2:end, 2:end);
load(fullfile(params_path, sprintf("all_params_averaged_%ddegC.mat", temperature)));
% 
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='R1_charge');
% R1_charge.SOC = data(1, 2:end);
% R1_charge.R = data(temperature_idx, 2:end);
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='R2_charge');
% R2_charge.SOC = data(1, 2:end);
% R2_charge.R = data(temperature_idx, 2:end);
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='R3_charge');
% R3_charge.SOC = data(1, 2:end);
% R3_charge.R = data(temperature_idx, 2:end);
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='C1_charge');
% C1_charge.SOC = data(1, 2:end);
% C1_charge.C = data(temperature_idx, 2:end);
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='C2_charge');
% C2_charge.SOC = data(1, 2:end);
% C2_charge.C = data(temperature_idx, 2:end);
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='C3_charge');
% C3_charge.SOC = data(1, 2:end);
% C3_charge.C = data(temperature_idx, 2:end);
% 
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='R1_discharge');
% R1_discharge.SOC = data(1, 2:end);
% R1_discharge.R = data(temperature_idx, 2:end);
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='R2_discharge');
% R2_discharge.SOC = data(1, 2:end);
% R2_discharge.R = data(temperature_idx, 2:end);
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='R3_discharge');
% R3_discharge.SOC = data(1, 2:end);
% R3_discharge.R = data(temperature_idx, 2:end);
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='C1_discharge');
% C1_discharge.SOC = data(1, 2:end);
% C1_discharge.C = data(temperature_idx, 2:end);
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='C2_discharge');
% C2_discharge.SOC = data(1, 2:end);
% C2_discharge.C = data(temperature_idx, 2:end);
% data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), Sheet='C3_discharge');
% C3_discharge.SOC = data(1, 2:end);
% C3_discharge.C = data(temperature_idx, 2:end);

% %% Read old parameters
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R0d');
% R0_discharge_old.SOC = data(1, 2:end);
% R0_discharge_old.T = data(2:end, 1);
% R0_discharge_old.R = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R1d');
% R1_discharge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'R'});
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R2d');
% R2_discharge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'R'});
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R3d');
% R3_discharge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'R'});
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C1d');
% C1_discharge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'C'});
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C2d');
% C2_discharge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'C'});
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C3d');
% C3_discharge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'C'});
% 
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R0c');
% R0_charge_old.SOC = data(1, 2:end);
% R0_charge_old.T = data(2:end, 1);
% R0_charge_old.R = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R1c');
% R1_charge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'R'});
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R2c');
% R2_charge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'R'});
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R3c');
% R3_charge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'R'});
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C1c');
% C1_charge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'C'});
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C2c');
% C2_charge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'C'});
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C3c');
% C3_charge_old = table(data(1, 2:end)', data(temperature_idx, 2:end)', 'VariableNames', {'SOC', 'C'});

min_time_pulses = 25;
max_time_pulses = 1200;
pulses = pulse_data([]);
for i = 1:length(pulse_data)
    if (pulse_data(i).pulse_duration > min_time_pulses) && (pulse_data(i).pulse_duration < max_time_pulses)
        pulses(end+1) = pulse_data(i);
    else
        continue;
    end
end

for i = 30:length(pulses)
    time = pulses(i).time_reset;
    current = timeseries(pulses(i).current, time);
    actual_voltage = timeseries(pulses(i).voltage, time);
    stop_time = time(end);
    SOC_init = pulses(i).soc(1);
    if isnan(SOC_init)
        SOC_init = 1;
    end

    if pulses(i).median_current < 0
        R0 = R0_discharge;
        R1 = R1_discharge;
        R2 = R2_discharge;
        R3 = R3_discharge;
        C1 = C1_discharge;
        C2 = C2_discharge;
        C3 = C3_discharge;
    else
        R0 = R0_charge;
        R1 = R1_charge;
        R2 = R2_charge;
        R3 = R3_charge;
        C1 = C1_charge;
        C2 = C2_charge;
        C3 = C3_charge;
    end
    
    simOut = sim('Circuit_3RC_single_temperature', 'SrcWorkspace', 'base');
    sim_voltage = reshape(simOut.sim_voltage, [length(simOut.sim_voltage), 1]);
    sim_voltage_interp = interp1(simOut.tout, sim_voltage, time, 'linear');
    voltage_error = sim_voltage_interp - actual_voltage.Data;
    
    f1 = figure();
    subplot(2, 1, 1);
    hold on;
    plot(actual_voltage, 'DisplayName', 'exp', 'LineWidth', 2);
    plot(simOut.tout, sim_voltage, 'DisplayName', 'sim', 'LineWidth', 2);
    xlabel('Time (s)');
    ylabel('Voltage (V)');
    title(sprintf('Pulse #%d, Avg SOC: %.2f', i, pulses(i).avg_soc));
    legend('Location', 'best');
    grid on;
    grid minor;

    subplot(2, 1, 2);
    plot(time, voltage_error*1000, 'k-', 'DisplayName', 'Voltage Error', 'LineWidth', 2);
    xlabel('Time (s)');
    ylabel('Voltage Error (mV)');
    ylim([-25 25]);
    legend('Location', 'best');
    grid on;
    grid minor;

    try
        exportgraphics(gcf, fullfile(params_path, sprintf('pulses_after_averaging_%ddegC.pdf', temperature)), 'Append', true);
    catch ME
        disp(ME.message);
    end

    % f2 = figure();
    % hold on;
    % plot(actual_voltage, 'DisplayName', 'exp', 'LineWidth', 2);
    % plot(simOut.tout, sim_voltage, 'DisplayName', 'updated model', 'LineWidth', 2);
    % 
    % if pulses(i).median_current < 0
    %     R0 = R0_discharge_old;
    %     R1 = R1_discharge_old;
    %     R2 = R2_discharge_old;
    %     R3 = R3_discharge_old;
    %     C1 = C1_discharge_old;
    %     C2 = C2_discharge_old;
    %     C3 = C3_discharge_old;
    % else
    %     R0 = R0_charge_old;
    %     R1 = R1_charge_old;
    %     R2 = R2_charge_old;
    %     R3 = R3_charge_old;
    %     C1 = C1_charge_old;
    %     C2 = C2_charge_old;
    %     C3 = C3_charge_old;
    % end
    % 
    % simOut = sim('Circuit_3RC_single_temperature', 'SrcWorkspace', 'base');
    % sim_voltage = reshape(simOut.sim_voltage, [length(simOut.sim_voltage), 1]);
    % sim_voltage_interp = interp1(simOut.tout, sim_voltage, time, 'linear');
    % voltage_error = sim_voltage_interp - actual_voltage.Data;
    % 
    % figure(f2);
    % hold on;
    % plot(simOut.tout, sim_voltage, 'DisplayName', 'previous model', 'LineWidth', 2);
    % xlabel('Time (s)');
    % ylabel('Voltage (V)');
    % title(sprintf('Pulse #%d, Avg SOC: %.2f', i, pulses(i).avg_soc));
    % legend('Location', 'best');
    % grid on;
    % grid minor;
    % 
    % try
    %     exportgraphics(gcf, fullfile(params_path, 'pulses_after_averaging_comparison_to_old_45degC.pdf'), 'Append', true);
    % catch ME
    %     disp(ME.message);
    % end
end