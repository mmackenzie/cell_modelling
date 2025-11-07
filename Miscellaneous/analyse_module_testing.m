clear; close all;

% output_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\03- Engineering\1_Cell Module\MAGNETIC & ELEC\2_Testing\Resultados ensayos modulo\CMT';
excel_filename = 'Summarized_results.xlsx';
case_name = "5degC_discharge_2C_pulses";

% Read the test data
data_pwr_source = readtable('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\03- Engineering\1_Cell Module\MAGNETIC & ELEC\2_Testing\Resultados ensayos modulo\CMT\A 20ºC\20degC_descarga_1C.csv');
load('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\03- Engineering\1_Cell Module\MAGNETIC & ELEC\2_Testing\Resultados ensayos modulo\CMT\A 20ºC\Message_unpack\Discharge1C_day5.mat');
% data_pwr_source = readtable('C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\03- Engineering\1_Cell Module\MAGNETIC & ELEC\2_Testing\Resultados ensayos modulo\CMT\A 20ºC\20degC_descarga_2C_pulsos.csv');
% load('C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\03- Engineering\1_Cell Module\MAGNETIC & ELEC\2_Testing\Resultados ensayos modulo\CMT\A 20ºC\Message_unpack\Discharge2C_pulses_day8.mat');
data_bms = DATA;

% % Remove extra rows at the end with meaningless data
% cutoff_time = 6680;
% fields = fieldnames(data_bms);
% for i = 1:numel(fields)
%     field_name = fields{i};
%     field_data = data_bms.(field_name);
%     if istimetable(field_data)
%         time_seconds = seconds(field_data.Time);
%         rows_to_keep = time_seconds <= cutoff_time;
%         data_bms.(field_name) = field_data(rows_to_keep, :);
%     end
% end

idx_voltage = find(data_bms.ModuleVolt.Volt_2_x10_V > 130);
% idx_voltage = find(data_bms.ModuleVolt.Volt_2_x10_V < 109);
if ~isempty(idx_voltage)
    bms_volt_start_idx = idx_voltage(end);
    time_start = data_bms.ModuleVolt.Time(bms_volt_start_idx);
else
    fprintf('No voltage value above 130V found.');
    % fprintf('No voltage value below 109V found.\n');
    bms_volt_start_idx = 1;
    time_start = data_bms.ModuleVolt.Time(bms_volt_start_idx);
end
bms_volt_start_idx = 1;
% bms_volt_start_idx = 6570;  % 5degC, 0.5C charge
% bms_volt_start_idx = 9167; % 5degC, 0.8C charge #1
time_start = data_bms.ModuleVolt.Time(bms_volt_start_idx);
[~, bms_temp_start_idx] = min(abs(data_bms.CMD2_CellTemp_1_2_3_4.Time - time_start));


% Read OCV data
ocv_data = readtable('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\141Ah\OCV.xlsx');
SOC_ref = ocv_data{2:end, 1};
OCV_ref = ocv_data{2:end, 4};

% Extract variables - power source
time_pwr_source = data_pwr_source.Time;
voltage_test = data_pwr_source.VoltagePhU_V_;
current_test = data_pwr_source.CurrentGlobal_A_;
ambient_temp_test = data_pwr_source.TemperatureGrid_In__degC_;
current_test(isnan(current_test)) = 0;
for i = 2:length(voltage_test)-1
    if isnan(voltage_test(i)) && ~isnan(voltage_test(i-1)) && ~isnan(voltage_test(i+1))
        voltage_test(i) = (voltage_test(i-1) + voltage_test(i+1)) / 2;
    end
end

% Extract variables - BMS
time_voltage_bms = seconds(data_bms.ModuleVolt.Time(bms_volt_start_idx:end)) - seconds(data_bms.ModuleVolt.Time(bms_volt_start_idx));
time_cell_temp_bms = seconds(data_bms.CMD2_CellTemp_1_2_3_4.Time(bms_temp_start_idx:end)) - seconds(data_bms.CMD2_CellTemp_1_2_3_4.Time(bms_temp_start_idx));
voltage_bms = data_bms.ModuleVolt.Volt_2_x10_V(bms_volt_start_idx:end);
cell_temp_bms = data_bms.CMD2_CellTemp_1_2_3_4.CellTemp2(bms_temp_start_idx:end) / 10;

% Extract start and end cell voltages
voltage_fields = {
    'CMD1_Cell_1_2_3', 'CMD1_Cell_4_5_6', 'CMD1_Cell_7_8_9', ...
    'CMD1_Cell_10_11_12', 'CMD1_Cell_13_14_15', 'CMD1_Cell_16_17_18', ...
    'CMD2_Cell_1_2_3', 'CMD2_Cell_4_5_6', 'CMD2_Cell_7_8_9', ...
    'CMD2_Cell_10_11_12', 'CMD2_Cell_13_14_15', 'CMD2_Cell_16_17_18'
};
% voltage_fields = {
%     'CMD1_Cell_1_2_3', 'CMD1_Cell_4_5_6', 'CMD1_Cell_7_8_9', ...
%     'CMD1_Cell_10_11_12', ...
%     'CMD2_Cell_1_2_3', 'CMD2_Cell_4_5_6', 'CMD2_Cell_7_8_9', ...
%     'CMD2_Cell_10_11_12'
% };

start_voltages = [];
end_voltages = [];
for i = 1:numel(voltage_fields)
    field_name = voltage_fields{i};
    voltage_tt = data_bms.(field_name);
    [~, bms_volt_start_idx] = min(abs(voltage_tt.Time - time_start));
    if bms_volt_start_idx > 1
        start_voltages = [start_voltages, voltage_tt{bms_volt_start_idx - 1, :}];
    else
        start_voltages = [start_voltages, voltage_tt{bms_volt_start_idx, :}];
    end
    end_voltages = [end_voltages, voltage_tt{end, :}];

    if i == 5
        start_voltages = start_voltages(1:end-1);  % Drop CMD1_cell 15
        end_voltages = end_voltages(1:end-1);
    elseif i == 6
        start_voltages = start_voltages(1:end-3);  % Drop CMD1_cell 16, 17, 18
        end_voltages = end_voltages(1:end-3);
    elseif i == 12
        start_voltages = start_voltages(1:end-2);  % Drop CMD2_cell 17, 18
        end_voltages = end_voltages(1:end-2);
    end
end


% Extract start and end cell temperatures
temperature_fields = {'CMD1_CellTemp_1_2_3_4', 'CMD2_CellTemp_1_2_3_4'};

start_temperatures = [];
end_temperatures = [];
for i = 1:numel(temperature_fields)
    field_name = temperature_fields{i};
    temp_tt = data_bms.(field_name);
    [~, temp_start_idx] = min(abs(temp_tt.Time - time_start));

    % Remove CMD1_CellTemp_3 (i.e., the 3rd value of CMD1 field)
    if i == 1
        temp_tt(:, 3) = [];
    end

    if temp_start_idx > 1
        start_temperatures = [start_temperatures, temp_tt{temp_start_idx - 1, :}];
    else
        start_temperatures = [start_temperatures, temp_tt{temp_start_idx, :}];
    end
    end_temperatures = [end_temperatures, temp_tt{end, :}];
    % start_temperatures(start_temperatures < 150) = start_temperatures(start_temperatures < 150) + 255;
    % end_temperatures(end_temperatures < 150) = end_temperatures(end_temperatures < 150) + 255;
end

% Plot results
figure()
hold on
plot(data_bms.CMD1_Cell_1_2_3.Time, data_bms.CMD1_Cell_1_2_3.Cell1, 'DisplayName', 'Cell 1');
plot(data_bms.CMD1_Cell_1_2_3.Time, data_bms.CMD1_Cell_1_2_3.Cell2, 'DisplayName', 'Cell 2');
plot(data_bms.CMD1_Cell_1_2_3.Time, data_bms.CMD1_Cell_1_2_3.Cell3, 'DisplayName', 'Cell 3');
plot(data_bms.CMD1_Cell_4_5_6.Time, data_bms.CMD1_Cell_4_5_6.Cell4, 'DisplayName', 'Cell 4');
plot(data_bms.CMD1_Cell_4_5_6.Time, data_bms.CMD1_Cell_4_5_6.Cell5, 'DisplayName', 'Cell 5');
plot(data_bms.CMD1_Cell_4_5_6.Time, data_bms.CMD1_Cell_4_5_6.Cell6, 'DisplayName', 'Cell 6');
plot(data_bms.CMD1_Cell_7_8_9.Time, data_bms.CMD1_Cell_7_8_9.Cell7, 'DisplayName', 'Cell 7');
plot(data_bms.CMD1_Cell_7_8_9.Time, data_bms.CMD1_Cell_7_8_9.Cell8, 'DisplayName', 'Cell 8');
plot(data_bms.CMD1_Cell_7_8_9.Time, data_bms.CMD1_Cell_7_8_9.Cell9, 'DisplayName', 'Cell 9');
plot(data_bms.CMD1_Cell_10_11_12.Time, data_bms.CMD1_Cell_10_11_12.Cell10, 'DisplayName', 'Cell 10');
plot(data_bms.CMD1_Cell_10_11_12.Time, data_bms.CMD1_Cell_10_11_12.Cell11, 'DisplayName', 'Cell 11');
plot(data_bms.CMD1_Cell_10_11_12.Time, data_bms.CMD1_Cell_10_11_12.Cell12, 'DisplayName', 'Cell 12');
plot(data_bms.CMD1_Cell_13_14_15.Time, data_bms.CMD1_Cell_13_14_15.Cell13, 'DisplayName', 'Cell 13');
plot(data_bms.CMD1_Cell_13_14_15.Time, data_bms.CMD1_Cell_13_14_15.Cell14, 'DisplayName', 'Cell 14');
plot(data_bms.CMD1_Cell_13_14_15.Time, data_bms.CMD1_Cell_13_14_15.Cell15, 'DisplayName', 'Cell 15');
plot(data_bms.CMD1_Cell_16_17_18.Time, data_bms.CMD1_Cell_16_17_18.Cell16, 'DisplayName', 'Cell 16');
plot(data_bms.CMD2_Cell_1_2_3.Time, data_bms.CMD2_Cell_1_2_3.Cell1, 'DisplayName', 'Cell 17');
plot(data_bms.CMD2_Cell_1_2_3.Time, data_bms.CMD2_Cell_1_2_3.Cell2, 'DisplayName', 'Cell 18');
plot(data_bms.CMD2_Cell_1_2_3.Time, data_bms.CMD2_Cell_1_2_3.Cell3, 'DisplayName', 'Cell 19');
plot(data_bms.CMD2_Cell_4_5_6.Time, data_bms.CMD2_Cell_4_5_6.Cell4, 'DisplayName', 'Cell 20');
plot(data_bms.CMD2_Cell_4_5_6.Time, data_bms.CMD2_Cell_4_5_6.Cell5, 'DisplayName', 'Cell 21');
plot(data_bms.CMD2_Cell_4_5_6.Time, data_bms.CMD2_Cell_4_5_6.Cell6, 'DisplayName', 'Cell 22');
plot(data_bms.CMD2_Cell_7_8_9.Time, data_bms.CMD2_Cell_7_8_9.Cell7, 'DisplayName', 'Cell 23');
plot(data_bms.CMD2_Cell_7_8_9.Time, data_bms.CMD2_Cell_7_8_9.Cell8, 'DisplayName', 'Cell 24');
plot(data_bms.CMD2_Cell_7_8_9.Time, data_bms.CMD2_Cell_7_8_9.Cell9, 'DisplayName', 'Cell 25');
plot(data_bms.CMD2_Cell_10_11_12.Time, data_bms.CMD2_Cell_10_11_12.Cell10, 'DisplayName', 'Cell 26');
plot(data_bms.CMD2_Cell_10_11_12.Time, data_bms.CMD2_Cell_10_11_12.Cell11, 'DisplayName', 'Cell 27');
plot(data_bms.CMD2_Cell_10_11_12.Time, data_bms.CMD2_Cell_10_11_12.Cell12, 'DisplayName', 'Cell 28');
plot(data_bms.CMD2_Cell_13_14_15.Time, data_bms.CMD2_Cell_13_14_15.Cell13, 'DisplayName', 'Cell 29');
plot(data_bms.CMD2_Cell_13_14_15.Time, data_bms.CMD2_Cell_13_14_15.Cell14, 'DisplayName', 'Cell 30');
plot(data_bms.CMD2_Cell_13_14_15.Time, data_bms.CMD2_Cell_13_14_15.Cell15, 'DisplayName', 'Cell 31');
plot(data_bms.CMD2_Cell_16_17_18.Time, data_bms.CMD2_Cell_16_17_18.Cell16, 'DisplayName', 'Cell 32');
legend('Location', 'best');
xlabel('Time (s)');
ylabel('Cell voltage (mV)');
grid on;
grid minor;
title('Cell voltages vs time');

figure()
plot(time_voltage_bms, voltage_bms);
xlabel('Time (s)');
ylabel('Module voltage (V)');
grid on;
grid minor;
title('Module voltage vs time');

% Calculate outputs
capacity = trapz(time_pwr_source, current_test) / 3600;  % Ah
energy = trapz(time_pwr_source, voltage_test .* current_test) / 3600 / 1000;  % kWh
min_start_voltage = min(start_voltages) / 1000;
max_start_voltage = max(start_voltages) / 1000;
min_start_temperature = min(start_temperatures) / 10;
max_start_temperature = max(start_temperatures) / 10;
min_end_voltage = min(end_voltages) / 1000;
max_end_voltage = max(end_voltages) / 1000;
min_end_temperature = min(end_temperatures) / 10;
max_end_temperature = max(end_temperatures) / 10;
min_start_soc = interp1(OCV_ref, SOC_ref, min_start_voltage, 'linear', 'extrap') * 100;
max_start_soc = interp1(OCV_ref, SOC_ref, max_start_voltage, 'linear', 'extrap') * 100;
min_end_soc = interp1(OCV_ref, SOC_ref, min_end_voltage, 'linear', 'extrap') * 100;
max_end_soc = interp1(OCV_ref, SOC_ref, max_end_voltage, 'linear', 'extrap') * 100;
start_soc_imbalance = max_start_soc - min_start_soc;
end_soc_imbalance = max_end_soc - min_end_soc;


% --- Display Results ---
fprintf('Capacity: %.1f Ah\n', capacity);
fprintf('Energy: %.1f kWh\n', energy);
fprintf('Voltage min and max at start: %.3f - %.3f V\n', min_start_voltage, max_start_voltage);
fprintf('Voltage min and max at end: %.3f - %.3f V\n', min_end_voltage, max_end_voltage);
fprintf('SOC min and max at start: %.1f - %.1f %%\n', min_start_soc, max_start_soc);
fprintf('SOC min and max at end: %.1f - %.1f %%\n', min_end_soc, max_end_soc);
fprintf('SOC imbalance at start and end: %.1f - %.1f %%\n', start_soc_imbalance, end_soc_imbalance);
fprintf('Temperature min and max at start: %.1f - %.1f degC\n', min_start_temperature, max_start_temperature);
fprintf('Temperature min and max at end: %.1f - %.1f degC\n', min_end_temperature, max_end_temperature);


% === Prepare results for export ===
results = table(...
    case_name, ...
    capacity, ...
    energy, ...
    min_start_voltage, max_start_voltage, ...
    min_end_voltage, max_end_voltage, ...
    min_start_soc, max_start_soc, ...
    min_end_soc, max_end_soc, ...
    start_soc_imbalance, end_soc_imbalance, ...
    min_start_temperature, max_start_temperature, ...
    min_end_temperature, max_end_temperature);

results.Properties.VariableNames = {...
    'CaseName', 'Capacity_Ah', 'Energy_kWh', ...
    'MinStartVolt_V', 'MaxStartVolt_V', ...
    'MinEndVolt_V', 'MaxEndVolt_V', ...
    'MinStartSOC_pct', 'MaxStartSOC_pct', ...
    'MinEndSOC_pct', 'MaxEndSOC_pct', ...
    'StartSOCImbalance_pct', 'EndSOCImbalance_pct', ...
    'MinStartTemp_degC', 'MaxStartTemp_degC', ...
    'MinEndTemp_degC', 'MaxEndTemp_degC'};

% === Export to Excel (append to existing sheet) ===
% if isfile(fullfile(output_folder, excel_filename))
%     try
%         existing_data = readtable(fullfile(output_folder, excel_filename));
%         all_data = [existing_data; results];
%     catch
%         all_data = results;
%     end
% else
%     all_data = results;
% end
% 
% writetable(all_data, fullfile(output_folder, excel_filename));
