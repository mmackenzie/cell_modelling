import os
import numpy as np
import pandas as pd
from scipy.optimize import least_squares

from data_handling import DataHandler
from degradation_physics import DegradationPhysics
import utils


class DegradationModelFitter:
    """
    Fits calendar and cycling degradation models
    to RPT test data (storage and cycling datasets).
    """

    def __init__(self, route_folder, output_folder, R: float = 8.314, soc_ref: float = 100.0):
        self.route_folder = route_folder
        self.output_folder = output_folder
        self.R = R
        self.soc_ref = soc_ref
        self.physics = DegradationPhysics(R, soc_ref)

    def fit_degradation_models(self, storage_data_df: pd.DataFrame, cycling_data_df: pd.DataFrame):
        """Main entry point – fits both calendar and cycling models."""
        if not storage_data_df.empty:
            calendar_model = self._fit_calendar(storage_data_df)
        else:
            calendar_model = None
        if not cycling_data_df.empty:
            cycling_model = self._fit_cycling(cycling_data_df)
        else:
            cycling_model = None

        return {"calendar": calendar_model, "cycling": cycling_model}
    
    def export_params_to_csv(self, model_params: dict, cell_id: str, file_path: str):
        """
        Exports optimized parameters to a shared CSV for cross-cell comparison.
        If the file exists, it appends the new cell data.
        """
        flat_row = {"Cell_ID": cell_id}
        
        for mode in ["calendar", "cycling"]:
            if mode in model_params:
                if model_params[mode] is None:
                    continue
                prefix = "cyc" if mode == "cycling" else "cal"

                # Add fit quality metrics
                flat_row[f"{prefix}_rmse"] = float(model_params[mode]["rmse"])
                flat_row[f"{prefix}_R2"] = float(model_params[mode]["R2"])
            
                # Add parameters with mode prefix (e.g., cyc_Ea, cyc_alpha)
                params = model_params[mode]["params"]
                names = model_params[mode]["param_names"]
                rel_errs = model_params[mode]["rel_errors"]
                for i, (name, val) in enumerate(zip(names, params)):
                    flat_row[f"{prefix}_{name}"] = float(val)
                    flat_row[f"{prefix}_{name}_error"] = float(rel_errs[i])
      
        df_new = pd.DataFrame([flat_row])

        # Save logic
        if not os.path.isfile(file_path):
            # Create file with headers if it doesn't exist
            df_new.to_csv(file_path, index=False)
        else:
            # Check if Cell_ID already exists to avoid duplicates (optional but recommended)
            df_existing = pd.read_csv(file_path)
            if cell_id in df_existing["Cell_ID"].values:
                # Overwrite the existing row for this Cell_ID
                df_existing = df_existing[df_existing["Cell_ID"] != cell_id]
                df_final = pd.concat([df_existing, df_new], ignore_index=True)
                df_final.to_csv(file_path, index=False)
            else:
                # Append new cell row
                df_new.to_csv(file_path, mode='a', index=False, header=False)
            
        print(f"Cell {cell_id} data synchronized in {file_path}")

    def _fit_calendar(self, storage_data_df: pd.DataFrame):
        """Fit parameters for the calendar ageing model."""
        t_all = storage_data_df["Day"].to_numpy()
        T_all = storage_data_df["Temperature"].to_numpy()
        SOC_all = storage_data_df["SOC"].to_numpy()
        Q_all = storage_data_df["Relative_Capacity"].to_numpy()

        # Scaling setup
        scale_factors = np.array([1e4, 1e4, 0.01])  # [k_cal, Ea, k_soc]
        p0_scaled = np.array([1.0, 1.0, 1.0])

        # Function to unscale for physical model
        def unscale(p_scaled):
            return p_scaled * scale_factors

        # Model function (maps parameters → predicted Q_loss)
        def model_func(p_scaled, x):
            p = unscale(p_scaled)
            t_days, T_degC, SOC = x[:, 0], x[:, 1], x[:, 2]
            return self.physics.extrapolate_calendar(p, t_days, T_degC, SOC)

        # Residual function for least_squares
        def residuals(p_scaled):
            Q_loss_pred = model_func(p_scaled, np.column_stack((t_all, T_all, SOC_all)))
            return (100 - Q_all) - Q_loss_pred

        # Bounds in scaled space
        lb_scaled = np.array([0.01, 0.01, 0.1])
        ub_scaled = np.array([100.0, 100.0, 10.0])

        res = least_squares(residuals, p0_scaled)
        p_fit = unscale(res.x)

        # Predictions and metrics
        Q_loss_pred = self.physics.extrapolate_calendar(p_fit, t_all, T_all, SOC_all)
        Q_pred = 100 - Q_loss_pred
        rmse = np.sqrt(np.mean((Q_pred - Q_all) ** 2))
        R2 = 1 - np.sum((Q_pred - Q_all) ** 2) / np.sum((Q_all - np.mean(Q_all)) ** 2)

        # --- Plot results
        utils.plot_fit(Q_all, Q_pred, "Calendar ageing", rmse, R2)
        # utils.plot_calendar_extrapolation(storage_data, p_fit, self.physics.extrapolate_calendar)
        utils.plot_calendar_soc_dependency(p_fit, self.physics.extrapolate_calendar, self.soc_ref)
        utils.plot_calendar_T_dependency(p_fit, self.physics.extrapolate_calendar, self.soc_ref)

        return {"params": p_fit, "rmse": rmse, "R2": R2}

    def _fit_cycling(self, cycling_data_df: pd.DataFrame):
        """Fit parameters for the refined cycling ageing model."""
        # Extract data from DataFrame
        N_all = cycling_data_df["Cycle"].to_numpy()
        T_all = cycling_data_df["Temperature"].to_numpy()
        Charge_rate_all = cycling_data_df["Charge_C-rate"].to_numpy()
        Discharge_rate_all = cycling_data_df["Discharge_C-rate"].to_numpy()
        SOC_lower_all = cycling_data_df["SOC_lower"].to_numpy()
        SOC_upper_all = cycling_data_df["SOC_upper"].to_numpy()
        
        Q_all = cycling_data_df["Relative_Capacity"].to_numpy()
        Q_loss_measured = 100 - Q_all

        def model_func(p, x):
            N, T, Cch, Cdis, SoC_low, SoC_up = x.T
            # return self.physics.extrapolate_cycling(p, N, T, Cch, Cdis, SoC_low, SoC_up)
            return self.physics.extrapolate_cycling_unified(p, N, T, Cch, Cdis, SoC_low, SoC_up)

        def residuals(p):
            X = np.column_stack((N_all, T_all, Charge_rate_all, Discharge_rate_all, 
                                SOC_lower_all, SOC_upper_all))
            return Q_loss_measured - model_func(p, X)

        # Parameter Order: 
        # [k_cyc, Ea, b_soc_avg, b_dod, a_Cch, b_Cch, a_Cdis, b_Cdis, alpha]
        
        # Initial guesses (p0)
        p0 = np.array([1e-3, 3e4, 0.5, 1.2, 0.1, 2.0, 0.05, 1.1, 0.7])

        # Define physically meaningful bounds
        # 0: k_cyc: Must be positive
        # 1: Ea: 20k-60k is the typical range for battery side-reactions
        # 2: b_soc_avg: Positive (high SOC = more stress)
        # 3: b_dod: Usually > 1 (mechanical fatigue is non-linear)
        # 4/6: a_Cch/a_Cdis: Positive
        # 5/7: b_Cch/b_Cdis: Must be >= 1 (faster is never better for the battery)
        # alpha: 0.5-1 (physics of SEI growth plus particle cracking)
        lb = [1e-7, 1e3, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.5]
        ub = [1.0, 1e5, 3.0, 3.0, 5.0, 100.0, 5.0, 100.0, 1.0]

        # Run Least Squares Optimization
        # Use x_scale='jac' to handle different parameter magnitudes (Ea vs k_cyc)
        res = least_squares(residuals, p0, bounds=(lb, ub), x_scale='jac', ftol=1e-8)
        p_fit = res.x

        # --- SENSITIVITY CALCULATION ---
        # 1. Calculate the Covariance Matrix: Cov = MSE * (J^T * J)^-1
        # Use the pseudo-inverse (pinv) to handle insensitive parameters (singular matrices)
        mse = np.mean(res.fun**2)
        jacobian = res.jac
        jtj = jacobian.T @ jacobian
        
        try:
            cov = np.linalg.pinv(jtj) * mse
            standard_errors = np.sqrt(np.diagonal(cov))
        except Exception:
            standard_errors = np.full(len(p_fit), np.nan)

        # 2. Calculate Relative Error (CV)
        # A value > 0.5 (50%) suggests the parameter is not well-identified by the data
        rel_errors = standard_errors / (np.abs(p_fit) + 1e-12)
        # -------------------------------

        # Validation Metrics
        Q_loss_pred = model_func(p_fit, np.column_stack((N_all, T_all, Charge_rate_all, 
                                                        Discharge_rate_all, SOC_lower_all, 
                                                        SOC_upper_all)))
        Q_pred = 100 - Q_loss_pred
        rmse = np.sqrt(np.mean((Q_pred - Q_all) ** 2))
        R2 = 1 - (np.sum((Q_all - Q_pred)**2) / np.sum((Q_all - np.mean(Q_all))**2))

        # Plot fit
        utils.plot_fit(Q_all, Q_pred, "Cycling ageing", rmse, R2, savepath=os.path.join(self.output_folder, "cycling_fit.png"))

        return {
            "params": p_fit,
            "rel_errors": rel_errors,
            "rmse": rmse,
            "R2": R2,
            "param_names": ["k_cyc", "Ea", "b_soc_avg", "b_dod", "a_Cch", "b_Cch", "a_Cdis", "b_Cdis", "alpha"]
        }
    

if __name__ == "__main__":
    ROUTE_PATH = r"C:\BatteryLife\dataset"
    DATASET = r"HUST"
    RPT_PATH = os.path.join(ROUTE_PATH, DATASET)
    RPT_FILE = f"{DATASET}_cleaned.xlsx".replace("\\", "_")
    OUTPUT_PATH = os.path.join(ROUTE_PATH, "Parameter fitting")
    # RPT_PATH = r"C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Meridian\05_Engineering_Design\02_Module\00_Cell\02_Modelling"
    # RPT_FILE = "Cell_ageing_RPT_with_fake_data.xlsx"

    # Load RPT data
    data_handler = DataHandler()
    storage_data, cycling_data = data_handler.read_RPT_data(RPT_PATH, RPT_FILE)
    storage_data_df, cycling_data_df = data_handler.convert_data_to_df(storage_data, cycling_data)

    # Data fitter
    fitter = DegradationModelFitter(ROUTE_PATH, OUTPUT_PATH)
    model_params = fitter.fit_degradation_models(storage_data_df, cycling_data_df)
    fitter.export_params_to_csv(model_params, DATASET.replace("\\", "_"), os.path.join(OUTPUT_PATH, "optimised_params.csv"))
    
    savepath = os.path.join(OUTPUT_PATH, f"{DATASET}_extrapolations.png".replace("\\", "_"))
    n_cycles = np.arange(0, 2000 + 1, 100)
    utils.plot_cycling_extrapolation(cycling_data, model_params["cycling"]["params"], fitter.physics.extrapolate_cycling, N_extrap=n_cycles, savepath=savepath)

    print("done")
