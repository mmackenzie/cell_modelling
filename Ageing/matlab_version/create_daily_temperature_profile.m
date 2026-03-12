clear; clc; close all;

base_folder = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\MATLAB\cell_modelling\Ageing';
T = readtable(fullfile(base_folder, 'Seville_temperatures.xlsx'));

% Extract columns
dates = datetime(T.date, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
tmin = T.tmin;
tmax = T.tmax;

yearly_temp = [];  % to hold final results
yearly_time = (1:24*365)';
t_hours = 1:24;

% Loop through each day (except the last since we need i and i+1)
for i = 1:height(T)
    Tmin_today = tmin(i);
    Tmax_today = tmax(i);
    if i ~= height(T)
        Tmin_next = tmin(i+1);
    end
    
    % Sine wave from Tmin → Tmax → next Tmin over 24 hrs
    % Phase the sine so it's min at 5 AM and max at 3 PM
    temp_curve = (Tmax_today - Tmin_today)/2 * sin((pi/12)*(t_hours+16)) + (Tmax_today + Tmin_today)/2;

    % Smooth transition to next day's Tmin
    % Replace last few hours (e.g. 20:00–24:00) using average of today/tomorrow
    if i ~= height(T)
        temp_curve(end-4:end) = linspace(temp_curve(end-4), Tmin_next, 5);
    end

    % Append to full profile
    yearly_temp = [yearly_temp; temp_curve(:)];
end

writematrix([yearly_time, yearly_temp], fullfile(base_folder, 'Seville_hourly_temperature_estimation.xlsx'));

% Plot result
figure;
plot(yearly_time, yearly_temp);
xlabel('Time (h)');
ylabel('Temperature [°C]');
title('Generated Hourly Temperature Profile');
grid on;


