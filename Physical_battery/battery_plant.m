%% =========================================================
% PHYSICAL BATTERY PLANT INITIALIZATION
% ==========================================================

Plant.SOC0 = Battery.SOC_initial;
Plant.V1_0 = 0;
Plant.V2_0 = 0;
Plant.T0_C = Battery.T_initial_C;
Plant.SOH0 = Battery.Aging.SOH_initial;
Plant.Q_available_Ah = Battery.Q_nom_Ah;
Plant.R0_current = Battery.R0;
Plant.Ts = 0.1;
Plant.I_initial = 0;
Plant.T_ambient_C = Battery.Thermal.T_ambient_C;
Plant.I_charge_max = Battery.I_max_charge;
Plant.I_discharge_max = Battery.I_max_discharge;

disp("Physical battery plant initialized.");
disp(Plant);