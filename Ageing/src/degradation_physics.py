from math import exp

import numpy as np

class DegradationPhysics:
    """
    Empirical degradation equations for calendar and cycling ageing.
    """

    def __init__(self, R: float = 8.314, soc_ref: float = 100.0):
        self.R = R
        self.soc_ref = soc_ref

    # ---- Calendar ageing ----
    def extrapolate_calendar(self, p, t_days, T_degC, SOC, alpha=0.6):
        """
        Cumulative calendar Q_loss [%] at time t_days, temperature, and SOC.
        """
        k_cal, Ea, k_soc = p
        T_K = T_degC + 273.15
        return k_cal * np.exp(-Ea / (self.R * T_K)) * np.exp(k_soc * (SOC - self.soc_ref)) * (t_days ** alpha)

    def invert_calendar(self, p, Q_loss, T_degC, SOC, alpha=0.6):
        """
        Solve for time given cumulative Q_loss (inverse of calendar model).
        """
        k_cal, Ea, k_soc = p
        T_K = T_degC + 273.15
        return (Q_loss / (k_cal * np.exp(-Ea / (self.R * T_K)) * np.exp(k_soc * (SOC - self.soc_ref)))) ** (1 / alpha)

    # ---- Cycling ageing ----
    def extrapolate_cycling(self, p, N, T_degC, C_charge, C_discharge, SOC_lower, SOC_upper, 
                        SOC_ref=50, DOD_ref=100, C_ref=1, Tref_degC=25):
        """
        Predicts cumulative capacity loss (%) due to cycling using a semi-empirical stress model.
        """
        # Unpack parameters
        k_cyc, Ea, b_soc_avg, b_dod, a_Cch, b_Cch, a_Cdis, b_Cdis, alpha = p

        T_K = T_degC + 273.15
        Tref_K = Tref_degC + 273.15
        SOC_avg = (SOC_upper + SOC_lower) / 2
        DOD = SOC_upper - SOC_lower
        
        # 1. SOC average stress
        f_SOC = np.exp(b_soc_avg * (SOC_avg - SOC_ref))
        
        # 2. DOD stress
        f_DOD = (DOD / DOD_ref) ** b_dod
        
        # 3. C-rate stress
        f_Cch = 1 + a_Cch * (C_charge / C_ref) ** b_Cch
        f_Cdis = 1 + a_Cdis * (C_discharge / C_ref) ** b_Cdis
        
        # 4. Temperature stress
        f_T = np.exp(-(Ea / 8.314) * (1/T_K - 1/Tref_K))

        # Combined severity factor K
        K = k_cyc * f_SOC * f_DOD * f_Cch * f_Cdis * f_T

        return K * (N ** alpha)

    def invert_cycling(self, p, Q_target, T_degC, C_charge, C_discharge, SOC_lower, SOC_upper, 
                         SOC_ref=50, DOD_ref=100, C_ref=1, Tref_degC=25):
        """
        Returns the number of cycles N needed to reach a specific Q_loss [%].
        """
        # Unpack parameters
        k_cyc, Ea, b_soc_avg, b_dod, a_Cch, b_Cch, a_Cdis, b_Cdis, alpha = p

        T_K = T_degC + 273.15
        Tref_K = Tref_degC + 273.15
        SOC_avg = (SOC_upper + SOC_lower) / 2
        DOD = SOC_upper - SOC_lower
        
        # Calculate severity factor K
        f_SOC = np.exp(b_soc_avg * (SOC_avg - SOC_ref))
        f_DOD = (DOD / DOD_ref) ** b_dod
        f_Cch = 1 + a_Cch * (C_charge / C_ref) ** b_Cch
        f_Cdis = 1 + a_Cdis * (C_discharge / C_ref) ** b_Cdis
        f_T = np.exp(-(Ea / 8.314) * (1/T_K - 1/Tref_K))

        K = k_cyc * f_SOC * f_DOD * f_Cch * f_Cdis * f_T

        # Solve for N: N = (Q_loss / K) ^ (1/alpha)
        # np.maximum to avoid division by zero or negative roots
        N_calc = (Q_target / np.maximum(K, 1e-12)) ** (1 / alpha)

        return N_calc
