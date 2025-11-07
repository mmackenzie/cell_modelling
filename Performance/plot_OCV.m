clear; close all;

temperatures = [25];

params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\STAYON\05_Engineering_Design_&_Systems\01_Energy_Storage_System\Pack\Modelling';
raw_data = readmatrix(fullfile(params_path, 'OCV.xlsx'), "Sheet", "Averaged");
OCV_SOC_averaged = raw_data(2:end, 1);
OCV_T_averaged = raw_data(1, 2:end);
OCV_V_averaged = raw_data(2:end, 2:end);

fig1 = figure('Position', [300, 300, 900, 450]);
for i = 1:length(temperatures)
    figure(fig1);
    hold on;
    plot(OCV_SOC_averaged, OCV_V_averaged(:, i), 'LineWidth', 2);
end

ylabel('Voltage (V)');
xlabel('SOC (-)');
title('Estimated OCV of the LG 78Ah cell', 'FontSize', 14);
% legend('Location', 'best');
xlim([-0.02 1]);
grid on;
grid minor;
saveas(gcf, fullfile(params_path, 'estimated_OCV.png'));
% 
% 
% raw_data = readmatrix(fullfile(params_path, 'OCV.xlsx'), "Sheet", "Charge_100SOH");
% OCV_SOC_charge = raw_data(2:end, 1);
% OCV_T_charge = raw_data(1, 2:end);
% OCV_V_charge = raw_data(2:end, 2:end);
% 
% fig1 = figure('Position', [300, 300, 900, 450]);
% for i = 1:length(temperatures)
%     figure(fig1);
%     hold on;
%     plot(OCV_SOC_charge, OCV_V_charge(:, i)*13, 'LineWidth', 2, 'DisplayName', sprintf('%d^oC', temperatures(i)));
% end
% 
% ylabel('Voltage (V)');
% xlabel('SOC (-)');
% title('Pack charge OCV as a function of temperature, SOC', 'FontSize', 14);
% legend('Location', 'best');
% grid on;
% grid minor;
% saveas(gcf, fullfile(params_path, 'OCV_charge_pack.png'));
% 
% 
% fig1 = figure('Position', [300, 300, 900, 450]);
% figure(fig1);
% hold on;
% plot(OCV_SOC_charge, OCV_V_charge(:, 5), 'LineWidth', 2, 'DisplayName', 'Charge direction');
% plot(OCV_SOC_discharge, OCV_V_discharge(:, 5), 'LineWidth', 2, 'DisplayName', 'Discharge direction');
% ylabel('Voltage (V)');
% xlabel('SOC (-)');
% title('Cell OCV in charge and discharge directions at 25 ^oC', 'FontSize', 14);
% legend('Location', 'best');
% grid on;
% grid minor;
% saveas(gcf, fullfile(params_path, 'OCV_both_cell.png'));

