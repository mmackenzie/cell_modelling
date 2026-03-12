clear; clc; close all;

% input_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\01_Results\03_HPPC\10';
% filename = 'ME-ITE-250223-04_HPPCTest @10oC.xlsx';
% output_folder = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Courage\02_SE\03_Testing_&_Validations\Caracterización_Eléctrica_Termica\02_Analysis\01_Plots';
% soc_init = 0.31;

dictionary_path = 'C:\cell_modelling\Estimators';
estimators_dictionary_file = 'TestDictionary.sldd';

capacity_Ah = 115.8;
data.Ts = 1;
data.T_init = 298.15;
data.soc_init = 0.2;
data.upper_soc = 0.95;
data.lower_soc = 0.05;
% SOC estimator
data.soc_estim_init = 0.5;  % Initial estimate for SOC
data.initial_covariance = [0.2 1e-7 1e-6 1e-5];  % P0, uncertainty in initial state estimate [SOC V1 V2 V3]
data.state_covariance = diag([1e-10, 1e-7, 1e-6, 1e-5]);  % Q, uncertainty in battery model (diagonal matrix) [SOC V1 V2 V3]
data.measurement_covariance = 0.0001;  % R, representing noise in voltage sensor (std^2)

% SOH estimator
data.cap_initial_covariance = 1e-8;  % EKF
data.cap_measurement_covariance = 5e-7;  % EKF
data.cap_process_covariance = 3e-6;  % EKF

data.cap_forgetting_factor = 0.9;  % least squares
data.cap_soc_change_threshold = 0.05;  % least squares
data.cap_current_measurement_variance = 1e-8;  % least squares

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

simOut = sim('test_SOC_SOH', 'SrcWorkspace', 'base');
% estimated_soc = simOut.estimated_soc;
