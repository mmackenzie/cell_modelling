clear; clc; close all;

base_folder = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Ageing';
T = readtable(fullfile(base_folder, 'Seville_temperatures.xlsx'));

% Extract columns
dates = datetime(T.date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
tmin = T.tmin;
tmax = T.tmax;

yearly_temp = [];  % To hold final results
minutes_per_day = 1440;
t_minutes = linspace(0, 24, minutes_per_day);  % 0 to 24 hours in minutes

% Loop through each day (except the last since we need i and i+1)
for i = 1:height(T)
    Tmin_today = tmin(i);
    Tmax_today = tmax(i);

    if i ~= height(T)
        Tmin_next = tmin(i+1);
    else
        Tmin_next = Tmin_today;  % Edge case: last day
    end

    % Base sine wave with min at ~5 AM and max at ~3 PM (15:00)
    temp_curve = (Tmax_today - Tmin_today)/2 * ...
                 sin((pi/12)*(t_minutes + 16)) + ...
                 (Tmax_today + Tmin_today)/2;

    % Smooth transition to next Tmin over last 3 hours (180 minutes)
    transition_minutes = 180;
    start_idx = minutes_per_day - transition_minutes + 1;
    temp_curve(start_idx:end) = linspace(temp_curve(start_idx), Tmin_next, transition_minutes);

    % Append to full profile
    yearly_temp = [yearly_temp; temp_curve(:)];
end

% Create minute-wise time vector (in minutes)
yearly_time = (0:length(yearly_temp)-1)';

% Save to Excel
output_file = fullfile(base_folder, 'Seville_minute_temperature_estimation.xlsx');
writematrix([yearly_time, yearly_temp], output_file);

% Plot result (first 3 days for readability)
figure;
plot(yearly_time(1:3*1440)/60, yearly_temp(1:3*1440));  % Convert minutes to hours
xlabel('Time (h)');
ylabel('Temperature [°C]');
title('Generated Minute-Resolution Temperature Profile (First 3 Days)');
grid on;



