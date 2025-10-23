clear; close all;

current_limits_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\STAYON\05_Engineering_Design_&_Systems\01_Energy_Storage_System\Pack';
current_limits_file = 'Dummy_current_limits_and_SOP.xlsx';
dictionary_path = 'C:\STAYON_git\dictionaries';
dictionary_file = 'LimitsDictionary.sldd';

dd = Simulink.data.dictionary.open(fullfile(dictionary_path, dictionary_file));
dataSection = getSection(dd, 'Design Data');

raw_data = readmatrix(fullfile(current_limits_path, current_limits_file), 'Sheet', 'Continuous charge limits');
data.cont_charge_limits_SOC = raw_data(1, 2:end);
data.cont_charge_limits_temperature = raw_data(2:end, 1);
data.cont_charge_limits_current = raw_data(2:end, 2:end);
raw_data = readmatrix(fullfile(current_limits_path, current_limits_file), 'Sheet', 'Continuous discharge limits');
data.cont_discharge_limits_SOC = raw_data(1, 2:end);
data.cont_discharge_limits_temperature = raw_data(2:end, 1);
data.cont_discharge_limits_current = raw_data(2:end, 2:end);

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

