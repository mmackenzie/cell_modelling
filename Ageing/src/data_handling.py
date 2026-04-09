import os
import re
import pandas as pd
import pickle
import numpy as np
import matplotlib.pyplot as plt
from tqdm import tqdm
from datetime import datetime
from matplotlib.backends.backend_pdf import PdfPages
from typing import List, Dict, Any, Optional, Tuple


class DataHandler:
    """
    Generic data handler for the degradation model.
    """

    def __init__(self, base_path: str = None, data_path: str = None):
        """
        Initialize DataHandler.

        Parameters
        ----------
        base_path : str, optional
            Root folder where data files are stored.
        """
        self.cell_list: List[Dict[str, Any]] = []
        self.base_path = base_path
        self.data_path = data_path

    def load_pickle_folder(self) -> None:
        """Reads all battery pickle files from a folder and stores them in memory."""
        if not os.path.exists(self.data_path):
            raise FileNotFoundError(f"Folder not found: {self.data_path}")

        for file_name in tqdm(os.listdir(self.data_path), desc="Loading pickle files"):
            if file_name.endswith(('.pkl', '.pickle')):
                file_path = os.path.join(self.data_path, file_name)
                with open(file_path, 'rb') as f:
                    try:
                        data = pickle.load(f)
                        if 'cell_id' not in data:
                            data['cell_id'] = file_name
                        self.cell_list.append(data)
                    except Exception as e:
                        print(f"Skipping {file_name} due to error: {e}")
        
        print(f"Loaded {len(self.cell_list)} cells.")
        return None
    
    def export_to_excel(self, filename: str):
        """
        Exports relative capacity tables to Excel with one sheet per condition,
        with a first sheet summarising cell characteristics.
        """
        output_file = os.path.join(self.data_path, filename)
        info = self._get_cell_characteristics()
        df_characteristics = info["characteristics_df"]
        consistent = info["consistent"]
        grouped: Dict[str, List[pd.DataFrame]] = {}

        for cell in self.cell_list:
            sheet_name = self._get_condition_string(cell, for_sheet=True)
            data = self._get_relative_capacity_data(cell, interval=10)
            if data:
                if sheet_name not in grouped:
                    grouped[sheet_name] = []
                grouped[sheet_name].append(pd.DataFrame(data))

        with pd.ExcelWriter(output_file, engine='xlsxwriter') as writer:
            # Write metadata sheet first
            df_characteristics.to_excel(writer, sheet_name="Cell_characteristics", index=False)
            worksheet = writer.sheets["Cell_characteristics"]
            for i, col in enumerate(df_characteristics.columns):
                max_len = df_characteristics[col].astype(str).map(len).max()
                worksheet.set_column(i, i, max_len + 2)

            # Write sheets with cell cycling data
            for sheet, df_list in grouped.items():
                final_df = pd.concat(df_list).pivot(index='FCE', columns='Cell_ID', values='Rel_Cap')
                final_df.to_excel(writer, sheet_name=sheet)
                worksheet = writer.sheets[sheet]
                for i, col in enumerate(final_df.reset_index().columns):
                    max_len = max(final_df.reset_index()[col].astype(str).map(len).max(), len(str(col)))
                    worksheet.set_column(i, i, max_len + 2)

        print(f"✅ Excel report saved: {output_file}")

    def export_to_pdf(self, filename: str):
        """
        Generates a multi-page PDF summary of capacity fade,
        with a cover page summarising cell characteristics.
        """
        # Gather and check cell characteristics
        output_file = os.path.join(self.data_path, filename)
        info = self._get_cell_characteristics()
        ref_cell = info["ref_cell"]
        consistent = info["consistent"]
        dataset = info["dataset"]
        now = info["now"]
        total_cells = info["total_cells"]

        # Create PDF
        with PdfPages(output_file) as pdf:
            # ---- Cover Page ----
            fig, ax = plt.subplots(figsize=(10, 6))
            ax.axis("off")

            # Header
            title = "CELL DEGRADATION SUMMARY REPORT"
            ax.text(0.5, 0.95, title, fontsize=16, fontweight="bold", ha="center")
            ax.text(0.5, 0.91, f"Generated on {now}   |   Total cells analysed: {total_cells}",
                    fontsize=10, color="gray", ha="center")

            # Description of the cell
            descriptive_text = [
                "CELL CHARACTERISTICS",
                "----------------------",
                "",
                f"Dataset: {dataset}",
                "",
                f"Form factor: {ref_cell.get('form_factor', 'N/A')}",
                f"Anode material: {ref_cell.get('anode_material', 'N/A')}",
                f"Cathode material: {ref_cell.get('cathode_material', 'N/A')}",
                f"Electrolyte: {ref_cell.get('electrolyte_material', 'N/A')}",
                "",
                f"Nominal capacity: {ref_cell.get('nominal_capacity_in_Ah', 'N/A')} Ah",
                f"Voltage limits: {ref_cell.get('min_voltage_limit_in_V', 'N/A')} – {ref_cell.get('max_voltage_limit_in_V', 'N/A')} V",
            ]

            # Place text
            ax.text(0.05, 0.78, "\n".join(descriptive_text),
                    va="top", ha="left", fontsize=12, fontfamily="monospace")

            # Add warning if inconsistent
            if not consistent:
                ax.text(0.05, 0.12, "⚠️ WARNING: Not all cells share identical specifications.",
                        fontsize=11, color="red", fontweight="bold")

            pdf.savefig(fig)
            plt.close(fig)

            # ---- Capacity Fade Plots ----
            grouped: Dict[str, List[Dict]] = {}
            for cell in self.cell_list:
                cond = self._get_condition_string(cell)
                grouped.setdefault(cond, []).append(cell)

            for condition, cells in grouped.items():
                plt.figure(figsize=(10, 6))
                for cell in cells:
                    df = pd.DataFrame(self._get_relative_capacity_data(cell, interval=10))
                    if not df.empty:
                        plt.plot(df["FCE"], df["Rel_Cap"], marker="o", label=cell["cell_id"])

                plt.title(f"Capacity Fade: {condition}", fontweight="bold")
                plt.xlabel("Full cycle equivalents (FCE)")
                plt.ylabel("Relative Capacity (%)")
                plt.ylim(70, 101)
                plt.grid(True, alpha=0.3)
                plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left")
                plt.tight_layout()
                pdf.savefig()
                plt.close()

        print(f"✅ PDF report saved: {output_file}")

    def read_RPT_data(self, base_path: str, filename: str):
        """
        Reads RPT test data (capacity, resistance, cycles, temp, etc.)
        from a multi-sheet Excel file.
        """
        filepath = os.path.join(base_path, filename)
        if not os.path.exists(filepath):
            raise FileNotFoundError(f"RPT data file not found: {filepath}")

        xls = pd.ExcelFile(filepath)
        sheet_names = xls.sheet_names
        storage_data, cycling_data = {}, {}

        # Helper to parse C-rate strings like "05C" -> 0.5, "1C" -> 1.0
        def _parse_crate(crate_str: str) -> float:
            if crate_str is None:
                return np.nan
            crate_str = crate_str.upper().strip()

            # Extract numeric part before 'C'
            match = re.search(r"([0-9]*\.?[0-9]*)C", crate_str)
            if not match:
                return np.nan
            val_str = match.group(1)

            # Handle shorthand formats:
            # 05C → 0.5C, 025C → 0.25C, 033C → 0.33C
            if val_str.startswith("0") and len(val_str) > 1 and not "." in val_str:
                return float(val_str) / (10 ** (len(val_str) - 1))
            try:
                return float(val_str)
            except ValueError:
                return np.nan

        for sheet in sheet_names:
            sheet_lower = sheet.lower()
            if any(skip in sheet_lower for skip in ["cell_characteristics", "cleaning_summary"]):
                continue

            # Identify storage vs cycling
            is_storage = "storage" in sheet_lower or "calendar" in sheet_lower

            # Temperature extraction
            temp_match = re.search(r"(-?\d+)\s*(?=degc)", sheet_lower)
            temperature = float(temp_match.group(1)) if temp_match else None

            df = pd.read_excel(xls, sheet_name=sheet)
            sheet_key = re.sub(r"[^0-9a-zA-Z_]", "_", sheet)
            sheet_clean = sheet.replace("-", "_")

            # --- STORAGE SHEET FORMAT: "Storage_100SOC_25degC" ---
            if is_storage:
                soc_match = re.search(r"(\d+)\s*(?=SOC)", sheet_clean, flags=re.IGNORECASE)
                soc = float(soc_match.group(1)) if soc_match else None

                df.columns = [c.strip() for c in df.columns]
                day_col = next((c for c in df.columns if "day" in c.lower()), None)
                if day_col is None:
                    print(f"⚠️ No 'Day' column found in storage sheet '{sheet}' — skipped.")
                    continue

                cap_cols = [c for c in df.columns if c.lower() != "day"]

                storage_data[sheet_key] = {
                    "soc": soc,
                    "temperature": temperature,
                    "day": df[day_col].to_numpy(),
                    "relative_capacity": {
                        cell_id: df[cell_id].to_numpy()
                        for cell_id in cap_cols
                    },
                }

            # --- CYCLING SHEET FORMAT: "05C_2C_SOC20-80_25degC" ---
            else:
                # Allow both underscores and hyphens
                match_crates = re.findall(r"([0-9\.]*C)", sheet_clean)
                charge_crate = _parse_crate(match_crates[0]) if len(match_crates) >= 1 else None
                discharge_crate = _parse_crate(match_crates[1]) if len(match_crates) >= 2 else None

                # SOC range (SOC20-80 or SOC20_80)
                soc_match = re.search(r"SOC(\d+)[_\-](\d+)", sheet_clean, flags=re.IGNORECASE)
                soc_lower, soc_upper = (
                    (float(soc_match.group(1)), float(soc_match.group(2)))
                    if soc_match else (None, None)
                )

                df.columns = [c.strip() for c in df.columns]
                cycle_col = next((c for c in df.columns if "fce" in c.lower()), None)
                if cycle_col is None:
                    print(f"⚠️ No 'Cycle' column found in cycling sheet '{sheet}' — skipped.")
                    continue

                cap_cols = [c for c in df.columns if c.lower() != "fce"]

                cycling_data[sheet_key] = {
                    "temperature": temperature,
                    "charge_crate": charge_crate,
                    "discharge_crate": discharge_crate,
                    "soc_lower": soc_lower,
                    "soc_upper": soc_upper,
                    "fce": df[cycle_col].to_numpy(),
                    "relative_capacity": {
                        cell_id: df[cell_id].to_numpy()
                        for cell_id in cap_cols
                    },
                }

        return storage_data, cycling_data
    
    def convert_data_to_df(self, storage_data: dict, cycling_data: dict):
        """Converts raw storage and cycling data into one large dataframe each containing all data"""
        # Storage
        t_all, SOC_all, T_all, Q_all = [], [], [], []
        for d in storage_data.values():
            for relative_capacities in d["relative_capacity"].values():
                t_all.extend(d["day"][:len(relative_capacities)])
                SOC_all.extend([d["soc"]] * len(d["day"][:len(relative_capacities)]))
                T_all.extend([d["temperature"]] * len(d["day"][:len(relative_capacities)]))
                Q_all.extend(relative_capacities)

        storage_data_df = pd.DataFrame({
            "Day": np.asarray(t_all),
            "SOC": np.asarray(SOC_all),
            "Temperature": np.asarray(T_all),
            "Relative_Capacity": np.asarray(Q_all)
        })
        mask_valid = storage_data_df["Relative_Capacity"].notna() & (storage_data_df["Relative_Capacity"] >= 70)
        storage_data_df = storage_data_df[mask_valid].reset_index(drop=True)

        # Cycling
        N_all, T_all, SOC_lower_all, SOC_upper_all, charge_rate_all, discharge_rate_all, Q_all = [], [], [], [], [], [], []
        for d in cycling_data.values():
            for relative_capacities in d["relative_capacity"].values():
                N_all.extend(d["fce"][:len(relative_capacities)])
                T_all.extend([d["temperature"]] * len(d["fce"][:len(relative_capacities)]))
                SOC_lower_all.extend([d["soc_lower"]] * len(d["fce"][:len(relative_capacities)]))
                SOC_upper_all.extend([d["soc_upper"]] * len(d["fce"][:len(relative_capacities)]))
                charge_rate_all.extend([d["charge_crate"]] * len(d["fce"][:len(relative_capacities)]))
                discharge_rate_all.extend([d["discharge_crate"]] * len(d["fce"][:len(relative_capacities)]))
                Q_all.extend(relative_capacities)

        cycling_data_df = pd.DataFrame({
            "FCE": np.asarray(N_all),
            "Temperature": np.asarray(T_all),
            "Charge_C-rate": np.asarray(charge_rate_all),
            "Discharge_C-rate": np.asarray(discharge_rate_all),
            "SOC_lower": np.asarray(SOC_lower_all),
            "SOC_upper": np.asarray(SOC_upper_all),
            "Relative_Capacity": np.asarray(Q_all)
        })
        mask_valid = cycling_data_df["Relative_Capacity"].notna() & (cycling_data_df["Relative_Capacity"] >= 70)
        cycling_data_df = cycling_data_df[mask_valid].reset_index(drop=True)

        return storage_data_df, cycling_data_df
    
    def _estimate_crates_from_current(self, cell: dict, nominal_capacity: float) -> tuple[float, float]:
        """Estimate median charge/discharge C-rates from the current profile."""
        current_A = np.array([])
        cycle_data = cell.get("cycle_data")

        if cycle_data and len(cycle_data) > 0:
            current_A = np.array(cycle_data[0].get("current_in_A"), dtype=float)
        if len(current_A) == 0:
            return (np.nan, np.nan)

        # Filter out rest periods (|I| <= 0.1 A)
        active = np.abs(current_A) > 0.1
        if not np.any(active):
            return (np.nan, np.nan)
        current_active = current_A[active]

        # Separate charge (>0) and discharge (<0)
        charge_currents = current_active[current_active > 0]
        discharge_currents = current_active[current_active < 0]
        charge_C = np.nan
        discharge_C = np.nan
        if len(charge_currents) > 0:
            charge_C = np.median(charge_currents) / nominal_capacity
        if len(discharge_currents) > 0:
            discharge_C = abs(np.median(discharge_currents)) / nominal_capacity

        return (charge_C, discharge_C)

    def _format_crate(self, value: any) -> str:
        """
        Formats C-rate values and rounds them to the nearest standard test rate.

        - First rounds to nearest in [0.1, 0.2, 0.25, 0.33, 0.5, 1, 1.5, 2, 3, 4, 5].
        - Whole integers (1.0, 2.0, 10.0) → "1C", "2C", "10C"
        - Decimals (0.5, 0.333) → "05C", "033C"
        - Strings (e.g., 'multi') are passed through unchanged.
        """

        def _round_to_standard_crate(val: float) -> float:
            """Helper to round to standard discrete C-rate values."""
            if val is None or np.isnan(val):
                return np.nan
            standard = np.array([0.1, 0.2, 0.25, 0.33, 0.5, 1, 1.5, 2, 3, 4, 5])
            idx = np.argmin(np.abs(standard - val))
            return float(standard[idx])

        try:
            f_val = float(value)
            # --- Round to standard discrete rates ---
            f_val = _round_to_standard_crate(f_val)

            # Handle NaN case after rounding
            if np.isnan(f_val):
                return "NaN"

            # --- Format integer or decimal nicely ---
            if f_val.is_integer():
                return f"{int(f_val)}C"
            else:
                # round to 2 decimals, remove decimal point for compactness
                formatted = str(round(f_val, 2)).replace('.', '')
                return f"{formatted}C"

        except (ValueError, TypeError):
            # Not numeric, e.g. 'multi'
            return str(value)
    
    def _get_condition_string(self, cell: Dict[str, Any], for_sheet: bool = False) -> str:
        """Helper to create a standardized condition string."""
        ch_raw = None
        dis_raw = None
        if len(cell.get("charge_protocol")) > 0 and len(cell.get("discharge_protocol")) > 0:
            ch_raw = cell.get('charge_protocol')[0].get('rate_in_C')
            dis_raw = cell.get('discharge_protocol')[0].get('rate_in_C')
        if not ch_raw or not dis_raw:
            ch_est, dis_est = self._estimate_crates_from_current(cell, cell.get("nominal_capacity_in_Ah"))
            ch_raw = np.round(ch_est, 2)
            dis_raw = np.round(dis_est, 2)

        ch_str = self._format_crate(ch_raw)
        dis_str = self._format_crate(dis_raw)

        # --- try to get median temperature normally ---
        temp_values = cell.get("cycle_data")[0].get("temperature_in_C")
        temp = np.nan

        if temp_values is not None and len(temp_values) > 0:
            temp = np.nanmedian(temp_values)

        # if temp is NaN, try to extract from cell_id
        if np.isnan(temp):
            cell_id = cell.get("cell_id", "")
            # look for patterns like "15C" or "15degC" (but not 2C from C-rate)
            match = re.search(r"(?<![-\d])(\d+)(?=degC|C(?=_|$|[A-Z]))", cell_id, flags=re.IGNORECASE)
            if match:
                temp = float(match.group(1))
            # handle special known cases
            elif "CALCE" or "Na-ion" or "RWTH" in cell_id:
                temp = 25.0
            elif "ISU-ILCC" or "HUST" or "Stanford" in cell_id:
                temp = 30.0
            elif "Tongji" in cell_id:
                match = re.search(r"(?<=CY)(\d{1,2})(?=(?:degC|-|_|$))", cell_id, re.IGNORECASE)
                temp = float(match.group(1))
            else:
                temp = np.nan  # fallback if unknown

        temp_str = str(int(round(temp))) if not np.isnan(temp) else "NaN"

        soc_interval = cell.get("SOC_interval")
        if soc_interval is not None and len(soc_interval) == 2:
            # Convert to % and round sensibly
            soc_low = int(round(soc_interval[0] * 100))
            soc_high = int(round(soc_interval[1] * 100))
            soc_str = f"SOC{soc_low}-{soc_high}"
        else:
            soc_str = "SOC_unknown"
        
        if for_sheet:
            # Format: 1C_05C_SOC0-100_25degC
            name = f"{ch_str}_{dis_str}_{soc_str}_{temp_str}degC"
            return name[:31]
        
        return f"Charge: {ch_str} | Discharge: {dis_str} | {soc_str} | {temp_str}°C"

    def _get_relative_capacity_data(self, cell: Dict[str, Any], interval: int = 100) -> List[Dict[str, Any]]:
        """Helper to extract capacity every N cycles."""
        results = []
        baseline_cap = None
        discharge_cap_throughput = 0
        charge_cap_throughput = 0
        
        soc_interval = cell.get("SOC_interval")
        if soc_interval is not None and len(soc_interval) == 2:
            # Convert to % and round sensibly
            soc_low = int(round(soc_interval[0] * 100))
            soc_high = int(round(soc_interval[1] * 100))
            dod = soc_high - soc_low 
        else:
            dod = 100
        
        cycles = cell.get('cycle_data', [])
        for cyc in cycles:
            discharge_caps = cyc.get('discharge_capacity_in_Ah', [])
            current_discharge_cap = np.max(discharge_caps) if discharge_caps else 0
            discharge_cap_throughput += current_discharge_cap

            charge_caps = cyc.get('charge_capacity_in_Ah', [])
            current_charge_cap = np.max(charge_caps) if charge_caps else 0
            charge_cap_throughput += current_charge_cap

            n = cyc.get('cycle_number')
            fce = n * dod / 100
            if n % interval == 0:                
                if n == 0 or baseline_cap is None:
                    baseline_cap = current_discharge_cap
                rel_cap = (current_discharge_cap / baseline_cap * 100) if baseline_cap > 0 else 0
                results.append({
                    'Cell_ID': cell['cell_id'],
                    'FCE': round(fce, 1),
                    'Discharge_Capacity_Throughput': round(discharge_cap_throughput, 2),
                    'Charge_Capacity_Throughput': round(charge_cap_throughput, 2),
                    'Rel_Cap': round(rel_cap, 2)
                })
        return results
    
    def _get_cell_characteristics(self):
        """
        Collects and validates key cell characteristics for export functions.

        Returns
        -------
        info : dict
            {
                "ref_cell": first cell used as reference,
                "characteristics_df": pd.DataFrame for Excel export,
                "consistent": bool,
                "dataset": str,
                "notes": list of inconsistencies,
                "now": timestamp string,
                "total_cells": int
            }
        """

        key_fields = [
            "form_factor", "anode_material", "cathode_material",
            "electrolyte_material", "nominal_capacity_in_Ah",
            "max_voltage_limit_in_V", "min_voltage_limit_in_V"
        ]
        char_values = {field: [] for field in key_fields}

        for cell in self.cell_list:
            for field in key_fields:
                char_values[field].append(cell.get(field))

        # Consistency check
        consistent = True
        notes = []
        for field, vals in char_values.items():
            unique_vals = {v for v in vals if v is not None}
            if len(unique_vals) > 1:
                consistent = False
                notes.append(f"Inconsistent '{field}': {unique_vals}")

        ref_cell = self.cell_list[0]
        total_cells = len(self.cell_list)
        now = datetime.now().strftime("%Y-%m-%d %H:%M")

        # Dataset folder path relative to root dataset
        dataset = "N/A"
        if os.path.commonpath([self.base_path, self.data_path]):
            rel_path = os.path.relpath(self.data_path, self.base_path)
            dataset = rel_path.replace("\\", "/")

        # Construct summary DataFrame (used for Excel export)
        df = pd.DataFrame({
            "Parameter": [
                "Dataset",
                "Form factor",
                "Anode material",
                "Cathode material",
                "Electrolyte",
                "Nominal capacity [Ah]",
                "Max cell voltage [V]",
                "Min cell voltage [V]",
                "Generated on",
                "Total cells analysed",
                "Consistency check"
            ],
            "Value": [
                dataset,
                ref_cell.get("form_factor", "N/A"),
                ref_cell.get("anode_material", "N/A"),
                ref_cell.get("cathode_material", "N/A"),
                ref_cell.get("electrolyte_material", "N/A"),
                ref_cell.get("nominal_capacity_in_Ah", "N/A"),
                ref_cell.get('max_voltage_limit_in_V', 'N/A'),
                ref_cell.get('min_voltage_limit_in_V', 'N/A'),
                now,
                total_cells,
                "PASS" if consistent else "⚠️ FAIL"
            ]
        })
        if not consistent:
            df.loc[len(df)] = ["Notes", "; ".join(notes)]

        return {
            "ref_cell": ref_cell,
            "characteristics_df": df,
            "consistent": consistent,
            "dataset": dataset,
            "notes": notes,
            "now": now,
            "total_cells": total_cells
        }
    

class DataCleaner:
    """
    Cleans capacity fade data stored in Excel sheets by removing outliers.
    Each Excel sheet corresponds to a testing condition (Cycle vs cell_id columns).
    """

    def __init__(self, input_excel: str, output_folder: str):
        self.input_excel = input_excel
        self.output_folder = output_folder
        os.makedirs(self.output_folder, exist_ok=True)

        # Read all sheets from Excel
        self.sheets = pd.read_excel(input_excel, sheet_name=None)
        print(f"Loaded {len(self.sheets)} sheets from {input_excel}")

        self.cell_characteristics = self.sheets.get("Cell_characteristics", None)

    def remove_outliers(self, window: int = 5, threshold: float = 1.3):
        """
        Removes capacity points that deviate more than `threshold`×std
        from a rolling mean of nearby points.

        Parameters
        ----------
        window : int
            Rolling window size for local trend comparison.
        threshold : float
            Number of standard deviations allowed before marking as outlier.
        """
        cleaned = {}
        self.stats = []  # Store number of removed points per sheet
        total_outliers = 0
        for sheet_name, df in tqdm(self.sheets.items(), desc="Removing outliers"):
            if sheet_name.lower() == "cell_characteristics":
                continue

            df_clean = df.copy()
            sheet_outliers = 0

            for col in df.columns:
                if col.lower() == "fce":
                    continue

                y = df[col].astype(float)
                if y.isna().all():
                    continue

                # Rolling mean + std
                rolling_mean = y.rolling(window=window, center=True).mean()
                rolling_std = y.rolling(window=window, center=True).std()

                # Outlier detection
                deviation = abs(y - rolling_mean)
                mask_outlier = deviation > (threshold * rolling_std)

                count_outliers = mask_outlier.sum()
                sheet_outliers += count_outliers
                total_outliers += count_outliers

                # Replace outliers with NaN
                df_clean.loc[mask_outlier, col] = np.nan

            cleaned[sheet_name] = df_clean
            self.stats.append({"Sheet": sheet_name, "Removed_Points": sheet_outliers})

        self.cleaned_sheets = cleaned
        self.total_outliers = total_outliers
        print(f"Outlier removal complete. Removed {total_outliers} outliers")
        return self
    
    def save_cleaned_data(self, output_excel: str):
        """
        Save cleaned data into a new Excel workbook.
        """
        with pd.ExcelWriter(output_excel, engine="xlsxwriter") as writer:
            # Cell characteristics
            if self.cell_characteristics is not None:
                self.cell_characteristics.to_excel(writer, sheet_name="Cell_characteristics", index=False)
                worksheet = writer.sheets["Cell_characteristics"]
                for i, col in enumerate(self.cell_characteristics.columns):
                    max_len = max(self.cell_characteristics[col].astype(str).map(len).max(), len(str(col)))
                    worksheet.set_column(i, i, max_len + 3)
            else:
                pd.DataFrame({"Info": ["No Cell_characteristics sheet found."]}).to_excel(
                    writer, sheet_name="Cell_characteristics", index=False
                )

            # Cleaning summary
            summary_df = pd.DataFrame(self.stats)
            summary_df.loc[len(summary_df)] = ["TOTAL", self.total_outliers]
            summary_df.to_excel(writer, sheet_name="Cleaning_summary", index=False)

            worksheet = writer.sheets["Cleaning_summary"]
            for i, col in enumerate(summary_df.columns):
                max_len = max(summary_df[col].astype(str).map(len).max(), len(str(col)))
                worksheet.set_column(i, i, max_len + 3)

            # Cleaned sheets
            for sheet, df in self.cleaned_sheets.items():
                df.to_excel(writer, sheet_name=sheet[:31], index=False)
                worksheet = writer.sheets[sheet[:31]]
                for i, col in enumerate(df.columns):
                    max_len = max(df[col].astype(str).map(len).max(), len(str(col)))
                    worksheet.set_column(i, i, max_len + 2)

        print(f"✅ Cleaned Excel saved: {output_excel}")
        self.output_excel = output_excel
        return self

    def plot_cleaned_pdf(self, output_pdf: str):
        """
        Creates multi-page PDF comparing original vs cleaned capacity fade data.
        """
        output_pdf = os.path.join(self.output_folder, output_pdf)
        with PdfPages(output_pdf) as pdf:
            # ---- Cover Page ----
            fig, ax = plt.subplots(figsize=(10, 6))
            ax.axis("off")

            title = "CLEANED CAPACITY FADE REPORT"
            ax.text(0.5, 0.95, title, fontsize=16, fontweight="bold", ha="center")
            ax.text(0.5, 0.91, f"Source file: {os.path.basename(self.input_excel)}",
                    fontsize=10, color="gray", ha="center")

            # Cell characteristics
            y = 0.8
            if self.cell_characteristics is not None:
                # Convert the entire DataFrame to a formatted string (like a table)
                cell_text = self.cell_characteristics.to_string(index=False)
                ax.text(0.05, y, cell_text, fontsize=10, fontfamily="monospace", va="top", ha="left")
            else:
                ax.text(0.05, y, "No cell_characteristics sheet found.", fontsize=11)

            # Total cleaned points
            ax.text(0.05, 0.15, f"TOTAL POINTS REMOVED: {self.total_outliers}",
                    fontsize=12, color="red", fontweight="bold")

            pdf.savefig(fig)
            plt.close(fig)

            # ---- Data Plots ----
            for sheet_name, df_clean in tqdm(self.cleaned_sheets.items(), desc="Plotting PDF"):
                df_orig = self.sheets[sheet_name]

                plt.figure(figsize=(10, 6))
                color_cycle = plt.cm.tab10(np.linspace(0, 1, len([c for c in df_clean.columns if c.lower() != "fce"])))

                for idx, col in enumerate([c for c in df_clean.columns if c.lower() != "fce"]):
                    color = color_cycle[idx % len(color_cycle)]
                    plt.plot(df_orig["FCE"], df_orig[col], color=color, marker="o", alpha=0.3)
                    plt.plot(df_clean["FCE"], df_clean[col], color=color, marker="o", label=col)

                plt.title(f"Capacity Fade (Cleaned): {sheet_name}", fontweight="bold")
                plt.xlabel("Full cycle equivalents (FCE)")
                plt.ylabel("Relative Capacity (%)")
                plt.ylim(70, 101)
                plt.grid(True, alpha=0.3)
                plt.legend(bbox_to_anchor=(1.05, 1), loc="upper left", fontsize=8)
                plt.tight_layout()
                pdf.savefig()
                plt.close()

        print(f"✅ Cleaned data PDF saved: {output_pdf}")


if __name__ == "__main__":
    ROUTE_FOLDER = r"C:\BatteryLife\dataset"
    DATASETS = [r"ISU_ILCC\batch1"]
    # DATASETS = [r"ISU_ILCC\batch1", r"MATR\batch2", r"MATR\batch3", r"MATR\batch4", "MICH", "MICH_EXP", "RWTH", "SDU",
    #             "SNL_LFP", "SNL_NCA", "SNL_NMC", "Stanford", r"Tongji\Tongji1", r"Tongji\Tongji2", r"Tongji\Tongji3", "UL_PUR", "XJTU"]
    for DATASET in DATASETS:
        DATASET_FOLDER = rf"C:\BatteryLife\dataset\{DATASET}"
        EXCEL_FILE = f"{DATASET}.xlsx".replace("\\", "_")
        PDF_FILE = f"{DATASET}.pdf".replace("\\", "_")
        handler = DataHandler(ROUTE_FOLDER, DATASET_FOLDER)
        handler.load_pickle_folder()
        handler.export_to_excel(EXCEL_FILE)
        handler.export_to_pdf(PDF_FILE)

        cleaner = DataCleaner(
            input_excel=os.path.join(DATASET_FOLDER, EXCEL_FILE),
            output_folder=DATASET_FOLDER
            )

        cleaner.remove_outliers()
        cleaner.save_cleaned_data(os.path.join(DATASET_FOLDER, f"{DATASET}_cleaned.xlsx".replace("\\", "_")))
        cleaner.plot_cleaned_pdf(os.path.join(DATASET_FOLDER, f"{DATASET}_cleaned.pdf".replace("\\", "_")))
