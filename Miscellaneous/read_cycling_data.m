clc; clear; close all;

% === Initialize Variables ===
input_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\06_Exchange\CMT\Electrico\Ensayos de celda\CATL 141Ah\Ageing\Cycling_45degC';
% folder_path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\06_Exchange\CMT\Electrico\Ensayos de celda\CATL 141Ah\Ageing\Cycling_25degC\09_cycling_400to500';
output_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\03- Engineering\1_Cell Module\MAGNETIC & ELEC\2_Testing\Ageing analysis';

% Find cycling folders
items = dir(input_folder);
subfolders = items([items.isdir]); 
subfolders = subfolders(~ismember({subfolders.name}, {'.', '..'})); 
cycling_folders = subfolders(contains({subfolders.name}, 'cycling', 'IgnoreCase', true));

% Preallocate storage for results
all_time = [];
all_voltage = [];
all_current = [];
all_temperature1 = [];
all_temperature2 = [];
% all_temperature3 = [];
% all_temperature4 = [];
discharge_capacities = [];
% for k = 1:length(cycling_folders)
k = 2;
    file_pattern = fullfile(input_folder, cycling_folders(k).name, '*.csv');
    file_list = dir(file_pattern);
    
    % --- Process each file ---
    for i = 1:length(file_list)
        filename = fullfile(input_folder, cycling_folders(k).name, file_list(i).name);
        data = readtable(filename);
    
        % Extract relevant data
        time = data.TestTime_s_;
        current = data.Current_A_;
        voltage = data.Voltage_V_;
        temperature1 = data.Aux_Temperature_1_C_;
        temperature2 = data.Aux_Temperature_2_C_;
        % temperature3 = data.Aux_Temperature_3_C_;
        % temperature4 = data.Aux_Temperature_4_C_;
    
        % Store data for plotting
        all_time = [all_time; time];
        all_voltage = [all_voltage; voltage];
        all_current = [all_current; current];
        all_temperature1 = [all_temperature1; temperature1];
        all_temperature2 = [all_temperature2; temperature2];
        % all_temperature3 = [all_temperature3; temperature3];
        % all_temperature4 = [all_temperature4; temperature4];
    
        % Find all discharge cycles in this file
        cycle_indices = find(diff(sign(current)) ~= 0); % Detect cycle transitions
    
        % Iterate over detected cycles
        for j = 1:length(cycle_indices) - 1
            idx_start = cycle_indices(j);
            idx_end = cycle_indices(j + 1);
    
            % Ensure it's a discharge (negative current)
            if mean(current(idx_start:idx_end)) < -50
                % Compute Discharge Capacity for this cycle
                discharge_cap = trapz(time(idx_start:idx_end), abs(current(idx_start:idx_end))) / 3600;
                discharge_capacities = [discharge_capacities; discharge_cap];
            end
        end
    end

    % === Plot Data ===
    % Subplot 1: Voltage and Current
    figure('Position', [100, 100, 600, 400]);
    subplot(2,1,1);
    yyaxis left;
    plot(all_time, all_voltage, 'b', 'LineWidth', 1.5);
    ylabel('Voltage (V)');
    hold on;
    yyaxis right;
    plot(all_time, all_current, 'r', 'LineWidth', 1.5);
    ylabel('Current (A)');
    xlabel('Time (s)');
    title('Voltage and Current Profile');
    grid on;

    % Subplot 2: Temperature Readings
    subplot(2,1,2);
    hold on;
    plot(all_time, all_temperature1, 'LineWidth', 1.5);
    plot(all_time, all_temperature2, 'LineWidth', 1.5);
    % plot(all_time, all_temperature3, 'LineWidth', 1.5);
    % plot(all_time, all_temperature4, 'LineWidth', 1.5);
    xlabel('Time (s)');
    ylabel('Temperature (°C)');
    title('Auxiliary Temperature Readings');
    grid on;
    % saveas(gcf, fullfile(output_folder, 'cycling_45degC.png'));
    xlim([0 30000]);
    subplot(2,1,1);
    xlim([0 30000]);
    % saveas(gcf, fullfile(output_folder, 'cycling_45degC_zoomed.png'));
% end

relative_capacities = discharge_capacities / discharge_capacities(1) * 100;


% === Plot Data ===
% Subplot 1: Voltage and Current
% figure('Position', [100, 100, 900, 600]);
% subplot(2,1,1);
% yyaxis left;
% plot(all_time, all_voltage, 'b', 'LineWidth', 1.5);
% ylabel('Voltage (V)');
% hold on;
% yyaxis right;
% plot(all_time, all_current, 'r', 'LineWidth', 1.5);
% ylabel('Current (A)');
% xlabel('Time (s)');
% title('Voltage and Current Profile');
% grid on;
% 
% Subplot 2: Temperature Readings
% subplot(2,1,2);
% hold on;
% plot(all_time, all_temperature1, 'LineWidth', 1.5);
% plot(all_time, all_temperature2, 'LineWidth', 1.5);
% plot(all_time, all_temperature3, 'LineWidth', 1.5);
% plot(all_time, all_temperature4, 'LineWidth', 1.5);
% xlabel('Time (s)');
% ylabel('Temperature (°C)');
% title('Auxiliary Temperature Readings');
% grid on;


figure('Position', [100, 100, 600, 350]);
plot(relative_capacities, 'LineWidth', 2);
ylabel('Relative capacity (%)');
xlabel('Cycle #');
ylim([70 100]);
title('Ageing of Latitude cells');
grid on;
grid minor;
