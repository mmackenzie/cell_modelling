clear; close all;

params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\LG_78Ah';
params_file = 'RC_params.xlsx';
temperatures = [0 10 25 45];

%% Read parameters
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

%% Read old parameters
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R0d');
% R0_discharge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R1d');
% R1_discharge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R2d');
% R2_discharge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R3d');
% R3_discharge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C1d');
% C1_discharge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C2d');
% C2_discharge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C3d');
% C3_discharge_old = data(2:end, 2:end);
% 
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R0c');
% R0_charge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R1c');
% R1_charge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R2c');
% R2_charge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='R3c');
% R3_charge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C1c');
% C1_charge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C2c');
% C2_charge_old = data(2:end, 2:end);
% data = readmatrix('C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\RC_params_gotion.xlsx', Sheet='C3c');
% C3_charge_old = data(2:end, 2:end);

% Create a figure with subplots for each RC parameter
params = {'R0_discharge', 'R1_discharge', 'R2_discharge', 'R3_discharge'};
data = {R0d, R1d, R2d, R3d};
% data_old = {R0_discharge_old, R1_discharge_old, R2_discharge_old, R3_discharge_old};
defaultColours = get(groot, 'defaultAxesColorOrder');
colours = defaultColours(1:4, :);
for i = 1:length(params)
    figure('Position', [100, 100, 600, 350]);
    hold on; grid on;
    
    % Plot each temperature line
    for t = 1:length(temperatures)
        plot(RC_SOC, data{i}(t, :), '-', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C', temperatures(t)), 'LineWidth', 1.5);
        % if t ~= 1
        %     plot(RC_SOC, data_old{i}(t-1, :), '--', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C old', temperatures(t)), 'LineWidth', 1.5);
        % end
    end
    
    % Customize plot
    titleName = strrep(params{i}, '_', '\_');
    title(titleName, 'Interpreter', 'tex');
    xlabel('SOC (-)');
    ylabel('Resistance (Ohms)');
    legend('show', 'Location', 'best');
    grid on;
    xlim([0, 1]);
    if i == 1  % R0
        ylim([0, 2.5e-3]);
    elseif i == 2  % R1
        ylim([0, 1.5e-3]);
    elseif i == 3  % R2
        ylim([0, 3e-3]);
    elseif i == 4  % R3
        ylim([0, 7e-3]);
    end
    saveas(gcf, fullfile(params_path, sprintf('%s.png', params{i})));
end

params = {'C1_discharge', 'C2_discharge', 'C3_discharge'};
data = {C1d, C2d, C3d};
% data_old = {C1_discharge_old, C2_discharge_old, C3_discharge_old};
for i = 1:length(params)
    figure('Position', [100, 100, 600, 350]);
    hold on; grid on;
    
    % Plot each temperature line
    for t = 1:length(temperatures)
        plot(RC_SOC, data{i}(t, :), '-', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C', temperatures(t)), 'LineWidth', 1.5);
        % if t ~= 1
        %     plot(RC_SOC, data_old{i}(t-1, :), '--', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C old', temperatures(t)), 'LineWidth', 1.5);
        % end
    end
    
    % Customize plot
    titleName = strrep(params{i}, '_', '\_');
    title(titleName, 'Interpreter', 'tex');
    xlabel('SOC (-)');
    ylabel('Capacitance (F)');
    legend('show', 'Location', 'best');
    grid on;
    xlim([0, 1]);
    if i == 1  % C1
        ylim([0, 3e4]);
    elseif i == 2  % C2
        ylim([0, 2e5]);
    elseif i == 3  % C3
        ylim([0, 6e6]);
    end
    saveas(gcf, fullfile(params_path, sprintf('%s.png', params{i})));
end

params = {'tau1_discharge', 'tau2_discharge', 'tau3_discharge'};
data = {R1d .* C1d, R2d .* C2d, R3d .* C3d};
% data_old = {R1_discharge_old .* C1_discharge_old, R2_discharge_old .* C2_discharge_old, R3_discharge_old .* C3_discharge_old};
for i = 1:length(params)
    figure('Position', [100, 100, 600, 350]);
    hold on; grid on;
    
    % Plot each temperature line
    for t = 1:length(temperatures)
        plot(RC_SOC, data{i}(t, :), '-', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C', temperatures(t)), 'LineWidth', 1.5);
        % if t ~= 1
        %     plot(RC_SOC, data_old{i}(t-1, :), '--', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C old', temperatures(t)), 'LineWidth', 1.5);
        % end
    end
    
    % Customize plot
    titleName = strrep(params{i}, '_', '\_');
    title(titleName, 'Interpreter', 'tex');
    xlabel('SOC (-)');
    ylabel('Time constant (s)');
    legend('show', 'Location', 'best');
    grid on;
    xlim([0, 1]);
    if i == 1  % tau1
        ylim([0, 10]);
    elseif i == 2  % tau2
        ylim([0, 200]);
    elseif i == 3  % tau3
        ylim([0, 4000]);
    end
    saveas(gcf, fullfile(params_path, sprintf('%s.png', params{i})));
end

params = {'R0_charge', 'R1_charge', 'R2_charge', 'R3_charge'};
data = {R0c, R1c, R2c, R3c};
% data_old = {R0_charge_old, R1_charge_old, R2_charge_old, R3_charge_old};
defaultColours = get(groot, 'defaultAxesColorOrder');
colours = defaultColours(1:4, :);
for i = 1:length(params)
    figure('Position', [100, 100, 600, 350]);
    hold on; grid on;
    
    % Plot each temperature line
    for t = 1:length(temperatures)
        plot(RC_SOC, data{i}(t, :), '-', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C', temperatures(t)), 'LineWidth', 1.5);
        % if t ~= 1
        %     plot(RC_SOC, data_old{i}(t-1, :), '--', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C old', temperatures(t)), 'LineWidth', 1.5);
        % end
    end
    
    % Customize plot
    titleName = strrep(params{i}, '_', '\_');
    title(titleName, 'Interpreter', 'tex');
    xlabel('SOC (-)');
    ylabel('Resistance (Ohms)');
    legend('show', 'Location', 'best');
    grid on;
    xlim([0, 1]);
    if i == 1  % R0
        ylim([0, 2.5e-3]);
    elseif i == 2  % R1
        ylim([0, 1.5e-3]);
    elseif i == 3  % R2
        ylim([0, 3e-3]);
    elseif i == 4  % R3
        ylim([0, 7e-3]);
    end
    saveas(gcf, fullfile(params_path, sprintf('%s.png', params{i})));
end

params = {'C1_charge', 'C2_charge', 'C3_charge'};
data = {C1c, C2c, C3c};
% data_old = {C1_charge_old, C2_charge_old, C3_charge_old};
for i = 1:length(params)
    figure('Position', [100, 100, 600, 350]);
    hold on; grid on;
    
    % Plot each temperature line
    for t = 1:length(temperatures)
        plot(RC_SOC, data{i}(t, :), '-', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C', temperatures(t)), 'LineWidth', 1.5);
        % if t ~= 1
        %     plot(RC_SOC, data_old{i}(t-1, :), '--', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C old', temperatures(t)), 'LineWidth', 1.5);
        % end
    end
    
    % Customize plot
    titleName = strrep(params{i}, '_', '\_');
    title(titleName, 'Interpreter', 'tex');
    xlabel('SOC (-)');
    ylabel('Capacitance (F)');
    legend('show', 'Location', 'best');
    grid on;
    xlim([0, 1]);
    if i == 1  % C1
        ylim([0, 3e4]);
    elseif i == 2  % C2
        ylim([0, 2e5]);
    elseif i == 3  % C3
        ylim([0, 6e6]);
    end
    saveas(gcf, fullfile(params_path, sprintf('%s.png', params{i})));
end

params = {'tau1_charge', 'tau2_charge', 'tau3_charge'};
data = {R1c .* C1c, R2c .* C2c, R3c .* C3c};
% data_old = {R1_charge_old .* C1_charge_old, R2_charge_old .* C2_charge_old, R3_charge_old .* C3_charge_old};
for i = 1:length(params)
    figure('Position', [100, 100, 600, 350]);
    hold on; grid on;
    
    % Plot each temperature line
    for t = 1:length(temperatures)
        plot(RC_SOC, data{i}(t, :), '-', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C', temperatures(t)), 'LineWidth', 1.5);
        % if t ~= 1
        %     plot(RC_SOC, data_old{i}(t-1, :), '--', 'Color', colours(t, :), 'DisplayName', sprintf('%d°C old', temperatures(t)), 'LineWidth', 1.5);
        % end
    end
    
    % Customize plot
    titleName = strrep(params{i}, '_', '\_');
    title(titleName, 'Interpreter', 'tex');
    xlabel('SOC (-)');
    ylabel('Time constant (s)');
    legend('show', 'Location', 'best');
    grid on;
    xlim([0, 1]);
    if i == 1  % tau1
        ylim([0, 10]);
    elseif i == 2  % tau2
        ylim([0, 200]);
    elseif i == 3  % tau3
        ylim([0, 4000]);
    end
    saveas(gcf, fullfile(params_path, sprintf('%s.png', params{i})));
end