clear; close all;

peak_current_gotion_33 = [0 10 60 180 300; 7 7 4 3 3];  % Max C-rate depending on pulse time. Gotion 33Ah, cylindrical cell
peak_current_gotion_55 = [0 10 60 180 300; 10 10 5 3 3];  % Max C-rate depending on pulse time. Gotion 55Ah
% peak_current_gotion_33 = [0 10 60 180 300; 8 8 5.5 3 3];  % Max C-rate depending on pulse time. Gotion 33Ah, cylindrical cell
% peak_current_gotion_55 = [0 10 30 60 180 300; 10 10 10 5.5 3 3];  % Max C-rate depending on pulse time. Gotion 55Ah

% peak_current_svolt = [0 10 30 180 300; 6.66 6.66 3.85 1 1];  % Max C-rate depending on pulse time. Svolt
% peak_current_molicel = [0 10 30 60 180 300; 3 3 3 3 3 3];  % Max C-rate depending on pulse time. Molicel
% peak_current_gotion_55 = [0 10 30 60; 10 10 8 5];  % Max C-rate depending on pulse time. Gotion 55Ah, 20% SOC
% peak_current_svolt = [0 10 60; 6 6 3];  % Max C-rate depending on pulse time. Svolt
% peak_current_molicel = [0 10 60; 10 10 6];  % Max C-rate depending on pulse time. Molicel
peak_current_cont2C = [0 1620; 2 2];  % 2C continuous current
peak_current_cont3C = [0 1080; 3 3];  % 3C continuous current

% peak_current_gotion_116 = [0 10 60 180 300; 8 8 5 3 3];  % Max C-rate depending on pulse time. Gotion 115.8 Ah
% peak_current_gotion_116 = [0 10 60; 8 8 4.5];  % Max C-rate depending on pulse time. Gotion 115.8 Ah, 20% SOC
% peak_current_gotion_116 = [0 1080; 3 3];  % Max C-rate depending on pulse time. Gotion

figure;
hold on;
plot(peak_current_gotion_55(1,:), peak_current_gotion_55(2,:), 'DisplayName', 'Gotion - 55Ah, prismatic', 'LineWidth', 2);
% plot(peak_current_gotion_116(1,:), peak_current_gotion_116(2,:), 'DisplayName', 'Gotion - 115.8Ah, prismatic', 'LineWidth', 2);
plot(peak_current_gotion_33(1,:), peak_current_gotion_33(2,:), 'DisplayName', 'Gotion - 33Ah, cylindrical', 'LineWidth', 2);
ylim([0 10]);
xlabel('Time (s)');
ylabel('C-rate (-)');
title('Max C-rate vs time')
legend();
% saveas(gcf, fullfile('C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_33Ah', 'max_currents_gotion.png'));

fig1 = figure;
fig2 = figure;
fig3 = figure;
for i = 1:2
    temperature = 25;
    if i == 1  % Gotion 55Ah
        cell_name = 'Gotion - 55Ah, prismatic';
        % soc_in = 1;
        soc_in = .33;
        capacity = 55;
        n_modules = 19;
        n_cells_series = 12;
        n_cells_parallel = 2;
        n_cells = n_modules * n_cells_series * n_cells_parallel;
        profile = peak_current_gotion_55;
        params_path = 'C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_55Ah';
        params_file = 'RC_params_gotion_55Ah.xlsx';
        ocv_file = 'OCV.xlsx';
    elseif i == 2  % Gotion 33Ah
        cell_name = 'Gotion - 33Ah, cylindrical';
        % soc_in = 1;
        soc_in = .29;
        capacity = 32.6;
        n_modules = 14;
        n_cells_series = 16;
        n_cells_parallel = 4;
        n_cells = n_modules * n_cells_series * n_cells_parallel;
        profile = peak_current_gotion_33;
        params_path = 'C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_33Ah';
        params_file = 'RC_params_gotion_33Ah.xlsx';
        ocv_file = 'OCV_gotion_33Ah.xlsx';
    end
    % 
    % cell_name = 'Gotion - 33Ah, cylindrical';
    % soc_in = 1;
    % capacity = 32.6;
    % n_modules = 14;
    % n_cells_series = 16;
    % n_cells_parallel = 4;
    % n_cells = n_modules * n_cells_series * n_cells_parallel;
    % params_path = 'C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_33Ah';
    % params_file = 'RC_params_gotion_33Ah.xlsx';
    % ocv_file = 'OCV_gotion_33Ah.xlsx';
    % 
    % if i == 1
    %     profile = peak_current_cont3C;
    % elseif i == 2
    %     profile = peak_current_cont2C;
    % end

    time = profile(1, :);
    temperature = timeseries(ones(1, length(profile)) * temperature, time);
    current = timeseries(profile(2, :) * -capacity, time);
    actual_voltage = timeseries(zeros(1, length(profile)), time);
    stop_time = time(end);

    % Load OCV & RC parameters
    data = readmatrix(fullfile(params_path, ocv_file));
    OCV_SOC = data(2:end, 1);
    OCV_T = data(1, 2:end);
    OCV_V = data(2:end, 2:end);
    data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R0d');
    RC_SOC = data(1, 2:end);
    RC_T = data(2:end, 1);
    R0d = data(2:end, 2:end);
    R0c = R0d;
    data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R1d');
    R1d = data(2:end, 2:end);
    R1c = R1d;
    data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R2d');
    R2d = data(2:end, 2:end);
    R2c = R2d;
    data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R3d');
    R3d = data(2:end, 2:end);
    R3c = R3d;
    data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C1d');
    C1d = data(2:end, 2:end);
    C1c = C1d;
    data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C2d');
    C2d = data(2:end, 2:end);
    C2c = C2d;
    data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C3d');
    C3d = data(2:end, 2:end);
    C3c = C3d;
    % load("all_params_averaged.mat");
    
    % Plots
    simOut = sim('cell_EC_model', 'SrcWorkspace', 'base');
    sim_voltage = reshape(simOut.sim_voltage, [length(simOut.sim_voltage), 1]);
    sim_current = reshape(simOut.sim_current.Data, [length(simOut.sim_current.Data), 1]);
    sim_soc = reshape(simOut.sim_soc.Data, [length(simOut.sim_soc.Data), 1]);
    cell_power = sim_voltage .* sim_current;
    pack_power = cell_power * n_cells * 0.9;
    if i == 1
        pack_power_3C = pack_power;
        time_3C = simOut.tout;
        soc_3C = sim_soc;
    % elseif i == 2
    %     pack_power_116 = pack_power;
    %     time_116 = simOut.tout;
    %     soc_116 = sim_soc;
    elseif i == 2
        pack_power_2C = pack_power;
        time_2C = simOut.tout;
        soc_2C = sim_soc;
    end
    
    figure(fig1);
    hold on;
    plot(simOut.tout, sim_voltage, 'DisplayName', cell_name, 'LineWidth', 2);

    figure(fig2);
    hold on;
    plot(simOut.tout, pack_power/1000, 'DisplayName', cell_name, 'LineWidth', 2);

    figure(fig3);
    hold on;
    plot(simOut.tout, sim_soc * 100, 'DisplayName', cell_name, 'LineWidth', 2);
end
% pack_power_2C_interp = interp1(time_2C, pack_power_2C, time_3C, 'linear', 'extrap');
% soc_2C_interp = interp1(time_2C, soc_2C, time_3C, 'linear', 'extrap');
% x_fill = [soc_3C(2:end)'*100, fliplr(soc_3C(2:end)'*100)];
% y_fill = [pack_power_2C_interp(2:end)'/1000, fliplr(pack_power_3C(2:end)')/1000];
% 
% figure(fig2);
% hold on;
% fill(x_fill, y_fill, 'cyan', 'FaceAlpha', 0.3, 'EdgeColor', 'black'); % Filled area
% h_line = yline(250, '--', 'Requirement', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 2, 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'top');
% h_line.Annotation.LegendInformation.IconDisplayStyle = 'off';
% title('Max continuous power vs SOC')
% xlabel('SOC (%)');
% ylabel('Power (kW)');
% xlim([10 100]);
% ylim([0 350]);
% saveas(gcf, fullfile('C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_33Ah\\', 'cont_power_100SOC.png'));

if soc_in < 0.5
    figure(fig1)
    xlabel('Time (s)');
    ylabel('Voltage (V)');
    title('Cell voltage vs time')
    xlim([0 60]);
    legend();
    saveas(gcf, fullfile('C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_33Ah\\', 'voltage_20SOC.png'));
%     
    figure(fig2)
    h_line = yline(450, '--', 'Requirement', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 2, 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');
    h_line.Annotation.LegendInformation.IconDisplayStyle = 'off';
    xlabel('Time (s)');
    ylabel('Power (kW)');
    title('Max power vs time, finishing at 20% SOC')
    xlim([0 60]);
    legend();
%     grid on;
    saveas(gcf, fullfile('C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_33Ah\\', 'power_20SOC.png'));

    figure(fig3)
    xlabel('Time (s)');
    ylabel('SOC (%)');
    title('SOC vs time, finishing at 20% SOC')
    xlim([0 60]);
    legend();
%     grid on;
    saveas(gcf, fullfile('C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_33Ah\\', 'soc_20SOC.png'));

else
    figure(fig1)
    xlabel('Time (s)');
    ylabel('Voltage (V)');
    title('Cell voltage vs time')
    xlim([0 60]);
    legend();
    saveas(gcf, fullfile('C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_33Ah\\', 'max_voltage_100SOC.png'));

    figure(fig2)
    h_line = yline(450, '--', 'Requirement', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 2, 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'bottom');
    h_line.Annotation.LegendInformation.IconDisplayStyle = 'off';
    xlabel('Time (s)');
    ylabel('Power (kW)');
    xlim([0 60]);
    ylim([300 900]);
    title('Max power vs time, starting at 100% SOC')
%     legend('Gotion - 55Ah', 'Gotion - 115.8Ah');
    saveas(gcf, fullfile('C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_33Ah\\', 'max_power_100SOC.png'));

    figure(fig3)
    xlabel('Time (s)');
    ylabel('SOC (%)');
    title('SOC vs time, starting at 100% SOC')
    xlim([0 60]);
    legend();
    saveas(gcf, fullfile('C:\\Users\\mmackenzie\\Documents\\MATLAB\\cell_modelling\\Gotion_33Ah\\', 'max_soc_100SOC.png'));
end
