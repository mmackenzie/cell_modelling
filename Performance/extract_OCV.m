clear; clc; close all;

output_path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\02_Analysis\02_Comparison_to_Gotion_data';
test_path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\01_Results\04_PsuedoOCV';
gotion_ocv_path = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\05_Engineering_Design\02_Module\00_Cell\02_Modelling\Initial_parameters\OCV_orig.xlsx';

gotion_ocv_discharge = readtable(gotion_ocv_path, Sheet="Discharge_100SOH", ReadVariableNames=true);
gotion_ocv_charge = readtable(gotion_ocv_path, Sheet="Charge_100SOH", ReadVariableNames=true);
gotion_ocv_average = readtable(gotion_ocv_path, Sheet="Average_100SOH", ReadVariableNames=true);

temperatures = [0, 25, 45];
v_0 = 3.09;  % Reference voltage for SOC = 0
v_100 = 4.23;  % Reference voltage for SOC = 100

soc_range = (-0.05:0.01:1)';  % Interpolation range
soc_ocv_charge = array2table(soc_range, 'VariableNames', {'SOC'});
soc_ocv_discharge = array2table(soc_range, 'VariableNames', {'SOC'});
soc_ocv_averaged = array2table(soc_range, 'VariableNames', {'SOC'});

for temperature = temperatures
    folder_path = fullfile(test_path, num2str(temperature));
    files = dir(fullfile(folder_path, '*.xlsx'));

    ocv_all_charge = [];
    ocv_all_discharge = [];

    for file = files'
        % Read data from correct sheet
        sheets = sheetnames(fullfile(file.folder, file.name));
        detail_sheet = sheets(contains(sheets, 'Detail_') & ~contains(sheets, 'Temp'));
        electrical = readtable(fullfile(file.folder, file.name), 'Sheet', detail_sheet{1});

        % Extract signals
        time_raw = datetime(electrical.Date_h_min_s_ms_, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
        time_s = seconds(time_raw - time_raw(1));
        voltage = electrical.Voltage_V_;
        current = electrical.Current_A_;

        % Discharge-only data
        discharge_idx = current < 0;
        time_dis = time_s(discharge_idx);
        current_dis = current(discharge_idx);
        voltage_dis = voltage(discharge_idx);

        % Calculate discharge capacity cumulatively
        cap_dis = zeros(size(current_dis));
        for i = 2:length(current_dis)
            delta_t = time_dis(i) - time_dis(i-1);
            cap_dis(i) = cap_dis(i-1) + abs(current_dis(i)) * delta_t / 3600;
        end

        % SOC from discharge capacity, 0 at V = vref
        [~, idx_ref] = min(abs(voltage_dis - v_0));
        soc_dis = (cap_dis(idx_ref) - cap_dis) / cap_dis(idx_ref);

        % Charge segment: current > 0 and occurs after discharge
        end_discharge_time = time_s(find(discharge_idx, 1, 'last'));
        charge_idx = (current > 0) & (time_s > end_discharge_time);
        time_charge = time_s(charge_idx);
        current_charge = current(charge_idx);
        voltage_charge = voltage(charge_idx);

        % Calculate charge capacity cumulatively
        cap_charge = zeros(size(current_charge));
        for i = 2:length(current_charge)
            delta_t = time_charge(i) - time_charge(i-1);
            cap_charge(i) = cap_charge(i-1) + abs(current_charge(i)) * delta_t / 3600;
        end

        total_cap_charge = max(cap_charge);  % Total discharge capacity (Ah)

        % SOC from discharge capacity, 0 at V = vref
        [~, idx_ref] = min(abs(voltage_charge - v_0));
        soc_charge = (cap_charge - cap_charge(idx_ref)) / total_cap_charge;

        % Unique points for interpolation
        [soc_charge_unique, ia] = unique(soc_charge, 'stable');
        voltage_charge_unique = voltage_charge(ia);
        [soc_discharge_unique, ib] = unique(soc_dis, 'stable');
        voltage_discharge_unique = voltage_dis(ib);

        % Interpolate to common SOC axis
        v_interp_charge = interp1(soc_charge_unique, voltage_charge_unique, soc_range, 'linear', NaN);
        v_interp_discharge = interp1(soc_discharge_unique, voltage_discharge_unique, soc_range, 'linear', NaN);
        v_interp_charge(end) = v_100;
        v_interp_discharge(end) = v_100;

        ocv_all_charge = [ocv_all_charge, v_interp_charge];
        ocv_all_discharge = [ocv_all_discharge, v_interp_discharge];
    end

    % Average over all files
    ocv_charge_averaged = mean(ocv_all_charge, 2, 'omitnan');
    ocv_discharge_averaged = mean(ocv_all_discharge, 2, 'omitnan');
    ocv_averaged = mean([ocv_charge_averaged, ocv_discharge_averaged], 2, 'omitnan');

    % Store in tables
    soc_ocv_charge.(sprintf('%ddegC', temperature)) = ocv_charge_averaged;
    soc_ocv_discharge.(sprintf('%ddegC', temperature)) = ocv_discharge_averaged;
    soc_ocv_averaged.(sprintf('%ddegC', temperature)) = ocv_averaged;
end

% Plot
fig_ocv_charge = figure(Position=[100, 100, 800, 500]);
fig_ocv_discharge = figure(Position=[200, 200, 800, 500]);
fig_ocv_both = figure(Position=[300, 300, 800, 500]);
fig_ocv_averaged = figure(Position=[400, 400, 800, 500]);
fig_ocv_averaged_25 = figure(Position=[500, 500, 800, 500]);

figure(fig_ocv_charge);
hold on;
plot(soc_ocv_charge.SOC, soc_ocv_charge.("0degC"), 'b-', 'LineWidth', 2, 'DisplayName', "0°C")
plot(soc_ocv_charge.SOC, soc_ocv_charge.("25degC"), 'g-', 'LineWidth', 2, 'DisplayName', "25°C")
plot(soc_ocv_charge.SOC, soc_ocv_charge.("45degC"), 'r-', 'LineWidth', 2, 'DisplayName', "45°C")
plot(gotion_ocv_charge.SOC, gotion_ocv_charge.x0, 'b--', 'LineWidth', 2, 'DisplayName', "Gotion 0°C")
plot(gotion_ocv_charge.SOC, gotion_ocv_charge.x25, 'g--', 'LineWidth', 2, 'DisplayName', "Gotion 25°C")
plot(gotion_ocv_charge.SOC, gotion_ocv_charge.x40, 'r--', 'LineWidth', 2, 'DisplayName', "Gotion 40°C")
xlabel('SOC (-)');
ylabel('Voltage (V)');
title('Charge OCV curves');
xlim([-0.02 1]);
ylim([2.7 4.3]);
grid on;
grid minor;
legend(Location="best");
saveas(gcf, fullfile(output_path, 'Charge_OCV.png'));

figure(fig_ocv_discharge);
hold on;
plot(soc_ocv_discharge.SOC, soc_ocv_discharge.("0degC"), 'b-', 'LineWidth', 2, 'DisplayName', "0°C")
plot(soc_ocv_discharge.SOC, soc_ocv_discharge.("25degC"), 'g-', 'LineWidth', 2, 'DisplayName', "25°C")
plot(soc_ocv_discharge.SOC, soc_ocv_discharge.("45degC"), 'r-', 'LineWidth', 2, 'DisplayName', "45°C")
plot(gotion_ocv_discharge.SOC, gotion_ocv_discharge.x0, 'b--', 'LineWidth', 2, 'DisplayName', "Gotion 0°C")
plot(gotion_ocv_discharge.SOC, gotion_ocv_discharge.x25, 'g--', 'LineWidth', 2, 'DisplayName', "Gotion 25°C")
plot(gotion_ocv_discharge.SOC, gotion_ocv_discharge.x40, 'r--', 'LineWidth', 2, 'DisplayName', "Gotion 40°C")
xlabel('SOC (-)');
ylabel('Voltage (V)');
title('Discharge OCV curves');
xlim([-0.02 1]);
ylim([2.7 4.3]);
grid on;
grid minor;
legend(Location="best");
saveas(gcf, fullfile(output_path, 'Discharge_OCV.png'));

figure(fig_ocv_both);
hold on;
plot(soc_ocv_discharge.SOC, soc_ocv_discharge.("25degC"), 'g-', 'LineWidth', 2, 'DisplayName', "Discharge 25°C")
plot(soc_ocv_charge.SOC, soc_ocv_charge.("25degC"), 'r-', 'LineWidth', 2, 'DisplayName', "Charge 25°C")
plot(gotion_ocv_discharge.SOC, gotion_ocv_discharge.x25, 'g--', 'LineWidth', 2, 'DisplayName', "Gotion discharge 25°C")
plot(gotion_ocv_charge.SOC, gotion_ocv_charge.x25, 'r--', 'LineWidth', 2, 'DisplayName', "Gotion charge 25°C")
xlabel('SOC (-)');
ylabel('Voltage (V)');
title('Both OCV curves at 25°C');
xlim([-0.02 1]);
ylim([2.7 4.3]);
grid on;
grid minor;
legend(Location="best");
saveas(gcf, fullfile(output_path, 'Both_OCV_25degC.png'));

figure(fig_ocv_averaged);
hold on;
plot(soc_ocv_averaged.SOC, soc_ocv_averaged.("0degC"), 'b-', 'LineWidth', 2, 'DisplayName', "0°C")
plot(soc_ocv_averaged.SOC, soc_ocv_averaged.("25degC"), 'g-', 'LineWidth', 2, 'DisplayName', "25°C")
plot(soc_ocv_averaged.SOC, soc_ocv_averaged.("45degC"), 'r-', 'LineWidth', 2, 'DisplayName', "45°C")
plot(gotion_ocv_average.SOC, gotion_ocv_average.x0, 'b--', 'LineWidth', 2, 'DisplayName', 'Gotion 0°C');
plot(gotion_ocv_average.SOC, gotion_ocv_average.x25, 'g--', 'LineWidth', 2, 'DisplayName', 'Gotion 25°C');
plot(gotion_ocv_average.SOC, gotion_ocv_average.x40, 'r--', 'LineWidth', 2, 'DisplayName', 'Gotion 40°C');
xlabel('SOC (-)');
ylabel('Voltage (V)');
title('Averaged OCV curves');
xlim([-0.02 1]);
ylim([2.7 4.3]);
grid on;
grid minor;
legend(Location="best");
saveas(gcf, fullfile(output_path, 'Average_OCV.png'));

figure(fig_ocv_averaged_25);
hold on;
plot(soc_ocv_averaged.SOC, soc_ocv_averaged.("25degC"), '-', 'LineWidth', 2, 'DisplayName', "25°C")
plot(gotion_ocv_average.SOC, gotion_ocv_average.x25, '-', 'LineWidth', 2, 'DisplayName', 'Gotion 25°C');
xlabel('SOC (-)');
ylabel('Voltage (V)');
title('Averaged OCV curves');
xlim([-0.02 1]);
ylim([2.7 4.3]);
grid on;
grid minor;
legend(Location="best");
saveas(gcf, fullfile(output_path, 'Average_OCV_25degC.png'));

% Export to Excel
writetable(soc_ocv_charge, fullfile(output_path, 'OCV.xlsx'), 'Sheet', 'Charge');
writetable(soc_ocv_discharge, fullfile(output_path, 'OCV.xlsx'), 'Sheet', 'Discharge');
writetable(soc_ocv_averaged, fullfile(output_path, 'OCV.xlsx'), 'Sheet', 'Averaged');
