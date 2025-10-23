clear; clc; close all;
% 
% input_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\01_Results\02_RateCapability';
% filename = 'ME-ITE-250223-02-Rate-Capacity_25oC.xlsx';
input_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\01_Results\03_HPPC\10';
filename = 'ME-ITE-250223-04_HPPCTest @10oC.xlsx';
% input_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\01_Results\05_Validation\35';
% filename = 'ME-ITE-250223-04_ValidationProfile@35oC.xlsx';
output_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\02_Analysis\01_Plots';

dictionary_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Estimators';
estimators_dictionary_file = 'EstimatorsDictionary.sldd';

soc_init = 0.31;
capacity_Ah = 115.8;
% Ts = 1;
data.Ts = 1;
data.soc_estim_init = 0.5;  % Initial estimate for SOC
data.initial_covariance = [0.2 1e-6 1e-5 1e-4];  % Uncertainty in initial state estimate [SOC V1 V2 V3]
data.state_covariance = diag([1e-10, 1e-8, 1e-8, 1e-8]);  % Uncertainty in battery model (diagonal matrix) [SOC V1 V2 V3]
data.measurement_covariance = 0.0001;  % Representing noise in voltage sensor (std^2)

%% Update estimator parameters
dd = Simulink.data.dictionary.open(fullfile(dictionary_path, estimators_dictionary_file));
dataSection = getSection(dd, 'Design Data');

varNames = fieldnames(data);
varValues = struct2cell(data);
for i = 1:length(varNames)
    varName = varNames{i};
    varValue = varValues{i};
    
    try
        % Try to get the existing entry
        entry = getEntry(dataSection, varName);
        % Update the value if the entry exists
        setValue(entry, Simulink.Parameter(varValue));
    catch
        % If the entry does not exist, add a new one
        addEntry(dataSection, varName, Simulink.Parameter(varValue));
    end
end

saveChanges(dd);
close(dd);

%% Run simulation
% Read sheets
electrical_sheet = sheetnames(fullfile(input_folder, filename));
electrical_sheet = electrical_sheet(contains(electrical_sheet, 'Detail_') & ~contains(electrical_sheet, 'Temp'));
electrical_data = readtable(fullfile(input_folder, filename), 'Sheet', electrical_sheet{1});

temperature_sheet = sheetnames(fullfile(input_folder, filename));
temperature_sheet = temperature_sheet(contains(temperature_sheet, 'DetailTemp'));
temperature_data = readtable(fullfile(input_folder, filename), 'Sheet', temperature_sheet{1});

% Convert relative time strings to duration
rel_time = duration(electrical_data.RelativeTime_h_min_s_ms_, 'InputFormat', 'hh:mm:ss.SSS');

% Loop through and find when relative time resets
time = zeros(size(rel_time));
offset = 0;
for i = 2:length(rel_time)
    if rel_time(i) < rel_time(i - 1)
        offset = time(i - 1) + 0.1;  % Carry on from previous time value
    end
    time(i) = seconds(rel_time(i)) + offset;
end
stop_time = time(end);

voltage = electrical_data.Voltage_V_;
current = electrical_data.Current_A_;
temperature = temperature_data.Aux_CHTU1T__C_;

measured_voltage = timeseries(voltage, time);
measured_current = timeseries(current, time);
measured_temperature = timeseries(temperature, time);

soc = cumtrapz(time, current) / capacity_Ah / 3600 + soc_init;
true_soc = timeseries(soc, time);

simOut = sim('test_SOC', 'SrcWorkspace', 'base');
estimated_soc = simOut.estimated_soc;

% --- Plot ---
figure('Position', [100, 100, 900, 600]);

t = tiledlayout(3,1);
t.TileSpacing = 'compact';
t.Padding = 'compact';

nexttile;
yyaxis left
plot(time, voltage, 'b', 'LineWidth', 2);
ylabel('Voltage (V)');
grid on;
grid minor;

yyaxis right
plot(time, current, 'r', 'LineWidth', 2);
ylabel('Current (A)');
xlabel('Time (s)');
title('Voltage and Current');

nexttile;
plot(time, temperature, 'k', 'LineWidth', 2);
ylabel('Temperature (°C)');
xlabel('Time (s)');
title('Temperature');
grid on;

nexttile;
plot(time, soc, 'g', 'LineWidth', 2);
ylabel('SOC (-)');
xlabel('Time (s)');
title('SOC');
grid on;