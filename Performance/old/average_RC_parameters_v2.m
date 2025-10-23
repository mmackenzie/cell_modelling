clear; close all; clc;

params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\Updated params';
temperature = 10;
SOC_output = (0:0.05:1)';

load(fullfile(params_path, sprintf("all_params_%ddegC.mat", temperature)));

tau1_charge_all = table(C1_charge_all.SOC, R1_charge_all.R .* C1_charge_all.C, R1_charge_all.std .* C1_charge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});
tau2_charge_all = table(C2_charge_all.SOC, R2_charge_all.R .* C2_charge_all.C, R2_charge_all.std .* C2_charge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});
tau3_charge_all = table(C3_charge_all.SOC, R3_charge_all.R .* C3_charge_all.C, R3_charge_all.std .* C3_charge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});
tau1_discharge_all = table(C1_discharge_all.SOC, R1_discharge_all.R .* C1_discharge_all.C, R1_discharge_all.std .* C1_discharge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});
tau2_discharge_all = table(C2_discharge_all.SOC, R2_discharge_all.R .* C2_discharge_all.C, R2_discharge_all.std .* C2_discharge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});
tau3_discharge_all = table(C3_discharge_all.SOC, R3_discharge_all.R .* C3_discharge_all.C, R3_discharge_all.std .* C3_discharge_all.std, 'VariableNames', {'SOC', 'tau', 'std'});

[R1_charge_averaged, R1_charge_lb, R1_charge_ub] = average_parameters(SOC_output, R1_charge_all, 'R');
[C1_charge_averaged, C1_charge_lb, C1_charge_ub] = average_parameters(SOC_output, C1_charge_all, 'C');
[R2_charge_averaged, R2_charge_lb, R2_charge_ub] = average_parameters(SOC_output, R2_charge_all, 'R');
[C2_charge_averaged, C2_charge_lb, C2_charge_ub] = average_parameters(SOC_output, C2_charge_all, 'C');
[R3_charge_averaged, R3_charge_lb, R3_charge_ub] = average_parameters(SOC_output, R3_charge_all, 'R');
[C3_charge_averaged, C3_charge_lb, C3_charge_ub] = average_parameters(SOC_output, C3_charge_all, 'C');
[R1_discharge_averaged, R1_discharge_lb, R1_discharge_ub] = average_parameters(SOC_output, R1_discharge_all, 'R');
[C1_discharge_averaged, C1_discharge_lb, C1_discharge_ub] = average_parameters(SOC_output, C1_discharge_all, 'C');
[R2_discharge_averaged, R2_discharge_lb, R2_discharge_ub] = average_parameters(SOC_output, R2_discharge_all, 'R');
[C2_discharge_averaged, C2_discharge_lb, C2_discharge_ub] = average_parameters(SOC_output, C2_discharge_all, 'C');
[R3_discharge_averaged, R3_discharge_lb, R3_discharge_ub] = average_parameters(SOC_output, R3_discharge_all, 'R');
[C3_discharge_averaged, C3_discharge_lb, C3_discharge_ub] = average_parameters(SOC_output, C3_discharge_all, 'C');

tau1_charge_averaged = R1_charge_averaged .* C1_charge_averaged;
tau2_charge_averaged = R2_charge_averaged .* C2_charge_averaged;
tau3_charge_averaged = R3_charge_averaged .* C3_charge_averaged;
tau1_discharge_averaged = R1_discharge_averaged .* C1_discharge_averaged;
tau2_discharge_averaged = R2_discharge_averaged .* C2_discharge_averaged;
tau3_discharge_averaged = R3_discharge_averaged .* C3_discharge_averaged;

% Extrapolate to 0% SOC using the values from 5 and 10% SOC
R2_discharge_averaged(1) = R2_discharge_averaged(2) / R2_discharge_averaged(3) * R2_discharge_averaged(2);
R3_discharge_averaged(1) = R3_discharge_averaged(2) / R3_discharge_averaged(3) * R3_discharge_averaged(2);
tau2_discharge_averaged(1) = tau2_discharge_averaged(2); % same as SOC=5%
tau3_discharge_averaged(1) = tau3_discharge_averaged(2);
C2_discharge_averaged(1) = tau2_discharge_averaged(1) / R2_discharge_averaged(1);
C3_discharge_averaged(1) = tau3_discharge_averaged(1) / R3_discharge_averaged(1);

R1_charge = table(SOC_output, R1_charge_averaged, 'VariableNames', {'SOC', 'R'});
R2_charge = table(SOC_output, R2_charge_averaged, 'VariableNames', {'SOC', 'R'});
R3_charge = table(SOC_output, R3_charge_averaged, 'VariableNames', {'SOC', 'R'});
C1_charge = table(SOC_output, C1_charge_averaged, 'VariableNames', {'SOC', 'C'});
C2_charge = table(SOC_output, C2_charge_averaged, 'VariableNames', {'SOC', 'C'});
C3_charge = table(SOC_output, C3_charge_averaged, 'VariableNames', {'SOC', 'C'});
R1_discharge = table(SOC_output, R1_discharge_averaged, 'VariableNames', {'SOC', 'R'});
R2_discharge = table(SOC_output, R2_discharge_averaged, 'VariableNames', {'SOC', 'R'});
R3_discharge = table(SOC_output, R3_discharge_averaged, 'VariableNames', {'SOC', 'R'});
C1_discharge = table(SOC_output, C1_discharge_averaged, 'VariableNames', {'SOC', 'C'});
C2_discharge = table(SOC_output, C2_discharge_averaged, 'VariableNames', {'SOC', 'C'});
C3_discharge = table(SOC_output, C3_discharge_averaged, 'VariableNames', {'SOC', 'C'});

save(fullfile(params_path, sprintf('all_params_averaged_%ddegC.mat', temperature)), "R1_charge", "R2_charge", "R3_charge", ...
    "C1_charge", "C2_charge", "C3_charge", ...
    "R1_discharge", "R2_discharge", "R3_discharge", ...
    "C1_discharge", "C2_discharge", "C3_discharge");

f1 = figure;
subplot(2, 3, 1);
hold on;
scatter(R1_discharge_all.SOC, R1_discharge_all.R, 'black');
plot(SOC_output, R1_discharge_averaged, 'red', 'LineWidth', 2);
fill([SOC_output; flip(SOC_output)], [R1_discharge_ub; flip(R1_discharge_lb)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R1 discharge');

subplot(2, 3, 2);
hold on;
scatter(R2_discharge_all.SOC, R2_discharge_all.R, 'black');
plot(SOC_output, R2_discharge_averaged, 'red', 'LineWidth', 2);
% fill([SOC_output; flip(SOC_output)], [R2_upper_bound; flip(R2_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R2 discharge');

subplot(2, 3, 3);
hold on;
scatter(R3_discharge_all.SOC, R3_discharge_all.R, 'black');
plot(SOC_output, R3_discharge_averaged, 'red', 'LineWidth', 2);
% fill([SOC_output; flip(SOC_output)], [R3_upper_bound; flip(R3_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R3 discharge');

subplot(2, 3, 4);
hold on;
scatter(tau1_discharge_all.SOC, tau1_discharge_all.tau, 'black');
plot(SOC_output, tau1_discharge_averaged, 'red', 'LineWidth', 2);
% fill([SOC_output; flip(SOC_output)], [tau1_upper_bound; flip(tau1_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Time constant (s)')
xlim([0 1]);
ylim([0 30]);
title('tau1 discharge');

subplot(2, 3, 5);
hold on;
scatter(tau2_discharge_all.SOC, tau2_discharge_all.tau, 'black');
plot(SOC_output, tau2_discharge_averaged, 'red', 'LineWidth', 2);
% fill([SOC_output; flip(SOC_output)], [tau1_upper_bound; flip(tau2_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Time constant (s)')
xlim([0 1]);
ylim([0 300]);
title('tau2 discharge');

subplot(2, 3, 6);
hold on;
scatter(tau3_discharge_all.SOC, tau3_discharge_all.tau, 'black');
plot(SOC_output, tau3_discharge_averaged, 'red', 'LineWidth', 2);
% fill([SOC_output; flip(SOC_output)], [tau1_upper_bound; flip(tau2_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Time constant (s)')
xlim([0 1]);
ylim([0 3000]);
title('tau3 discharge');


f2 = figure;
subplot(2, 3, 1);
hold on;
scatter(R1_discharge_all.SOC, R1_discharge_all.R, 'black');
plot(SOC_output, R1_discharge_averaged, 'red', 'LineWidth', 2);
fill([SOC_output; flip(SOC_output)], [R1_discharge_ub; flip(R1_discharge_lb)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R1 discharge');

subplot(2, 3, 2);
hold on;
scatter(R2_discharge_all.SOC, R2_discharge_all.R, 'black');
plot(SOC_output, R2_discharge_averaged, 'red', 'LineWidth', 2);
% fill([SOC_output; flip(SOC_output)], [R2_upper_bound; flip(R2_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R2 discharge');

subplot(2, 3, 3);
hold on;
scatter(R3_discharge_all.SOC, R3_discharge_all.R, 'black');
plot(SOC_output, R3_discharge_averaged, 'red', 'LineWidth', 2);
% fill([SOC_output; flip(SOC_output)], [R3_upper_bound; flip(R3_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Resistance (Ohms)')
xlim([0 1]);
ylim([0 2e-3]);
title('R3 discharge');

subplot(2, 3, 4);
hold on;
scatter(C1_discharge_all.SOC, C1_discharge_all.C, 'black');
plot(SOC_output, C1_discharge_averaged, 'red', 'LineWidth', 2);
% fill([SOC_output; flip(SOC_output)], [tau1_upper_bound; flip(tau1_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Capacitance (F)')
xlim([0 1]);
title('C1 discharge');

subplot(2, 3, 5);
hold on;
scatter(C2_discharge_all.SOC, C2_discharge_all.C, 'black');
plot(SOC_output, C2_discharge_averaged, 'red', 'LineWidth', 2);
% fill([SOC_output; flip(SOC_output)], [tau1_upper_bound; flip(tau1_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Capacitance (F)')
xlim([0 1]);
title('C2 discharge');

subplot(2, 3, 6);
hold on;
scatter(C3_discharge_all.SOC, C3_discharge_all.C, 'black');
plot(SOC_output, C3_discharge_averaged, 'red', 'LineWidth', 2);
% fill([SOC_output; flip(SOC_output)], [tau1_upper_bound; flip(tau1_lower_bound)], 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Hampel Band');
xlabel('SOC (%)')
ylabel('Capacitance (F)')
xlim([0 1]);
title('C3 discharge');
% 
% saveas(gcf, fullfile(params_path, sprintf('RC_averaging_%d.png', temperature)));


function [parameter_output, parameter_lower_bound, parameter_upper_bound] = average_parameters(SOC_target, parameter_input, type)
    parameter_output = nan(length(SOC_target), 1);
    parameter_upper_bound = nan(length(SOC_target), 1);
    parameter_lower_bound = nan(length(SOC_target), 1);
    for i = 1:length(SOC_target)
        current_SOC = SOC_target(i);
        SOC_start = current_SOC - 0.05;
        SOC_end = current_SOC + 0.05;

        % Extract values in SOC range
        indices = (parameter_input.SOC >= SOC_start) & (parameter_input.SOC <= SOC_end);
        if type == 'R'
            data = parameter_input.R(indices);
        elseif type == 'C'
            data = parameter_input.C(indices);
        else
            disp('Wrong type chosen in average_parameters')
        end
            
        std = parameter_input.std(indices);
        
        % Ensure no zero or NaN std values (which would blow up weights)
        valid = ~isnan(data) & ~isnan(std) & (std > 0);
        data = data(valid);
        std = std(valid);
        
        if ~isempty(data)
            % Compute weights as inverse variance (more confident = more weight)
            weights = 1 ./ std .^ 2;
        
            % Weighted average
            parameter_output(i) = sum(weights .* data) / sum(weights);
        
            % Optional: Compute weighted median bounds (for confidence intervals)
            weighted_mean = parameter_output(i);
            weighted_std = sqrt(1 / sum(weights));  % Approximate std of weighted mean
            parameter_upper_bound(i) = weighted_mean + 3 * weighted_std;
            parameter_lower_bound(i) = weighted_mean - 3 * weighted_std;
        end
    end
end