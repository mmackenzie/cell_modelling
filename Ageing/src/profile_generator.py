import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt

class ProfileGenerator:
    def __init__(self):
        # Define bin edges as class attributes
        self.soc_bins = np.arange(0, 110, 10)
        self.temp_bins = np.arange(-10, 75, 5)
        self.c_rate_bins = np.arange(-1, 1.5, 0.5)

    def profile_to_histograms(self, filename, q_nom):
        """
        Converts customer usage profile into degradation histograms.
        """
        # Load data
        df = pd.read_csv(filename)
        
        # Map columns
        time = df['time'].values
        current = df['batt_current'].values
        # Clamp SOC between 0 and 100
        soc = np.clip(df['soc'].values * 100, 0, 100)
        temp = df['temperature_M1'].values
        c_rate = current / q_nom
        
        # Calculations
        name = os.path.splitext(os.path.basename(filename))[0]
        print(f"Customer: {name}")
        print(f"Average yearly temperature: {np.mean(temp):.1f}°C")
        
        # Time step (dt)
        dt = np.concatenate([[0], np.diff(time)])
        
        # Indices for different states
        idle_idx = np.abs(current) < 0.1
        discharge_idx = current < -0.1
        charge_idx = current > 0.1
        cycling_idx = discharge_idx | charge_idx
        
        capacity_throughput = np.abs(current) * dt / 3600
        
        # ---------------- Calendar histogram ----------------
        cal_hist, _, _ = np.histogram2d(
            soc[idle_idx], 
            temp[idle_idx], 
            bins=[self.soc_bins, self.temp_bins],
            weights=dt[idle_idx]
        )
        cal_hist = cal_hist / (3600 * 24) # sec -> days
        
        # ---------------- Cycling histogram ----------------
        cyc_hist, _, _ = np.histogram2d(
            c_rate[cycling_idx], 
            temp[cycling_idx], 
            bins=[self.c_rate_bins, self.temp_bins],
            weights=capacity_throughput[cycling_idx]
        )
        cyc_hist = cyc_hist / q_nom / 2 # Ah throughput -> full cycles
        
        # ---------------- Time accounting ----------------
        time_summary = {
            'total': np.sum(dt) / (3600 * 24),
            'idle': np.sum(dt[idle_idx]) / (3600 * 24),
            'charge': np.sum(dt[current > 0.1]) / (3600 * 24),
            'discharge': np.sum(dt[current < -0.1]) / (3600 * 24)
        }
        
        # Internal Plotting Call
        self._plot_results(cal_hist, cyc_hist)
        
        return self.soc_bins, self.temp_bins, cal_hist, cyc_hist, time_summary

    def _plot_results(self, cal_hist, cyc_hist):
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))
        
        im1 = ax1.imshow(cal_hist, aspect='auto', origin='lower')
        ax1.set_title('Calendar Histogram (Days)')
        plt.colorbar(im1, ax=ax1)
        
        im2 = ax2.imshow(cyc_hist, aspect='auto', origin='lower')
        ax2.set_title('Cycling Histogram (Eq. Cycles)')
        plt.colorbar(im2, ax=ax2)
        
        plt.tight_layout()
        # plt.show()

# Example Usage:
# pg = ProfileGenerator()
# soc_b, temp_b, cal, cyc, summary = pg.profile_to_histograms('data.csv', Q_nom=100)