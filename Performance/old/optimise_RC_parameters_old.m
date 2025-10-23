clear; clc; close all;

%% Input
temperature = 10;
capacity = 115.8;
test_path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\02_Analysis\03_Pulse_data';
mat_files = dir(fullfile(test_path, string(temperature), '*.mat'));
params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\Updated params';

% Import excel with OCV, R0
ocv_data = readmatrix(fullfile(params_path, 'OCV.xlsx'), Sheet='Averaged');
OCV.SOC = ocv_data(2:end, 1);
OCV.T = ocv_data(1, 2:end);
OCV.V = ocv_data(2:end, 2:end);
data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'R0_charge');
R0_charge.SOC = data(1, 2:end);
R0_charge.T = data(2:end, 1);
R0_charge.R = data(2:end, 2:end);
data = readmatrix(fullfile(params_path, 'RC_params.xlsx'), 'Sheet', 'R0_discharge');
R0_discharge.SOC = data(1, 2:end);
R0_discharge.T = data(2:end, 1);
R0_discharge.R = data(2:end, 2:end);
    
% Define the initial guesses for parameters [R1, C1, R2, C2, R3, C3, soc_in]
tau1_init = 5;
tau2_init = 50;
tau3_init = 500;
R1_init = 0.0005;
R2_init = 0.0005;
R3_init = 0.0005;
scaling_factor_C1 = (tau1_init / R1_init) / R1_init;
scaling_factor_C2 = (tau2_init / R2_init) / R2_init;
scaling_factor_C3 = (tau3_init / R3_init) / R3_init;
C1_init = (tau1_init / R1_init) / scaling_factor_C1;
C2_init = (tau2_init / R2_init) / scaling_factor_C2;
C3_init = (tau3_init / R3_init) / scaling_factor_C3;
capacity_init = capacity;  % Ah

% Define the threshold time to separate into long or short pulses
min_time_short_pulses = 25;
max_time_short_pulses = 35;
min_time_long_pulses = 600;
max_time_long_pulses = 1200;

%% Loop through all the HPPC files for a given temperature
R1_charge_all = table([], [], 'VariableNames', {'SOC', 'R'});
C1_charge_all = table([], [], 'VariableNames', {'SOC', 'C'});
R2_charge_all = table([], [], 'VariableNames', {'SOC', 'R'});
C2_charge_all = table([], [], 'VariableNames', {'SOC', 'C'});
R3_charge_all = table([], [], 'VariableNames', {'SOC', 'R'});
C3_charge_all = table([], [], 'VariableNames', {'SOC', 'C'});
R1_discharge_all = table([], [], 'VariableNames', {'SOC', 'R'});
C1_discharge_all = table([], [], 'VariableNames', {'SOC', 'C'});
R2_discharge_all = table([], [], 'VariableNames', {'SOC', 'R'});
C2_discharge_all = table([], [], 'VariableNames', {'SOC', 'C'});
R3_discharge_all = table([], [], 'VariableNames', {'SOC', 'R'});
C3_discharge_all = table([], [], 'VariableNames', {'SOC', 'C'});
for j = 1:length(mat_files)
    load(fullfile(mat_files(j).folder, mat_files(j).name));
    %% Separate short and long pulses
    short_pulses = pulse_data([]);
    long_pulses = pulse_data([]);
    for i = 1:length(pulse_data)
        if (pulse_data(i).pulse_duration > min_time_short_pulses) && (pulse_data(i).pulse_duration < max_time_short_pulses)
            short_pulses(end+1) = pulse_data(i);
        elseif (pulse_data(i).pulse_duration > min_time_long_pulses) && (pulse_data(i).pulse_duration < max_time_long_pulses)
            long_pulses(end+1) = pulse_data(i);
        else
            continue;
        end
    end

    % Initialise variables so that Simulink doesn't complain. These
    % variables aren't actually used in this step
    R3_from_optim = table('Size', [21, 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'SOC', 'R'});
    C3_from_optim = table('Size', [21, 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'SOC', 'C'});
    R3_from_optim.SOC = linspace(0, 1, height(R3_from_optim))';
    C3_from_optim.SOC = linspace(0, 1, height(C3_from_optim))';
    R3_from_optim.R = rand(height(R3_from_optim), 1);
    C3_from_optim.C = rand(height(C3_from_optim), 1);
    
    %% Loop through the long pulses to find R3, C3
    R1_charge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'R', 'std'});
    C1_charge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'C', 'std'});
    R2_charge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'R', 'std'});
    C2_charge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'C', 'std'});
    R3_charge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'R', 'std'});
    C3_charge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'C', 'std'});
    R1_discharge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'R', 'std'});
    C1_discharge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'C', 'std'});
    R2_discharge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'R', 'std'});
    C2_discharge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'C', 'std'});
    R3_discharge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'R', 'std'});
    C3_discharge_out = table('Size', [length(long_pulses), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'SOC', 'C', 'std'});
    pulses = long_pulses;
    optimise_long = true;  % Used inside the simulink model
    for i = 1:length(pulses)
        time = pulses(i).time_reset;
        current = timeseries(pulses(i).current, time);
        actual_voltage = timeseries(pulses(i).voltage, time);
        stop_time = time(end) + 1;
        
        soc_end = interp1(OCV.V(:, find(OCV.T == temperature)), OCV.SOC, actual_voltage.Data(end));
        soc_in = interp1(OCV.V(:, find(OCV.T == temperature)), OCV.SOC, actual_voltage.Data(1));
%         soc_in = soc_end - trapz(current.Time, current.Data) / 3600 / capacity_init;
        avg_soc = mean([soc_end, soc_in]);  % Average SOC during the pulse

        if pulses(i).median_current < 0
            R0 = R0_discharge;
        else
            R0 = R0_charge;
        end
        
        % Optimisation options
        initial_params = [R1_init, C1_init, R2_init, C2_init, R3_init, C3_init, capacity_init];
        lb = [R1_init*0.01, C1_init*0.01, R2_init*0.01, C2_init*0.01, R3_init*0.01, C3_init*0.01, capacity_init*0.5];
        ub = [R1_init*100, C1_init*100, R2_init*100, C2_init*100, R3_init*100, C3_init*100, capacity_init*2];
    %     options = optimoptions('lsqnonlin', 'Algorithm', 'trust-region-reflective', 'MaxIter', 100, 'Display', 'iter', 'TolFun', 1e-12, 'TolX', 1e-12);
        options = optimoptions('lsqnonlin', 'MaxIter', 100, 'Display', 'iter', 'TolFun', 1e-6, 'TolX', 1e-6);
        
        % Perform optimisation using lsqnonlin
        [optimal_params, resnorm, residual, ~, ~, ~, jacobian] = lsqnonlin(@(params) long_optimisation(params, current, time, actual_voltage, scaling_factor_C1, scaling_factor_C2, scaling_factor_C3), initial_params, lb, ub, options);
        
        R1 = optimal_params(1);
        C1 = optimal_params(2) * scaling_factor_C1;
        R2 = optimal_params(3);
        C2 = optimal_params(4) * scaling_factor_C2;
        R3 = optimal_params(5);
        C3 = optimal_params(6) * scaling_factor_C3;
        capacity = optimal_params(7);

        J = full(jacobian);
        n_params = length(optimal_params);
        n_residuals = length(residual);
        mse = resnorm / (n_residuals - n_params);
        covariance_matrix = inv(J' * J) * mse;
        param_std = sqrt(diag(covariance_matrix));
        
        % Display the optimized parameters
        disp('Optimized Parameters:');
        disp(['R1 = ', num2str(R1), ' ohms']);
        disp(['C1 = ', num2str(C1), ' F']);
        disp(['tau1 = ', num2str(R1 * C1), ' s']);
        disp(['R2 = ', num2str(R2), ' ohms']);
        disp(['C2 = ', num2str(C2), ' F']);
        disp(['tau2 = ', num2str(R2 * C2), ' s']);
        disp(['R3 = ', num2str(R3), ' ohms']);
        disp(['C3 = ', num2str(C3), ' F']);
        disp(['tau3 = ', num2str(R3 * C3), ' s']);
        disp(['capacity = ', num2str(capacity)]);
        disp('Parameter Standard Deviations (Sensitivity Estimate):');
        disp(param_std);
        
        simOut = sim('Circuit_3RC_single_optimiser', 'SrcWorkspace', 'base');
        sim_voltage = reshape(simOut.sim_voltage, [1, length(simOut.sim_voltage)]);
        figure; hold on;
        xlabel('Time (s)');
        ylabel('Voltage (V)');
        grid on; grid minor;
        plot(actual_voltage, 'DisplayName', 'exp', 'LineWidth', 2);
        plot(simOut.tout, sim_voltage, 'DisplayName', 'sim', 'LineWidth', 2);
        title(sprintf('pulse #%d', i));
        legend();

        textString = sprintf('SOC: %.2f\nR3: %.6f\nC3: %.0f\ntau3: %.0f', avg_soc, R3, C3, R3*C3);
        x_limits = xlim; y_limits = ylim;
        x_position = x_limits(2) - 0.3 * (x_limits(2) - x_limits(1));
        y_position = y_limits(1) + 0.2 * (y_limits(2) - y_limits(1));
        text(x_position, y_position, textString, 'FontSize', 12, 'Color', 'black');
        % try
        %     exportgraphics(gcf, fullfile(params_path, sprintf('long_pulses_%ddegC.pdf', temperature)), 'Append', true);
        % catch ME
        %     disp(ME.message);
        % end

        if pulses(i).median_current < 0
            R1_discharge_out.SOC(i) = avg_soc;
            R1_discharge_out.R(i) = R1;
            C1_discharge_out.SOC(i) = avg_soc;
            C1_discharge_out.C(i) = C1;
            R2_discharge_out.SOC(i) = avg_soc;
            R2_discharge_out.R(i) = R2;
            C2_discharge_out.SOC(i) = avg_soc;
            C2_discharge_out.C(i) = C2;
            R3_discharge_out.SOC(i) = avg_soc;
            R3_discharge_out.R(i) = R3;
            C3_discharge_out.SOC(i) = avg_soc;
            C3_discharge_out.C(i) = C3;
        else
            R1_charge_out.SOC(i) = avg_soc;
            R1_charge_out.R(i) = R1;
            C1_charge_out.SOC(i) = avg_soc;
            C1_charge_out.C(i) = C1;
            R2_charge_out.SOC(i) = avg_soc;
            R2_charge_out.R(i) = R2;
            C2_charge_out.SOC(i) = avg_soc;
            C2_charge_out.C(i) = C2;
            R3_charge_out.SOC(i) = avg_soc;
            R3_charge_out.R(i) = R3;
            C3_charge_out.SOC(i) = avg_soc;
            C3_charge_out.C(i) = C3;
        end
    end
    R1_charge_out(sum(table2array(R1_charge_out), 2) == 0, :) = [];
    C1_charge_out(sum(table2array(C1_charge_out), 2) == 0, :) = [];
    R2_charge_out(sum(table2array(R2_charge_out), 2) == 0, :) = [];
    C2_charge_out(sum(table2array(C2_charge_out), 2) == 0, :) = [];
    R3_charge_out(sum(table2array(R3_charge_out), 2) == 0, :) = [];
    C3_charge_out(sum(table2array(C3_charge_out), 2) == 0, :) = [];
    R1_discharge_out(sum(table2array(R1_discharge_out), 2) == 0, :) = [];
    C1_discharge_out(sum(table2array(C1_discharge_out), 2) == 0, :) = [];
    R2_discharge_out(sum(table2array(R2_discharge_out), 2) == 0, :) = [];
    C2_discharge_out(sum(table2array(C2_discharge_out), 2) == 0, :) = [];
    R3_discharge_out(sum(table2array(R3_discharge_out), 2) == 0, :) = [];
    C3_discharge_out(sum(table2array(C3_discharge_out), 2) == 0, :) = [];

    R3_charge_from_optim = sortrows(R3_charge_out, 'SOC');
    C3_charge_from_optim = sortrows(C3_charge_out, 'SOC');
    R3_discharge_from_optim = sortrows(R3_discharge_out, 'SOC');
    C3_discharge_from_optim = sortrows(C3_discharge_out, 'SOC');
    save(fullfile(params_path, sprintf('params_from_long_pulses_%d_%d.mat', temperature, j)), 'R1_charge_out', 'C1_charge_out', 'R2_charge_out', 'C2_charge_out', 'R3_charge_out', 'C3_charge_out', ...
        'R1_discharge_out', 'C1_discharge_out', 'R2_discharge_out', 'C2_discharge_out', 'R3_discharge_out', 'C3_discharge_out');
    save(fullfile(params_path, sprintf('R3C3_from_optim_%d_%d.mat', temperature, j)), 'R3_charge_from_optim', 'C3_charge_from_optim', 'R3_discharge_from_optim', 'C3_discharge_from_optim');

    %% Loop through all pulses to find R1, C1, R2, C2
    R1_charge_out = table('Size', [length(pulse_data), 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'SOC', 'R'});
    C1_charge_out = table('Size', [length(pulse_data), 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'SOC', 'C'});
    R2_charge_out = table('Size', [length(pulse_data), 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'SOC', 'R'});
    C2_charge_out = table('Size', [length(pulse_data), 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'SOC', 'C'});
    R1_discharge_out = table('Size', [length(pulse_data), 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'SOC', 'R'});
    C1_discharge_out = table('Size', [length(pulse_data), 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'SOC', 'C'});
    R2_discharge_out = table('Size', [length(pulse_data), 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'SOC', 'R'});
    C2_discharge_out = table('Size', [length(pulse_data), 2], 'VariableTypes', {'double', 'double'}, 'VariableNames', {'SOC', 'C'});

    pulses = pulse_data;
    optimise_long = false;
    R3 = 0; % Set to 0 just so that Simulink doesn't complain. The actual values are used from R3_from_optim
    C3 = 0;
    for i = 1:length(pulses)
        time_full = pulses(i).time_reset;
        actual_voltage_full = timeseries(pulses(i).voltage, time_full);

        time = time_full(time_full < pulses(i).pulse_duration * 10);  % Use relaxation time as a portion of total pulse time
        current = timeseries(pulses(i).current(1:length(time)), time);
        actual_voltage = timeseries(pulses(i).voltage(1:length(time)), time);
        stop_time = time(end) + 1;

        soc_end = interp1(OCV.V(:, find(OCV.T == temperature)), OCV.SOC, actual_voltage.Data(end));
        soc_in = interp1(OCV.V(:, find(OCV.T == temperature)), OCV.SOC, actual_voltage.Data(1));
        avg_soc = mean([soc_end, soc_in]);  % Average SOC during the pulse

        if pulses(i).median_current < 0
            R0 = R0_discharge;
            R3_from_optim = R3_discharge_from_optim;
            C3_from_optim = C3_discharge_from_optim;
        else
            R0 = R0_charge;
            R3_from_optim = R3_charge_from_optim;
            C3_from_optim = C3_charge_from_optim;
        end
        
        % Optimisation options
        initial_params = [R1_init, C1_init, R2_init, C2_init, capacity_init];
        lb = [R1_init*0.01, C1_init*0.01, R2_init*0.01, C2_init*0.01, capacity_init*0.5];
        ub = [R1_init*100, C1_init*100, R2_init*100, C2_init*100, capacity_init*2];
%         options = optimoptions('lsqnonlin', 'Algorithm', 'trust-region-reflective', 'MaxIter', 100, 'Display', 'iter', 'TolFun', 1e-12, 'TolX', 1e-12);
        options = optimoptions('lsqnonlin', 'MaxIter', 100, 'Display', 'iter', 'TolFun', 1e-6, 'TolX', 1e-6);
        
        % Perform optimisation using lsqnonlin
        [optimal_params, resnorm] = lsqnonlin(@(params) short_optimisation(params, current, time, actual_voltage, scaling_factor_C1, scaling_factor_C2), initial_params, lb, ub, options);
        
        R1 = optimal_params(1);
        C1 = optimal_params(2) * scaling_factor_C1;
        R2 = optimal_params(3);
        C2 = optimal_params(4) * scaling_factor_C2;
        capacity = optimal_params(5);
        
        % Display the optimised parameters
        disp('Optimised Parameters:');
        disp(['R1 = ', num2str(R1), ' ohms']);
        disp(['C1 = ', num2str(C1), ' F']);
        disp(['R2 = ', num2str(R2), ' ohms']);
        disp(['C2 = ', num2str(C2), ' F']);
        disp(['capacity = ', num2str(capacity)]);
        
        simOut = sim('Circuit_3RC_single_optimiser', 'SrcWorkspace', 'base');
        sim_voltage = reshape(simOut.sim_voltage, [1, length(simOut.sim_voltage)]);
        figure; hold on;
        xlabel('Time (s)');
        ylabel('Voltage (V)');
        grid on; grid minor;
        plot(actual_voltage, 'DisplayName', 'exp', 'LineWidth', 2);
        plot(simOut.tout, sim_voltage, 'DisplayName', 'sim', 'LineWidth', 2);
        title(sprintf('pulse #%d', i));
        legend();

        textString = sprintf('SOC: %.2f\nR1: %.6f\nC1: %.0f\ntau1: %.0f\nR2: %.6f\nC2: %.0f\ntau2: %.0f', avg_soc, R1, C1, R1*C1, R2, C2, R2*C2);
        x_limits = xlim;
        y_limits = ylim;
        x_position = x_limits(2) - 0.3 * (x_limits(2) - x_limits(1));
        y_position = y_limits(1) + 0.3 * (y_limits(2) - y_limits(1));
        text(x_position, y_position, textString, 'FontSize', 12, 'Color', 'black');
        try
            exportgraphics(gcf, fullfile(params_path, sprintf('all_pulses_%ddegC.pdf', temperature)), 'Append', true);
        catch ME
            disp(ME.message);
        end
    
        if pulses(i).median_current < 0
            R1_discharge_out.SOC(i) = avg_soc;
            R1_discharge_out.R(i) = R1;
            C1_discharge_out.SOC(i) = avg_soc;
            C1_discharge_out.C(i) = C1;
            R2_discharge_out.SOC(i) = avg_soc;
            R2_discharge_out.R(i) = R2;
            C2_discharge_out.SOC(i) = avg_soc;
            C2_discharge_out.C(i) = C2;
        else
            R1_charge_out.SOC(i) = avg_soc;
            R1_charge_out.R(i) = R1;
            C1_charge_out.SOC(i) = avg_soc;
            C1_charge_out.C(i) = C1;
            R2_charge_out.SOC(i) = avg_soc;
            R2_charge_out.R(i) = R2;
            C2_charge_out.SOC(i) = avg_soc;
            C2_charge_out.C(i) = C2;
        end
    end
    R1_charge_out(sum(table2array(R1_charge_out), 2) == 0, :) = [];
    C1_charge_out(sum(table2array(C1_charge_out), 2) == 0, :) = [];
    R2_charge_out(sum(table2array(R2_charge_out), 2) == 0, :) = [];
    C2_charge_out(sum(table2array(C2_charge_out), 2) == 0, :) = [];
    R3_charge_out(sum(table2array(R3_charge_out), 2) == 0, :) = [];
    C3_charge_out(sum(table2array(C3_charge_out), 2) == 0, :) = [];
    R1_discharge_out(sum(table2array(R1_discharge_out), 2) == 0, :) = [];
    C1_discharge_out(sum(table2array(C1_discharge_out), 2) == 0, :) = [];
    R2_discharge_out(sum(table2array(R2_discharge_out), 2) == 0, :) = [];
    C2_discharge_out(sum(table2array(C2_discharge_out), 2) == 0, :) = [];
    R3_discharge_out(sum(table2array(R3_discharge_out), 2) == 0, :) = [];
    C3_discharge_out(sum(table2array(C3_discharge_out), 2) == 0, :) = [];

    R1_charge_all = [R1_charge_all; R1_charge_out];
    C1_charge_all = [C1_charge_all; C1_charge_out];
    R2_charge_all = [R2_charge_all; R2_charge_out];
    C2_charge_all = [C2_charge_all; C2_charge_out];
    R3_charge_all = [R3_charge_all; R3_charge_out];
    C3_charge_all = [C3_charge_all; C3_charge_out];
    R1_discharge_all = [R1_discharge_all; R1_discharge_out];
    C1_discharge_all = [C1_discharge_all; C1_discharge_out];
    R2_discharge_all = [R2_discharge_all; R2_discharge_out];
    C2_discharge_all = [C2_discharge_all; C2_discharge_out];
    R3_discharge_all = [R3_discharge_all; R3_discharge_out];
    C3_discharge_all = [C3_discharge_all; C3_discharge_out];
end
save(fullfile(params_path, sprintf('all_params_%ddegC.mat', temperature)), 'R1_charge_all', 'C1_charge_all', 'R2_charge_all', 'C2_charge_all', 'R3_charge_all', 'C3_charge_all', ...
    'R1_discharge_all', 'C1_discharge_all', 'R2_discharge_all', 'C2_discharge_all', 'R3_discharge_all', 'C3_discharge_all');

function error = long_optimisation(params, current, time, actual_voltage, scaling_factor_C1, scaling_factor_C2, scaling_factor_C3)
    % Set up the parameters for Simulink
    R1 = params(1); C1 = params(2) * scaling_factor_C1;
    R2 = params(3); C2 = params(4) * scaling_factor_C2;
    R3 = params(5); C3 = params(6) * scaling_factor_C3;
    capacity = params(7);
    
    % Assign these parameters to the Simulink model workspace and run
    assignin('base', 'R1', R1);
    assignin('base', 'C1', C1);
    assignin('base', 'R2', R2);
    assignin('base', 'C2', C2);
    assignin('base', 'R3', R3);
    assignin('base', 'C3', C3);
    assignin('base', 'capacity', capacity)
    assignin('base', 'current', current);
    assignin('base', 'time', time);
    simOut = sim('Circuit_3RC_single_optimiser', 'SrcWorkspace', 'base');
    
    % Extract the simulated voltage and compare to actual voltage
    sim_voltage = reshape(simOut.sim_voltage, [length(simOut.sim_voltage), 1]);
    sim_voltage_interp = interp1(simOut.tout, sim_voltage, time, 'linear');
    error = actual_voltage.Data - sim_voltage_interp;
end

function error = short_optimisation(params, current, time, actual_voltage, scaling_factor_C1, scaling_factor_C2)
    % Set up the parameters for Simulink
    R1 = params(1); C1 = params(2) * scaling_factor_C1;
    R2 = params(3); C2 = params(4) * scaling_factor_C2;
    capacity = params(5);
    
    % Assign these parameters to the Simulink model workspace and run
    assignin('base', 'R1', R1);
    assignin('base', 'C1', C1);
    assignin('base', 'R2', R2);
    assignin('base', 'C2', C2);
    assignin('base', 'capacity', capacity)
    assignin('base', 'current', current);
    assignin('base', 'time', time);
    simOut = sim('Circuit_3RC_single_optimiser', 'SrcWorkspace', 'base');
    
    % Extract the simulated voltage and compare to actual voltage
    sim_voltage = reshape(simOut.sim_voltage, [length(simOut.sim_voltage), 1]);
    sim_voltage_interp = interp1(simOut.tout, sim_voltage, time, 'linear');
    error = actual_voltage.Data - sim_voltage_interp;
end
