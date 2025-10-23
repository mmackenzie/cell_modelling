function [soc_bins, temperature_bins, cal_hist, cyc_hist, time_summary] = profile_to_histograms(filename, Q_nom)
    % Convert customer usage profile into degradation histograms
    % INPUT: filename (CSV with time, current, SOC, temp, mode)
    % OUTPUT: cal_hist, cyc_hist (matrices), profile (table with processed vars)

    profile = readtable(filename);

    time = profile.Time_s_;  % [s]
    current = profile.CellCurrent_A_;  % [A]
    soc = min(profile.SOC___, 100);  % [%]
    temperature = profile.CellTemperature;  % [°C]
    mode = profile.Mode;  % 'Charge'/'Discharge'/'Storage'
    c_rate = current / Q_nom;

    [~, name, ~] = fileparts(filename);
    fprintf('Customer: %s\n', name);
    fprintf('Average yearly temperature: %.1fdegC\n', mean(temperature));

    % Time step
    dt = [0; diff(time)];

    % Histogram bin edges
    soc_bins = 0:10:100;
    temperature_bins = -10:5:70;
    c_rate_bins = -1:0.5:1;

    idle_idx = (abs(current) < 0.1);   % tolerance for zero current
    discharge_idx = current < -0.1;
    charge_idx = current > 0.1;
    cycling_idx = discharge_idx | charge_idx;
    capacity_throughput = abs(current) .* dt / 3600;

    % ---------------- Calendar histogram ----------------
    cal_hist = accumarray( ...
        [discretize(soc(idle_idx), soc_bins), ...
         discretize(temperature(idle_idx), temperature_bins)], ...
        dt(idle_idx), ...
        [length(soc_bins) length(temperature_bins)], ...
        @sum, 0);

    cal_hist = cal_hist / (3600 * 24); % convert sec → days

    % ---------------- Cycling histogram ----------------
    % cyc_hist = accumarray( ...
    %     [discretize(temperature, temperature_bins)], ...
    %     abs(profile.Current_A_) .* dt / 3600, ...
    %     [length(temperature_bins) - 1, 1], @sum, 0);

    cyc_hist = accumarray( ...
        [discretize(c_rate(cycling_idx), c_rate_bins), ...
         discretize(temperature(cycling_idx), temperature_bins)], ...
        capacity_throughput(cycling_idx), ...
        [length(c_rate_bins) length(temperature_bins)], ...
        @sum, 0);

    cyc_hist = cyc_hist / Q_nom / 2; % Ah throughput → equivalent cycles

    % ---------------- Time accounting ----------------
    time_summary.total = sum(dt) / (3600 * 24);
    time_summary.idle = sum(dt(idle_idx)) / (3600 * 24);
    time_summary.charge = sum(dt(current > 0.1)) / (3600 * 24);
    time_summary.discharge = sum(dt(current < -0.1)) / (3600 * 24);

    % ---------------- Plotting ----------------
    Plotting.plot_temperature_histograms(cal_hist, cyc_hist, temperature_bins);
    Plotting.plot_3D_histograms(cal_hist, cyc_hist, temperature_bins, soc_bins, c_rate_bins);
end
