clear; clc; close all;

input_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\01_Results\03_HPPC\25';
output_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\02_Analysis\01_Plots';
filename = 'ME-ITE-250223-02_HPPCTest @25oC_old.xlsx';
case_name = 'HPPC_25degC_02';

%% Read data
electrical_sheet = sheetnames(fullfile(input_folder, filename));
electrical_sheet = electrical_sheet(contains(electrical_sheet, 'Detail_') & ~contains(electrical_sheet, 'Temp'));
electrical_data = readtable(fullfile(input_folder, filename), 'Sheet', electrical_sheet{1});

temperature_sheet = sheetnames(fullfile(input_folder, filename));
temperature_sheet = temperature_sheet(contains(temperature_sheet, 'DetailTemp'));
temperature_data = readtable(fullfile(input_folder, filename), 'Sheet', temperature_sheet{1});

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

%% Analyse results
% --- Identify discharge segments ---
discharge_idx = current < 0;
discharge_diff = diff([0; discharge_idx; 0]);
start_indices = find(discharge_diff == 1);
end_indices = find(discharge_diff == -1) - 1;

% First discharge
idx1 = start_indices(1):end_indices(1);
time_discharge1 = time(idx1);
current_discharge1 = current(idx1);
capacity_Ah_1 = -trapz(time_discharge1, current_discharge1) / 3600;

% --- Plot ---
figure('Position', [100, 100, 900, 600]);

t = tiledlayout(2,1);
t.TileSpacing = 'compact';
t.Padding = 'compact';

nexttile;
yyaxis left
plot(time, voltage, 'b', 'LineWidth', 2);
ylabel('Voltage (V)');
ylim([2.5 4.5]);
grid on;
grid minor;

yyaxis right
plot(time, current, 'r', 'LineWidth', 2);
ylabel('Current (A)');
xlabel('Time (s)');
title('Voltage and Current');

nexttile;
plot(time, temperature, 'k', 'LineWidth', 2);
ylabel('Temperature (°C)');
xlabel('Time (s)');
title('Temperature');
grid on;

sgtitle(case_name, 'Interpreter', 'none');

saveas(gcf, fullfile(output_folder, strcat(case_name, '.png')));

figure('Position', [100, 100, 800, 400]);
plot(time, voltage, 'b', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('Voltage (V)');
ylim([2.5 4.5]);
grid on;
grid minor;
title(case_name, 'Interpreter', 'none');

