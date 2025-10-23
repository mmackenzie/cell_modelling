clc; clear; close all;

% === Load CSV File ===
% path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\06_Exchange\CMT\Electrico\Ensayos de celda\CATL 141Ah\Ageing\Cycling_25degC\10_RPT_500cycles';
path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\06_Exchange\CMT\Electrico\Ensayos de celda\CATL 141Ah\Ageing\Cycling_45degC\02_RPT_100cycles';
filename = '02_RPT_100cycles.csv';
output_path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\03- Engineering\1_Cell Module\MAGNETIC & ELEC\2_Testing\Ageing analysis';
output_file = 'Ageing_data.xlsx';
data = readtable(fullfile(path, filename));
n_cycles = 100;
sheet = 'RPT_45degC';

% === Extract Relevant Data ===
time = data.TestTime_s_;
current = data.Current_A_;
voltage = data.Voltage_V_;
temperature1 = data.Aux_Temperature_1_C_;
temperature2 = data.Aux_Temperature_2_C_;
% temperature3 = data.Aux_Temperature_3_C_;
% temperature4 = data.Aux_Temperature_4_C_;

% === Identify Vmax First ===
voltage_threshold = 4.2 - 0.001; % 1mV tolerance below 4.2V
idx_Vmax_candidates = find(voltage >= voltage_threshold); % All points near Vmax

if isempty(idx_Vmax_candidates)
    error('Could not find Vmax point within the voltage threshold.');
end

idx_Vmax = idx_Vmax_candidates(1); % First occurrence of Vmax

% === Find First Zero Current AFTER Vmax ===
idx_zero_current = find(current(idx_Vmax:end) == 0, 1) + idx_Vmax - 1;

if isempty(idx_zero_current)
    error('Could not find a zero current point after Vmax.');
end

idx_Vmax_final = idx_zero_current; % The index just after Vmax where current is zero

% === Find First Vmin After This Vmax ===
[~, idx_Vmin] = min(voltage(idx_Vmax_final:end)); 
idx_Vmin = idx_Vmin + idx_Vmax_final - 1; % Adjust index

% Compute Discharge Capacity (Integration of |Current| over Time)
discharge_capacity = trapz(time(idx_Vmax_final:idx_Vmin), abs(current(idx_Vmax_final:idx_Vmin))) / 3600;

% === Identify First Complete Charge (Vmin to Vmax, Including CV Phase) ===
[~, idx_Vmin_first] = min(voltage); % First minimum voltage index
[~, idx_Vmax_after] = max(voltage(idx_Vmin_first:end)); % Find max after first Vmin
idx_Vmax_after = idx_Vmax_after + idx_Vmin_first - 1; % Adjust index

% Include CV Phase: Identify where Current drops significantly
cv_threshold = 0.01 * max(abs(current)); % 1% of max current as threshold
cv_phase_idx = find(abs(current(idx_Vmax_after:end)) < cv_threshold, 1) + idx_Vmax_after - 1;
idx_charge_start = idx_Vmin_first + 1;

% Compute Charge Capacity (Including CV Phase)
charge_capacity = trapz(time(idx_charge_start:cv_phase_idx), abs(current(idx_charge_start:cv_phase_idx))) / 3600;

% === Calculate Pulse Resistances ===
all_pulse_indices = find(diff(sign(current)) ~= 0); % Find zero crossings
pulse_indices = all_pulse_indices(6:end);
all_resistances = diff(voltage(pulse_indices)) ./ diff(current(pulse_indices)); % dV/dI
pulse_resistances = all_resistances(1:2:end);

% === Plot Results ===
figure('Position', [100, 100, 600, 400]);

% Subplot 1: Voltage and Current
subplot(2,1,1);
yyaxis left;
plot(time, voltage, 'b', 'LineWidth', 1.5);
ylabel('Voltage (V)');
hold on;
yyaxis right;
plot(time, current, 'r', 'LineWidth', 1.5);
ylabel('Current (A)');
xlabel('Time (s)');
title('Voltage and Current Profile');
grid on;

% Subplot 2: Temperature Readings
subplot(2,1,2);
hold on;
plot(time, temperature1, 'LineWidth', 1.5);
plot(time, temperature2, 'LineWidth', 1.5);
% plot(time, temperature3, 'LineWidth', 1.5);
% plot(time, temperature4, 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Temperature (°C)');
title('Auxiliary Temperature Readings');
grid on;

% saveas(gcf, fullfile(output_path, 'RPT_25degC.png'));

% === Output Results ===
prev_data = readtable(fullfile(output_path, output_file));
lr = size(prev_data, 1);
writematrix(n_cycles, fullfile(output_path, output_file), 'Sheet', sheet, 'Range', ['A', num2str(lr+2)]);
writematrix(discharge_capacity, fullfile(output_path, output_file), 'Sheet', sheet, 'Range', ['B', num2str(lr+2)]);
writematrix(charge_capacity, fullfile(output_path, output_file), 'Sheet', sheet, 'Range', ['D', num2str(lr+2)]);
writematrix(pulse_resistances', fullfile(output_path, output_file), 'Sheet', sheet, 'Range', ['N', num2str(lr+2)]);
