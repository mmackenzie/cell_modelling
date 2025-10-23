soc = 0.5:-0.0001:0.4;
voltage = 3.6:-0.001:2.6;
temperature = 25:0.001:26;
time = 0:1:1000;

temperature = timeseries(temperature, time);
voltage = timeseries(voltage, time);
soc = timeseries(soc, time);
stop_time = time(end);

simOut = sim('SOP_tester.slx', 'SrcWorkspace', 'base');
