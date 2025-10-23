% clear; clc; close all;

%% Input
temperature = 45;
capacity = 115.8;
test_path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\02_Analysis\03_Pulse_data';
mat_files = dir(fullfile(test_path, string(temperature), '*.mat'));
params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Gotion_115.8Ah\Updated params';
SOC_output = (0:0.05:1)';

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

% Define the pulse threshold time
min_time_pulses = 25;
max_time_pulses = 1200;

%% Loop through all the HPPC files for a given temperature
R1_charge_all = table([], [], [], 'VariableNames', {'SOC', 'R', 'std'});
C1_charge_all = table([], [], [], 'VariableNames', {'SOC', 'C', 'std'});
R2_charge_all = table([], [], [], 'VariableNames', {'SOC', 'R', 'std'});
C2_charge_all = table([], [], [], 'VariableNames', {'SOC', 'C', 'std'});
R3_charge_all = table([], [], [], 'VariableNames', {'SOC', 'R', 'std'});
C3_charge_all = table([], [], [], 'VariableNames', {'SOC', 'C', 'std'});
R1_discharge_all = table([], [], [], 'VariableNames', {'SOC', 'R', 'std'});
C1_discharge_all = table([], [], [], 'VariableNames', {'SOC', 'C', 'std'});
R2_discharge_all = table([], [], [], 'VariableNames', {'SOC', 'R', 'std'});
C2_discharge_all = table([], [], [], 'VariableNames', {'SOC', 'C', 'std'});
R3_discharge_all = table([], [], [], 'VariableNames', {'SOC', 'R', 'std'});
C3_discharge_all = table([], [], [], 'VariableNames', {'SOC', 'C', 'std'});
% for j = 1:length(mat_files)
    j = 1;
    load(fullfile(mat_files(j).folder, mat_files(j).name));

    pulses = pulse_data([]);
    for i = 1:length(pulse_data)
        if (pulse_data(i).pulse_duration > min_time_pulses) && (pulse_data(i).pulse_duration < max_time_pulses)
            pulses(end+1) = pulse_data(i);
        else
            continue;
        end
    end

    optimise_long = false;  % Used inside the simulink model
    % for i = 1:length(pulses)
    i = 13;
        tic;
        time_full = pulses(i).time_reset;
        actual_voltage_full = timeseries(pulses(i).voltage, time_full);

        time = time_full(time_full < pulses(i).pulse_duration * 10);  % Use relaxation time as a portion of total pulse time
        current = timeseries(pulses(i).current(1:length(time)), time);
        actual_voltage = timeseries(pulses(i).voltage(1:length(time)), time);
        stop_time = time(end) + 1;

        soc_end = interp1(OCV.V(:, find(OCV.T == temperature)), OCV.SOC, actual_voltage_full.Data(end), "linear", 'extrap');
        soc_in = interp1(OCV.V(:, find(OCV.T == temperature)), OCV.SOC, actual_voltage_full.Data(1), "linear", 'extrap');
        avg_soc = mean([soc_end, soc_in]);  % Average SOC during the pulse

        if pulses(i).median_current < 0
            R0 = R0_discharge;
        else
            R0 = R0_charge;
        end
        
        % Optimisation options
        initial_params = [R1_init, C1_init, R2_init, C2_init, R3_init, C3_init, capacity_init];
        lb = [R1_init*0.1, C1_init*0.01, R2_init*0.1, C2_init*0.01, R3_init*0.1, C3_init*0.01, capacity_init*0.8];
        ub = [R1_init*10, C1_init*100, R2_init*10, C2_init*100, R3_init*10, C3_init*100, capacity_init*1.2];

        % % Original
        % % Perform optimisation using lsqnonlin
        % options = optimoptions('lsqnonlin', 'MaxIter', 100, 'Display', 'iter', 'TolFun', 1e-6, 'TolX', 1e-6);
        % [optimal_params, resnorm, residual, ~, ~, ~, jacobian] = lsqnonlin(@(params) pulse_optimisation(params, current, time, actual_voltage, scaling_factor_C1, scaling_factor_C2, scaling_factor_C3), initial_params, lb, ub, options);

        % % Using GlobalSearch
        % obj_fun = @(params) sum(pulse_optimisation(params, current, time, actual_voltage, scaling_factor_C1, scaling_factor_C2, scaling_factor_C3).^2);
        % options = optimoptions('fmincon', 'MaxIter', 100, 'Display', 'iter', 'Algorithm', 'sqp', 'TolFun', 1e-6, 'TolX', 1e-6);
        % problem = createOptimProblem('fmincon', ...
        %     'x0', initial_params, ...
        %     'objective', obj_fun, ...
        %     'lb', lb, ...
        %     'ub', ub, ...
        %     'options', options);
        % 
        % gs = GlobalSearch('Display', 'iter', 'NumTrialPoints', 100, 'NumStageOnePoints', 50);
        % [optimal_params, fval, exitflag, output, solutions] = run(gs, problem);
        % [~, ~, residual, ~, ~, ~, jacobian] = lsqnonlin(problem.objective, x_best, lb, ub, options);

        % Using MultiStart
        options = optimoptions('lsqnonlin', 'Display', 'off', 'MaxIter', 100, 'TolFun', 1e-6, 'TolX', 1e-6);
        objective = @(params) pulse_optimisation(params, current, time, actual_voltage, ...
                                         scaling_factor_C1, scaling_factor_C2, scaling_factor_C3);
        problem = createOptimProblem('lsqnonlin', ...
            'x0', initial_params, ...
            'objective', objective, ...
            'lb', lb, ...
            'ub', ub, ...
            'options', options);
        ms = MultiStart('Display', 'iter', 'UseParallel', true);
        n_starts = 50;
        [result, fval] = run(ms, problem, n_starts);
        [optimal_params_final, resnorm, residual, ~, ~, ~, jacobian] = lsqnonlin(objective, result, lb, ub, options);

        J = full(jacobian);
        n_residuals = length(residual);
        n_parameters = length(optimal_params);
        covariance_matrix = inv(J' * J) * resnorm / (n_residuals - n_parameters);
        param_std = sqrt(diag(covariance_matrix));

        % Extract raw parameters (before scaling)
        R_vals = [optimal_params(1), optimal_params(3), optimal_params(5)];
        C_vals_scaled = [optimal_params(2), optimal_params(4), optimal_params(6)];
        C_vals = C_vals_scaled .* [scaling_factor_C1, scaling_factor_C2, scaling_factor_C3];
        
        % Calculate time constants and sort
        taus = R_vals .* C_vals;
        [~, sort_idx] = sort(taus);
        
        % Reorder R, C, and param_std using the same sort order
        R_vals_sorted = R_vals(sort_idx);
        C_vals_sorted = C_vals(sort_idx);
        param_std_RC = param_std([1, 3, 5; 2, 4, 6]); % 2-row matrix: R row, C row
        param_std_RC_sorted = param_std_RC(:, sort_idx);
        
        % Assign sorted values
        R1 = R_vals_sorted(1);  C1 = C_vals_sorted(1);  std_R1 = param_std_RC_sorted(1,1);  std_C1 = param_std_RC_sorted(2,1) * scaling_factor_C1;
        R2 = R_vals_sorted(2);  C2 = C_vals_sorted(2);  std_R2 = param_std_RC_sorted(1,2);  std_C2 = param_std_RC_sorted(2,2) * scaling_factor_C2;
        R3 = R_vals_sorted(3);  C3 = C_vals_sorted(3);  std_R3 = param_std_RC_sorted(1,3);  std_C3 = param_std_RC_sorted(2,3) * scaling_factor_C3;
        
        capacity = optimal_params(7);
        std_capacity = param_std(7);
        
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
        
        simOut = sim('Circuit_3RC_single_optimiser2', 'SrcWorkspace', 'base');
        sim_voltage = reshape(simOut.sim_voltage, [1, length(simOut.sim_voltage)]);
        figure; hold on;
        xlabel('Time (s)');
        ylabel('Voltage (V)');
        grid on; grid minor;
        plot(actual_voltage, 'DisplayName', 'exp', 'LineWidth', 2);
        plot(simOut.tout, sim_voltage, 'DisplayName', 'sim', 'LineWidth', 2);
        title(sprintf('file #%d, pulse #%d', j, i));
        legend();

        textString = sprintf('SOC: %.2f\nR1: %.6f\ntau1: %.0f\nR2: %.6f\ntau2: %.0f\nR3: %.6f\ntau3: %.0f', avg_soc, R1, R1*C1, R2, R2*C2, R3, R3*C3);
        x_limits = xlim; y_limits = ylim;
        x_position = x_limits(2) - 0.3 * (x_limits(2) - x_limits(1));
        y_position = y_limits(1) + 0.2 * (y_limits(2) - y_limits(1));
        text(x_position, y_position, textString, 'FontSize', 10, 'Color', 'black');
        % try
        %     exportgraphics(gcf, fullfile(params_path, sprintf('all_pulses_%ddegC.pdf', temperature)), 'Append', true);
        % catch ME
        %     disp(ME.message);
        % end

        if pulses(i).median_current < 0
            R1_discharge_all = [R1_discharge_all; table(avg_soc, R1, param_std(1), 'VariableNames', {'SOC', 'R', 'std'})];
            C1_discharge_all = [C1_discharge_all; table(avg_soc, C1, param_std(2) * scaling_factor_C1, 'VariableNames', {'SOC', 'C', 'std'})];
            R2_discharge_all = [R2_discharge_all; table(avg_soc, R2, param_std(3), 'VariableNames', {'SOC', 'R', 'std'})];
            C2_discharge_all = [C2_discharge_all; table(avg_soc, C2, param_std(4) * scaling_factor_C2, 'VariableNames', {'SOC', 'C', 'std'})];
            R3_discharge_all = [R3_discharge_all; table(avg_soc, R3, param_std(5), 'VariableNames', {'SOC', 'R', 'std'})];
            C3_discharge_all = [C3_discharge_all; table(avg_soc, C3, param_std(6) * scaling_factor_C3, 'VariableNames', {'SOC', 'C', 'std'})];
        else
            R1_charge_all = [R1_charge_all; table(avg_soc, R1, param_std(1), 'VariableNames', {'SOC', 'R', 'std'})];
            C1_charge_all = [C1_charge_all; table(avg_soc, C1, param_std(2) * scaling_factor_C1, 'VariableNames', {'SOC', 'C', 'std'})];
            R2_charge_all = [R2_charge_all; table(avg_soc, R2, param_std(3), 'VariableNames', {'SOC', 'R', 'std'})];
            C2_charge_all = [C2_charge_all; table(avg_soc, C2, param_std(4) * scaling_factor_C2, 'VariableNames', {'SOC', 'C', 'std'})];
            R3_charge_all = [R3_charge_all; table(avg_soc, R3, param_std(5), 'VariableNames', {'SOC', 'R', 'std'})];
            C3_charge_all = [C3_charge_all; table(avg_soc, C3, param_std(6) * scaling_factor_C3, 'VariableNames', {'SOC', 'C', 'std'})];
        end
        elapsed_time = toc;
        fprintf('Elapsed time: %.1f seconds\n', elapsed_time);
    % end
% end
% save(fullfile(params_path, sprintf('all_params_%ddegC.mat', temperature)), 'R1_charge_all', 'C1_charge_all', 'R2_charge_all', 'C2_charge_all', 'R3_charge_all', 'C3_charge_all', ...
%     'R1_discharge_all', 'C1_discharge_all', 'R2_discharge_all', 'C2_discharge_all', 'R3_discharge_all', 'C3_discharge_all');

function error = pulse_optimisation(params, current, time, actual_voltage, scaling_factor_C1, scaling_factor_C2, scaling_factor_C3)
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
    simOut = sim('Circuit_3RC_single_optimiser2', 'SrcWorkspace', 'base');
    
    % Extract the simulated voltage and compare to actual voltage
    sim_voltage = reshape(simOut.sim_voltage, [length(simOut.sim_voltage), 1]);
    sim_voltage_interp = interp1(simOut.tout, sim_voltage, time, 'linear');
    error = actual_voltage.Data - sim_voltage_interp;
end
