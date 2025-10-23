clear; clc; close all;

capacity = 280;

test_path = 'C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\Test data';

% --- 1C discharge ---
file1 = 'CTAG_descarga1C.ChannelGroup_0_SV_TX_REQUEST_0x65.csv';
file2 = 'CTAG_descarga1C.ChannelGroup_1_SV_TX_STATE_0x66.csv';
file3 = 'CTAG_descarga1C.ChannelGroup_2_SV_TX_RCK_1_0x67.csv';
file4 = 'CTAG_descarga1C.ChannelGroup_3_SV_TX_RCK_2_0x68.csv';
file5 = 'CTAG_descarga1C.ChannelGroup_4_SV_TX_RCK_3_0x69.csv';
file6 = 'CTAG_descarga1C.ChannelGroup_5_MON_BCU_TX_STATUS_1_0x70.csv';
file7 = 'CTAG_descarga1C.ChannelGroup_6_MON_BCU_TX_STATUS_2_0x71.csv';
file8 = 'CTAG_descarga1C.ChannelGroup_7_MON_BCU_TX_STATUS_3_0x72.csv';
file9 = 'CTAG_descarga1C.ChannelGroup_8_MON_TX_SDC_STATUS_0x73.csv';
file10 = 'CTAG_descarga1C.ChannelGroup_9_MON_TX_SV_CONTROL_STATUS_1_0x74.csv';
file11 = 'CTAG_descarga1C.ChannelGroup_10_MON_BCU_TX_STATUS_4_0x78.csv';
file12 = 'CTAG_descarga1C.ChannelGroup_5_SV_TX_ERR_0x6B.csv';
ctag_1C_discharge_path = 'C:\Users\mmackenzie\Downloads\IN251518-01 ensayo CTAG\IN251518-01\Ficheros de adqusición\03 Pruebas 08C y 1C\Descarga 1C\p251518_001_002_test_battera_descarga_sin_cooling_1c_01.xlsx';

% --- 0.8C charge ---
ctag_08C_charge_path1 = 'C:\Users\mmackenzie\Downloads\IN251518-01 ensayo CTAG\IN251518-01\Ficheros de adqusición\03 Pruebas 08C y 1C\Carga 08C\p251518_001_002_test_battera_carga_sin_cooling_08c_02.xlsx';
ctag_08C_charge_path2 = 'C:\Users\mmackenzie\Downloads\IN251518-01 ensayo CTAG\IN251518-01\Ficheros de adqusición\03 Pruebas 08C y 1C\Carga 08C\p251518_001_002_test_battera_carga_sin_cooling_08c_03.xlsx';

SV_TX_REQUEST = readtable(fullfile(test_path, file1));
SV_TX_STATE = readtable(fullfile(test_path, file2));
SV_TX_RCK_1 = readtable(fullfile(test_path, file3));
SV_TX_RCK_2 = readtable(fullfile(test_path, file4));
SV_TX_RCK_3 = readtable(fullfile(test_path, file5));
MON_BCU_TX_STATUS_1 = readtable(fullfile(test_path, file6));
MON_BCU_TX_STATUS_2 = readtable(fullfile(test_path, file7));
MON_BCU_TX_STATUS_3 = readtable(fullfile(test_path, file8));
MON_TX_SDC_STATUS = readtable(fullfile(test_path, file9));
MON_TX_SV_CONTROL_STATUS = readtable(fullfile(test_path, file10));
MON_BCU_TX_STATUS_4 = readtable(fullfile(test_path, file11));
SV_TX_ERR = readtable(fullfile(test_path, file12));
CTAG_1C_discharge_data = readtable(ctag_1C_discharge_path);
CTAG_1C_discharge_data.PATime = CTAG_1C_discharge_data.PATime - CTAG_1C_discharge_data.PATime(1) + 421.4;
CTAG_08C_charge_data1 = readtable(ctag_08C_charge_path1);
CTAG_08C_charge_data2 = readtable(ctag_08C_charge_path2);
CTAG_08C_charge_data1.PATime = CTAG_08C_charge_data1.PATime - CTAG_08C_charge_data1.PATime(1);
CTAG_08C_charge_data2.PATime = CTAG_08C_charge_data2.PATime - CTAG_08C_charge_data2.PATime(1) + CTAG_08C_charge_data1.PATime(end) + 1;
CTAG_08C_charge_data = vertcat(CTAG_08C_charge_data1, CTAG_08C_charge_data2);

% Map each unique string to a number
sv_state_map = containers.Map( ...
    {'INIT', 'READY', 'PRECHARGE', 'HV_READY', 'CHARGE', 'SHUTDOWN', 'ERROR'}, ...
    [0, 1, 2, 3, 4, 5, 6]); 
contactor_state_map = containers.Map( ...
    {'OPEN', 'CLOSED'}, ...
    [0, 1]);
[unique_BMS_states, ~, MON_BCU_TX_STATUS_1.STATE_IDX] = unique(MON_BCU_TX_STATUS_1.BCU_STATUS);
for i = 1:height(SV_TX_STATE)
    SV_TX_STATE.STATE_IDX(i) = sv_state_map(erase(erase(string(SV_TX_STATE.SV_STATE(i)), "b'"), "'"));
    SV_TX_STATE.K1_POS_STATE_IDX(i) = contactor_state_map(erase(erase(string(SV_TX_STATE.K1_positiveStatus(i)), "b'"), "'"));
    SV_TX_STATE.K1_NEG_STATE_IDX(i) = contactor_state_map(erase(erase(string(SV_TX_STATE.K1_negativeStatus(i)), "b'"), "'"));
    SV_TX_STATE.K2_POS_STATE_IDX(i) = contactor_state_map(erase(erase(string(SV_TX_STATE.K2_positiveStatus(i)), "b'"), "'"));
    SV_TX_STATE.K2_NEG_STATE_IDX(i) = contactor_state_map(erase(erase(string(SV_TX_STATE.K2_negativeStatus(i)), "b'"), "'"));
    SV_TX_STATE.K3_POS_STATE_IDX(i) = contactor_state_map(erase(erase(string(SV_TX_STATE.K3_positiveStatus(i)), "b'"), "'"));
    SV_TX_STATE.K3_NEG_STATE_IDX(i) = contactor_state_map(erase(erase(string(SV_TX_STATE.K3_negativeStatus(i)), "b'"), "'"));
    SV_TX_STATE.K4_POS_STATE_IDX(i) = contactor_state_map(erase(erase(string(SV_TX_STATE.K4_positiveStatus(i)), "b'"), "'"));
    SV_TX_STATE.K4_NEG_STATE_IDX(i) = contactor_state_map(erase(erase(string(SV_TX_STATE.K4_negativeStatus(i)), "b'"), "'"));
end

%% --- Discharge analysis ---
% --- Discharge capacity and SOC estimation ---
discharge_capacity = zeros(height(SV_TX_RCK_1), 1);
soc = zeros(height(SV_TX_RCK_1), 1);
soc(1) = SV_TX_RCK_2.RCK_SOC(1);
for i = 2:height(SV_TX_RCK_1)
    delta_t = SV_TX_RCK_1.timestamps(i) - SV_TX_RCK_1.timestamps(i-1);
    discharge_capacity(i) = discharge_capacity(i-1) + SV_TX_RCK_1.RCK_CURRENT(i) * delta_t / 3600;
    soc(i) = soc(i-1) - (SV_TX_RCK_1.RCK_CURRENT(i) * delta_t / 3600) / capacity * 100;
end

% --- Battery indexing ---
bcu1_batt1_idx = MON_BCU_TX_STATUS_1.BCU_IDX == 0;
bcu1_batt2_idx = MON_BCU_TX_STATUS_1.BCU_IDX == 1;
bcu1_batt3_idx = MON_BCU_TX_STATUS_1.BCU_IDX == 2;
bcu1_batt4_idx = MON_BCU_TX_STATUS_1.BCU_IDX == 3;
bcu2_batt1_idx = MON_BCU_TX_STATUS_2.BCU_IDX == 0;
bcu2_batt2_idx = MON_BCU_TX_STATUS_2.BCU_IDX == 1;
bcu2_batt3_idx = MON_BCU_TX_STATUS_2.BCU_IDX == 2;
bcu2_batt4_idx = MON_BCU_TX_STATUS_2.BCU_IDX == 3;
bcu3_batt1_idx = MON_BCU_TX_STATUS_3.BCU_IDX == 0;
bcu3_batt2_idx = MON_BCU_TX_STATUS_3.BCU_IDX == 1;
bcu3_batt3_idx = MON_BCU_TX_STATUS_3.BCU_IDX == 2;
bcu3_batt4_idx = MON_BCU_TX_STATUS_3.BCU_IDX == 3;

% % --- Rack voltage and current --- 
% figure('Position', [100, 100, 600, 400]);
% yyaxis left;
% plot(SV_TX_RCK_1.timestamps, SV_TX_RCK_1.RCK_VOLTAGE, 'b', 'LineWidth', 2);
% ylabel('Voltage (V)');
% hold on;
% yyaxis right;
% plot(SV_TX_RCK_1.timestamps, SV_TX_RCK_1.RCK_CURRENT, 'r', 'LineWidth', 2, 'DisplayName', 'RCK_CURRENT');
% plot(CTAG_data.PATime, CTAG_data.I1_Batt_AV * -1, 'r--', 'LineWidth', 2, 'DisplayName', 'RCK_CURRENT');
% ylabel('Current (A)');
% xlabel('Time (s)');
% title('Voltage and Current Profile');
% grid on;

% --- SOC analysis ---
figure('Position', [100, 100, 600, 400]);
hold on;
plot(SV_TX_RCK_2.timestamps, SV_TX_RCK_2.RCK_SOC, 'b', 'LineWidth', 2, 'DisplayName', 'BMS SOC calculation');
plot(SV_TX_RCK_1.timestamps, soc, 'r', 'LineWidth', 2, 'DisplayName', 'Coulomb-counting SOC calculation');
ylabel('SOC (%)');
xlabel('Time (s)');
legend();
grid on;

% --- Temperature analysis ---
figure('Position', [100, 100, 600, 400]);
hold on;
plot(SV_TX_RCK_3.timestamps, SV_TX_RCK_3.RCK_maxCellTemperature, 'r', 'LineWidth', 2, 'DisplayName', 'RCK\_maxCellTemperature');
plot(SV_TX_RCK_3.timestamps, SV_TX_RCK_3.RCK_minCellTemperature, 'b', 'LineWidth', 2, 'DisplayName', 'RCK\_minCellTemperature');
plot(SV_TX_RCK_1.timestamps, SV_TX_RCK_1.RCK_TEMPERATURE, 'k--', 'LineWidth', 2, 'DisplayName', 'RCK\_TEMPERATURE');
ylabel('Temperature (^oC)');
xlabel('Time (s)');
title('Cell and rack temperature')
legend('Location', 'best');
grid on;

% --- Cell imbalance analysis ---
figure('Position', [100, 100, 600, 400]);
hold on;
plot(MON_BCU_TX_STATUS_2.timestamps(bcu2_batt1_idx), MON_BCU_TX_STATUS_2.BCU_CELL_VOLT_MAX(bcu2_batt1_idx), 'r', 'LineWidth', 2, 'DisplayName', 'BCU\_CELL\_VOLT\_MAX\_BATT1');
plot(MON_BCU_TX_STATUS_2.timestamps(bcu2_batt1_idx), MON_BCU_TX_STATUS_2.BCU_CELL_VOLT_MIN(bcu2_batt1_idx), 'r', 'LineWidth', 2, 'DisplayName', 'BCU\_CELL\_VOLT\_MIN\_BATT1');
plot(MON_BCU_TX_STATUS_2.timestamps(bcu2_batt2_idx), MON_BCU_TX_STATUS_2.BCU_CELL_VOLT_MAX(bcu2_batt2_idx), 'b', 'LineWidth', 2, 'DisplayName', 'BCU\_CELL\_VOLT\_MAX\_BATT2');
plot(MON_BCU_TX_STATUS_2.timestamps(bcu2_batt2_idx), MON_BCU_TX_STATUS_2.BCU_CELL_VOLT_MIN(bcu2_batt2_idx), 'b', 'LineWidth', 2, 'DisplayName', 'BCU\_CELL\_VOLT\_MIN\_BATT2');
plot(MON_BCU_TX_STATUS_2.timestamps(bcu2_batt3_idx), MON_BCU_TX_STATUS_2.BCU_CELL_VOLT_MAX(bcu2_batt3_idx), 'g', 'LineWidth', 2, 'DisplayName', 'BCU\_CELL\_VOLT\_MAX\_BATT3');
plot(MON_BCU_TX_STATUS_2.timestamps(bcu2_batt3_idx), MON_BCU_TX_STATUS_2.BCU_CELL_VOLT_MIN(bcu2_batt3_idx), 'g', 'LineWidth', 2, 'DisplayName', 'BCU\_CELL\_VOLT\_MIN\_BATT3');
plot(MON_BCU_TX_STATUS_2.timestamps(bcu2_batt4_idx), MON_BCU_TX_STATUS_2.BCU_CELL_VOLT_MAX(bcu2_batt4_idx), 'y', 'LineWidth', 2, 'DisplayName', 'BCU\_CELL\_VOLT\_MAX\_BATT4');
plot(MON_BCU_TX_STATUS_2.timestamps(bcu2_batt4_idx), MON_BCU_TX_STATUS_2.BCU_CELL_VOLT_MIN(bcu2_batt4_idx), 'y', 'LineWidth', 2, 'DisplayName', 'BCU\_CELL\_VOLT\_MIN\_BATT4');
plot(SV_TX_RCK_3.timestamps, SV_TX_RCK_3.RCK_maxCellVoltage, 'k--', 'LineWidth', 2, 'DisplayName', 'RCK\_maxCellVoltage');
plot(SV_TX_RCK_3.timestamps, SV_TX_RCK_3.RCK_minCellVoltage, 'k--', 'LineWidth', 2, 'DisplayName', 'RCK\_minCellVoltage');
ylabel('Voltage (mV)');
xlabel('Time (s)');
legend();
grid on;

% --- Pack imbalance analysis ---
figure('Position', [100, 100, 600, 400]);
hold on;
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt1_idx), MON_BCU_TX_STATUS_1.BCU_BAT_VOLT(bcu1_batt1_idx), 'r', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_BATT1');
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt2_idx), MON_BCU_TX_STATUS_1.BCU_BAT_VOLT(bcu1_batt2_idx), 'b', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_BATT2');
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt3_idx), MON_BCU_TX_STATUS_1.BCU_BAT_VOLT(bcu1_batt3_idx), 'g', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_BATT3');
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt4_idx), MON_BCU_TX_STATUS_1.BCU_BAT_VOLT(bcu1_batt4_idx), 'y', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_BATT4');
plot(MON_BCU_TX_STATUS_4.timestamps, MON_BCU_TX_STATUS_4.BCU_BAT_VOLT_MAX, 'k--', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_MAX');
plot(MON_BCU_TX_STATUS_4.timestamps, MON_BCU_TX_STATUS_4.BCU_BAT_VOLT_MIN, 'k--', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_MIN');
ylabel('Voltage (V)');
xlabel('Time (s)');
legend();
grid on;

% % --- SOP analysis ---
% figure('Position', [100, 100, 600, 400]);
% hold on;
% plot(MON_BCU_TX_STATUS_3.timestamps(bcu3_batt1_idx), MON_BCU_TX_STATUS_3.BCU_SOP_DISCHARGE(bcu3_batt1_idx), 'r', 'LineWidth', 2, 'DisplayName', 'BCU\_SOP\_DISCHARGE\_BATT1');
% plot(MON_BCU_TX_STATUS_3.timestamps(bcu3_batt2_idx), MON_BCU_TX_STATUS_3.BCU_SOP_DISCHARGE(bcu3_batt2_idx), 'b', 'LineWidth', 2, 'DisplayName', 'BCU\_SOP\_DISCHARGE\_BATT2');
% plot(MON_BCU_TX_STATUS_3.timestamps(bcu3_batt3_idx), MON_BCU_TX_STATUS_3.BCU_SOP_DISCHARGE(bcu3_batt3_idx), 'g', 'LineWidth', 2, 'DisplayName', 'BCU\_SOP\_DISCHARGE\_BATT3');
% plot(MON_BCU_TX_STATUS_3.timestamps(bcu3_batt4_idx), MON_BCU_TX_STATUS_3.BCU_SOP_DISCHARGE(bcu3_batt4_idx), 'y', 'LineWidth', 2, 'DisplayName', 'BCU\_SOP\_DISCHARGE\_BATT4');
% plot(SV_TX_RCK_2.timestamps, SV_TX_RCK_2.RCK_CURR_AVAILABLE, 'k', 'LineWidth', 2, 'DisplayName', 'RCK\_CURR\_AVAILABLE');
% ylabel('Current (A)');
% xlabel('Time (s)');
% title('SOP signal of the 4 packs')
% legend();
% grid on;

% % --- Error signal analysis ---
% figure('Position', [100, 100, 600, 400]);
% hold on;
% plot(SV_TX_ERR.timestamps, SV_TX_ERR.RCK_DEM_ERR, 'r', 'LineWidth', 2, 'DisplayName', 'RCK\_DEM\_ERR');
% plot(SV_TX_ERR.timestamps, SV_TX_ERR.ERROR_TYPE_1_PRESENT, 'g', 'LineWidth', 2, 'DisplayName', 'ERROR\_TYPE\_1\_PRESENT');
% plot(SV_TX_ERR.timestamps, SV_TX_ERR.ERROR_TYPE_2_PRESENT, 'b', 'LineWidth', 2, 'DisplayName', 'ERROR\_TYPE\_2\_PRESENT');
% ylabel('Error signal');
% xlabel('Time (s)');
% title('Error signals')
% legend();
% grid on;

% --- Plot all signals together --- 
fig = figure();
fig.WindowState = 'maximized';
tiledlayout(2, 4, 'Padding', 'none', 'TileSpacing', 'compact');
nexttile
plot(SV_TX_RCK_1.timestamps, SV_TX_RCK_1.RCK_VOLTAGE, 'b', 'LineWidth', 2, 'DisplayName', 'RCK\_VOLTAGE');
ylabel('Voltage (V)');
xlabel('Time (s)');
title('Rack voltage');
grid on;
legend('Location', 'best');

nexttile
hold on;
plot(SV_TX_RCK_1.timestamps, SV_TX_RCK_1.RCK_CURRENT, 'r', 'LineWidth', 2, 'DisplayName', 'RCK\_CURRENT');
plot(CTAG_1C_discharge_data.PATime, CTAG_1C_discharge_data.I1_Batt_AV * -1, 'b', 'LineWidth', 2, 'DisplayName', 'I1\_Batt\_AV');
ylabel('Current (A)');
xlabel('Time (s)');
title('Rack and power supply current');
legend('Location', 'best');
grid on;

nexttile
hold on;
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt1_idx), MON_BCU_TX_STATUS_1.BCU_BAT_VOLT(bcu1_batt1_idx), 'r', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_BATT1');
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt2_idx), MON_BCU_TX_STATUS_1.BCU_BAT_VOLT(bcu1_batt2_idx), 'b', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_BATT2');
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt3_idx), MON_BCU_TX_STATUS_1.BCU_BAT_VOLT(bcu1_batt3_idx), 'g', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_BATT3');
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt4_idx), MON_BCU_TX_STATUS_1.BCU_BAT_VOLT(bcu1_batt4_idx), 'y', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_BATT4');
plot(MON_BCU_TX_STATUS_4.timestamps, MON_BCU_TX_STATUS_4.BCU_BAT_VOLT_MAX, 'k--', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_MAX');
plot(MON_BCU_TX_STATUS_4.timestamps, MON_BCU_TX_STATUS_4.BCU_BAT_VOLT_MIN, 'k--', 'LineWidth', 2, 'DisplayName', 'BCU\_BAT\_VOLT\_MIN');
ylabel('Voltage (V)');
xlabel('Time (s)');
title('Batt voltage');
legend('Location', 'best');
grid on;

nexttile
hold on;
plot(MON_BCU_TX_STATUS_3.timestamps(bcu3_batt1_idx), MON_BCU_TX_STATUS_3.BCU_SOP_DISCHARGE(bcu3_batt1_idx), 'r', 'LineWidth', 2, 'DisplayName', 'BCU\_SOP\_DISCHARGE\_BATT1');
plot(MON_BCU_TX_STATUS_3.timestamps(bcu3_batt2_idx), MON_BCU_TX_STATUS_3.BCU_SOP_DISCHARGE(bcu3_batt2_idx), 'b', 'LineWidth', 2, 'DisplayName', 'BCU\_SOP\_DISCHARGE\_BATT2');
plot(MON_BCU_TX_STATUS_3.timestamps(bcu3_batt3_idx), MON_BCU_TX_STATUS_3.BCU_SOP_DISCHARGE(bcu3_batt3_idx), 'g', 'LineWidth', 2, 'DisplayName', 'BCU\_SOP\_DISCHARGE\_BATT3');
plot(MON_BCU_TX_STATUS_3.timestamps(bcu3_batt4_idx), MON_BCU_TX_STATUS_3.BCU_SOP_DISCHARGE(bcu3_batt4_idx), 'y', 'LineWidth', 2, 'DisplayName', 'BCU\_SOP\_DISCHARGE\_BATT4');
plot(SV_TX_RCK_2.timestamps, SV_TX_RCK_2.RCK_CURR_AVAILABLE, 'k', 'LineWidth', 2, 'DisplayName', 'RCK\_CURR\_AVAILABLE');
ylabel('Current (A)');
xlabel('Time (s)');
title('SOP signal of the 4 packs')
legend('Location', 'best');
grid on;

nexttile
hold on;
plot(SV_TX_ERR.timestamps, SV_TX_ERR.RCK_DEM_ERR, 'r', 'LineWidth', 2, 'DisplayName', 'RCK\_DEM\_ERR');
plot(SV_TX_ERR.timestamps, SV_TX_ERR.ERROR_TYPE_1_PRESENT, 'g', 'LineWidth', 2, 'DisplayName', 'ERROR\_TYPE\_1\_PRESENT');
plot(SV_TX_ERR.timestamps, SV_TX_ERR.ERROR_TYPE_2_PRESENT, 'b', 'LineWidth', 2, 'DisplayName', 'ERROR\_TYPE\_2\_PRESENT');
ylabel('Error signal');
xlabel('Time (s)');
title('Error signals')
legend('Location', 'best');
grid on;

nexttile
hold on;
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt1_idx), MON_BCU_TX_STATUS_1.STATE_IDX(bcu1_batt1_idx), 'r', 'LineWidth', 2, 'DisplayName', 'BCU\_STATUS\_BATT1');
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt2_idx), MON_BCU_TX_STATUS_1.STATE_IDX(bcu1_batt2_idx), 'b', 'LineWidth', 2, 'DisplayName', 'BCU\_STATUS\_BATT2');
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt3_idx), MON_BCU_TX_STATUS_1.STATE_IDX(bcu1_batt3_idx), 'g', 'LineWidth', 2, 'DisplayName', 'BCU\_STATUS\_BATT3');
plot(MON_BCU_TX_STATUS_1.timestamps(bcu1_batt4_idx), MON_BCU_TX_STATUS_1.STATE_IDX(bcu1_batt4_idx), 'y', 'LineWidth', 2, 'DisplayName', 'BCU\_STATUS\_BATT4');
ylabel('State');
xlabel('Time (s)');
title('BMS state')
legend('Location', 'best');
grid on;

nexttile
hold on;
plot(SV_TX_STATE.timestamps, SV_TX_STATE.STATE_IDX, 'r', 'LineWidth', 2, 'DisplayName', 'SV\_STATE');
ylabel('State');
xlabel('Time (s)');
title('Supervisor state')
legend('Location', 'best');
grid on;

nexttile
hold on;
plot(SV_TX_STATE.timestamps, SV_TX_STATE.K1_POS_STATE_IDX, 'LineWidth', 2, 'DisplayName', 'K1\_positive');
plot(SV_TX_STATE.timestamps, SV_TX_STATE.K1_NEG_STATE_IDX, 'LineWidth', 2, 'DisplayName', 'K1\_negative');
plot(SV_TX_STATE.timestamps, SV_TX_STATE.K2_POS_STATE_IDX, 'LineWidth', 2, 'DisplayName', 'K2\_positive');
plot(SV_TX_STATE.timestamps, SV_TX_STATE.K2_NEG_STATE_IDX, 'LineWidth', 2, 'DisplayName', 'K2\_negative');
plot(SV_TX_STATE.timestamps, SV_TX_STATE.K3_POS_STATE_IDX, 'LineWidth', 2, 'DisplayName', 'K3\_positive');
plot(SV_TX_STATE.timestamps, SV_TX_STATE.K3_NEG_STATE_IDX, 'LineWidth', 2, 'DisplayName', 'K3\_negative');
plot(SV_TX_STATE.timestamps, SV_TX_STATE.K4_POS_STATE_IDX, 'LineWidth', 2, 'DisplayName', 'K4\_positive');
plot(SV_TX_STATE.timestamps, SV_TX_STATE.K4_NEG_STATE_IDX, 'LineWidth', 2, 'DisplayName', 'K4\_negative');
ylabel('State');
xlabel('Time (s)');
title('Contactor state')
legend('Location', 'best');
grid on;

% Link x-axes of all subplots
ax = findall(gcf, 'type', 'axes');
linkaxes(ax, 'x');

%% --- Charge analysis ---
% --- Charge capacity and SOC estimation ---
discharge_capacity = zeros(height(CTAG_08C_charge_data), 1);
soc = zeros(height(CTAG_08C_charge_data), 1);
soc(1) = CTAG_08C_charge_data.RCK_SOC(1);
for i = 2:height(CTAG_08C_charge_data)
    delta_t = CTAG_08C_charge_data.PATime(i) - CTAG_08C_charge_data.PATime(i-1);
    discharge_capacity(i) = discharge_capacity(i-1) + CTAG_08C_charge_data.RCK_CURRENT(i) / 10 * delta_t / 3600;
    soc(i) = soc(i-1) - (CTAG_08C_charge_data.RCK_CURRENT(i) / 10 * delta_t / 3600) / capacity * 100;
end

% --- Rack voltage and current --- 
figure('Position', [100, 100, 600, 400]);
yyaxis left;
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_VOLTAGE, 'b', 'LineWidth', 2, 'DisplayName', 'RCK\_VOLTAGE');
ylabel('Voltage (V)');
hold on;
yyaxis right;
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_CURRENT / 10, 'r', 'LineWidth', 2, 'DisplayName', 'RCK\_CURRENT');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.I1_Batt_AV * -1, 'r--', 'LineWidth', 2, 'DisplayName', 'I1\_Batt\_AV');
ylabel('Current (A)');
xlabel('Time (s)');
title('Voltage and Current Profile');
legend('Location', 'best');
grid on;

% --- SOC analysis ---
figure('Position', [100, 100, 600, 400]);
hold on;
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_SOC, 'b', 'LineWidth', 2, 'DisplayName', 'BMS SOC calculation');
plot(CTAG_08C_charge_data.PATime, soc, 'r', 'LineWidth', 2, 'DisplayName', 'Coulomb-counting SOC calculation');
ylabel('SOC (%)');
xlabel('Time (s)');
legend('Location', 'best');
grid on;

% --- Temperature analysis ---
figure('Position', [100, 100, 600, 400]);
hold on;
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_maxCellTemperature, 'r', 'LineWidth', 2, 'DisplayName', 'RCK\_maxCellTemperature');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_minCellTemperature, 'b', 'LineWidth', 2, 'DisplayName', 'RCK\_minCellTemperature');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_TEMPERATURE, 'k--', 'LineWidth', 2, 'DisplayName', 'RCK\_TEMPERATURE');
ylabel('Temperature (^oC)');
xlabel('Time (s)');
title('Cell and rack temperature')
legend('Location', 'best');
grid on;

% --- Cell imbalance analysis ---
figure('Position', [100, 100, 600, 400]);
hold on;
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_maxCellVoltage, 'k--', 'LineWidth', 2, 'DisplayName', 'RCK\_maxCellVoltage');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_minCellVoltage, 'k--', 'LineWidth', 2, 'DisplayName', 'RCK\_minCellVoltage');
ylabel('Voltage (mV)');
xlabel('Time (s)');
legend('Location', 'best');
grid on;

% --- Plot all signals together --- 
fig = figure();
fig.WindowState = 'maximized';
tiledlayout(2, 3, 'Padding', 'none', 'TileSpacing', 'compact');
nexttile
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_VOLTAGE, 'b', 'LineWidth', 2, 'DisplayName', 'RCK\_VOLTAGE');
ylabel('Voltage (V)');
xlabel('Time (s)');
title('Rack voltage');
grid on;
legend('Location', 'best');

nexttile
hold on;
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_CURRENT / 10, 'r', 'LineWidth', 2, 'DisplayName', 'RCK\_CURRENT');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.I1_Batt_AV * -1, 'b', 'LineWidth', 2, 'DisplayName', 'I1\_Batt\_AV');
ylabel('Current (A)');
xlabel('Time (s)');
title('Rack and power supply current');
legend('Location', 'best');
grid on;

% nexttile
% hold on;
% ylabel('Voltage (V)');
% xlabel('Time (s)');
% title('Batt voltage');
% legend('Location', 'best');
% grid on;

nexttile
hold on;
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_SOP_CHARGE, 'r', 'LineWidth', 2, 'DisplayName', 'RCK\_SOP\_CHARGE');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_CURR_AVAILABLE, 'k--', 'LineWidth', 2, 'DisplayName', 'RCK\_CURR\_AVAILABLE');
ylabel('Current (A)');
xlabel('Time (s)');
title('Available current')
legend('Location', 'best');
grid on;

nexttile
hold on;
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.RCK_DEM_ERR, 'r', 'LineWidth', 2, 'DisplayName', 'RCK\_DEM\_ERR');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.ERROR_TYPE_1_PRESENT, 'g', 'LineWidth', 2, 'DisplayName', 'ERROR\_TYPE\_1\_PRESENT');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.ERROR_TYPE_2_PRESENT, 'b', 'LineWidth', 2, 'DisplayName', 'ERROR\_TYPE\_2\_PRESENT');
ylabel('Error signal');
xlabel('Time (s)');
title('Error signals')
legend('Location', 'best');
grid on;

% nexttile
% hold on;
% plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.SV_STATE_REQUEST, 'r', 'LineWidth', 2, 'DisplayName', 'SV\_STATE\_REQUEST');
% ylabel('State');
% xlabel('Time (s)');
% title('SV state request')
% legend('Location', 'best');
% grid on;

nexttile
hold on;
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.SV_STATE, 'r', 'LineWidth', 2, 'DisplayName', 'SV\_STATE');
ylabel('State');
xlabel('Time (s)');
title('Supervisor state')
legend('Location', 'best');
grid on;

nexttile
hold on;
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.CONT_POS_ITP, 'LineWidth', 2, 'DisplayName', 'CONT\_POS\_ITP');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.CONT_NEG_ITP, 'LineWidth', 2, 'DisplayName', 'CONT\_NEG\_ITP');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.K1_positiveStatus, 'LineWidth', 2, 'DisplayName', 'K1\_positive');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.K1_negativeStatus, 'LineWidth', 2, 'DisplayName', 'K1\_negative');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.K2_positiveStatus, 'LineWidth', 2, 'DisplayName', 'K2\_positive');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.K2_negativeStatus, 'LineWidth', 2, 'DisplayName', 'K2\_negative');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.K3_positiveStatus, 'LineWidth', 2, 'DisplayName', 'K3\_positive');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.K3_negativeStatus, 'LineWidth', 2, 'DisplayName', 'K3\_negative');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.K4_positiveStatus, 'LineWidth', 2, 'DisplayName', 'K4\_positive');
plot(CTAG_08C_charge_data.PATime, CTAG_08C_charge_data.K4_negativeStatus, 'LineWidth', 2, 'DisplayName', 'K4\_negative');
ylabel('State');
xlabel('Time (s)');
title('Contactor state')
legend('Location', 'best');
grid on;

% Link x-axes of all subplots
ax = findall(gcf, 'type', 'axes');
linkaxes(ax, 'x');