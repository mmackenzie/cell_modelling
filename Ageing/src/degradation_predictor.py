import numpy as np

from data_handling import DataHandler
from fit_degradation_models import DegradationModelFitter
from degradation_physics import DegradationPhysics
import utils


class DegradationPredictor:
    """
    Applies fitted degradation models to customer usage histograms.
    """

    def __init__(self, model_params: dict, R: float = 8.314):
        self.model_params = model_params
        self.R = R
        self.physics = DegradationPhysics(R=R)

    # --------------------------------------------------------------
    def apply(self, cal_hist, cyc_hist, SOC_edges, T_edges, years=30, months_per_year=12):
        """
        Simulate degradation progression using calendar and cycling histograms.

        Parameters
        ----------
        cal_hist : np.ndarray
            2D histogram of calendar exposure [days].
        cyc_hist : np.ndarray
            2D histogram of cycling exposure [cycles].
        SOC_edges : np.ndarray
            SOC bin edges.
        T_edges : np.ndarray
            Temperature bin edges.
        years : int
            Simulation duration.
        months_per_year : int
            Resolution (default 12 → monthly).

        Returns
        -------
        soh_traj, q_loss_cal, q_loss_cyc, time_days, cycles
        """
        p_cal = self.model_params["calendar"]["params"]
        p_cyc = self.model_params["cycling"]["params"]

        # Split histograms into months
        cal_hist_monthly = cal_hist / months_per_year
        cyc_hist_monthly = cyc_hist / months_per_year

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
                # Calendar ageing
                for iSOC in range(cal_hist_monthly.shape[0]):
                    for iT in range(cal_hist_monthly.shape[1]):
                        dt = cal_hist_monthly[iSOC, iT]
                        if dt > 0:
                            T_mid = np.mean(T_edges[iT:iT+2])
                            SOC_mid = np.max(SOC_edges[iSOC:iSOC+2])

                            # compute previous/new time equivalent
                            t_prev = self.physics.invert_calendar(p_cal, q_loss_total, T_mid, SOC_mid)
                            t_new = t_prev + dt

                            Q_new = self.physics.extrapolate_calendar(p_cal, t_new, T_mid, SOC_mid)
                            Q_prev = self.physics.extrapolate_calendar(p_cal, t_prev, T_mid, SOC_mid)
                            dQ = Q_new - Q_prev

                            q_loss_calendar += dQ
                            q_loss_total += dQ

                # Cycling ageing
                for iC in range(cyc_hist_monthly.shape[0]):
                    for iT in range(cyc_hist_monthly.shape[1]):
                        dN = cyc_hist_monthly[iC, iT]
                        if dN > 0:
                            T_mid = np.mean(T_edges[iT:iT+2])

                            N_prev = self.physics.invert_cycling(p_cyc, q_loss_total, T_mid)
                            N_new = N_prev + dN

                            Q_new = self.physics.extrapolate_cycling(p_cyc, N_new, T_mid)
                            Q_prev = self.physics.extrapolate_cycling(p_cyc, N_prev, T_mid)
                            dQ = Q_new - Q_prev

                            q_loss_cycling += dQ
                            q_loss_total += dQ
                            total_cycles += dN

                # Update trajectory
                soh = 100.0 - q_loss_total
                soh_traj.append(soh)
                total_days += 365.0 / months_per_year
                time_axis.append(total_days)
                cycle_axis.append(total_cycles)

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