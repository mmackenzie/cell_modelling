clc; clear; close all;

% === Load Data from Excel ===
input_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\03- Engineering\1_Cell Module\MAGNETIC & ELEC\2_Testing\Ageing analysis';
% input_folder = 'C:\Users\mmackenzie\Documents\MATLAB\cell_modelling\141Ah\';
output_path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Latitude\03- Engineering\1_Cell Module\MAGNETIC & ELEC\2_Testing\Ageing analysis';
filename = 'Ageing_data.xlsx';
data_25degC = readtable(fullfile(input_folder, filename), 'Sheet', 'RPT_25degC');
data_45degC = readtable(fullfile(input_folder, filename), 'Sheet', 'RPT_45degC');

% === Plot 25 and 45 degC capacity data ===
figure('Position', [100, 100, 600, 400]);
hold on;
plot(data_25degC.Cycles, data_25degC.RelativeDischargeCapacity___ * 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '25 ^oC');
plot(data_45degC.Cycles, data_45degC.RelativeDischargeCapacity___ * 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '45 ^oC');
xlabel('Cycle number');
ylabel('Relative capacity (%)');
title('Capacity fade over cycles');
ylim([80 100]);
xlim([0 500]);
grid on;
legend('Location', 'best');
saveas(gcf, fullfile(output_path, 'RPT_cap_fade.png'));

% === Plot 25 and 45 degC resistance data ===
x = [0.95, 0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.25];
figure('Position', [100, 100, 600, 400]);
hold on;
plot(x, table2array(data_25degC(1, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '0 cycles');
plot(x, table2array(data_25degC(2, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '100 cycles');
plot(x, table2array(data_25degC(3, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '200 cycles');
plot(x, table2array(data_25degC(4, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '300 cycles');
plot(x, table2array(data_25degC(5, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '400 cycles');
plot(x, table2array(data_25degC(6, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '500 cycles');
xlabel('SOC (-)');
ylabel('Relative resistance (%)');
title('Resistance increase over cycles: 25 ^oC');
% ylim([80 100]);
xlim([0 1]);
grid on;
legend('Location', 'best');
saveas(gcf, fullfile(output_path, 'RPT_resistance_increase_25degC.png'));

figure('Position', [100, 100, 600, 400]);
hold on;
plot(x, table2array(data_45degC(1, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '0 cycles');
plot(x, table2array(data_45degC(2, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '100 cycles');
plot(x, table2array(data_45degC(3, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '200 cycles');
plot(x, table2array(data_45degC(4, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '300 cycles');
plot(x, table2array(data_45degC(5, 6:13)) .* 100, 'o-', 'MarkerSize', 6, 'LineWidth', 2, 'DisplayName', '331 cycles');
xlabel('SOC (-)');
ylabel('Relative resistance (%)');
title('Resistance increase over cycles: 45 ^oC');
% ylim([80 100]);
xlim([0 1]);
grid on;
legend('Location', 'best');
saveas(gcf, fullfile(output_path, 'RPT_resistance_increase_45degC.png'));

% Extract relevant columns
cycles = data_25degC.Cycles;
discharge_capacity = data_25degC.DischargeCapacity_Ah_;
relative_capacity = data_25degC.RelativeDischargeCapacity___ * 100;

% --- Curve fitting ---
exp_model = @(a, b, x) 100 * exp(-(x ./ a) .^ b);
x_fit = linspace(min(cycles), 20 * max(cycles), 100);

% === Plot curve fits ===
% b = 0.6
figure('Position', [100, 100, 700, 400]);
hold on;
plot(data_25degC.Cycles, data_25degC.RelativeDischargeCapacity___ * 100, 'ko', 'MarkerSize', 6, 'DisplayName', 'RPT data');
xlabel('Cycle number');
ylabel('Relative capacity (%)');
title('Extrapolation with beta = 0.6');
ylim([80 100]);
xlim([0 4000]);
grid on;
fit_eq = fittype('100 * exp(-(x/a) ^ 0.6)', 'independent', 'x', 'coefficients', 'a');
fit_result = fit(cycles, relative_capacity, fit_eq, 'StartPoint', 10000);
a_exp = fit_result.a;
plot(x_fit, exp_model(a_exp, 0.6, x_fit), 'LineWidth', 1.5, 'DisplayName', 'curve fit, b=0.6');
saveas(gcf, fullfile(output_path, 'extrapolation_25degC_beta06.png'));

% b = 0.8
figure('Position', [100, 100, 700, 400]);
hold on;
plot(data_25degC.Cycles, data_25degC.RelativeDischargeCapacity___ * 100, 'ko', 'MarkerSize', 6, 'DisplayName', 'RPT data');
xlabel('Cycle number');
ylabel('Relative capacity (%)');
title('Extrapolation with beta = 0.8');
ylim([80 100]);
xlim([0 4000]);
grid on;
fit_eq = fittype('100 * exp(-(x/a) ^ 0.8)', 'independent', 'x', 'coefficients', 'a');
fit_result = fit(cycles, relative_capacity, fit_eq, 'StartPoint', 10000);
a_exp = fit_result.a;
plot(x_fit, exp_model(a_exp, 0.8, x_fit), 'b-', 'LineWidth', 1.5, 'DisplayName', 'curve fit, b=0.8');
saveas(gcf, fullfile(output_path, 'extrapolation_25degC_beta08.png'));


