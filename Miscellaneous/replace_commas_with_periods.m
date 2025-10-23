% Specify the folder path containing the CSV files
folderPath = 'C:\Users\mmackenzie\ZELEROS GLOBAL S.L\Programs - 03_ESS\03_PRISMIA\05_Work\1_Cell Module\MAGNETIC & ELEC\2_Testing\CMT - TestResults\Primera celda\Para45grados';
outputFolder = 'C:\Users\mmackenzie\Documents\CMT_test_data\CATL_140.9Ah\45degC';

% Get list of all CSV files in the folder
csvFiles = dir(fullfile(folderPath, '*.csv'));

% Loop through each CSV file in the folder
for k = 1:length(csvFiles)
    % Get the full path of the current file
    inputFilePath = fullfile(folderPath, csvFiles(k).name);
    
    % Read the file content as text
    fileText = fileread(inputFilePath);
    
    % Replace commas with periods (for decimal separators)
    updatedText = strrep(fileText, ',', '.');
    
    % Generate a new file name for the modified CSV
    [~, baseFileName, ext] = fileparts(csvFiles(k).name);
    newFileName = [baseFileName '_modified' ext];
    newFullPath = fullfile(outputFolder, newFileName);
    
    % Write the updated text to a new file
    fid = fopen(newFullPath, 'w');
    fwrite(fid, updatedText);
    fclose(fid);
    
    % Optional: Display progress
    fprintf('Processed and saved: %s\n', newFileName);
end

disp('All files processed.');
