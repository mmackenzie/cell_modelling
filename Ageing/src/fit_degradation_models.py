import sys
import os
import numpy as np
import pandas as pd
from scipy.optimize import least_squares

from .data_handling import DataHandler
from .degradation_physics import DegradationPhysics
from .utils import *


class DegradationModelFitter:
    """
    Fits calendar and cycling degradation models
    to RPT test data (storage and cycling datasets).
    """

    def __init__(self, dataset, output_folder, soc_ref: float = 100.0):
        self.dataset = dataset.replace("\\", "_")
        self.output_folder = output_folder
        self.soc_ref = soc_ref
        self.physics = DegradationPhysics()

    def fit_degradation_models(self, storage_data_df: pd.DataFrame, cycling_data_df: pd.DataFrame, cycling_model_type: str):
        """Main entry point – fits both calendar and cycling models."""
        if not storage_data_df.empty:
            calendar_model = self._fit_calendar(storage_data_df)
        else:
            calendar_model = None
        if not cycling_data_df.empty:
            cycling_model = self._fit_cycling(cycling_data_df, cycling_model_type)
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
        """
        Fit parameters for the calendar ageing model (LLI).
        Parameters: [k_cal_LLI, Ea_LLI, beta_SOC, z_time]
        """
        # 1. Prepare Data
        t_all = storage_data_df["Day"].to_numpy()
        T_all = storage_data_df["Temperature"].to_numpy()
        SOC_all = storage_data_df["SOC"].to_numpy()
        Q_meas_loss = 100 - storage_data_df["Relative_Capacity"].to_numpy()

        # 2. Residual function
        def residuals(p):
            # p = [k_cal_LLI, Ea_LLI, beta_SOC, z_time]
            Q_pred_loss = self.physics.extrapolate_calendar(p, t_all, T_all, SOC_all, T_ref_degC=25.0, SOC_ref=50.0)
            return Q_meas_loss - Q_pred_loss

        # 3. Optimization Setup
        # [k_cal_LLI, Ea_LLI, beta_SOC, z_time]
        p0 = [1e-3, 35000, 0.0, 0.6]
        lb = [1e-7, 10000, -0.01, 0.6]
        ub = [1e2,  80000, 0.01, 0.7]

        # Run optimization with automatic Jacobian scaling
        res = least_squares(residuals, p0, bounds=(lb, ub), x_scale='jac', ftol=1e-12)
        p_fit = res.x

        # 4. Sensitivity Analysis (Calculating relative errors)
        mse = np.mean(res.fun**2)
        try:
            # Use pseudo-inverse of Jacobian to find the covariance matrix
            cov = np.linalg.pinv(res.jac.T @ res.jac) * mse
            rel_errors = np.sqrt(np.diagonal(cov)) / (np.abs(p_fit) + 1e-12)
        except:
            rel_errors = np.full(len(p_fit), np.nan)

        # 5. Validation Metrics
        Q_loss_pred = self.physics.extrapolate_calendar(p_fit, t_all, T_all, SOC_all)
        Q_pred = 100 - Q_loss_pred
        Q_actual = 100 - Q_meas_loss # Original Relative Capacity
        
        rmse = np.sqrt(np.mean((Q_pred - Q_actual) ** 2))
        ss_res = np.sum((Q_pred - Q_actual) ** 2)
        ss_tot = np.sum((Q_actual - np.mean(Q_actual)) ** 2)
        r2 = 1 - (ss_res / (ss_tot + 1e-12))

        # 6. Plotting (Passing 50 as SOC_ref to match model logic)
        save_path = os.path.join(self.output_folder, f"{self.dataset}_fit_calendar.png")
        plot_fit(Q_actual, Q_pred, "Calendar Ageing (LLI)", rmse, r2, savepath=save_path)
        save_path = os.path.join(self.output_folder, f"{self.dataset}_calendar_soc_dependency.png")
        plot_calendar_soc_dependency(p_fit, self.physics.extrapolate_calendar, 50.0, savepath=save_path)
        save_path = os.path.join(self.output_folder, f"{self.dataset}_calendar_T_dependency.png")
        plot_calendar_T_dependency(p_fit, self.physics.extrapolate_calendar, 50.0, savepath=save_path)

        return {
            "params": p_fit, 
            "rel_errors": rel_errors,
            "rmse": rmse, 
            "R2": r2,
            "param_names": ["k_cal_LLI", "Ea_LLI", "beta_SOC", "z_time"]
        }

    def _fit_cycling(self, cycling_data_df: pd.DataFrame, model_type: str):
        """
        Fit parameters for the cycling ageing model.
        Supported model_type: 'simple', 'extended', 'semi-fixed'
        """
        # 0. Validity Check
        valid_types = ["simple", "extended", "semi-fixed"]
        if model_type not in valid_types:
            raise ValueError(f"Invalid model_type '{model_type}'. Must be one of {valid_types}")

        # 1. Prepare data
        N_all = cycling_data_df["FCE"].to_numpy()
        T_all = cycling_data_df["Temperature"].to_numpy()
        Charge_rate_all = cycling_data_df["Charge_C-rate"].to_numpy()
        Discharge_rate_all = cycling_data_df["Discharge_C-rate"].to_numpy()
        SOC_lower_all = cycling_data_df["SOC_lower"].to_numpy()
        SOC_upper_all = cycling_data_df["SOC_upper"].to_numpy()
        
        Q_all = cycling_data_df["Relative_Capacity"].to_numpy()
        Q_loss_measured = 100 - Q_all

        # 2. Optimization Parameters & Mapping Setup
        # Configuration for the "semi-fixed" mode (subset of extended)
        fixed_values = {"z": 0.6, "m": 2.0, "w": 1.0, "g_dis": 2.0}
        varying_names_fixed = ["k_LLI", "k_LAM", "Ea_LLI", "beta", "a_plat", "Ea_plat", "a_dis"]
        param_names_extended = ["k_LLI", "z", "k_LAM", "m", "Ea_LLI", "beta", "w", "a_plat", "Ea_plat", "a_dis", "g_dis"]
        param_names_simple = ["k_cyc", "Ea", "z"]

        def get_full_p(p_opt):
            """Helper to convert optimizer output to the vector the physics engine expects."""
            if model_type == "semi-fixed":
                v = dict(zip(varying_names_fixed, p_opt))
                return np.array([
                    v["k_LLI"], fixed_values["z"], v["k_LAM"], fixed_values["m"],
                    v["Ea_LLI"], v["beta"], fixed_values["w"],
                    v["a_plat"], v["Ea_plat"], v["a_dis"], fixed_values["g_dis"]
                ])
            return p_opt # 'simple' and 'extended' pass through directly

        if model_type == "simple":
            # 3-param vector: [k_cyc, Ea, z]
            p0 = [1e-3, 35000, 0.9]
            lb = [1e-7, 5000, 0.89]
            ub = [1.0, 100000, 0.91]
            param_names = param_names_simple
        
        elif model_type == "extended":
            # Full 11-param vector: [k_LLI, z, k_LAM, m, Ea_LLI, beta, w, a_plat, Ea_plat, a_dis, g_dis]
            p0 = [1e-3, 0.6, 1e-8, 2.0, 35000, 0.5, 1.2, 0.05, 25000, 0.05, 1.5]
            lb = [1e-7, 0.5, 0.0,  1.1, 5000, 0.0, 1.0, 0.01, 5000, 0.0, 1.0]
            ub = [1.0,  0.9, 1e-3, 5.0, 100000, 2.0, 3.0, 2.0, 100000, 2.0, 4.0]
            param_names = param_names_extended
            
        elif model_type == "semi-fixed":
            # 7-param vector: [k_LLI, k_LAM, Ea_LLI, beta, a_plat, Ea_plat, a_dis]
            p0 = [1e-3, 1e-8, 35000, 0.5, 0.05, 25000, 0.05]
            lb = [1e-7, 0.0,  5000,  0.0, 0.01, 5000,  0.0]
            ub = [1.0,  1e-3, 100000, 2.0, 2.0,  100000, 2.0]
            param_names = varying_names_fixed

        # 3. Model and Residuals
        def model_func(p_opt):
            p_full = get_full_p(p_opt)
            if model_type == "simple":
                return self.physics.extrapolate_cycling_simple(p_full, N_all, T_all)
            else:
                # Both 'extended' and 'semi-fixed' use the extended physics function
                return self.physics.extrapolate_cycling(
                    p_full, N_all, T_all, Charge_rate_all, Discharge_rate_all, SOC_lower_all, SOC_upper_all
                )

        def residuals(p_opt):
            return Q_loss_measured - model_func(p_opt)

        # 4. Optimisation
        res = least_squares(residuals, p0, bounds=(lb, ub), x_scale='jac', ftol=1e-12)
        p_fit_opt = res.x
        p_fit_full = get_full_p(p_fit_opt)

        # 5. Sensitivity Analysis
        mse = np.mean(res.fun**2)
        try:
            cov = np.linalg.pinv(res.jac.T @ res.jac) * mse
            std_errors_opt = np.sqrt(np.diagonal(cov))
        except Exception:
            std_errors_opt = np.full(len(p_fit_opt), np.nan)

        rel_errors_opt = std_errors_opt / (np.abs(p_fit_opt) + 1e-12)

        # Reconstruct 11-param relative errors for 'semi-fixed' mode
        if model_type == "semi-fixed":
            rel_errors_final = []
            v_idx = 0
            for name in param_names_extended:
                if name in varying_names_fixed:
                    rel_errors_final.append(rel_errors_opt[v_idx])
                    v_idx += 1
                else:
                    rel_errors_final.append(0.0)
            rel_errors_final = np.array(rel_errors_final)
            final_names = param_names_extended
        else:
            rel_errors_final = rel_errors_opt
            final_names = param_names

        # 6. Metrics
        Q_loss_pred = model_func(p_fit_opt)
        Q_pred = 100 - Q_loss_pred
        rmse = np.sqrt(np.mean((Q_pred - Q_all) ** 2))
        R2 = 1 - (np.sum((Q_all - Q_pred)**2) / (np.sum((Q_all - np.mean(Q_all))**2) + 1e-12))

        # 7. Plotting
        save_path = os.path.join(self.output_folder, f"{self.dataset}_fit_cycling_{model_type}.png")
        plot_fit(Q_all, Q_pred, f"Cycling Ageing ({model_type})", rmse, R2, savepath=save_path)

        return {
            "model_type": model_type,
            "params": p_fit_full,
            "rel_errors": rel_errors_final,
            "rmse": rmse,
            "R2": R2,
            "param_names": final_names
        }

    def _fit_cycling_old(self, cycling_data_df: pd.DataFrame, model_type: str):
        """Fit parameters for the cycling ageing model."""
        # Check that model_type is valid
        if not any(model_type in x for x in ["simple", "extended"]):
            print(f"{model_type} is not a valid cycling model. It must be either 'simple' or 'extended'")
            sys.exit()

        # 1. Prepare data
        N_all = cycling_data_df["FCE"].to_numpy()
        T_all = cycling_data_df["Temperature"].to_numpy()
        Charge_rate_all = cycling_data_df["Charge_C-rate"].to_numpy()
        Discharge_rate_all = cycling_data_df["Discharge_C-rate"].to_numpy()
        SOC_lower_all = cycling_data_df["SOC_lower"].to_numpy()
        SOC_upper_all = cycling_data_df["SOC_upper"].to_numpy()
        
        Q_all = cycling_data_df["Relative_Capacity"].to_numpy()
        Q_loss_measured = 100 - Q_all

        # 2. Define internal model function
        def model_func(p, x):
            if model_type == "simple":
                N, T = x.T
                return self.physics.extrapolate_cycling_simple(p, N, T)
            elif model_type == "extended":
                N, T, Cch, Cdis, SoC_low, SoC_up = x.T
                return self.physics.extrapolate_cycling(p, N, T, Cch, Cdis, SoC_low, SoC_up)

        def residuals(p):
            if model_type == "simple":
                X = np.column_stack((N_all, T_all))
            elif model_type == "extended":
                X = np.column_stack((N_all, T_all, Charge_rate_all, Discharge_rate_all, SOC_lower_all, SOC_upper_all))
            return Q_loss_measured - model_func(p, X)

        # 3. Optimisation setup
        if model_type == "simple":
            # [k_cyc, Ea, z]
            p0 = [1e-3, 35000, 0.9]
            lb = [1e-7, 5000, 0.8]
            ub = [1.0, 100000, 1.0]
        elif model_type == "extended":
            # [k_LLI, z, k_LAM, m, Ea_LLI, beta, w, a_plat, Ea_plat, a_dis, g_dis]
            p0 = [1e-3, 0.6, 1e-8, 2.0, 35000, 0.5, 1.2, 0.05, 25000, 0.05, 1.5]
            lb = [1e-7, 0.5, 0.0,  1.1, 5000, 0.0, 1.0, 0.01, 5000, 0.0, 1.0]
            ub = [1.0,  0.9, 1e-3, 5.0, 100000, 2.0, 3.0, 2.0, 100000, 2.0, 4.0]

        # Run Least Squares Optimization
        # Use x_scale='jac' to handle different parameter magnitudes (Ea vs k_cyc)
        res = least_squares(residuals, p0, bounds=(lb, ub), x_scale='jac', ftol=1e-12)
        p_fit = res.x

        # 4. Sensitivity analysis (Jacobian)
        mse = np.mean(res.fun**2)
        jacobian = res.jac
        jtj = jacobian.T @ jacobian
        
        try:
            cov = np.linalg.pinv(jtj) * mse
            standard_errors = np.sqrt(np.diagonal(cov))
        except Exception:
            standard_errors = np.full(len(p_fit), np.nan)

        rel_errors = standard_errors / (np.abs(p_fit) + 1e-12)

        # 5. Validation Metrics
        if model_type == "simple":
            x = np.column_stack((N_all, T_all))
        elif model_type == "extended":
            x = np.column_stack((N_all, T_all, Charge_rate_all, Discharge_rate_all, SOC_lower_all, SOC_upper_all))
        Q_loss_pred = model_func(p_fit, x)
        Q_pred = 100 - Q_loss_pred

        rmse = np.sqrt(np.mean((Q_pred - Q_all) ** 2))
        R2 = 1 - (np.sum((Q_all - Q_pred)**2) / np.sum((Q_all - np.mean(Q_all))**2))

        # Plot fit
        plot_fit(Q_all, Q_pred, "Cycling ageing", rmse, R2, savepath=os.path.join(self.output_folder, f"{self.dataset}_cycling_fit.png"))

        if model_type == "simple":
            param_names = ["k_cyc", "Ea", "z"]
        elif model_type == "extended":
            param_names = ["k_LLI", "z", "k_LAM", "m", "Ea_LLI", "beta", "w", "a_plat", "Ea_plat", "a_dis", "g_dis"]

        return {
            "params": p_fit,
            "rel_errors": rel_errors,
            "rmse": rmse,
            "R2": R2,
            "param_names": param_names
        }
    
    def _fit_cycling_with_fixed_params(self, cycling_data_df: pd.DataFrame):
        """
        Fits magnitudes while fixing exponents to physical constants.
        Fixed: z=0.5, m=2.0, w=1.0, g_dis=2.0
        Varying: [k_LLI, k_LAM, Ea_LLI, beta, a_plat, Ea_plat, a_dis]
        """
        # 1. Prepare data
        N_all = cycling_data_df["FCE"].to_numpy()
        T_all = cycling_data_df["Temperature"].to_numpy()
        Charge_rate_all = cycling_data_df["Charge_C-rate"].to_numpy()
        Discharge_rate_all = cycling_data_df["Discharge_C-rate"].to_numpy()
        SOC_lower_all = cycling_data_df["SOC_lower"].to_numpy()
        SOC_upper_all = cycling_data_df["SOC_upper"].to_numpy()
        
        Q_all = cycling_data_df["Relative_Capacity"].to_numpy()
        Q_loss_measured = 100 - Q_all

        # 2. Setup Parameter Mapping
        # Define which parameters are constant
        fixed_values = {"z": 0.6, "m": 2.0, "w": 1.0, "g_dis": 2.0}
        # Define the order of the 7 fitting parameters
        varying_names = ["k_LLI", "k_LAM", "Ea_LLI", "beta", "a_plat", "Ea_plat", "a_dis"]
        
        def get_full_p(p_varying):
            """Reconstructs the 11-param vector for the physics engine."""
            v = dict(zip(varying_names, p_varying))
            # Order must strictly match extrapolate_cycling_unified signature:
            # [k_LLI, z, k_LAM, m, Ea_LLI, beta, w, a_plat, Ea_plat, a_dis, g_dis]
            return np.array([
                v["k_LLI"], fixed_values["z"], v["k_LAM"], fixed_values["m"],
                v["Ea_LLI"], v["beta"], fixed_values["w"],
                v["a_plat"], v["Ea_plat"], v["a_dis"], fixed_values["g_dis"]
            ])

        # 3. Model and Residuals
        def model_func(p_varying):
            p_full = get_full_p(p_varying)
            return self.physics.extrapolate_cycling_unified(
                p_full, N_all, T_all, Charge_rate_all, Discharge_rate_all, SOC_lower_all, SOC_upper_all
            )

        def residuals(p_varying):
            return Q_loss_measured - model_func(p_varying)

        # 4. Optimization Setup (7 Parameters)
                   # [k_LLI, k_LAM, Ea_LLI, beta, a_plat, Ea_plat, a_dis]
        p0_varying = [1e-3,  1e-8,  35000,  0.5,  0.05,   25000,   0.05]
        lb_varying = [1e-7,  0.0,   5000,   0.0,  0.01,   5000,    0.0]
        ub_varying = [1.0,   1e-3,  100000, 2.0,  2.0,    100000,  2.0]

        res = least_squares(residuals, p0_varying, bounds=(lb_varying, ub_varying), 
                            x_scale='jac', ftol=1e-12)
        
        p_fit_varying = res.x
        p_fit_full = get_full_p(p_fit_varying)

        # 5. Sensitivity Analysis (calculating errors for the varying params)
        mse = np.mean(res.fun**2)
        try:
            cov = np.linalg.pinv(res.jac.T @ res.jac) * mse
            std_err_varying = np.sqrt(np.diagonal(cov))
        except Exception:
            std_err_varying = np.full(len(p_fit_varying), np.nan)

        # Map relative errors back to 11-length array (Fixed params = 0.0 error)
        rel_err_varying = std_err_varying / (np.abs(p_fit_varying) + 1e-12)
        
        rel_errors_full = []
        v_idx = 0
        param_names_11 = ["k_LLI", "z", "k_LAM", "m", "Ea_LLI", "beta", "w", "a_plat", "Ea_plat", "a_dis", "g_dis"]
        
        for name in param_names_11:
            if name in varying_names:
                rel_errors_full.append(rel_err_varying[v_idx])
                v_idx += 1
            else:
                rel_errors_full.append(0.0) # Fixed parameters have no fit-uncertainty

        # 6. Metrics
        Q_loss_pred = model_func(p_fit_varying)
        Q_pred = 100 - Q_loss_pred
        rmse = np.sqrt(np.mean((Q_pred - Q_all) ** 2))
        R2 = 1 - (np.sum((Q_all - Q_pred)**2) / (np.sum((Q_all - np.mean(Q_all))**2) + 1e-12))

        # Plot fit
        save_name = f"{self.dataset}_cycling_fixed_fit.png"
        plot_fit(Q_all, Q_pred, "Cycling Ageing (Fixed Exponents)", rmse, R2, 
                    savepath=os.path.join(self.output_folder, save_name))

        return {
            "params": p_fit_full,
            "rel_errors": np.array(rel_errors_full),
            "rmse": rmse,
            "R2": R2,
            "param_names": param_names_11
        }
    

if __name__ == "__main__":
    ROUTE_PATH = r"C:\BatteryLife\dataset"
    # DATASETS = [r"ISU_ILCC\batch1", r"ISU_ILCC\batch2", r"ISU_ILCC\batch3", r"ISU_ILCC\batch4", r"ISU_ILCC\batch5", r"ISU_ILCC\batch6", r"ISU_ILCC\batch7"]
    # DATASETS = [r"CALCE", r"HNEI", r"HUST"]
    # DATASETS = [r"ISU_ILCC\batch1", r"ISU_ILCC\batch2", r"ISU_ILCC\batch3", r"ISU_ILCC\batch4", r"ISU_ILCC\batch5", r"ISU_ILCC\batch6", r"ISU_ILCC\batch7",
    #             "CALCE", "HNEI", "HUST", "MICH", "MICH_EXP", "RWTH", "SDU", "SNL_LFP", "SNL_NCA", "SNL_NMC", "Stanford", "UL_PUR", "XJTU",
    #             r"Tongji\Tongji1", r"Tongji\Tongji2", r"Tongji\Tongji3", r"MATR\batch1", r"MATR\batch2", r"MATR\batch3", r"MATR\batch4"]
    DATASETS = ["Gotion"]
    # OUTPUT_PATH = os.path.join(ROUTE_PATH, "Parameter fitting v4")
    OUTPUT_PATH = r"C:\Degradation model outputs"
    CYCLING_MODEL_TYPE = "semi-fixed"  # simple, extended, or semi-fixed
    
    for DATASET in DATASETS:
        print(f"Analysing: {DATASET}")
        if "Gotion" in DATASET:
            RPT_PATH = r"C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Zeleros - Zeleros\Operaciones\4- E-drive\05- Projects\Meridian\05_Engineering_Design\02_Module\00_Cell\02_Modelling"
            RPT_FILE = "Cell_ageing_RPT_data.xlsx"
        else:
            RPT_PATH = os.path.join(ROUTE_PATH, DATASET)
            RPT_FILE = f"{DATASET}_cleaned.xlsx".replace("\\", "_")

        # Load RPT data
        data_handler = DataHandler()
        storage_data, cycling_data = data_handler.read_RPT_data(RPT_PATH, RPT_FILE)
        storage_data_df, cycling_data_df = data_handler.convert_data_to_df(storage_data, cycling_data)

        # Data fitter
        fitter = DegradationModelFitter(DATASET, OUTPUT_PATH)
        model_params = fitter.fit_degradation_models(storage_data_df, cycling_data_df, CYCLING_MODEL_TYPE)
        fitter.export_params_to_csv(model_params, DATASET.replace("\\", "_"), os.path.join(OUTPUT_PATH, f"optimised_params_{CYCLING_MODEL_TYPE}.csv"))
        
        if model_params["calendar"] is not None:
            savepath = os.path.join(OUTPUT_PATH, f"{DATASET}_storage_extrapolations.png".replace("\\", "_"))
            plot_calendar_extrapolation(storage_data, model_params["calendar"]["params"], fitter.physics.extrapolate_calendar, savepath=savepath)
        
        if model_params["cycling"] is not None:
            savepath = os.path.join(OUTPUT_PATH, f"{DATASET}_cycling_extrapolations_{CYCLING_MODEL_TYPE}.png".replace("\\", "_"))
            n_cycles = np.arange(0, 2000 + 1, 100)
            if CYCLING_MODEL_TYPE == "simple":
                physics_func = fitter.physics.extrapolate_cycling_simple
            else:
                physics_func = fitter.physics.extrapolate_cycling
            plot_cycling_extrapolation(cycling_data, model_params["cycling"]["params"], CYCLING_MODEL_TYPE, physics_func, N_extrap=n_cycles, savepath=savepath)

    print("done")
