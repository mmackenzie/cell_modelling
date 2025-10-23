soc = 0.5;
voltage = 3.6;
temperature = 25;
time = linspace(0, 180, 0.1);

temperature = timeseries(ones(1, length(time)) * temperature, time);
voltage = timeseries(ones(1, length(time)) * voltage, time);
soc = timeseries(ones(1, length(time)) * soc, time);
stop_time = time(end);

simOut = sim('cell_EC_model', 'SrcWorkspace', 'base');
