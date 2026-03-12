function [storage_data, cycling_data] = read_RPT_data(filename)
    % Reads RPT test data (capacity, resistance, cycles, temp, etc.)
    % INPUT: filename (string)
    % OUTPUT: storage and cycling data in struct format

    sheets = sheetnames(filename);
    for i=1:numel(sheets)
        data = readtable(filename, "Sheet", sheets(i));
        sheet_name = matlab.lang.makeValidName(sheets(i));
        temperature = str2double(regexp(sheets(i), sprintf('\\d+(?=%s)', "degC"), 'match'));
        if contains(sheets(i), "Storage")
            soc = str2double(regexp(sheets(i), sprintf('\\d+(?=%s)', "SOC"), 'match'));
            storage_data.(sheet_name).soc = soc;
            storage_data.(sheet_name).temperature = temperature;
            storage_data.(sheet_name).day = data.Day;
            storage_data.(sheet_name).relative_capacity = data.Relative_capacity;
        else
            cycling_data.(sheet_name).cycle = data.Cycle;
            cycling_data.(sheet_name).temperature = temperature;
            cycling_data.(sheet_name).relative_capacity = data.Relative_capacity;
        end
    end
end
