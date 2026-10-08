function Results = run_bms_protection_tests()

clc;

fprintf("\n============================================\n");
fprintf("   BMS PROTECTION VALIDATION TEST SUITE\n");
fprintf("============================================\n\n");


%% ============================================================
% PROJECT PATHS
% =============================================================

projectRoot = fileparts(fileparts(mfilename("fullpath")));

modelPath = fullfile( ...
    projectRoot, ...
    "Battery_Digital_Twin.slx");

modelName = "Battery_Digital_Twin";


%% ============================================================
% LOAD SIMULINK MODEL
% =============================================================

if ~bdIsLoaded(modelName)
    load_system(modelPath);
end

fprintf("Simulink model loaded: %s\n", modelName);


%% ============================================================
% LOAD MOLICEL BATTERY PROFILE
% =============================================================

profilePath = fullfile( ...
    projectRoot, ...
    "Parameters", ...
    "Battery_Profiles", ...
    "battery_molicel_M35A.m");

clear Battery

run(profilePath);


%% ============================================================
% DISPLAY BATTERY INFORMATION
% =============================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("      MOLICEL INR-18650-M35A PROFILE LOADED\n");
fprintf("============================================================\n");

if isfield(Battery,"Manufacturer")
    fprintf("Manufacturer       : %s\n", ...
        Battery.Manufacturer);
end

if isfield(Battery,"PartNumber")
    fprintf("Cell               : %s\n", ...
        Battery.PartNumber);
end

fprintf("Chemistry          : %s\n", ...
    Battery.Chemistry);

fprintf("\n");

fprintf("Nominal Capacity   : %.2f Ah\n", ...
    Battery.Q_nom_Ah);

fprintf("Nominal Voltage    : %.2f V\n", ...
    Battery.V_nom);

fprintf("Maximum Voltage    : %.2f V\n", ...
    Battery.V_max);

fprintf("Minimum Voltage    : %.2f V\n", ...
    Battery.V_min);

fprintf("\n");

fprintf("Maximum Charge     : %.2f A\n", ...
    Battery.I_max_charge);

fprintf("Maximum Discharge  : %.2f A\n", ...
    Battery.I_max_discharge);

fprintf("\n");

fprintf("Initial SOC        : %.2f\n", ...
    Battery.SOC_initial);

fprintf("Initial Temperature: %.2f °C\n", ...
    Battery.T_initial_C);

fprintf("\n");

fprintf("NOTE:\n");
fprintf("Manufacturer values are used for cell specifications.\n");
fprintf("ECM, thermal, OCV and aging parameters remain model\n");
fprintf("parameters until they are identified/refined.\n");

fprintf("============================================================\n");


%% ============================================================
% LOAD SENSOR PARAMETERS
% =============================================================

run(fullfile( ...
    projectRoot, ...
    "Parameters", ...
    "init_sensors.m"));


%% ============================================================
% LOAD INITIAL BMS PARAMETERS
% =============================================================

run(fullfile( ...
    projectRoot, ...
    "Parameters", ...
    "init_bms.m"));


%% ============================================================
% TEST SETTINGS
% =============================================================

Ts = 0.1;

T_end = 300;

t = (0:Ts:T_end)';


%% ============================================================
% CREATE RESULT STRUCTURE
% =============================================================

Results = struct();


%% ============================================================
% TEST 1 — NORMAL OPERATION
% =============================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("TEST 1: NORMAL OPERATION\n");
fprintf("============================================================\n");

Battery.T_initial_C = 25;

Battery.Thermal.T_ambient_C = 25;

I_command = zeros(size(t));

% Normal discharge
I_command(t >= 50 & t < 150) = 1.0;

% Normal charge
I_command(t >= 200 & t < 250) = -1.0;

T_ambient = 25 * ones(size(t));

Results.Normal = run_single_test( ...
    modelName, ...
    Battery, ...
    t, ...
    I_command, ...
    T_ambient, ...
    "Normal");


%% ============================================================
% TEST 2 — OVER TEMPERATURE
% =============================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("TEST 2: OVER TEMPERATURE\n");
fprintf("============================================================\n");

Battery.T_initial_C = 45;

Battery.Thermal.T_ambient_C = 42;

I_command = zeros(size(t));

I_command(t >= 50 & t < 150) = 1.0;

T_ambient = 42 * ones(size(t));

Results.OverTemperature = run_single_test( ...
    modelName, ...
    Battery, ...
    t, ...
    I_command, ...
    T_ambient, ...
    "OverTemperature");


%% ============================================================
% TEST 3 — UNDER TEMPERATURE
% =============================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("TEST 3: UNDER TEMPERATURE\n");
fprintf("============================================================\n");

Battery.T_initial_C = -5;
Battery.Thermal.T_ambient_C = -5;

I_command = zeros(size(t));

I_command(t >= 50 & t < 150) = 1.0;

T_ambient = -5 * ones(size(t));

Results.UnderTemperature = run_single_test( ...
    modelName, ...
    Battery, ...
    t, ...
    I_command, ...
    T_ambient, ...
    "UnderTemperature");


%% ============================================================
% TEST 4 — DISCHARGE OVER-CURRENT
% =============================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("TEST 4: DISCHARGE OVER-CURRENT\n");
fprintf("============================================================\n");

Battery.T_initial_C = 25;

Battery.Thermal.T_ambient_C = 25;

I_command = zeros(size(t));

I_command(t >= 50 & t < 150) = ...
    1.2 * Battery.I_max_discharge;

T_ambient = 25 * ones(size(t));

Results.DischargeOverCurrent = run_single_test( ...
    modelName, ...
    Battery, ...
    t, ...
    I_command, ...
    T_ambient, ...
    "DischargeOverCurrent");


%% ============================================================
% TEST 5 — CHARGE OVER-CURRENT
% =============================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("TEST 5: CHARGE OVER-CURRENT\n");
fprintf("============================================================");

Battery.T_initial_C = 25;

Battery.Thermal.T_ambient_C = 25;

I_command = zeros(size(t));

I_command(t >= 50 & t < 150) = ...
    -1.2 * Battery.I_max_charge;

T_ambient = 25 * ones(size(t));

Results.ChargeOverCurrent = run_single_test( ...
    modelName, ...
    Battery, ...
    t, ...
    I_command, ...
    T_ambient, ...
    "ChargeOverCurrent");


%% ============================================================
% SUMMARY
% =============================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("              TEST SUMMARY\n");
fprintf("============================================================\n\n");

names = fieldnames(Results);

for k = 1:numel(names)

    R = Results.(names{k});

    fprintf("%-25s : %s\n", ...
        names{k}, ...
        R.Status);

end

fprintf("\n");
fprintf("============================================================\n");


end


%% ============================================================
% SINGLE TEST RUNNER
% =============================================================

function R = run_single_test( ...
    modelName, ...
    Battery, ...
    t, ...
    I_command, ...
    T_ambient, ...
    testName)


%% ============================================================
% CREATE BMS PARAMETERS FOR THIS TEST
% =============================================================

BMS = struct();

BMS.Ts = 0.1;

BMS.Filter.Alpha = 0.9;

BMS.SOC.Initial = Battery.SOC_initial;

BMS.SOC.Min = 0;

BMS.SOC.Max = 1;

BMS.SOC.Efficiency = Battery.eta_discharge;

% SOH estimation parameters
BMS.SOH.Initial = Battery.Aging.SOH_initial;
BMS.SOH.Min = 0;
BMS.SOH.Max = 1;
BMS.SOH.VoltageStressWeight = 1.0;
BMS.SOH.TemperatureStressWeight = 1.0;

BMS.Protection.Enable = true;

BMS.Control.Enable = true;

BMS.Fault.ResetEnable = true;


%% ============================================================
% PUSH CURRENT TEST PARAMETERS TO BASE WORKSPACE
% =============================================================

assignin( ...
    "base", ...
    "Battery", ...
    Battery);

assignin( ...
    "base", ...
    "BMS", ...
    BMS);


%% ============================================================
% CREATE WORKSPACE INPUT SIGNALS
% =============================================================

I_input = timeseries( ...
    I_command, ...
    t);

T_ambient_input = timeseries( ...
    T_ambient, ...
    t);


%% ============================================================
% PUSH INPUT SIGNALS TO BASE WORKSPACE
% =============================================================

assignin( ...
    "base", ...
    "I_input", ...
    I_input);

assignin( ...
    "base", ...
    "T_ambient_input", ...
    T_ambient_input);


%% ============================================================
% DISPLAY ACTIVE TEST PARAMETERS
% =============================================================

fprintf("\nActive test parameters:\n");

fprintf("  Test name       : %s\n", testName);

fprintf("  Initial temp    : %.2f °C\n", ...
    Battery.T_initial_C);

fprintf("  Ambient temp    : %.2f °C\n", ...
    Battery.Thermal.T_ambient_C);

fprintf("  Max charge      : %.2f A\n", ...
    Battery.I_max_charge);

fprintf("  Max discharge   : %.2f A\n", ...
    Battery.I_max_discharge);


%% ============================================================
% UPDATE SIMULINK MODEL
% =============================================================

set_param( ...
    modelName, ...
    "SimulationCommand", ...
    "update");


%% ============================================================
% SET SIMULATION STOP TIME
% =============================================================

set_param( ...
    modelName, ...
    "StopTime", ...
    num2str(t(end)));


%% ============================================================
% RUN SIMULATION
% =============================================================

out = sim(modelName);


%% ============================================================
% CREATE RESULT STRUCTURE
% =============================================================

R = struct();

R.TestName = testName;

R.Output = out;


%% ============================================================
% EXTRACT PROTECTION SIGNALS
% =============================================================

R.Fault = ...
    extract_signal(out,"Fault");

R.Emergency = ...
    extract_signal(out,"Emergency_Shutdown");

R.OverVoltage = ...
    extract_signal(out,"OverVoltage");

R.UnderVoltage = ...
    extract_signal(out,"UnderVoltage");

R.ChargeOverCurrent = ...
    extract_signal(out,"ChargeOverCurrent");

R.DischargeOverCurrent = ...
    extract_signal(out,"DischargeOverCurrent");

R.OverTemperature = ...
    extract_signal(out,"OverTemperature");

R.UnderTemperature = ...
    extract_signal(out,"UnderTemperature");


%% ============================================================
% EXTRACT BMS STATUS
% =============================================================

R.FaultCode = ...
    extract_signal(out,"Fault_Code");

R.BMSState = ...
    extract_signal(out,"BMS_State");


%% ============================================================
% EXTRACT CURRENT SIGNALS
% =============================================================

R.IRequested = ...
    extract_signal(out,"I_battery_measured");

R.ISafe = ...
    extract_signal(out,"I_safe_command");

R.IBattery = ...
    extract_signal(out,"I_battery");


%% ============================================================
% COUNT PROTECTION EVENTS
% =============================================================

R.Count.OverVoltage = ...
    nnz(R.OverVoltage > 0.5);

R.Count.UnderVoltage = ...
    nnz(R.UnderVoltage > 0.5);

R.Count.ChargeOverCurrent = ...
    nnz(R.ChargeOverCurrent > 0.5);

R.Count.DischargeOverCurrent = ...
    nnz(R.DischargeOverCurrent > 0.5);

R.Count.OverTemperature = ...
    nnz(R.OverTemperature > 0.5);

R.Count.UnderTemperature = ...
    nnz(R.UnderTemperature > 0.5);

R.Count.Fault = ...
    nnz(R.Fault > 0.5);

R.Count.Emergency = ...
    nnz(R.Emergency > 0.5);


%% ============================================================
% UNIQUE FAULT CODES AND BMS STATES
% =============================================================

R.FaultCodes = ...
    unique(R.FaultCode);

R.BMSStates = ...
    unique(R.BMSState);


%% ============================================================
% EMERGENCY SHUTDOWN VALIDATION
% =============================================================

% Battery current and emergency shutdown may have
% different sample counts. Use their common portion.

n = min( ...
    numel(R.IBattery), ...
    numel(R.Emergency));

Ibat = ...
    R.IBattery(1:n);

Emergency = ...
    R.Emergency(1:n) > 0.5;


if any(Emergency)

    R.MaxEmergencyCurrent = ...
        max(abs(Ibat(Emergency)));

    currentShutdownPass = ...
        R.MaxEmergencyCurrent < 1e-3;

else

    R.MaxEmergencyCurrent = NaN;

    currentShutdownPass = true;

end


%% ============================================================
% DETERMINE EXPECTED TEST BEHAVIOR
% =============================================================

switch testName

    case "Normal"

        passed = ...
            R.Count.Fault == 0 && ...
            R.Count.Emergency == 0;


    case "OverTemperature"

        passed = ...
            R.Count.OverTemperature > 0 && ...
            R.Count.Fault > 0 && ...
            R.Count.Emergency > 0;


    case "UnderTemperature"

        passed = ...
            R.Count.UnderTemperature > 0 && ...
            R.Count.Fault > 0 && ...
            R.Count.Emergency > 0;


    case "DischargeOverCurrent"

        passed = ...
            R.Count.DischargeOverCurrent > 0 && ...
            R.Count.Fault > 0 && ...
            R.Count.Emergency > 0;


    case "ChargeOverCurrent"

        passed = ...
            R.Count.ChargeOverCurrent > 0 && ...
            R.Count.Fault > 0 && ...
            R.Count.Emergency > 0;


    otherwise

        passed = false;

end


%% ============================================================
% INCLUDE EMERGENCY CURRENT VALIDATION
% =============================================================

passed = ...
    passed && ...
    currentShutdownPass;


%% ============================================================
% FINAL STATUS
% =============================================================

if passed

    R.Status = "PASS";

else

    R.Status = "FAIL";

end


%% ============================================================
% DISPLAY TEST RESULTS
% =============================================================

fprintf("\n");
fprintf("----- %s RESULT -----\n",testName);

fprintf( ...
    "  Fault samples        : %d\n", ...
    R.Count.Fault);

fprintf( ...
    "  Emergency samples    : %d\n", ...
    R.Count.Emergency);

fprintf( ...
    "  OverVoltage          : %d\n", ...
    R.Count.OverVoltage);

fprintf( ...
    "  UnderVoltage         : %d\n", ...
    R.Count.UnderVoltage);

fprintf( ...
    "  ChargeOverCurrent    : %d\n", ...
    R.Count.ChargeOverCurrent);

fprintf( ...
    "  DischargeOverCurrent : %d\n", ...
    R.Count.DischargeOverCurrent);

fprintf( ...
    "  OverTemperature      : %d\n", ...
    R.Count.OverTemperature);

fprintf( ...
    "  UnderTemperature     : %d\n", ...
    R.Count.UnderTemperature);

fprintf("  Fault codes          : ");

disp(R.FaultCodes');

fprintf("  BMS states           : ");

disp(R.BMSStates');


if ~isnan(R.MaxEmergencyCurrent)

    fprintf( ...
        "  Max emergency current: %.6f A\n", ...
        R.MaxEmergencyCurrent);

end


fprintf( ...
    "  RESULT               : %s\n", ...
    R.Status);


end


%% ============================================================
% SIGNAL EXTRACTION FUNCTION
% =============================================================

function x = extract_signal(out,name)

x = out.(name);


if isa(x,"timeseries")

    x = x.Data;

end


x = squeeze(x);

x = x(:);


end