import os
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D  # noqa: F401 (needed for 3D)
import matplotlib.colors as mcolors
from typing import Optional, Sequence, Callable, Dict


def _ensure_array(a):
    return np.asarray(a) if a is not None else None


# ---------------------------------------------------------------------
# Basic histogram plots
# ---------------------------------------------------------------------
def plot_temperature_histograms(storage_hist: np.ndarray,
                                cycling_hist: np.ndarray,
                                temperature_bins: Sequence[float],
                                figsize=(6, 8),
                                savepath: Optional[str] = None):
    """
    Two stacked bar plots: storage days per temperature and cycles per temperature.

    Parameters
    ----------
    storage_hist : 2D array (soc x temp) or 1D array (temp)
    cycling_hist : 2D array (crate x temp) or 1D array (temp)
    temperature_bins : sequence
        temperature bin centers (or edges) used as x ticks.
    """
    # aggregate if 2D
    storage = np.sum(storage_hist, axis=0) if storage_hist.ndim == 2 else np.asarray(storage_hist)
    cycling = np.sum(cycling_hist, axis=0) if cycling_hist.ndim == 2 else np.asarray(cycling_hist)

    fig, axes = plt.subplots(2, 1, figsize=figsize, constrained_layout=True)

    axes[0].bar(temperature_bins, storage, color=(0.2, 0.6, 0.8))
    axes[0].set_xlabel("Temperature [°C]")
    axes[0].set_ylabel("Days in storage")
    axes[0].set_title("Storage histogram vs temperature")
    axes[0].grid(True, linestyle="--", alpha=0.5)

    axes[1].bar(temperature_bins, cycling, color=(0.8, 0.3, 0.2))
    axes[1].set_xlabel("Temperature [°C]")
    axes[1].set_ylabel("Cycles")
    axes[1].set_title("Cycling histogram vs temperature")
    axes[1].grid(True, linestyle="--", alpha=0.5)

    if savepath:
        plt.savefig(savepath, dpi=300)
    # plt.show()


# ---------------------------------------------------------------------
# 3D histograms
# ---------------------------------------------------------------------
def plot_3d_histograms(storage_hist: np.ndarray,
                       cycling_hist: np.ndarray,
                       temperature_bins: Sequence[float],
                       soc_bins: Sequence[float],
                       c_rate_bins: Sequence[float],
                       figsize=(8, 10),
                       savepath: Optional[str] = None):
    """
    Two 3D bar plots to visualize storage_hist (SOC x Temp) and cycling_hist (Crate x Temp).
    storage_hist shape: (n_soc_bins, n_temp_bins)
    cycling_hist shape: (n_cr_bins, n_temp_bins)
    """
    storage_hist = np.asarray(storage_hist)
    cycling_hist = np.asarray(cycling_hist)

    fig = plt.figure(figsize=figsize, constrained_layout=True)

    # Storage: z = days, x=temp, y=SOC
    ax1 = fig.add_subplot(2, 1, 1, projection="3d")
    nx = storage_hist.shape[1]
    ny = storage_hist.shape[0]
    _x = np.arange(nx)
    _y = np.arange(ny)
    _xx, _yy = np.meshgrid(_x, _y)
    x = _xx.ravel()
    y = _yy.ravel()
    z = np.zeros_like(x, dtype=float)
    dx = dy = 0.8
    dz = storage_hist.ravel()
    cmap = plt.get_cmap("turbo")
    norm = mcolors.Normalize(vmin=np.nanmin(dz), vmax=np.nanmax(dz))
    colors = cmap(norm(dz))
    ax1.bar3d(x, y, z, dx, dy, dz, shade=True, color=colors)
    ax1.set_xticks(np.arange(len(temperature_bins)))
    ax1.set_xticklabels([str(int(t)) for t in temperature_bins])
    ax1.set_yticks(np.arange(len(soc_bins)))
    ax1.set_yticklabels([str(int(s)) for s in soc_bins])
    ax1.set_xlabel("Temperature [°C]")
    ax1.set_ylabel("SOC [%]")
    ax1.set_zlabel("Days in storage")
    ax1.set_title("Storage histogram (temperature vs SOC)")

    # Cycling: z = cycles, x=temp, y=c-rate
    ax2 = fig.add_subplot(2, 1, 2, projection="3d")
    nx = cycling_hist.shape[1]
    ny = cycling_hist.shape[0]
    _x = np.arange(nx)
    _y = np.arange(ny)
    _xx, _yy = np.meshgrid(_x, _y)
    x = _xx.ravel()
    y = _yy.ravel()
    z = np.zeros_like(x, dtype=float)
    dx = dy = 0.8
    dz = cycling_hist.ravel()
    norm = mcolors.Normalize(vmin=np.nanmin(dz), vmax=np.nanmax(dz))
    colors = cmap(norm(dz))
    ax2.bar3d(x, y, z, dx, dy, dz, shade=True, color=colors)
    ax2.set_xticks(np.arange(len(temperature_bins)))
    ax2.set_xticklabels([str(int(t)) for t in temperature_bins])
    ax2.set_yticks(np.arange(len(c_rate_bins)))
    ax2.set_yticklabels([str(cr) for cr in c_rate_bins])
    ax2.set_ylabel("C-rate [-]")
    ax2.set_xlabel("Temperature [°C]")
    ax2.set_zlabel("Cycles")
    ax2.set_title("Cycling histogram (temperature vs C-rate)")

    if savepath:
        plt.savefig(savepath, dpi=300)
    # plt.show()


# ---------------------------------------------------------------------
# Fit parity plot
# ---------------------------------------------------------------------
def plot_fit(Q_meas: Sequence[float],
             Q_pred: Sequence[float],
             title_str: str = "Fit",
             rmse: Optional[float] = None,
             R2: Optional[float] = None,
             figsize=(6, 6),
             savepath: Optional[str] = None):
    """
    Scatter measured vs predicted with unity line and metrics in title.
    """
    Q_meas = np.asarray(Q_meas)
    Q_pred = np.asarray(Q_pred)

    plt.figure(figsize=figsize)
    plt.scatter(Q_meas, Q_pred, s=20, alpha=0.6)
    mn = min(np.nanmin(Q_meas), np.nanmin(Q_pred))
    mx = max(np.nanmax(Q_meas), np.nanmax(Q_pred))
    plt.plot([mn, mx], [mn, mx], 'k--', linewidth=1.5)
    title = title_str
    if rmse is not None and R2 is not None:
        title = f"{title}  |  RMSE={rmse:.2f}  |  R²={R2:.3f}"
    plt.xlabel("Measured relative capacity (%)")
    plt.ylabel("Predicted relative capacity (%)")
    plt.title(title)
    plt.grid(True, linestyle="--", alpha=0.5)

    # axis limits similar to MATLAB
    if "Calendar" in title_str:
        plt.xlim([90, 100]); plt.ylim([90, 100])
    else:
        plt.xlim([70, 100]); plt.ylim([70, 100])

    if savepath:
        plt.savefig(savepath, dpi=300)
    # plt.show()


# ---------------------------------------------------------------------
# Extrapolation + measured overlay (calendar)
# ---------------------------------------------------------------------
def plot_calendar_extrapolation(storage_data: Dict,
                                p_cal: Sequence[float],
                                physics_func: Callable,
                                t_extrap_days: Optional[np.ndarray] = None,
                                figsize=(16, 10),
                                savepath: Optional[str] = None):
    """
    Overlay measured storage data with extrapolated model lines.
    storage_data: dict with each entry containing keys 'day', 'relative_capacity', 'temperature', 'soc'
    physics_func: expects signature physics_func(p_cal, t_days, T_degC, SOC)
    """
    if t_extrap_days is None:
        t_extrap_days = np.arange(0, 3 * 365 + 1)

    plt.figure(figsize=figsize)
    default_colours = plt.rcParams["axes.prop_cycle"].by_key()["color"]

    i = 0
    for key, d in storage_data.items():
        cell_n = 1
        for cell_id, relative_capacities in d["relative_capacity"].items():
            days = np.asarray(d["day"][:len(relative_capacities)])
            rel = np.asarray(relative_capacities)
            c = default_colours[i % len(default_colours)]
            plt.plot(days / 365.0, rel, marker='*', linestyle='None', color=c, label=f"{key}_{cell_n} - measured", markersize=6)
            cell_n += 1
        T = float(d["temperature"])
        SOC = float(d.get("soc", np.nan))
        Qloss = physics_func(p_cal, t_extrap_days, T, SOC)
        Qpred = 100.0 - Qloss
        plt.plot(t_extrap_days / 365.0, Qpred, linestyle='--', color=c, linewidth=1.3, label=f"{key} - estimated")
        i += 1

    plt.xlabel("Years")
    plt.ylabel("Relative capacity (%)")
    plt.title("Measured vs extrapolated storage data")
    plt.ylim([70, 100])
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize="small")
    plt.tight_layout()
    if savepath:
        plt.savefig(savepath, dpi=300)
    # plt.show()


# ---------------------------------------------------------------------
# Extrapolation + measured overlay (cycling)
# ---------------------------------------------------------------------
def plot_cycling_extrapolation(cycling_data: Dict,
                               p_cyc: Sequence[float],
                               model_type: str,
                               physics_func: Callable,
                               N_extrap: Optional[np.ndarray] = None,
                               figsize=(16, 10),
                               savepath: Optional[str] = None):
    """
    Overlay cycling measured data with model predictions.
    physics_func: expects signature physics_func(p_cyc, N, T)
    """
    if N_extrap is None:
        N_extrap = np.arange(0, 2000 + 1, 100)

    plt.figure(figsize=figsize)
    default_colours = plt.rcParams["axes.prop_cycle"].by_key()["color"]

    i = 0
    for key, d in cycling_data.items():
        cell_n = 1
        for cell_id, relative_capacities in d["relative_capacity"].items():
            cycles = np.asarray(d["fce"][:len(relative_capacities)])
            rel = np.asarray(relative_capacities)
            c = default_colours[i % len(default_colours)]
            plt.plot(cycles, rel, marker='*', linestyle='None', color=c, label=f"{key}_{cell_n} - measured", markersize=6)
            cell_n += 1
        T = float(d["temperature"])
        C_charge = float(d["charge_crate"])
        C_discharge = float(d["discharge_crate"])
        SOC_lower = float(d["soc_lower"])
        SOC_upper = float(d["soc_upper"])
        if model_type == "simple":
            Qloss = physics_func(p_cyc, N_extrap, T)
        else:
            Qloss = physics_func(p_cyc, N_extrap, T, C_charge, C_discharge, SOC_lower, SOC_upper)
        Qpred = 100.0 - Qloss
        plt.plot(N_extrap, Qpred, linestyle='--', color=c, linewidth=1.5, label=f"{key} - estimated")
        i += 1

    plt.xlabel("Full cycle equivalents (FCE)")
    plt.ylabel("Relative capacity (%)")
    plt.title("Measured vs extrapolated cycling data")
    plt.ylim([70, 100])
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left', fontsize="small")
    plt.tight_layout()
    if savepath:
        plt.savefig(savepath, dpi=300)
    # plt.show()


# ---------------------------------------------------------------------
# SOC dependency and temperature dependency plots
# ---------------------------------------------------------------------
def plot_calendar_soc_dependency(p_cal: Sequence[float],
                                 physics_func: Callable,
                                 soc_ref: float = 100.0,
                                 figsize=(8, 5),
                                 savepath: Optional[str] = None):
    """
    Plot SOC multiplier (exp(k_soc*(SOC - SOC_ref)) ) and example SOH curves at different SOC levels.
    physics_func must accept (p_cal, t_days, T_degC, SOC)
    """
    SOC_range = np.arange(0, 101, 10)
    k_soc = p_cal[2] if len(p_cal) > 2 else 0.0
    soc_multiplier = np.exp(k_soc * (SOC_range - soc_ref))

    plt.figure(figsize=(6, 3))
    plt.plot(SOC_range, soc_multiplier, linewidth=2)
    plt.xlabel("SOC (%)")
    plt.ylabel("SOC multiplier")
    plt.title("Effect of SOC on calendar ageing")
    plt.grid(True, linestyle="--", alpha=0.5)
    if savepath:
        plt.savefig(savepath, dpi=300)
    # plt.show()

    # example SOH curves
    t_extrap = np.arange(0, 5 * 365 + 1, 30)  # up to 5 years (monthly)
    SOC_levels = [30, 50, 70, 90, 100]
    T_plot = 25

    plt.figure(figsize=figsize)
    default_colours = plt.rcParams["axes.prop_cycle"].by_key()["color"]
    for i, SOC_val in enumerate(SOC_levels):
        Qloss = physics_func(p_cal, t_extrap, T_plot, SOC_val)
        Qpred = 100.0 - Qloss
        plt.plot(t_extrap / 365.0, Qpred, color=default_colours[i % len(default_colours)], linewidth=1.5, label=f"SOC = {SOC_val}%")

    plt.xlabel("Years")
    plt.ylabel("SOH (%)")
    plt.ylim([80, 100])
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(loc="best")
    if savepath:
        plt.savefig(savepath, dpi=300)
    # plt.show()


def plot_calendar_T_dependency(p_cal: Sequence[float],
                              physics_func: Callable,
                              soc_ref: float = 100.0,
                              figsize=(8, 5),
                              savepath: Optional[str] = None):
    """
    Plot SOH vs time at different temperatures.
    physics_func must accept (p_cal, t_days, T_degC, SOC)
    """
    t_extrap = np.arange(0, 5 * 365 + 1, 30)  # up to 5 years monthly
    SOC_plot = soc_ref
    T_levels = [10, 20, 30, 40, 50]

    plt.figure(figsize=figsize)
    default_colours = plt.rcParams["axes.prop_cycle"].by_key()["color"]
    for i, T_val in enumerate(T_levels):
        Qloss = physics_func(p_cal, t_extrap, T_val, SOC_plot)
        Qpred = 100.0 - Qloss
        plt.plot(t_extrap / 365.0, Qpred, color=default_colours[i % len(default_colours)], linewidth=1.5, label=f"T = {T_val}°C")

    plt.xlabel("Years")
    plt.ylabel("SOH (%)")
    plt.ylim([70, 100])
    plt.grid(True, linestyle="--", alpha=0.5)
    plt.legend(loc="best")
    if savepath:
        plt.savefig(savepath, dpi=300)
    # plt.show()


# ---------------------------------------------------------------------
# Simple SOH trajectory plot
# ---------------------------------------------------------------------
def plot_SOH_trajectory(time_days: Sequence[float],
                        SOH: Sequence[float],
                        figsize=(8, 4),
                        savepath: Optional[str] = None):
    plt.figure(figsize=figsize)
    plt.plot(np.asarray(time_days) / 365.0, np.asarray(SOH), linewidth=2)
    plt.xlabel("Time (years)")
    plt.ylabel("State of Health (%)")
    plt.ylim([70, 100])
    plt.title("Predicted SOH trajectory")
    plt.grid(True, linestyle="--", alpha=0.5)
    if savepath:
        plt.savefig(savepath, dpi=300)
    # plt.show()
