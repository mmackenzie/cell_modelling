clear; close all;

% Load Excel file
filename = 'Gotion_customer_profile.xlsx';
data = readmatrix(filename, 'Sheet', '1 cycle per day - pack level');

% Extract time and signals
time = data(2:end, 1);
soc = data(2:end, 5);
current = data(2:end, 4);
cell_temp = data(2:end, 6);
ambient_temp = data(2:end, 3);

% Plot SOC vs Time
figure;
subplot(3,1,1);
plot(time, soc, 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('SOC (%)');
title('SOC vs time');
grid on;
xlim([0 24*7]);

% Plot Current vs Time
subplot(3,1,2);
plot(time, current, 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('Current (A)');
title('Current vs time');
grid on;
xlim([0 24*7]);

% Plot Temperatures vs Time
subplot(3,1,3);
plot(time, cell_temp, 'r', 'LineWidth', 1.5); hold on;
plot(time, ambient_temp, 'b--', 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('Temperature (°C)');
title('Cell and ambient temperature vs time');
legend('Cell temperature', 'Ambient temperature (Seville)');
grid on;
xlim([0 24*7]);

% Plot Temperatures vs Time
figure;
plot(time, cell_temp, 'r', 'LineWidth', 1.5); hold on;
plot(time, ambient_temp, 'b--', 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('Temperature (°C)');
title('Cell and ambient temperature vs time');
legend('Cell temperature', 'Ambient temperature (Seville)');
grid on;

% Load Excel file
filename = 'Gotion_customer_profile.xlsx';
data = readmatrix(filename, 'Sheet', '2 cycles per day - pack level');

% Extract time and signals
time = data(2:end, 1);
soc = data(2:end, 5);
current = data(2:end, 4);
cell_temp = data(2:end, 6);
ambient_temp = data(2:end, 3);

% Plot SOC vs Time
figure;
subplot(3,1,1);
plot(time, soc, 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('SOC (%)');
title('SOC vs time');
grid on;
xlim([0 24*7]);

% Plot Current vs Time
subplot(3,1,2);
plot(time, current, 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('Current (A)');
title('Current vs time');
grid on;
xlim([0 24*7]);

% Plot Temperatures vs Time
subplot(3,1,3);
plot(time, cell_temp, 'r', 'LineWidth', 1.5); hold on;
plot(time, ambient_temp, 'b--', 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('Temperature (°C)');
title('Cell and ambient temperature vs time');
legend('Cell temperature', 'Ambient temperature (Seville)');
grid on;
xlim([0 24*7]);

% Plot Temperatures vs Time
figure;
plot(time, cell_temp, 'r', 'LineWidth', 1.5); hold on;
plot(time, ambient_temp, 'b--', 'LineWidth', 1.5);
xlabel('Time (h)');
ylabel('Temperature (°C)');
title('Cell and ambient temperature vs time');
legend('Cell temperature', 'Ambient temperature (Seville)');
grid on;