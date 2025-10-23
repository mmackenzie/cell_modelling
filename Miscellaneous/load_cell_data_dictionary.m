clear; close all;

params_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\LG_78Ah';
dictionary_path = 'C:\STAYON_git\dictionaries';
params_file = 'RC_params.xlsx';
dictionary_file = 'CellDictionary.sldd';

dd = Simulink.data.dictionary.open(fullfile(dictionary_path, dictionary_file));
dataSection = getSection(dd, 'Design Data');

% Load OCV & RC parameters
% raw_data = readmatrix(fullfile(params_path, 'OCV_orig.xlsx'), 'Sheet', '100SOH');
% data.OCV_SOC = raw_data(2:end, 1);
% data.OCV_T = raw_data(1, 2:end);
% data.OCV_V = raw_data(2:end, 2:end);

raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R0_discharge');
data.ECM_SOC = raw_data(1, 2:end);
data.ECM_T = raw_data(2:end, 1);
data.R0_discharge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R1_discharge');
data.R1_discharge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R2_discharge');
data.R2_discharge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R3_discharge');
data.R3_discharge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C1_discharge');
data.C1_discharge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C2_discharge');
data.C2_discharge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C3_discharge');
data.C3_discharge = raw_data(2:end, 2:end);

raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R0_charge');
data.R0_charge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R1_charge');
data.R1_charge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R2_charge');
data.R2_charge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'R3_charge');
data.R3_charge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C1_charge');
data.C1_charge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C2_charge');
data.C2_charge = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(params_path, params_file), 'Sheet', 'C3_charge');
data.C3_charge = raw_data(2:end, 2:end);

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

