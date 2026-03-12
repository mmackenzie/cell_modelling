import os
import numpy as np
import pandas as pd
from matplotlib.cm import turbo

from src.data_handling import DataHandler
from src.fit_degradation_models import DegradationModelFitter
from src.degradation_predictor import DegradationPredictor
from src.profile_generator import ProfileGenerator
from src.utils import plot_SOH_trajectory


def main_degradation(
    rpt_path: str,
    rpt_file: str,
    customer_path: str,
    output_folder: str,
    batteries: list[str],
    nominal_capacity: float = 115.8,
):
    """
    Main degradation workflow:
      - Reads RPT data
      - Applies degradation models to customer usage profiles
      - Produces summary table and plots

    Parameters
    ----------
    rpt_path : str
        Path to RPT data file or folder.
    customer_path : str
        Folder with customer usage profiles.
    output_folder : str
        Where plots and results will be saved.
    customers : list[str]
        List of customer identifiers (filenames without extension).
    nominal_capacity : float, optional
        Rated capacity [Ah].
    """

    os.makedirs(output_folder, exist_ok=True)
    n_customers = len(batteries)

    # --- Load RPT data ---
    reader = DataHandler()
    storage_data, cycling_data = reader.read_RPT_data(rpt_path, rpt_file)

    # --- Data fitter ---
    fitter = DegradationModelFitter()
    model_params = fitter.fit_degradation_models(storage_data, cycling_data)

    # --- Predictor ---
    predictor = DegradationPredictor(model_params)

    # --- Containers ---
    results = []
    colours = turbo(n_customers)

    for i, batt in enumerate(batteries):
        battery_profile_path = os.path.join(customer_path, f"{batt}.csv")
        generator = ProfileGenerator()
        soc_bins, temp_bins, cal_hist, cyc_hist, time_summary = generator.profile_to_histograms(battery_profile_path, nominal_capacity)

        soh, q_loss_cal, q_loss_cyc, time_days, cycles = predictor.apply(cal_hist, cyc_hist, soc_bins, temp_bins)
        q_loss_tot = q_loss_cal + q_loss_cyc
        pct_loss_cal = q_loss_cal / q_loss_tot * 100
        pct_loss_cyc = q_loss_cyc / q_loss_tot * 100
        pct_time_cal = time_summary["idle"] / time_summary["total"] * 100
        pct_time_cyc = (time_summary["charge"] + time_summary["discharge"]) / time_summary["total"] * 100

        results.append({
            "Battery": batt,
            "Years_to_75SOH": time_days[np.argmax(soh <= 75)] / 365 if np.any(soh <= 75) else np.nan,
            "Years_to_70SOH": time_days[np.argmax(soh <= 70)] / 365 if np.any(soh <= 70) else np.nan,
            "Cycles_to_75SOH": cycles[np.argmax(soh <= 75)] if np.any(soh <= 75) else np.nan,
            "Cycles_to_70SOH": cycles[np.argmax(soh <= 70)] if np.any(soh <= 70) else np.nan,
            "Percent_Cycling_Time": pct_time_cyc,
            "Percent_Calendar_Time": pct_time_cal,
            "Percent_Cycling_Degradation": pct_loss_cyc,
            "Percent_Calendar_Degradation": pct_loss_cal
        })

        plot_SOH_trajectory(time_days, soh, savepath=os.path.join(output_folder, f"{batt}_SOH_traj.png"))

    summary = pd.DataFrame(results)
    summary.to_csv(os.path.join(output_folder, "degradation_summary.csv"), index=False)
    print("\nSummary:\n", summary.round(1))

    return summary


if __name__ == "__main__":
    # Example usage
    RPT_PATH = r"C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Meridian\05_Engineering_Design\02_Module\00_Cell\02_Modelling"
    RPT_FILE = "Cell_ageing_RPT_data.xlsx"
    PROFILE_PATH = r"C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\Synthetic data\Yearly profiles"
    OUTPUT_FOLDER = r"C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\Synthetic data\Life estimations"

    BATTERIES = [
        "battery_01", "battery_02", "battery_03", "battery_04",
        "battery_05", "battery_06", "battery_07", "battery_08"
    ]

    results = main_degradation(
        rpt_path=RPT_PATH,
        rpt_file=RPT_FILE,
        customer_path=PROFILE_PATH,
        output_folder=OUTPUT_FOLDER,
        batteries=BATTERIES
    )
