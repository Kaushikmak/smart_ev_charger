%% =========================================================================
% build_bms_state.m
%
% Creates the complete 06_BMS_Status subsystem automatically.
%
% BMS STATE CODES
%   0 = INIT
%   1 = NORMAL
%   2 = LIMITED
%   3 = FAULT
%   4 = SHUTDOWN
%
% =========================================================================

clc;

fprintf("\n");
fprintf("============================================================\n");
fprintf("              BMS STATUS AUTO BUILDER\n");
fprintf("============================================================\n");

%% ========================================================================
% MODEL NAME
% ========================================================================

modelName = "BMS_Status_AutoBuild";

modelFile = fullfile(pwd, modelName + ".slx");

%% ========================================================================
% CLOSE EXISTING MODEL
% ========================================================================

if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

%% ========================================================================
% DELETE OLD MODEL FILE
% ========================================================================

if isfile(modelFile)
    delete(modelFile);
end

%% ========================================================================
% CREATE NEW MODEL
% ========================================================================

new_system(modelName);
open_system(modelName);

%% ========================================================================
% CREATE 06_BMS_STATUS SUBSYSTEM
% ========================================================================

subsystemPath = modelName + "/06_BMS_Status";

add_block( ...
    "simulink/Ports & Subsystems/Subsystem", ...
    subsystemPath, ...
    "Position", [200 100 900 600]);

open_system(subsystemPath);

%% ========================================================================
% DELETE DEFAULT CONTENTS
% ========================================================================

blocks = find_system( ...
    subsystemPath, ...
    "SearchDepth", 1, ...
    "Type", "Block");

for k = 1:numel(blocks)

    blockName = get_param(blocks{k}, "Name");

    if ~strcmp(blockName, "06_BMS_Status")

        try
            delete_block(blocks{k});
        catch
        end

    end

end

%% ========================================================================
% INPUTS
% ========================================================================

inputNames = [
    "Fault"
    "Fault_Code"
    "Charge_Allowed"
    "Discharge_Allowed"
    "SOC_estimated"
    "SOH_estimated"
    "I_charge_limit"
    "I_discharge_limit"
    "Emergency_Shutdown"
    "T_filtered"
];

inputY = [
     40
     90
    140
    190
    240
    290
    340
    390
    440
    490
];

%% ========================================================================
% CREATE INPUT PORTS
% ========================================================================

for k = 1:numel(inputNames)

    add_block( ...
        "simulink/Ports & Subsystems/In1", ...
        subsystemPath + "/" + inputNames(k), ...
        "Position", ...
        [30 inputY(k) 100 inputY(k)+30], ...
        "Port", num2str(k));

end

%% ========================================================================
% OUTPUTS
%
% 1 = BMS_State
% 2 = BMS_Ready
% 3 = BMS_Fault
% ========================================================================

add_block( ...
    "simulink/Ports & Subsystems/Out1", ...
    subsystemPath + "/BMS_State", ...
    "Position", [850 470 920 500], ...
    "Port", "1");

add_block( ...
    "simulink/Ports & Subsystems/Out1", ...
    subsystemPath + "/BMS_Ready", ...
    "Position", [850 300 920 330], ...
    "Port", "2");

add_block( ...
    "simulink/Ports & Subsystems/Out1", ...
    subsystemPath + "/BMS_Fault", ...
    "Position", [850 125 920 155], ...
    "Port", "3");

%% ========================================================================
% BMS FAULT
%
% Fault directly becomes BMS_Fault.
% ========================================================================

add_line( ...
    subsystemPath, ...
    "Fault/1", ...
    "BMS_Fault/1", ...
    "autorouting", "on");

%% ========================================================================
% SOH LIMIT CHECK
%
% SOH_estimated < 0.95
% ========================================================================

add_block( ...
    "simulink/Logic and Bit Operations/Relational Operator", ...
    subsystemPath + "/SOH_Limit_Check", ...
    "Position", [300 210 370 250]);

set_param( ...
    subsystemPath + "/SOH_Limit_Check", ...
    "Operator", "<");

%% ========================================================================
% SOH THRESHOLD
% ========================================================================

add_block( ...
    "simulink/Sources/Constant", ...
    subsystemPath + "/SOH_Threshold", ...
    "Position", [180 260 240 290], ...
    "Value", "0.95");

%% ========================================================================
% CONNECT SOH CHECK
% ========================================================================

add_line( ...
    subsystemPath, ...
    "SOH_estimated/1", ...
    "SOH_Limit_Check/1", ...
    "autorouting", "on");

add_line( ...
    subsystemPath, ...
    "SOH_Threshold/1", ...
    "SOH_Limit_Check/2", ...
    "autorouting", "on");

%% ========================================================================
% TEMPERATURE LIMIT CHECK
%
% T_filtered > 35
% ========================================================================

add_block( ...
    "simulink/Logic and Bit Operations/Relational Operator", ...
    subsystemPath + "/Temperature_Limit_Check", ...
    "Position", [300 330 370 370]);

set_param( ...
    subsystemPath + "/Temperature_Limit_Check", ...
    "Operator", ">");

%% ========================================================================
% TEMPERATURE THRESHOLD
% ========================================================================

add_block( ...
    "simulink/Sources/Constant", ...
    subsystemPath + "/Temperature_Threshold", ...
    "Position", [180 380 240 410], ...
    "Value", "35");

%% ========================================================================
% CONNECT TEMPERATURE CHECK
% ========================================================================

add_line( ...
    subsystemPath, ...
    "T_filtered/1", ...
    "Temperature_Limit_Check/1", ...
    "autorouting", "on");

add_line( ...
    subsystemPath, ...
    "Temperature_Threshold/1", ...
    "Temperature_Limit_Check/2", ...
    "autorouting", "on");

%% ========================================================================
% LIMITED REQUEST OR
%
% SOH_Limited OR Temperature_Limited
% ========================================================================

add_block( ...
    "simulink/Logic and Bit Operations/Logical Operator", ...
    subsystemPath + "/Limited_Request_OR", ...
    "Position", [430 260 500 330]);

set_param( ...
    subsystemPath + "/Limited_Request_OR", ...
    "Operator", "OR", ...
    "Inputs", "2");

%% ========================================================================
% CONNECT LIMITED REQUEST OR
% ========================================================================

add_line( ...
    subsystemPath, ...
    "SOH_Limit_Check/1", ...
    "Limited_Request_OR/1", ...
    "autorouting", "on");

add_line( ...
    subsystemPath, ...
    "Temperature_Limit_Check/1", ...
    "Limited_Request_OR/2", ...
    "autorouting", "on");

%% ========================================================================
% NOT FAULT
% ========================================================================

add_block( ...
    "simulink/Logic and Bit Operations/Logical Operator", ...
    subsystemPath + "/NOT_Fault", ...
    "Position", [420 100 490 140]);

set_param( ...
    subsystemPath + "/NOT_Fault", ...
    "Operator", "NOT");

%% ========================================================================
% NOT EMERGENCY SHUTDOWN
% ========================================================================

add_block( ...
    "simulink/Logic and Bit Operations/Logical Operator", ...
    subsystemPath + "/NOT_Emergency", ...
    "Position", [420 160 490 200]);

set_param( ...
    subsystemPath + "/NOT_Emergency", ...
    "Operator", "NOT");

%% ========================================================================
% BMS READY AND
%
% NOT Fault AND NOT Emergency_Shutdown
% ========================================================================

add_block( ...
    "simulink/Logic and Bit Operations/Logical Operator", ...
    subsystemPath + "/BMS_Ready_AND", ...
    "Position", [560 120 630 180]);

set_param( ...
    subsystemPath + "/BMS_Ready_AND", ...
    "Operator", "AND", ...
    "Inputs", "2");

%% ========================================================================
% CONNECT NOT FAULT
% ========================================================================

add_line( ...
    subsystemPath, ...
    "Fault/1", ...
    "NOT_Fault/1", ...
    "autorouting", "on");

%% ========================================================================
% CONNECT NOT EMERGENCY
% ========================================================================

add_line( ...
    subsystemPath, ...
    "Emergency_Shutdown/1", ...
    "NOT_Emergency/1", ...
    "autorouting", "on");

%% ========================================================================
% CONNECT READY AND
% ========================================================================

add_line( ...
    subsystemPath, ...
    "NOT_Fault/1", ...
    "BMS_Ready_AND/1", ...
    "autorouting", "on");

add_line( ...
    subsystemPath, ...
    "NOT_Emergency/1", ...
    "BMS_Ready_AND/2", ...
    "autorouting", "on");

%% ========================================================================
% CONNECT BMS READY OUTPUT
% ========================================================================

add_line( ...
    subsystemPath, ...
    "BMS_Ready_AND/1", ...
    "BMS_Ready/1", ...
    "autorouting", "on");

%% ========================================================================
% CREATE MATLAB FUNCTION FOR BMS STATE
% ========================================================================

functionPath = subsystemPath + "/BMS_State_Logic";

add_block( ...
    "simulink/User-Defined Functions/MATLAB Function", ...
    functionPath, ...
    "Position", [650 250 820 400]);

%% ========================================================================
% ACCESS MATLAB FUNCTION CHART
% ========================================================================

rt = sfroot;

chart = rt.find( ...
    "-isa", ...
    "Stateflow.EMChart", ...
    "Path", ...
    char(functionPath));

%% ========================================================================
% MATLAB FUNCTION CODE
% ========================================================================

code = [
    "function BMS_State = fcn(Fault, Emergency_Shutdown, BMS_Ready, Limited_Request)"
    ""
    "% BMS State Codes"
    "% 0 = INIT"
    "% 1 = NORMAL"
    "% 2 = LIMITED"
    "% 3 = FAULT"
    "% 4 = SHUTDOWN"
    ""
    "% Highest priority: Emergency Shutdown"
    "if Emergency_Shutdown"
    "    BMS_State = 4;"
    ""
    "% Protection fault"
    "elseif Fault"
    "    BMS_State = 3;"
    ""
    "% BMS not ready"
    "elseif ~BMS_Ready"
    "    BMS_State = 0;"
    ""
    "% Battery operating under limitation"
    "elseif Limited_Request"
    "    BMS_State = 2;"
    ""
    "% Normal operation"
    "else"
    "    BMS_State = 1;"
    "end"
    ""
    "end"
];

chart.Script = strjoin(code, newline);

%% ========================================================================
% CONNECT FAULT TO STATE FUNCTION
% ========================================================================

add_line( ...
    subsystemPath, ...
    "Fault/1", ...
    "BMS_State_Logic/1", ...
    "autorouting", "on");

%% ========================================================================
% CONNECT EMERGENCY SHUTDOWN TO STATE FUNCTION
% ========================================================================

add_line( ...
    subsystemPath, ...
    "Emergency_Shutdown/1", ...
    "BMS_State_Logic/2", ...
    "autorouting", "on");

%% ========================================================================
% CONNECT BMS READY TO STATE FUNCTION
% ========================================================================

add_line( ...
    subsystemPath, ...
    "BMS_Ready_AND/1", ...
    "BMS_State_Logic/3", ...
    "autorouting", "on");

%% ========================================================================
% CONNECT LIMITED REQUEST TO STATE FUNCTION
% ========================================================================

add_line( ...
    subsystemPath, ...
    "Limited_Request_OR/1", ...
    "BMS_State_Logic/4", ...
    "autorouting", "on");

%% ========================================================================
% CONNECT STATE FUNCTION OUTPUT
% ========================================================================

add_line( ...
    subsystemPath, ...
    "BMS_State_Logic/1", ...
    "BMS_State/1", ...
    "autorouting", "on");

%% ========================================================================
% SAVE MODEL
% ========================================================================

save_system( ...
    modelName, ...
    modelFile);

%% ========================================================================
% DISPLAY RESULT
% ========================================================================

fprintf("\n");
fprintf("BMS STATUS SUBSYSTEM CREATED SUCCESSFULLY.\n");

fprintf("\n");
fprintf("INPUTS:\n");

for k = 1:numel(inputNames)
    fprintf("  %2d = %s\n", k, inputNames(k));
end

fprintf("\n");
fprintf("OUTPUTS:\n");
fprintf("   1 = BMS_State\n");
fprintf("   2 = BMS_Ready\n");
fprintf("   3 = BMS_Fault\n");

fprintf("\n");
fprintf("BMS STATE CODES:\n");
fprintf("   0 = INIT\n");
fprintf("   1 = NORMAL\n");
fprintf("   2 = LIMITED\n");
fprintf("   3 = FAULT\n");
fprintf("   4 = SHUTDOWN\n");

fprintf("\n");
fprintf("LIMITED CONDITION:\n");
fprintf("   SOH_estimated < 0.95\n");
fprintf("             OR\n");
fprintf("   T_filtered > 35 C\n");

fprintf("\n");
fprintf("GENERATED MODEL:\n");
fprintf("   %s\n", modelFile);

fprintf("\n");
fprintf("============================================================\n");