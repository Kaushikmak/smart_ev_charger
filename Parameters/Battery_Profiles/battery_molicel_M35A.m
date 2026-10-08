%% =========================================================
% MOLICEL INR-18650-M35A BATTERY PROFILE
% FYP - Battery Digital Twin
%
% Commercial cell:
% Molicel INR-18650-M35A
%
% Manufacturer-based cell specifications
% ==========================================================

clear Battery

%% ---------------------------------------------------------
% CELL IDENTIFICATION
% ---------------------------------------------------------

Battery.Name = "Molicel_INR_18650_M35A";
Battery.Manufacturer = "Molicel";
Battery.PartNumber = "INR-18650-M35A";
Battery.Chemistry = "Lithium-Ion";

%% ---------------------------------------------------------
% NOMINAL ELECTRICAL PARAMETERS
% ---------------------------------------------------------

Battery.Q_nom_Ah = 3.45;

Battery.V_nom = 3.60;
Battery.V_max = 4.20;
Battery.V_min = 2.50;

%% ---------------------------------------------------------
% CURRENT LIMITS
% ---------------------------------------------------------

Battery.I_max_charge = 1.70;
Battery.I_max_discharge = 10.0;

%% ---------------------------------------------------------
% INITIAL CONDITIONS
% ---------------------------------------------------------

Battery.SOC_initial = 0.95;
Battery.T_initial_C = 45;

%% ---------------------------------------------------------
% EQUIVALENT CIRCUIT MODEL
% ---------------------------------------------------------
%
% These parameters are MODEL PARAMETERS and are not being
% claimed as manufacturer-published values.
%
% They are initially retained from the validated FYP model.
% We will identify/refine them later using real battery data.

Battery.R0 = 0.045;

Battery.R1 = 0.020;
Battery.C1 = 2200;

Battery.R2 = 0.012;
Battery.C2 = 15000;

%% ---------------------------------------------------------
% EFFICIENCY
% ---------------------------------------------------------

Battery.eta_charge = 0.995;
Battery.eta_discharge = 0.995;

%% ---------------------------------------------------------
% THERMAL MODEL
% ---------------------------------------------------------
%
% Initial model values retained from the existing FYP model.
% These should later be replaced/identified using experimental
% temperature data from the actual cell.

Battery.Thermal.Cth = 500;
Battery.Thermal.hA = 1.2;
Battery.Thermal.T_ambient_C = 42;

Battery.Thermal.T_max_C = 45;
Battery.Thermal.T_min_C = 0;

%% ---------------------------------------------------------
% AGING MODEL
% ---------------------------------------------------------
%
% Initial placeholder model.
% These parameters must eventually be identified from
% experimental aging/cycle-life data.

Battery.Aging.SOH_initial = 1.0;

Battery.Aging.capacity_fade_per_Ah = 2e-5;
Battery.Aging.resistance_growth_per_Ah = 3e-5;

%% ---------------------------------------------------------
% OCV-SOC MODEL
% ---------------------------------------------------------
%
% IMPORTANT:
% This OCV curve is currently retained from the previous
% generic model.
%
% It is NOT being claimed as the manufacturer's M35A OCV
% characterization.
%
% We will replace this with a cell-specific OCV-SOC curve
% when experimental/reference data is available.

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
% MODEL CONFIGURATION
% ---------------------------------------------------------

Battery.Model.num_RC_pairs = 2;

Battery.Model.enable_thermal = true;
Battery.Model.enable_aging = true;

%% ---------------------------------------------------------
% DISPLAY
% ---------------------------------------------------------

fprintf('\n');
fprintf('============================================================\n');
fprintf('      MOLICEL INR-18650-M35A PROFILE LOADED\n');
fprintf('============================================================\n');

fprintf('Manufacturer       : %s\n', Battery.Manufacturer);
fprintf('Cell               : %s\n', Battery.PartNumber);
fprintf('Chemistry          : %s\n', Battery.Chemistry);

fprintf('\n');
fprintf('Nominal Capacity   : %.2f Ah\n', Battery.Q_nom_Ah);
fprintf('Nominal Voltage    : %.2f V\n', Battery.V_nom);
fprintf('Maximum Voltage    : %.2f V\n', Battery.V_max);
fprintf('Minimum Voltage    : %.2f V\n', Battery.V_min);

fprintf('\n');
fprintf('Maximum Charge     : %.2f A\n', Battery.I_max_charge);
fprintf('Maximum Discharge  : %.2f A\n', Battery.I_max_discharge);

fprintf('\n');
fprintf('Initial SOC        : %.2f\n', Battery.SOC_initial);
fprintf('Initial Temperature: %.2f °C\n', Battery.T_initial_C);

fprintf('\n');
fprintf('NOTE:\n');
fprintf('Manufacturer values are used for cell specifications.\n');
fprintf('ECM, thermal, OCV and aging parameters remain model\n');
fprintf('parameters until they are identified/refined.\n');

fprintf('============================================================\n');