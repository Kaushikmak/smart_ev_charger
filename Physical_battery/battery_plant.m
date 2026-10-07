%% =========================================================
%  PHYSICAL BATTERY PLANT INITIALIZATION
%  FYP Battery Digital Twin
% ==========================================================

% Make sure Battery parameters exist
if ~exist("Battery","var")
    run("../Parameters/init_all.m");
end

%% Initial states

Plant.SOC0 = Battery.SOC_initial;

Plant.V1_0 = 0;
Plant.V2_0 = 0;

Plant.T0_C = Battery.T_initial_C;

Plant.SOH0 = Battery.Aging.SOH_initial;

%% Initial aging states

Plant.Q_available_Ah = Battery.Q_nom_Ah;

Plant.R0_current = Battery.R0;

%% Simulation configuration

Plant.Ts = 0.1;             % Simulation sample time [s]

Plant.I_initial = 0;        % Initial current [A]

Plant.T_ambient_C = ...
    Battery.Thermal.T_ambient_C;

%% Current limits

Plant.I_charge_max = ...
    Battery.I_max_charge;

Plant.I_discharge_max = ...
    Battery.I_max_discharge;

%% Display

disp("Physical battery plant initialized.");

disp(Plant);