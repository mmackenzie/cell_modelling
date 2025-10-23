% clear; close all;

%% Input
temperature = 25;
if temperature == 0
    capacity = 138.4;  % Ah
elseif temperature == 10
    capacity = 142.6;
elseif temperature == 25
    capacity = 143.6;
elseif temperature == 45
    capacity = 144.1;
end

zero_U1 = 30; % seconds after pulse where U1 is considered 0
zero_U2 = 5 * 60; % seconds after pulse where U2 is considered 0
% zero_U3 = 50 * 60; % seconds after pulse where U3 is considered 0
tau_threshold = 0.3;

test_path = sprintf('C:\\Users\\mmackenzie\\Documents\\CMT_test_data\\CATL_140.9Ah\\%ddegC', temperature);
file_name = '211A_25degC_pulses.mat';
load(fullfile(test_path, file_name));

%% Extract R3, tau3
% Import excel with OCV, R0 and initial RC data
OCV = readtable('OCV.xlsx');
R0 = readtable('R0.xlsx');

time = pulse_data(2).time_reset;
current = pulse_data(2).current;
voltage = pulse_data(2).voltage;
pulse_start1_idx = pulse_data(2).pulse_start1_idx;
pulse_start2_idx = pulse_data(2).pulse_start2_idx;
pulse_end_idx = pulse_data(2).pulse_end_idx;
relaxation_start_idx = pulse_data(2).relaxation_start_idx;
relaxation_end_idx = pulse_data(2).relaxation_end_idx;
I_pulse = abs(median(pulse_data(2).current(pulse_data(2).pulse_start2_idx:pulse_data(2).pulse_end_idx)));  % Current during pulse
pulse_length = time(pulse_end_idx) - time(pulse_start2_idx);  % seconds

idx_zero_U1 = find(time >= (time(relaxation_start_idx) + zero_U1), 1);
idx_zero_U2 = find(time >= (time(relaxation_start_idx) + zero_U2), 1);

% Determine if the cell is sufficiently relaxed after the pulse
final_relaxation_indices = find(time >= (time(relaxation_end_idx) - 600) & time <= time(end));  % Look at the last 10 minutes of relaxation time
final_voltages = voltage(final_relaxation_indices);
voltage_change = max(final_voltages) - min(final_voltages);

if abs(voltage_change) <= 1e-3  % 1mV
    soc_end = interp1(OCV.(sprintf('x%ddegC', temperature)), OCV.SOC, voltage(relaxation_end_idx));
    soc_start = soc_end - trapz(time, current) / 3600 / capacity;

    soc = NaN(length(time), 1);
    soc(1) = soc_start;
    for i = 2:length(time)
        soc(i) = soc(i-1) + current(i) * (time(i) - time(i-1)) / 3600 / capacity;
    end

    Uocv = interp1(OCV.SOC, OCV.(sprintf('x%ddegC', temperature)), soc);  % underlying OCV across the complete pulse and relaxation
    Upol = abs(voltage - Uocv);  % polarisation voltage across the complete pulse and relaxation

    % Calculate tau3 and R3
    idx_tau3_threshold = find(Upol <= tau_threshold * (Upol(idx_zero_U2) - Upol(end)), 1);
    dt = time(idx_tau3_threshold) - time(idx_zero_U2);
    tau3 = -dt / log(Upol(idx_tau3_threshold) / Upol(idx_zero_U2));
    dt = time(idx_zero_U2) - time(relaxation_start_idx);
    U3_relaxation_start = Upol(idx_zero_U2) / exp(-dt/tau3);
    R3 = U3_relaxation_start / (I_pulse * (1 - exp(-pulse_length/tau3)));

    % Calculate tau2 and R2
    idx_tau2_threshold = find(Upol <= tau_threshold * (Upol(idx_zero_U1) - Upol(idx_zero_U2)), 1);
    dt = time(idx_tau2_threshold) - time(relaxation_start_idx);
    U3_idx_tau2_threshold = U3_relaxation_start * exp(-dt/tau3);
    U2_idx_tau2_threshold = Upol(idx_tau2_threshold) - U3_idx_tau2_threshold;

    dt = time(idx_zero_U1) - time(relaxation_start_idx);
    U3_idx_zero_U1 = U3_relaxation_start * exp(-dt/tau3);
    U2_idx_zero_U1 = Upol(idx_zero_U1) - U3_idx_zero_U1;
    dt = time(idx_tau2_threshold) - time(idx_zero_U1);
    tau2 = -dt / log(U2_idx_tau2_threshold / U2_idx_zero_U1);



%     tau3_threshold_idx = find()
else
    disp('The cell is not relaxed within 1 mV over the last 10 minutes.');
end

U0 = NaN(length(time), 1);
Usim = NaN(length(time), 1);
for i = 1:length(time)

end

% U0(i) = I*R0
% U1(i) = U1(i-1)*exp(-dt/tau1) + I*R1*(1-exp(-dt/tau1))
% U2(i) = U2(i-1)*exp(-dt/tau2) + I*R2*(1-exp(-dt/tau2))
% U3(i) = U3(i-1)*exp(-dt/tau3) + I*R3*(1-exp(-dt/tau3))
% Usim(i) = U_ocv(i) + U0(i) + U1(i) + U2(i) + U3(i)