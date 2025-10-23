# cell_modelling
Repository for all code related to cell modelling in general
____________________________________________________

Potential future model developments:

Ageing:
- Automate generation of customer profiles in Simulink
- Include minimum and maximum cell temperatures in both the thermal model and ageing model
- Inclusion of resistance increase and feedback into model
- Prediction of SOH spread within a pack
- Inclusion of confidence intervals (uncertainties in temperature profile, each of the individual optimisations, extrapolation beyond test data, sudden capacity fade)
- Further cell testing: storage SOC, cycling DoD, cycling C-rates
- Add functions for these dependencies
- Integration into an SOH estimator for BMS
- Internal gas pressure and swelling force model
- Machine learning model combining cloud data and cycling data

Performance:
- Hysteresis model for the OCV curve
- Improve visualisation of parameter averaging
- Investigate C-rate dependency of parameters
- Investigate use of diffusion parameter to distinguish between surface SOC and bulk SOC at low SOC ranges
- Investigate machine learning model for parameter determination

Estimators:
- Test implementation of the EKF SOC model into a BMS
- Expand the SOC model to estimate SOC for all cells in a pack
- SOH estimator (start with the one from Simscape Battery toolbox)
- SOP estimator. Use the ECM to predict available power
- Live R0 estimator. I think there's one in the Simscape Battery toolbox
- Investigate i2t function similar to the one that Lithium Balance uses
- Investigate use of machine learning estimators
