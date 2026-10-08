%% =========================================================
%  BATTERY PARAMETERS
%  FYP - Battery Digital Twin
% ==========================================================

clear Battery

%% ---------------------------------------------------------
% Battery identification
% ----------------------------------------------------------

Battery.Name = "FYP_LiIon_Cell";
Battery.Chemistry = "Lithium-Ion";

%% ---------------------------------------------------------
% Nominal electrical parameters
% ----------------------------------------------------------

Battery.Q_nom_Ah = 2.5;       % Nominal capacity [Ah]

Battery.V_nom = 3.7;          % Nominal voltage [V]
Battery.V_max = 4.2;          % Maximum voltage [V]
Battery.V_min = 3.0;          % Minimum voltage [V]

Battery.I_max_charge = 2.5;    % Maximum charge current [A]
Battery.I_max_discharge = 5.0; % Maximum discharge current [A]

%% ---------------------------------------------------------
% Initial conditions
% ----------------------------------------------------------

Battery.SOC_initial = 0.95;    % Initial SOC [0-1]
Battery.T_initial_C = 25;      % Initial temperature [deg C]

%% ---------------------------------------------------------
% Equivalent Circuit Model
% 2-RC Thevenin model
% ----------------------------------------------------------

% Ohmic resistance
Battery.R0 = 0.045;             % [Ohm]

% First RC branch
Battery.R1 = 0.020;             % [Ohm]
Battery.C1 = 2200;              % [F]

% Second RC branch
Battery.R2 = 0.012;             % [Ohm]
Battery.C2 = 15000;             % [F]

%% ---------------------------------------------------------
% Coulombic efficiency
% ----------------------------------------------------------

Battery.eta_charge = 0.995;
Battery.eta_discharge = 0.995;

%% ---------------------------------------------------------
% Thermal model
% ----------------------------------------------------------

Battery.Thermal.Cth = 500;      % Thermal capacitance [J/K]
Battery.Thermal.hA = 1.2;       % Heat transfer coefficient*area [W/K]

Battery.Thermal.T_ambient_C = 25;
Battery.Thermal.T_max_C = 45;
Battery.Thermal.T_min_C = 0;

%% ---------------------------------------------------------
% Aging model
% ----------------------------------------------------------

Battery.Aging.SOH_initial = 1.0;

% Demonstration aging coefficients.
% These will later be replaced by experimentally identified values.

Battery.Aging.capacity_fade_per_Ah = 2e-5;

Battery.Aging.resistance_growth_per_Ah = 3e-5;

%% ---------------------------------------------------------
% OCV-SOC relationship
% ----------------------------------------------------------

Battery.OCV.SOC = [ ...
    0.00
    0.05
    0.10
    0.20
    0.30
    0.40
    0.50
    0.60
    0.70
    0.80
    0.90
    0.95
    1.00 ];

Battery.OCV.Voltage = [ ...
    3.00
    3.25
    3.35
    3.48
    3.55
    3.60
    3.65
    3.68
    3.72
    3.78
    3.88
    3.98
    4.15 ];

%% ---------------------------------------------------------
% Model configuration
% ----------------------------------------------------------

Battery.Model.num_RC_pairs = 2;

Battery.Model.enable_thermal = true;
Battery.Model.enable_aging = true;

%% ---------------------------------------------------------
% Display
% ----------------------------------------------------------

disp("Battery parameters loaded successfully.");

disp(Battery);