import numpy as np
from scipy.optimize import brentq

class DegradationPhysics:
    """
    Empirical degradation equations for calendar and cycling ageing.
    """

    def __init__(self):
        self.R = 8.314

    # ---- Calendar ageing ----
    def extrapolate_calendar(self, p, t_days, T_degC, SOC, T_ref_degC=25.0, SOC_ref=50.0):
        """
        Predicts capacity loss (%) due to calendar ageing (Loss of Lithium Inventory).

        This function models the passive growth of the SEI layer and electrolyte 
        decomposition as a function of temperature (Arrhenius), voltage stress (SOC), 
        and a power-law time exponent.

        Parameters
        ----------
        p : array-like (4 parameters)
            - k_cal_LLI : Baseline rate of calendar LLI growth.
            - Ea_LLI    : Activation energy (J/mol) for SEI growth kinetics.
            - beta_SOC  : Sensitivity coefficient for SOC-driven voltage stress.
            - z_time    : Time-exponent for LLI (typically ~0.5 for diffusion-limited growth).
        t_days : float or np.ndarray
            Total time elapsed in days.
        T_degC : float
            Storage or ambient temperature [°C].
        SOC : float
            Average State of Charge during storage [%].
        T_ref_degC : float, optional
            Reference temperature for Arrhenius anchoring (default 25°C).
        SOC_ref : float, optional
            Reference SOC for voltage stress anchoring (default 50%).

        Returns
        -------
        Q_loss : float or np.ndarray
            Predicted cumulative capacity loss [%].
        """
        k_cal_LLI, Ea_LLI, beta_SOC, z_time = p
        
        T_K = T_degC + 273.15
        T_ref_K = T_ref_degC + 273.15
        
        f_T = np.exp(-(Ea_LLI / self.R) * (1/T_K - 1/T_ref_K))
        f_SOC = np.exp(beta_SOC * (SOC - SOC_ref))
        
        return k_cal_LLI * f_T * f_SOC * (t_days ** z_time)

    def invert_calendar(self, p, Q_target, T_degC, SOC, T_ref_degC=25.0, SOC_ref=50.0):
        """
        Solve for time given cumulative Q_loss (inverse of calendar model).
        """
        k_cal_LLI, Ea_LLI, beta_SOC, z_time = p
        T_K = T_degC + 273.15
        T_ref_K = T_ref_degC + 273.15
        
        f_T = np.exp(-(Ea_LLI / self.R) * (1/T_K - 1/T_ref_K))
        f_SOC = np.exp(beta_SOC * (SOC - SOC_ref))
        
        return (Q_target / (k_cal_LLI * f_T * f_SOC))**(1/z_time)

    # ---- Cycling ageing ----
    def extrapolate_cycling_simple(self, p, N, T_degC, Tref_degC=25):
        """
        Predicts cumulative capacity loss (%) due to cycling using a simplified 
        semi-empirical stress model, considering only temperature and number of cycles.

        In this function the model takes the form:
        Q_loss = k_cyc * exp(-(Ea / R) * (1/T - 1/Tref)) * N^z
        """
        k_cyc, Ea, z = p

        T_K = T_degC + 273.15
        Tref_K = Tref_degC + 273.15
        
        # 1. Temperature stress (Arrhenius law)
        f_T = np.exp(-(Ea / self.R) * (1/T_K - 1/Tref_K))

        # Combined severity factor K
        K = k_cyc * f_T

        # Total capacity loss
        Q_loss = K * (N ** z)

        return Q_loss
    
    def extrapolate_cycling(self, p, N, T_degC, C_ch, C_dis, SOC_avg, DOD,
                            SOC_ref=50, DOD_ref=100, C_ref=1.0, T_ref_degC=25):
        """
        Predicts capacity loss (%) using a multi-mechanism model capturing LLI, LAM, and Plating.

        The model decouples gradual aging (SEI/LLI) from accelerated aging (Structural LAM) 
        and includes a temperature-coupled lithium plating stress factor.

        Parameters
        ----------
        p : array-like (11 parameters)
            - k_LLI    : Baseline rate of Loss of Lithium Inventory (SEI growth).
            - z        : Time-exponent for LLI (typically ~0.5 for diffusion).
            - k_LAM    : Rate of Loss of Active Material (structural degradation/knee).
            - m        : Acceleration exponent for LAM (typically > 1.0).
            - Ea_LLI   : Activation energy (J/mol) for baseline chemical aging.
            - beta     : Sensitivity to average SOC level (voltage stress).
            - w        : Exponent for Depth of Discharge (mechanical fatigue).
            - a_plat   : Magnitude of lithium plating stress during charge.
            - Ea_plat  : Activation energy (J/mol) for the lithium diffusion/plating threshold.
            - a_dis    : Magnitude of discharge-induced mechanical stress.
            - g_dis    : Exponent for discharge C-rate (Joule heating/strain).
        N : float or np.ndarray
            Cycle count or Amp-hour throughput.
        T_degC : float
            Cell temperature [°C].
        C_ch, C_dis : float
            Charge and Discharge C-rates.
        SOC_lo, SOC_up : float
            Cycle boundaries [%].
        C_ref : float, optional
            Reference C-rate for normalization (default 1.0C).
        T_ref_degC : float, optional
            Reference temperature for Arrhenius anchoring (default 25°C).

        Returns
        -------
        Q_loss : float or np.ndarray
            Predicted cumulative capacity loss [%].
        """
        # Unpack parameters for readability
        (k_LLI, z, k_LAM, m, Ea_LLI, beta, w, a_plat, Ea_plat, a_dis, g_dis) = p

        # Conversions
        T_K = T_degC + 273.15
        T_ref_K = T_ref_degC + 273.15

        # 1. Temperature stress (Arrhenius law)
        f_T = np.exp(-(Ea_LLI / self.R) * (1/T_K - 1/T_ref_K))

        # 2. SOC average stress (Nernst/Butler-Volmer approximation)
        f_SOC = np.exp(beta * (SOC_avg - SOC_ref))

        # 3. DOD stress (Manson-Coffin fatigue law)
        f_DOD = (DOD / DOD_ref) ** w

        # 4. Discharge Stress (Mechanical/Ohmic)
        f_dis = 1 + a_dis * (C_dis / C_ref) ** g_dis

        # 5. Charge Plating Stress (Coupled: High C-rate + Low Temp)
        # The exponential term increases as T_K drops below T_ref_K
        f_plat = 1 + a_plat * (C_ch / C_ref)**2 * np.exp((Ea_plat / self.R) * (1/T_K - 1/T_ref_K))

        # Severity factors K_LLI and K_LAM
        K_LLI = f_T * f_SOC
        K_LAM = f_DOD * f_dis * f_plat

        # Total capacity loss
        # Dual-Path Degradation: LLI (SEI) + LAM (Knee Effect)
        Q_loss = k_LLI * K_LLI * f_SOC * (N**z) + k_LAM * K_LAM * (N**m)
        
        return Q_loss
    
    def invert_cycling_simple(self, p, Q_target, T_degC, Tref_degC=25):
        """
        Returns the number of cycles N needed to reach a specific Q_loss [%] for the simplified model.
        """
        k_cyc, Ea, z = p

        T_K = T_degC + 273.15
        Tref_K = Tref_degC + 273.15
        
        # Calculate severity factor K
        f_T = np.exp(-(Ea / self.R) * (1/T_K - 1/Tref_K))
        K = k_cyc * f_T

        # Solve for N: N = (Q_loss / K) ^ (1/z)
        # np.maximum to avoid division by zero or negative roots
        N_calc = (Q_target / np.maximum(K, 1e-12)) ** (1 / z)

        return N_calc
    
    def invert_cycling(self, p, Q_target, T_degC, C_ch, C_dis, SOC_avg, DOD, 
                   SOC_ref=50, DOD_ref=100, C_ref=1.0, T_ref_degC=25):
        """
        Calculates the number of cycles required to reach a specific capacity loss target.
        
        Since the cycling model (LLI + LAM) is non-linear, this uses a numerical 
        root-finder (Brent's method) to find N.
        """
        # Define the root-finding objective: extrapolate(N) - Q_target = 0
        def objective(N):
            return self.extrapolate_cycling(p, N, T_degC, C_ch, C_dis, SOC_avg, DOD, 
                                            SOC_ref=SOC_ref, DOD_ref=DOD_ref, C_ref=C_ref, T_ref_degC=T_ref_degC) - Q_target

        try:
            # Search for N between 0 and 100,000 cycles
            # This range can be adjusted based on expected battery life
            N_sol = brentq(objective, a=0, b=1e6)
            return N_sol
        except ValueError:
            # If the target is never reached within the bounds
            return np.nan
