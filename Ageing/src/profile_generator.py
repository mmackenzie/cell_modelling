import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt

class ProfileGenerator:
    def __init__(self):
        # Define bin edges as class attributes
        self.soc_bins = np.array([0, 10, 30, 50, 80, 90, 95, 100])
        self.temp_bins = np.arange(-10, 75, 5)
        self.dod_bins = np.array([0, 10, 30, 50, 80, 90, 95, 100])
        self.c_bins = np.array([0, 0.1, 0.5, 1.0, 2.0, 5.0])

    def profile_to_summaries(self, filename, q_nom):
        """
        Converts customer usage profile into summary tables using BMS state flags.
        Returns: cal_hist_days (np.array), cyc_summary (pd.DataFrame), time_summary (dict)
        """
        df = pd.read_csv(filename)
        
        # Standardize columns
        time = df['time'].values
        current = df['batt_current'].values  # (+) Charge, (-) Discharge
        soc = np.clip(df['soc'].values * 100, 0, 100)
        temp = df['temperature_M1'].values
        dt = np.concatenate([[0], np.diff(time)])
        
        # 0. Define State Masks based on BMS Mode
        is_charge = df['mode'] == 'Charge'
        is_discharge = df['mode'] == 'Discharge'
        is_cycling = is_charge | is_discharge
        is_idle = ~is_cycling

        # ---------------- 1. CALENDAR SUMMARY (DataFrame Format) ----------------
        # Create a temporary DF for idle periods to use the same grouping logic
        idle_df = pd.DataFrame({
            'T': temp[is_idle],
            'SOC': soc[is_idle],
            'dt': dt[is_idle]
        })

        # Binning
        idle_df['T_bin'] = pd.cut(idle_df['T'], bins=self.temp_bins, include_lowest=True).apply(lambda x: x.right)
        idle_df['SOC_bin'] = pd.cut(idle_df['SOC'], bins=self.soc_bins, include_lowest=True).apply(lambda x: x.right)

        # Group and convert seconds to days
        cal_summary = idle_df.groupby(['T_bin', 'SOC_bin'], observed=True)['dt'].sum().reset_index()
        cal_summary['days'] = cal_summary['dt'] / (3600 * 24)
        cal_summary = cal_summary[cal_summary['days'] > 0].drop(columns=['dt'])

        # ---------------- 2. CYCLING SUMMARY (Event-based logic) ----------------
        # Group continuous cycling blocks (sequences of Charge/Discharge)
        df['is_cycling'] = is_cycling
        df['event_id'] = (df['is_cycling'] != df['is_cycling'].shift()).cumsum()
        
        cycle_events = []
        # Process only groups where the battery was active
        for eid, group in df[df['is_cycling']].groupby('event_id'):
            if len(group) < 2: continue
            
            # Physical metrics for this specific event
            s_min = max(group['soc'].min() * 100, 0)
            s_max = min(group['soc'].max() * 100, 100)
            dod = round(s_max - s_min, 0)
            soc_avg = round((s_max + s_min) / 2, 0)
            T_avg = round(group['temperature_M1'].mean(), 0)
            
            # Calculate C-rates separately within the event
            ch_mask = group['mode'] == 'Charge'
            dis_mask = group['mode'] == 'Discharge'
            
            c_ch = round(group[ch_mask]['batt_current'].mean() / q_nom if any(ch_mask) else 0, 2)
            c_dis = round(abs(group[dis_mask]['batt_current'].mean() / q_nom) if any(dis_mask) else 0, 2)
            
            # Throughput (FCE)
            ah_throughput = (group['batt_current'].abs() * dt[group.index]).sum() / 3600
            fce = round(ah_throughput / (2 * q_nom), 2)
            
            cycle_events.append([T_avg, soc_avg, dod, c_ch, c_dis, fce])

        # Convert events to DataFrame
        events_df = pd.DataFrame(cycle_events, columns=['T', 'SOC_avg', 'DOD', 'C_ch', 'C_dis', 'FCE'])

        # 3. COMPRESSING THE CYCLING DATA (Upper-edge binning)
        # Using .right ensures that a 96% DOD cycle is binned as "100" if 100 is the upper edge
        events_df['T_bin'] = pd.cut(events_df['T'], bins=self.temp_bins, include_lowest=True).apply(lambda x: x.right)
        events_df['SOC_bin'] = pd.cut(events_df['SOC_avg'], bins=self.soc_bins, include_lowest=True).apply(lambda x: x.right)
        events_df['DOD_bin'] = pd.cut(events_df['DOD'], bins=self.dod_bins, include_lowest=True).apply(lambda x: x.right)
        
        # Group by binned attributes
        cyc_summary = events_df.groupby(['T_bin', 'SOC_bin', 'DOD_bin', 'C_ch', 'C_dis'],
                                        observed=True)['FCE'].sum().reset_index()
        cyc_summary = cyc_summary[cyc_summary['FCE'] > 0]

        # 4. TIME ACCOUNTING SUMMARY
        sec_per_day = 3600 * 24
        time_summary = {
            'total_days': np.sum(dt) / sec_per_day,
            'idle_days': np.sum(dt[is_idle]) / sec_per_day,
            'charge_days': np.sum(dt[is_charge]) / sec_per_day,
            'discharge_days': np.sum(dt[is_discharge]) / sec_per_day
        }

        return cal_summary, cyc_summary, time_summary

    def plot_summary(self, cal_hist, cyc_summary):
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
        
        # Calendar plot remains easy
        im1 = ax1.imshow(cal_hist, aspect='auto', origin='lower', extent=[self.temp_bins[0], self.temp_bins[-1], 0, 100])
        ax1.set_title('Calendar Exposure (Days)')
        ax1.set_ylabel('SOC (%)')
        ax1.set_xlabel('Temp (°C)')
        
        # For cycling, since it's multi-D, we plot DOD vs SOC_avg weighted by FCE
        sc = ax2.scatter(cyc_summary['SOC_bin'], cyc_summary['DOD_bin'], 
                         s=cyc_summary['FCE']*100, c=cyc_summary['T_bin'], cmap='plasma', alpha=0.6)
        ax2.set_title('Cycling Distribution (Bubble Size = FCE)')
        ax2.set_xlabel('Avg SOC (%)')
        ax2.set_ylabel('DOD (%)')
        plt.colorbar(sc, ax=ax2, label='Temp (°C)')
        
        plt.tight_layout()
    
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

if __name__ == "__main__":
    # Example usage
    PROFILE_PATH = r"C:\Users\mmackenzie\OneDrive - ZELEROS GLOBAL S.L\Documents\Synthetic data\Yearly profiles"
    NOMINAL_CAPACITY = 116*4
    BATTERIES = [
        "battery_01", "battery_02", "battery_03", "battery_04",
        "battery_05", "battery_06", "battery_07", "battery_08"
    ]

    for batt in BATTERIES:
        battery_profile_path = os.path.join(PROFILE_PATH, f"{batt}.csv")
        generator = ProfileGenerator()
        cal_summary, cyc_summary, time_summary = generator.profile_to_summaries(battery_profile_path, NOMINAL_CAPACITY)
