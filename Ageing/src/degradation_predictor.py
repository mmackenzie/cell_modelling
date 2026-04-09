import numpy as np

from .data_handling import DataHandler
from .fit_degradation_models import DegradationModelFitter
from .degradation_physics import DegradationPhysics
from .utils import *


class DegradationPredictor:
    """
    Applies fitted degradation models to customer usage histograms.
    """

    def __init__(self, model_params: dict):
        self.model_params = model_params
        self.physics = DegradationPhysics()

    # --------------------------------------------------------------
    def apply(self, cal_summary, cyc_summary, years=30, months_per_year=12):
        """
        Simulate degradation progression using Sparse DataFrame summaries.
        """
        p_cal = self.model_params["calendar"]["params"]
        p_cyc = self.model_params["cycling"]["params"]
        cyc_model_type = self.model_params["cycling"]["model_type"]

        # Pre-scale usage for the simulation time-step (monthly)
        cal_step = cal_summary.copy()
        cal_step['days'] = cal_step['days'] / months_per_year
        
        cyc_step = cyc_summary.copy()
        cyc_step['FCE'] = cyc_step['FCE'] / months_per_year

        # State variables
        soh_traj = [100.0]
        q_loss_calendar = 0.0
        q_loss_cycling = 0.0
        q_loss_total = 0.0
        
        time_axis = [0.0]
        cycle_axis = [0.0]
        total_days = 0.0
        total_cycles = 0.0

        for y in range(years):
            for m in range(months_per_year):
                
                # --- 1. Calendar Ageing Step ---
                for _, row in cal_step.iterrows():
                    dt = row['days']
                    T_degC = row['T_bin']
                    SOC = row['SOC_bin']

                    # Use current state to find equivalent starting point
                    t_prev = self.physics.invert_calendar(p_cal, q_loss_total, T_degC, SOC)
                    t_new = t_prev + dt

                    Q_new = self.physics.extrapolate_calendar(p_cal, t_new, T_degC, SOC)
                    Q_prev = self.physics.extrapolate_calendar(p_cal, t_prev, T_degC, SOC)
                    
                    dQ = max(Q_new - Q_prev, 0)
                    q_loss_calendar += dQ
                    q_loss_total += dQ

                # --- 2. Cycling Ageing Step ---
                for _, row in cyc_step.iterrows():
                    dN = row['FCE']
                    # Pass all stress factors into the physics engine
                    T_degC = row['T_bin']
                    SOC_avg = row['SOC_bin']
                    DOD = row['DOD_bin']
                    C_ch = row['C_ch']
                    C_dis = row['C_dis']

                    if cyc_model_type == "simple":
                        N_prev = self.physics.invert_cycling_simple(p_cyc, q_loss_total, T_degC)
                        N_new = N_prev + dN

                        Q_new = self.physics.extrapolate_cycling_simple(p_cyc, N_new, T_degC)
                        Q_prev = self.physics.extrapolate_cycling_simple(p_cyc, N_prev, T_degC)
                    else:
                        N_prev = self.physics.invert_cycling(p_cyc, q_loss_total, T_degC, C_ch, C_dis, SOC_avg, DOD)
                        N_new = N_prev + dN

                        Q_new = self.physics.extrapolate_cycling(p_cyc, N_new, T_degC, C_ch, C_dis, SOC_avg, DOD)
                        Q_prev = self.physics.extrapolate_cycling(p_cyc, N_prev, T_degC, C_ch, C_dis, SOC_avg, DOD)
                    
                    dQ = max(Q_new - Q_prev, 0)
                    q_loss_cycling += dQ
                    q_loss_total += dQ
                    total_cycles += dN

                # --- 3. Update Trajectory ---
                soh = 100.0 - q_loss_total
                soh_traj.append(soh)
                
                total_days += 365.25 / months_per_year
                time_axis.append(total_days)
                cycle_axis.append(total_cycles)

                # End of Life Check
                if soh <= 70:
                    break
            if soh <= 70:
                break

        return (
            np.array(soh_traj),
            q_loss_calendar,
            q_loss_cycling,
            np.array(time_axis),
            np.array(cycle_axis)
        )

if __name__ == "__main__":
    RPT_PATH = r"C:\BatteryLife\dataset\SNL_NCA"
    RPT_FILE = "SNL_NCA_cleaned.xlsx"
    # RPT_PATH = r"C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Meridian\05_Engineering_Design\02_Module\00_Cell\02_Modelling"
    # RPT_FILE = "Cell_ageing_RPT_with_fake_data.xlsx"

    # Load RPT data
    data_handler = DataHandler()
    storage_data, cycling_data = data_handler.read_RPT_data(RPT_PATH, RPT_FILE)
    storage_data_df, cycling_data_df = data_handler.convert_data_to_df(storage_data, cycling_data)

    # Data fitter
    fitter = DegradationModelFitter()
    model_params = fitter.fit_degradation_models(storage_data_df, cycling_data_df)
    
    utils.plot_cycling_extrapolation(cycling_data, model_params["cycling"]["params"], fitter.physics.extrapolate_cycling)

    # Predictor
    predictor = DegradationPredictor(model_params)
    predictor.apply()