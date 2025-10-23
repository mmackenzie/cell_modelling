% Set base filename and directory (modify as needed)
baseFilename = 'HPPC_45degree_15C_001_';
directory = 'C:\\Users\\mmackenzie\\Documents\\CMT_test_data\\CATL_141Ah\\HPPC\\45degC'; % Folder containing the CSV files
numFiles = 5;                       % Number of files to concatenate

% Initialize an empty table for concatenation
combinedData = table();

% Loop through each file and concatenate
for i = 1:numFiles
    filename = fullfile(directory, sprintf('%s%d.csv', baseFilename, i));
    
    % Read the CSV file into a table
    tempData = readtable(filename);
    
    % Concatenate with the existing table
    combinedData = [combinedData; tempData];
end

writetable(combinedData, fullfile(directory, 'HPPC_45degree_15C_001_combined.csv'));
