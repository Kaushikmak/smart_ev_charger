%% =========================================================================
% test_complete_bms.m
%
% COMPLETE BMS VERIFICATION TEST
%
% Tests:
%
%   1. Physical Battery
%   2. Sensors
%   3. Measurement Processing
%   4. State Estimation
%   5. Protection
%   6. Limits and Permissions
%   7. BMS Control
%   8. BMS Status
%   9. BMS State Logic
%  10. BMS outputs/entities
%
% =========================================================================

clc;
clearvars -except Battery BatteryLibrary Sensors BMS Plant
close all;

fprintf("\n");
fprintf("====================================================================\n");
fprintf("                 COMPLETE BMS VERIFICATION TEST\n");
fprintf("====================================================================\n");

%% ========================================================================
% PROJECT PATHS
% ========================================================================

projectRoot = fileparts(fileparts(mfilename("fullpath")));

modelPath = fullfile( ...
    projectRoot, ...
    "Battery_Digital_Twin.slx");

modelName = "Battery_Digital_Twin";

%% ========================================================================
% CHECK MODEL
% ========================================================================

if ~isfile(modelPath)

    error( ...
        "Battery_Digital_Twin.slx was not found:\n%s", ...
        modelPath);

end

fprintf("\nModel found:\n%s\n", modelPath);

%% ========================================================================
% LOAD BATTERY PROFILE
% ========================================================================

profilePath = fullfile( ...
    projectRoot, ...
    "Parameters", ...
    "Battery_Profiles", ...
    "battery_molicel_M35A.m");

if ~isfile(profilePath)

    error( ...
        "Molicel battery profile not found:\n%s", ...
        profilePath);

end

clear Battery

run(profilePath);

%% ========================================================================
% LOAD SENSOR PARAMETERS
% ========================================================================

sensorPath = fullfile( ...
    projectRoot, ...
    "Parameters", ...
    "init_sensors.m");

if isfile(sensorPath)

    run(sensorPath);

else

    warning("init_sensors.m not found.");

end

%% ========================================================================
% LOAD BMS PARAMETERS IF AVAILABLE
% ========================================================================

bmsParameterPath = fullfile( ...
    projectRoot, ...
    "Parameters", ...
    "init_bms.m");

if isfile(bmsParameterPath)

    run(bmsParameterPath);

else

    warning("init_bms.m not found.");

end

%% ========================================================================
% DISPLAY BATTERY
% ========================================================================

fprintf("\n");
fprintf("Battery:\n");
fprintf("  Name       : %s\n", Battery.Name);

if isfield(Battery,"Manufacturer")
    fprintf("  Manufacturer: %s\n", Battery.Manufacturer);
end

if isfield(Battery,"PartNumber")
    fprintf("  Part Number : %s\n", Battery.PartNumber);
end

fprintf("  Capacity   : %.3f Ah\n", Battery.Q_nom_Ah);
fprintf("  Vnom       : %.3f V\n", Battery.V_nom);
fprintf("  Vmax       : %.3f V\n", Battery.V_max);
fprintf("  Vmin       : %.3f V\n", Battery.V_min);
fprintf("  Charge max : %.3f A\n", Battery.I_max_charge);
fprintf("  Discharge max: %.3f A\n", Battery.I_max_discharge);

%% ========================================================================
% IMPORTANT TEST CONDITION
%
% Your current Molicel profile uses 45 C initial temperature and 42 C
% ambient. For an architecture test, we temporarily use a safe temperature
% so the BMS can demonstrate normal/limited behavior without immediately
% triggering over-temperature protection.
%
% This does NOT modify the battery profile file.
% ========================================================================

Battery.T_initial_C = 25;
Battery.Thermal.T_ambient_C = 25;

fprintf("\n");
fprintf("Architecture test temperature:\n");
fprintf("  Initial = %.1f C\n", Battery.T_initial_C);
fprintf("  Ambient = %.1f C\n", Battery.Thermal.T_ambient_C);

%% ========================================================================
% TEST SETTINGS
% ========================================================================

Ts = 0.1;

T_end = 300;

t = (0:Ts:T_end)';

%% ========================================================================
% CURRENT TEST PROFILE
%
% 0-40      : Rest
% 40-100    : Discharge
% 100-130   : Rest
% 130-190   : Charge
% 190-230   : Discharge
% 230-300   : Rest
% ========================================================================

I_command = zeros(size(t));

I_command(t >= 40  & t < 100) = 1.0;

I_command(t >= 130 & t < 190) = -1.0;

I_command(t >= 190 & t < 230) = 1.5;

%% ========================================================================
% AMBIENT TEMPERATURE
% ========================================================================

T_ambient = ...
    Battery.Thermal.T_ambient_C * ones(size(t));

%% ========================================================================
% CREATE SIMULINK WORKSPACE INPUTS
% ========================================================================

I_input = timeseries(I_command,t);

T_ambient_input = timeseries(T_ambient,t);

%% ========================================================================
% OPEN MODEL
% ========================================================================

load_system(modelName);

%% ========================================================================
% PRE-FLIGHT BMS CHECK
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("PRE-FLIGHT BMS CHECK\n");
fprintf("--------------------------------------------------------------------\n");

bmsPath = modelName + "/BMS";

if ~isempty(find_system(modelName, ...
        "SearchDepth",1, ...
        "Name","BMS"))

    fprintf("PASS: BMS subsystem exists.\n");

else

    fprintf("FAIL: BMS subsystem not found.\n");

end

%% ========================================================================
% CHECK BMS INPUT PORTS
% ========================================================================

try

    ph = get_param(char(bmsPath),"PortHandles");

    numberOfBMSInputs = numel(ph.Inport);

    fprintf("BMS input ports detected: %d\n", ...
        numberOfBMSInputs);

    if numberOfBMSInputs >= 4

        fprintf("PASS: BMS has I_command input.\n");

    else

        fprintf("\n");
        fprintf("WARNING: BMS currently has only %d inputs.\n", ...
            numberOfBMSInputs);

        fprintf("\n");
        fprintf("Expected architecture:\n");
        fprintf("  V_measured\n");
        fprintf("  I_measured\n");
        fprintf("  T_measured\n");
        fprintf("  I_command\n");

        fprintf("\n");
        fprintf("The BMS cannot control the physical battery until\n");
        fprintf("I_command is exposed as the fourth BMS input.\n");

    end

catch ME

    fprintf("WARNING: Could not inspect BMS ports.\n");
    fprintf("%s\n",ME.message);

end

%% ========================================================================
% CHECK BMS OUTPUT PORTS
% ========================================================================

try

    numberOfBMSOutputs = numel(ph.Outport);

    fprintf("BMS output ports detected: %d\n", ...
        numberOfBMSOutputs);

catch

    numberOfBMSOutputs = 0;

end

%% ========================================================================
% RUN FULL PHYSICAL + SENSOR + BMS SIMULATION
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("FULL SYSTEM SIMULATION\n");
fprintf("--------------------------------------------------------------------\n");

fprintf("Duration: %.1f s\n",T_end);
fprintf("Sample time: %.2f s\n",Ts);

%% Set simulation stop time

set_param( ...
    modelName, ...
    "StopTime", ...
    num2str(T_end));

%% Run simulation

simulationFailed = false;

try

    out = sim(modelName);

    fprintf("\nPASS: Full system simulation completed.\n");

catch ME

    simulationFailed = true;

    fprintf("\nFAIL: Full system simulation failed.\n");
    fprintf("\n");
    fprintf("%s\n",ME.message);

end

%% ========================================================================
% STOP IF SIMULATION FAILED
% ========================================================================

if simulationFailed

    fprintf("\n");
    fprintf("====================================================================\n");
    fprintf("SIMULATION STOPPED BECAUSE THE MODEL FAILED.\n");
    fprintf("Fix the simulation error before continuing with BMS verification.\n");
    fprintf("====================================================================\n");

    return;

end

%% ========================================================================
% LIST SIMULATION OUTPUTS
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("SIMULATION OUTPUTS\n");
fprintf("--------------------------------------------------------------------\n");

try

    outputNames = out.who;

    for k = 1:numel(outputNames)

        fprintf("  %s\n",outputNames{k});

    end

catch

    fprintf("Could not enumerate SimulationOutput fields.\n");

end

%% ========================================================================
% PHYSICAL BATTERY TEST
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("1. PHYSICAL BATTERY\n");
fprintf("--------------------------------------------------------------------\n");

physicalSignals = [
    "V_battery"
    "I_battery"
    "T_battery"
    "SOC_true"
    "SOH_true"
    "Q_available"
    "R0_current"
    "Ah_throughput"
];

for k = 1:numel(physicalSignals)

    [data,ok] = getSignal(out,physicalSignals(k));

    if ok

        if isempty(data)

            fprintf("FAIL: %-20s empty\n",physicalSignals(k));

        elseif all(isfinite(data))

            fprintf("PASS: %-20s available\n",physicalSignals(k));

        else

            fprintf("FAIL: %-20s contains NaN/Inf\n", ...
                physicalSignals(k));

        end

    else

        fprintf("FAIL: %-20s not found\n",physicalSignals(k));

    end

end

%% ========================================================================
% SENSOR TEST
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("2. SENSORS\n");
fprintf("--------------------------------------------------------------------\n");

sensorSignals = [
    "V_battery_measured"
    "I_battery_measured"
    "T_battery_measured"
];

for k = 1:numel(sensorSignals)

    [data,ok] = getSignal(out,sensorSignals(k));

    if ok && ~isempty(data) && all(isfinite(data))

        fprintf("PASS: %-25s\n",sensorSignals(k));

    elseif ok

        fprintf("FAIL: %-25s invalid data\n",sensorSignals(k));

    else

        fprintf("FAIL: %-25s not found\n",sensorSignals(k));

    end

end

%% ========================================================================
% MEASUREMENT PROCESSING TEST
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("3. MEASUREMENT PROCESSING\n");
fprintf("--------------------------------------------------------------------\n");

filteredSignals = [
    "V_filtered"
    "I_filtered"
    "T_filtered"
];

for k = 1:numel(filteredSignals)

    [data,ok] = getSignal(out,filteredSignals(k));

    if ok && ~isempty(data) && all(isfinite(data))

        fprintf("PASS: %-20s available\n",filteredSignals(k));

    elseif ok

        fprintf("FAIL: %-20s invalid\n",filteredSignals(k));

    else

        fprintf("FAIL: %-20s not found\n",filteredSignals(k));

    end

end

%% ========================================================================
% STATE ESTIMATION TEST
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("4. STATE ESTIMATION\n");
fprintf("--------------------------------------------------------------------\n");

estimationSignals = [
    "SOC_estimated"
    "SOH_estimated"
];

for k = 1:numel(estimationSignals)

    [data,ok] = getSignal(out,estimationSignals(k));

    if ok && ~isempty(data) && all(isfinite(data))

        fprintf("PASS: %-20s available\n",estimationSignals(k));

        if strcmp(estimationSignals(k),"SOC_estimated")

            if all(data >= 0 & data <= 1)

                fprintf("PASS: SOC remains within [0,1]\n");

            else

                fprintf("FAIL: SOC exceeded [0,1]\n");

            end

        end

        if strcmp(estimationSignals(k),"SOH_estimated")

            if all(data >= 0 & data <= 1)

                fprintf("PASS: SOH remains within [0,1]\n");

            else

                fprintf("FAIL: SOH exceeded [0,1]\n");

            end

        end

    else

        fprintf("FAIL: %-20s not found/invalid\n", ...
            estimationSignals(k));

    end

end

%% ========================================================================
% PROTECTION TEST
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("5. PROTECTION\n");
fprintf("--------------------------------------------------------------------\n");

protectionSignals = [
    "OverVoltage"
    "UnderVoltage"
    "ChargeOverCurrent"
    "DischargeOverCurrent"
    "OverTemperature"
    "UnderTemperature"
    "Fault"
    "Fault_Code"
];

for k = 1:numel(protectionSignals)

    [data,ok] = getSignal(out,protectionSignals(k));

    if ok && ~isempty(data) && all(isfinite(data))

        fprintf("PASS: %-25s available\n", ...
            protectionSignals(k));

    elseif ok

        fprintf("FAIL: %-25s invalid\n", ...
            protectionSignals(k));

    else

        fprintf("FAIL: %-25s not found\n", ...
            protectionSignals(k));

    end

end

%% ========================================================================
% LIMITS AND PERMISSIONS TEST
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("6. LIMITS AND PERMISSIONS\n");
fprintf("--------------------------------------------------------------------\n");

limitSignals = [
    "Charge_Allowed"
    "Discharge_Allowed"
    "I_charge_limit"
    "I_discharge_limit"
];

for k = 1:numel(limitSignals)

    [data,ok] = getSignal(out,limitSignals(k));

    if ok && ~isempty(data) && all(isfinite(data))

        fprintf("PASS: %-25s available\n", ...
            limitSignals(k));

    elseif ok

        fprintf("FAIL: %-25s invalid\n", ...
            limitSignals(k));

    else

        fprintf("FAIL: %-25s not found\n", ...
            limitSignals(k));

    end

end

%% ========================================================================
% BMS CONTROL TEST
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("7. BMS CONTROL\n");
fprintf("--------------------------------------------------------------------\n");

controlSignals = [
    "I_safe_command"
    "Emergency_Shutdown"
];

for k = 1:numel(controlSignals)

    [data,ok] = getSignal(out,controlSignals(k));

    if ok && ~isempty(data) && all(isfinite(data))

        fprintf("PASS: %-25s available\n", ...
            controlSignals(k));

    elseif ok

        fprintf("FAIL: %-25s invalid\n", ...
            controlSignals(k));

    else

        fprintf("FAIL: %-25s not found\n", ...
            controlSignals(k));

    end

end

%% ========================================================================
% BMS STATUS TEST
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("8. BMS STATUS\n");
fprintf("--------------------------------------------------------------------\n");

statusSignals = [
    "BMS_State"
    "BMS_Ready"
    "BMS_Fault"
];

for k = 1:numel(statusSignals)

    [data,ok] = getSignal(out,statusSignals(k));

    if ok && ~isempty(data) && all(isfinite(data))

        fprintf("PASS: %-20s available\n", ...
            statusSignals(k));

    elseif ok

        fprintf("FAIL: %-20s invalid\n", ...
            statusSignals(k));

    else

        fprintf("FAIL: %-20s not found\n", ...
            statusSignals(k));

    end

end

%% ========================================================================
% FULL BMS ENTITY CHECK
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("9. COMPLETE BMS ENTITY CHECK\n");
fprintf("--------------------------------------------------------------------\n");

allBMS = [
    "V_filtered"
    "I_filtered"
    "T_filtered"
    "SOC_estimated"
    "SOH_estimated"
    "OverVoltage"
    "UnderVoltage"
    "ChargeOverCurrent"
    "DischargeOverCurrent"
    "OverTemperature"
    "UnderTemperature"
    "Fault"
    "Fault_Code"
    "Charge_Allowed"
    "Discharge_Allowed"
    "I_charge_limit"
    "I_discharge_limit"
    "I_safe_command"
    "Emergency_Shutdown"
    "BMS_State"
    "BMS_Ready"
    "BMS_Fault"
];

entityPass = true;

for k = 1:numel(allBMS)

    [data,ok] = getSignal(out,allBMS(k));

    if ok && ~isempty(data) && all(isfinite(data))

        fprintf("PASS   %s\n",allBMS(k));

    else

        fprintf("FAIL   %s\n",allBMS(k));

        entityPass = false;

    end

end

%% ========================================================================
% STATE ANALYSIS
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("10. BMS STATE ANALYSIS\n");
fprintf("--------------------------------------------------------------------");

[stateData,stateOK] = getSignal(out,"BMS_State");

if stateOK && ~isempty(stateData)

    stateData = round(stateData(:));

    uniqueStates = unique(stateData);

    fprintf("\n\nStates observed during full simulation:\n");

    for k = 1:numel(uniqueStates)

        state = uniqueStates(k);

        switch state

            case 0
                name = "INIT";

            case 1
                name = "NORMAL";

            case 2
                name = "LIMITED";

            case 3
                name = "FAULT";

            case 4
                name = "SHUTDOWN";

            otherwise
                name = "UNKNOWN";

        end

        fprintf("  State %d = %s\n",state,name);

    end

else

    fprintf("\nBMS_State unavailable.\n");

end

%% ========================================================================
% STATE LOGIC ANALYSIS
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("11. BMS STATE LOGIC CONSISTENCY\n");
fprintf("--------------------------------------------------------------------\n");

fprintf("\nChecking state priority and reachable states...\n");

if stateOK

    [faultData,faultOK] = getSignal(out,"Fault");
    [emergencyData,emergencyOK] = ...
        getSignal(out,"Emergency_Shutdown");
    [readyData,readyOK] = getSignal(out,"BMS_Ready");

    if faultOK && emergencyOK && readyOK

        faultData = logical(round(faultData(:)));
        emergencyData = logical(round(emergencyData(:)));
        readyData = logical(round(readyData(:)));
        stateData = round(stateData(:));

        n = min([
            numel(faultData)
            numel(emergencyData)
            numel(readyData)
            numel(stateData)
        ]);

        faultData = faultData(1:n);
        emergencyData = emergencyData(1:n);
        readyData = readyData(1:n);
        stateData = stateData(1:n);

        expectedState = zeros(n,1);

        for k = 1:n

            if emergencyData(k)

                expectedState(k) = 4;

            elseif faultData(k)

                expectedState(k) = 3;

            elseif ~readyData(k)

                expectedState(k) = 0;

            else

                expectedState(k) = 1;

            end

        end

        mismatch = stateData ~= expectedState;

        if ~any(mismatch)

            fprintf("PASS: State priority is internally consistent.\n");

        else

            fprintf("FAIL: BMS_State does not match its defined priority.\n");
            fprintf("Mismatches: %d\n",sum(mismatch));

        end

    end

end

%% ========================================================================
% REACHABILITY CHECK
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("12. STATE REACHABILITY CHECK\n");
fprintf("--------------------------------------------------------------------\n");

fprintf("\n");

fprintf("Expected state codes:\n");
fprintf("  0 = INIT\n");
fprintf("  1 = NORMAL\n");
fprintf("  2 = LIMITED\n");
fprintf("  3 = FAULT\n");
fprintf("  4 = SHUTDOWN\n");

fprintf("\n");

if stateOK

    observed = unique(round(stateData));

    for state = 0:4

        if ismember(state,observed)

            fprintf("OBSERVED  State %d\n",state);

        else

            fprintf("NOT OBSERVED State %d\n",state);

        end

    end

end

%% ========================================================================
% IMPORTANT LOGIC CHECK
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("13. STATE ARCHITECTURE CHECK\n");
fprintf("--------------------------------------------------------------------\n");

fprintf("\n");

fprintf("Current BMS_Ready logic is:\n");
fprintf("  BMS_Ready = NOT(Fault) AND NOT(Emergency_Shutdown)\n");

fprintf("\n");

fprintf("Therefore INIT (State 0) is not normally reachable from\n");
fprintf("the current combinational logic because:\n\n");

fprintf("  BMS_Ready = 0 occurs when Fault or Emergency_Shutdown = 1,\n");
fprintf("  but those conditions are checked before the INIT condition.\n");

fprintf("\n");

fprintf("Also verify whether your BMS_Control currently implements:\n");
fprintf("  Emergency_Shutdown = Fault\n");

fprintf("\n");

fprintf("If that is true, FAULT (State 3) will be immediately\n");
fprintf("overridden by SHUTDOWN (State 4).\n");

%% ========================================================================
% CURRENT LIMIT VALIDATION
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("14. CURRENT LIMIT VALIDATION\n");
fprintf("--------------------------------------------------------------------\n");

[iCommand,cmdOK] = getSignal(out,"I_command");

[iSafe,safeOK] = getSignal(out,"I_safe_command");

[iChargeLimit,chargeLimitOK] = ...
    getSignal(out,"I_charge_limit");

[iDischargeLimit,dischargeLimitOK] = ...
    getSignal(out,"I_discharge_limit");

if cmdOK && safeOK

    iCommand = iCommand(:);
    iSafe = iSafe(:);

    n = min(numel(iCommand),numel(iSafe));

    iCommand = iCommand(1:n);
    iSafe = iSafe(1:n);

    fprintf("Command samples: %d\n",n);

    if all(isfinite(iSafe))

        fprintf("PASS: I_safe_command contains finite values.\n");

    else

        fprintf("FAIL: I_safe_command contains invalid values.\n");

    end

else

    fprintf("I_command or I_safe_command unavailable.\n");

end

if chargeLimitOK

    fprintf("PASS: I_charge_limit available.\n");
end

if dischargeLimitOK

    fprintf("PASS: I_discharge_limit available.\n");
end

%% ========================================================================
% PHYSICAL BATTERY SAFETY CHECK
% ========================================================================

fprintf("\n");
fprintf("--------------------------------------------------------------------\n");
fprintf("15. PHYSICAL BATTERY SAFETY CHECK\n");
fprintf("--------------------------------------------------------------------\n");

[vData,vOK] = getSignal(out,"V_battery");
[tData,tOK] = getSignal(out,"T_battery");

if vOK

    fprintf("Voltage range: %.4f V to %.4f V\n", ...
        min(vData),max(vData));

end

if tOK

    fprintf("Temperature range: %.4f C to %.4f C\n", ...
        min(tData),max(tData));

end

%% ========================================================================
% SAVE TEST RESULT
% ========================================================================

resultsDir = fullfile( ...
    projectRoot, ...
    "Results", ...
    "BMS_Test");

if ~isfolder(resultsDir)

    mkdir(resultsDir);

end

resultFile = fullfile( ...
    resultsDir, ...
    "complete_bms_test.mat");

save(resultFile, ...
    "out", ...
    "Battery", ...
    "I_input", ...
    "T_ambient_input");

fprintf("\n");
fprintf("Test results saved to:\n");
fprintf("%s\n",resultFile);

%% ========================================================================
% FINAL SUMMARY
% ========================================================================

fprintf("\n");
fprintf("====================================================================\n");
fprintf("                    FINAL TEST SUMMARY\n");
fprintf("====================================================================\n");

fprintf("\n");
fprintf("Physical battery : TESTED\n");
fprintf("Sensors          : TESTED\n");
fprintf("Measurement      : TESTED\n");
fprintf("State estimation : TESTED\n");
fprintf("Protection       : TESTED\n");
fprintf("Limits           : TESTED\n");
fprintf("BMS control      : TESTED\n");
fprintf("BMS status       : TESTED\n");
fprintf("BMS entities     : TESTED\n");
fprintf("BMS states       : ANALYZED\n");

fprintf("\n");
fprintf("IMPORTANT: A state being 'not observed' does not automatically\n");
fprintf("mean the model is wrong. It may mean that the current architecture\n");
fprintf("does not provide a physical condition capable of reaching that state.\n");

fprintf("\n");
fprintf("====================================================================\n");


%% =========================================================================
% LOCAL FUNCTION
% =========================================================================

function [data,ok] = getSignal(out,name)

data = [];
ok = false;

name = char(name);

%% ------------------------------------------------------------------------
% Direct SimulationOutput field
% -------------------------------------------------------------------------

try

    if isprop(out,name)

        value = out.(name);

        data = extractData(value);

        if ~isempty(data)

            ok = true;
            return;

        end

    end

catch
end

%% ------------------------------------------------------------------------
% Check SimulationOutput variables
% -------------------------------------------------------------------------

try

    names = out.who;

    for k = 1:numel(names)

        if strcmp(names{k},name)

            value = out.(names{k});

            data = extractData(value);

            if ~isempty(data)

                ok = true;
                return;

            end

        end

    end

catch
end

%% ------------------------------------------------------------------------
% Check yout
% -------------------------------------------------------------------------

try

    if isprop(out,"yout")

        yout = out.yout;

        if isa(yout,"Simulink.SimulationData.Dataset")

            element = yout.getElement(name);

            if ~isempty(element)

                data = extractData(element.Values);

                if ~isempty(data)

                    ok = true;
                    return;

                end

            end

        end

    end

catch
end

end


%% =========================================================================
% EXTRACT NUMERIC DATA
% =========================================================================

function data = extractData(value)

data = [];

try

    if isa(value,"timeseries")

        data = value.Data;

    elseif isnumeric(value)

        data = value;

    elseif islogical(value)

        data = double(value);

    elseif isa(value,"Simulink.SimulationData.Signal")

        data = value.Values.Data;

    elseif isa(value,"Simulink.SimulationData.Dataset")

        if value.numElements > 0

            element = value.getElement(1);

            data = extractData(element.Values);

        end

    elseif isstruct(value)

        if isfield(value,"Data")

            data = value.Data;

        elseif isfield(value,"signals")

            if isfield(value.signals,"values")

                data = value.signals.values;

            end

        end

    end

catch

    data = [];

end

if ~isempty(data)

    data = squeeze(data);

end

end