import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from matplotlib.colors import LinearSegmentedColormap
from scipy.ndimage import zoom

from DashvoltAnalytics.common.battery_data_handling import ProfileConverter


def plot_BMS_state_pcts(df: pd.DataFrame):
    """Creates a plot of the time percentage that the BMS spends in each state"""
    # Aggregate hours per week and mode
    weekly = df.groupby(["week", "mode"], observed=True)["duration_h"].sum().reset_index()

    # Pivot to wide table for stacked bars
    weekly_pivot = weekly.pivot(index="week", columns="mode", values="duration_h").fillna(0)
    weekly_pivot = weekly_pivot.sort_index()

    # Convert weekly totals to percentages
    weekly_pct = weekly_pivot.div(weekly_pivot.sum(axis=1), axis=0) * 100

    # Year summary (hours & percentage per mode)
    yearly = df.groupby("mode", observed=True)["duration_h"].sum().reset_index()
    total_hours = yearly["duration_h"].sum()
    yearly["pct_time"] = yearly["duration_h"] / total_hours * 100
    yearly = yearly.sort_values("duration_h", ascending=False)

    # Build summary text
    summary_lines = [f"Total hours: {total_hours:4.1f}h\n"]
    for _, row in yearly.iterrows():
        summary_lines.append(f"{row['mode']:<11s}: {row['duration_h']:4.1f}h ({row['pct_time']:2.1f}%)")
    summary_text = "\n".join(summary_lines)

    # Plot stacked bar chart
    fig, ax = plt.subplots(figsize=(14, 6))
    weekly_pct.plot(kind="bar", stacked=True, width=0.9, ax=ax, colormap="tab20")

    ax.set_xlabel("Week of year")
    ax.set_ylabel("Percentage of time in state (%)")
    ax.set_title("Weekly percentage of time spent in each BMS state")
    legend = ax.legend(title="BMS state",
                    bbox_to_anchor=(1, 1),
                    loc="upper right",
                    frameon=True,
                    facecolor="white",
                    framealpha=0.9,
                    edgecolor="gray")

    # Render the figure to compute legend position
    fig.canvas.draw()

    # Get legend bounding box in axes coordinates
    legend_bbox = legend.get_window_extent().transformed(ax.transAxes.inverted())

    # Compute text box position directly below legend, same right edge
    legend_right_x = legend_bbox.x1
    legend_bottom_y = legend_bbox.y0

    # Add text box just below the legend 
    props = dict(boxstyle="round,pad=0.4",
                facecolor="white",
                alpha=0.9,
                edgecolor="gray")

    ax.text(
        legend_right_x, legend_bottom_y - 0.02,  # x ~ right edge, y just below legend
        summary_text,
        transform=ax.transAxes,
        fontsize=10,
        verticalalignment="top",
        horizontalalignment="right",
        multialignment="left",
        bbox=props,
        family="monospace"
    )

    plt.tight_layout()
    plt.show()

def heatmap_time_vs_SOC_and_T(df: pd.DataFrame, mode="All"):
    """
    Heatmap of total time exposure vs SOC and temperature.
    
    Parameters:
    -----------
    df : pd.DataFrame
        Input data containing 'soc', 'temperature_M1', 'duration_h', and 'mode'.
    mode : str
        The operational mode to filter by (e.g., 'Storage', 'Charge', 'Discharge').
        Use 'all' to see the total cumulative time.
    """
    
    # 1. Filter data based on mode
    if mode.lower() == "all":
        plot_df = df.copy()
        title_suffix = "All Modes"
    else:
        # Case-insensitive filtering to be safe
        plot_df = df[df["mode"].str.lower() == mode.lower()].copy()
        title_suffix = mode.capitalize()

    # 2. Safety check: avoid crashing if the mode has no data
    if plot_df.empty:
        print(f"Warning: No data found for mode '{mode}'.")
        return

    # 3. Compute Histogram (Weighted by duration_h)
    heatmap_data, xedges, yedges = np.histogram2d(
        plot_df["soc"] * 100,
        plot_df["temperature_M1"],
        bins=[10, 10],
        weights=plot_df["duration_h"],
        density=False
    )

    # 4. Plotting
    plt.figure(figsize=(7, 6))
    sns.heatmap(
        heatmap_data.T,
        cmap="Reds",
        cbar_kws={'label': 'Total Time (h)'},
        xticklabels=np.round(xedges[:-1], 0).astype(int),
        yticklabels=np.round(yedges[:-1], 0).astype(int),
        rasterized=True
    )
    
    plt.gca().invert_yaxis() # High temperatures at the top
    
    plt.xlabel("SOC [%]")
    plt.ylabel("Temperature [°C]")
    plt.title(f"Time exposure heatmap: {title_suffix}")
    plt.tight_layout()
    plt.show()

def heatmap_cycles_vs_Crate_and_T(df: pd.DataFrame):
    """
    Heatmap of FCE vs C-rate and temperature with synchronized global axes.
    """
    # 1. Prepare absolute C-rate and FCE weights
    df["C_rate_abs"] = df["C_rate"].abs()
    df["fce_weight"] = np.abs(df["d_soc"]) / 2

    # 2. Determine Global Limits for synchronization
    # We use the absolute max C-rate and global temp range
    c_max = df["C_rate_abs"].max()
    T_min = df["temperature_M1"].min()
    T_max = df["temperature_M1"].max()

    # Create fixed 10x10 bin edges based on global min/max
    c_bins = np.linspace(0, c_max, 11)
    T_bins = np.linspace(T_min, T_max, 11)

    # 3. Split data
    charge_df = df[df["mode"] == "Charge"].copy()
    discharge_df = df[df["mode"] == "Discharge"].copy()

    # 4. Visualization
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 6), sharey=True)

    # --- CHARGE HEATMAP ---
    h_charge, x_e, y_e = np.histogram2d(
        charge_df["C_rate_abs"], charge_df["temperature_M1"],
        bins=[c_bins, T_bins], weights=charge_df["fce_weight"]
    )
    sns.heatmap(h_charge.T, ax=ax1, cmap="Blues", cbar_kws={'label': 'Total FCE'},
                xticklabels=np.round(x_e[:-1], 2), yticklabels=np.round(y_e[:-1], 0))
    ax1.invert_yaxis()
    ax1.set_title("Cycling intensity heatmap: Charge")
    ax1.set_xlabel("C-Rate [-]")
    ax1.set_ylabel("Temperature [°C]")

    # --- DISCHARGE HEATMAP ---
    h_discharge, x_e, y_e = np.histogram2d(
        discharge_df["C_rate_abs"], discharge_df["temperature_M1"],
        bins=[c_bins, T_bins], weights=discharge_df["fce_weight"]
    )
    sns.heatmap(h_discharge.T, ax=ax2, cmap="Oranges", cbar_kws={'label': 'Total FCE'},
                xticklabels=np.round(x_e[:-1], 2), yticklabels=np.round(y_e[:-1], 0))
    ax2.invert_yaxis()
    ax2.set_title("Cycling intensity heatmap: Discharge")
    ax2.set_xlabel("C-Rate [-]")
    ax2.set_ylabel("Temperature [°C]")

    plt.tight_layout()
    plt.show()

def plot_soc_transitions(df: pd.DataFrame, mode_label: str):
    """
    Histogram of SOC at the start and end of a specific activity.
    
    Parameters:
    -----------
    df : pd.DataFrame
        Input data with 'soc' and 'mode'
    mode_label : str
        'Charge' or 'Discharge'
    """
    
    # 1. Identify transitions
    # We use shift to compare current row to previous/next rows
    df["prev_mode"] = df["mode"].shift(1)
    df["next_mode"] = df["mode"].shift(-1)
    
    # Start: Current is Mode, Previous was NOT Mode
    starts = df[(df["mode"]== mode_label) & (df["prev_mode"] != mode_label)]
    
    # End: Current is Mode, Next is NOT Mode 
    ends = df[(df["mode"] == mode_label) & (df["next_mode"] != mode_label)]
    
    # 2. Plotting
    plt.figure(figsize=(10, 5))
    
    # Use stat="count" or "percent" for easier interpretation
    sns.histplot(starts["soc"] * 100, bins=10, color='skyblue', 
                 label=f'Start of {mode_label}', alpha=0.7, kde=True)
    sns.histplot(ends["soc"] * 100, bins=10, color='orange', 
                 label=f'End of {mode_label}', alpha=0.7, kde=True)
    
    plt.xlabel("SOC [%]")
    plt.ylabel("Count")
    plt.title(f"SOC distribution: {mode_label} transitions")
    plt.legend()
    plt.grid(axis='y', alpha=0.3)
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":
    PROFILE_PATH = r"C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\Synthetic data\Yearly profiles"
    NOMINAL_CAPACITY = 116*4
    BATTERIES = [
        "battery_01", "battery_02", "battery_03", "battery_04",
        "battery_05", "battery_06", "battery_07", "battery_08"
    ]

    for batt in BATTERIES:
        battery_profile_path = os.path.join(PROFILE_PATH, f"{batt}.csv")
        profile_converter = ProfileConverter(batt, NOMINAL_CAPACITY)
        profile_df = profile_converter.csv_to_df(battery_profile_path)
        
        plot_BMS_state_pcts(profile_df)
        heatmap_time_vs_SOC_and_T(profile_df, model="All")
        heatmap_time_vs_SOC_and_T(profile_df, mode="Storage")
        heatmap_cycles_vs_Crate_and_T(profile_df)
        plot_soc_transitions(profile_df, "Charge")
        plot_soc_transitions(profile_df, "Discharge")

        print('done')
