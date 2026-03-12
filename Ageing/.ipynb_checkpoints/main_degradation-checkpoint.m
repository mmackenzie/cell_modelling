clear; clc; close all;

RPT_file_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Meridian\05_Engineering_Design\02_Module\00_Cell\02_Modelling\Cell_ageing_RPT_data.xlsx';
customer_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Ageing\Customer_profiles';
customers = {'Gotion_116Ah_1_cycle_per_day_Seville', 'Gotion_116Ah_300cycles_per_year_30degC_ambient', 'Gotion_116Ah_300cycles_per_year_25degC_ambient', ...
    'Gotion_116Ah_300cycles_per_year_20degC_ambient', 'Gotion_116Ah_300cycles_per_year_25degC_5degC_std_dev', 'Gotion_116Ah_300cycles_per_year_25degC_10degC_std_dev', ...
    'Gotion_116Ah_300cycles_per_year_25degC_15degC_std_dev', 'Gotion_116Ah_600cycles_per_year_20degC_1degC_std_dev', 'Gotion_116Ah_600cycles_per_year_25degC_1degC_std_dev', ...
    'Gotion_116Ah_600cycles_per_year_30degC_1degC_std_dev', 'Gotion_116Ah_600cycles_per_year_25degC_5degC_std_dev', 'Gotion_116Ah_600cycles_per_year_25degC_10degC_std_dev', ...
    'Gotion_116Ah_600cycles_per_year_25degC_15degC_std_dev', 'Gotion_116Ah_100cycles_per_year_20degC_1degC_std', 'Gotion_116Ah_100cycles_per_year_25degC_1degC_std', ...
    'Gotion_116Ah_100cycles_per_year_30degC_1degC_std', 'Gotion_116Ah_100cycles_per_year_25degC_5degC_std', 'Gotion_116Ah_100cycles_per_year_25degC_10degC_std', ...
    'Gotion_116Ah_100cycles_per_year_25degC_15degC_std'}';
n_customers = length(customers);
gotion_life_estimation_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Meridian\05_Engineering_Design\02_Module\00_Cell\01_Info received from Gotion\Life_estimations.xlsx';
nominal_capacity = 115.8;  % Ah
R = 8.314;  % J/(mol*K)
SOC_ref = 100;  % Reference SOC for calendar ageing

% --- Read RPT data ---
[storage_data, cycling_data] = read_RPT_data(RPT_file_path);

% --- Fit Models ---
model = fit_degradation_models(storage_data, cycling_data, R, SOC_ref);

% --- Calculate capacity fade for each customer ---
SOH_traj = cell(n_customers, 1);
Q_loss_calendar = cell(n_customers, 1);
Q_loss_cycling = cell(n_customers, 1);
time_axis = cell(n_customers, 1);
cycle_axis = cell(n_customers, 1);
years_75 = nan(n_customers, 1);
years_70 = nan(n_customers, 1);
cycles_75 = nan(n_customers, 1);
cycles_70 = nan(n_customers, 1);
pct_cycling = nan(n_customers, 1);
pct_storage = nan(n_customers, 1);
for i = 1:n_customers
    customer_profile_path = fullfile(customer_path, sprintf('%s.csv', string(customers(i))));
    [SOC_edges, T_edges, cal_hist, cyc_hist, time_summary] = profile_to_histograms(customer_profile_path, nominal_capacity);
    [soh, q_loss_cal, q_loss_cyc, time_days, cycles] = apply_degradation_models(model, cal_hist, cyc_hist, SOC_edges, T_edges);

    SOH_traj{i} = soh;
    time_axis{i} = time_days;
    cycle_axis{i} = cycles;
    Q_loss_cycling{i} = q_loss_cyc;
    Q_loss_calendar{i} = q_loss_cal;

    % --- Years and cycles to 75% and 70% SOH ---
    idx75 = find(soh <= 75, 1, 'first');
    idx70 = find(soh <= 70, 1, 'first');

    if ~isempty(idx75)
        years_75(i) = time_days(idx75) / 365;
        cycles_75(i) = cycles(idx75);
    end
    if ~isempty(idx70)
        years_70(i) = time_days(idx70) / 365;
        cycles_70(i) = cycles(idx70);
    end

    % --- Percent degradation contributions ---
    total_deg = q_loss_cyc(end) + q_loss_cal(end);
    if total_deg > 0
        pct_cycling(i) = 100 * q_loss_cyc(end) / total_deg;
        pct_storage(i) = 100 * q_loss_cal(end) / total_deg;
    end
end

remove_str = 'Gotion_116Ah_';
customers = cellfun(@(x) strrep(x, remove_str, ''), customers, 'UniformOutput', false);
% --- Create summary table ---
customer_summary = table(string(customers), years_75, years_70, cycles_75, cycles_70, pct_cycling, pct_storage, ...
    'VariableNames', {'Customer', 'Years_to_75SOH', 'Years_to_70SOH', 'Cycles_to_75SOH', 'Cycles_to_70SOH', ...
                      'Percent_Cycling_Degradation', 'Percent_Storage_Degradation'});
disp(customer_summary);


% % --- Gotion's predictions ---
% gotion_cust1_estimation = readtable(gotion_life_estimation_path, 'Sheet', '1 cycle per day');
% gotion_cust2_estimation = readtable(gotion_life_estimation_path, 'Sheet', '2 cycles per day');

% --- Plot results ---
set(groot, 'defaultTextInterpreter', 'none');
set(groot, 'defaultLegendInterpreter', 'none');
set(groot, 'defaultAxesTickLabelInterpreter', 'none');
defaultColours = get(groot, 'defaultAxesColorOrder');
colours = turbo(n_customers);
figure;
hold on;
for i = 1:n_customers
    plot(time_axis{i} / 365, SOH_traj{i}, 'Color', colours(i, :), 'LineWidth', 2, 'DisplayName', customers{i});
end
xlabel('Time [years]');
ylabel('SOH [%]');
grid on; ylim([69 100]);
title('SOH prediction vs time');
legend();

figure;
hold on;
for i = 1:n_customers
    plot(cycle_axis{i}, SOH_traj{i}, 'Color', colours(i, :), 'LineWidth', 2, 'DisplayName', customers{i});
end
xlabel('Cycles');
ylabel('SOH [%]');
grid on; ylim([69 100]);
title('SOH prediction vs cycles');
legend();
