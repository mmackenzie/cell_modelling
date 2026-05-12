clear; close all;

params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\CATL_51Ah_test_module';
dictionary_path = 'C:\cell_modelling\Estimators';
params_file = 'RC_params_51Ah_test_module.xlsx';
dictionary_file = 'ParametersDataDictionary.sldd';

dd = Simulink.data.dictionary.open(fullfile(dictionary_path, dictionary_file));
dataSection = getSection(dd, 'Design Data');

% Load OCV & RC parameters
% raw_data = readmatrix(fullfile(params_path, 'OCV.xlsx'), 'Sheet', 'Averaged');
% data.OCV_SOC = raw_data(2:end, 1);
% data.OCV_T = raw_data(1, 2:end);
% data.OCV_V = raw_data(2:end, 2:end);

raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R0_discharge');
data.ECM_SOC = raw_data(1, 2:end);
data.ECM_T = raw_data(2:end, 1);
data.ECM_R0_D = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R1_discharge');
data.ECM_R1_D = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R2_discharge');
data.ECM_R2_D = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R3_discharge');
data.ECM_R3_D = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C1_discharge');
data.ECM_C1_D = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C2_discharge');
data.ECM_C2_D = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C3_discharge');
data.ECM_C3_D = raw_data(2:end, 2:end);

raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R0_charge');
data.ECM_R0_C = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R1_charge');
data.ECM_R1_C = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R2_charge');
data.ECM_R2_C = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R3_charge');
data.ECM_R3_C = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C1_charge');
data.ECM_C1_C = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C2_charge');
data.ECM_C2_C = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C3_charge');
data.ECM_C3_C = raw_data(2:end, 2:end);

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

