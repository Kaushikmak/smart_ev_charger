%% =========================================================================
% plot_complete_results.m
%
% Complete plotting script for Battery Digital Twin + BMS simulation
%
% Requirements:
%   1. Run the Simulink model first:
%         out = sim("Battery_Digital_Twin");
%
%   2. The simulation output variable must be named "out".
%
% The script generates:
%   01 - Current
%   02 - Voltage
%   03 - Temperature
%   04 - SOC
%   05 - SOH
%   06 - Available Capacity
%   07 - Internal Resistance
%   08 - Ah Throughput
%   09 - BMS State
%   10 - Fault Code
%   11 - Protection Signals
%   12 - BMS Current Control
%   13 - Charge/Discharge Permissions
%   14 - BMS Readiness/Fault
%   15 - SOC + Temperature
%   16 - Complete Battery Overview
%
% All figures are displayed and optionally saved.
%% =========================================================================

clc;

fprintf('\n');
fprintf('============================================================\n');
fprintf('   BATTERY DIGITAL TWIN + BMS RESULTS PLOTTING\n');
fprintf('============================================================\n');

%% ------------------------------------------------------------------------
% CHECK SIMULATION OUTPUT
% -------------------------------------------------------------------------

if ~exist("out","var")
    error(['Simulation output "out" was not found in the workspace.' newline ...
           'Run the Simulink model first:' newline ...
           '    out = sim("Battery_Digital_Twin");']);
end

fprintf('\nSimulation output found.\n');

%% ------------------------------------------------------------------------
% OUTPUT DIRECTORY
% -------------------------------------------------------------------------

projectRoot = fileparts(fileparts(mfilename("fullpath")));

resultsDir = fullfile(projectRoot,"Results","Complete_Run");
plotsDir   = fullfile(resultsDir,"plots");

if ~exist(resultsDir,"dir")
    mkdir(resultsDir);
end

if ~exist(plotsDir,"dir")
    mkdir(plotsDir);
end

fprintf("Plots will be saved to:\n%s\n\n",plotsDir);

%% ------------------------------------------------------------------------
% HELPER FUNCTION
% -------------------------------------------------------------------------
% This function converts common Simulink output formats into vectors.

getData = @(x) extract_signal(x);

%% ------------------------------------------------------------------------
% EXTRACT SIGNALS
% -------------------------------------------------------------------------

% Time
if isprop(out,"tout")
    t = out.tout;
else
    t = [];
end

% Physical battery
V_battery = getData(out.V_battery);
I_battery = getData(out.I_battery);
T_battery = getData(out.T_battery);

SOC_true  = getData(out.SOC_true);
SOH_true  = getData(out.SOH_true);

% Estimated states
SOC_estimated = getData(out.SOC_estimated);
SOH_estimated = getData(out.SOH_estimated);

% Battery aging
Q_available = getData(out.Q_available);
R0_current  = getData(out.R0_current);
Ah_throughput = getData(out.Ah_throughput);

% BMS measurements
V_filtered = getData(out.V_filtered);
I_filtered = getData(out.I_filtered);
T_filtered = getData(out.T_filtered);

% BMS current control
I_safe_command = getData(out.I_safe_command);

% BMS permissions
Charge_Allowed = getData(out.Charge_Allowed);
Discharge_Allowed = getData(out.Discharge_Allowed);

I_charge_limit = getData(out.I_charge_limit);
I_discharge_limit = getData(out.I_discharge_limit);

% BMS states
BMS_State = getData(out.BMS_State);
BMS_Ready = getData(out.BMS_Ready);
BMS_Fault = getData(out.BMS_Fault);

% Fault/protection
Fault = getData(out.Fault);
Fault_Code = getData(out.Fault_Code);
Emergency_Shutdown = getData(out.Emergency_Shutdown);

OverVoltage = getData(out.OverVoltage);
UnderVoltage = getData(out.UnderVoltage);

ChargeOverCurrent = getData(out.ChargeOverCurrent);
DischargeOverCurrent = getData(out.DischargeOverCurrent);

OverTemperature = getData(out.OverTemperature);
UnderTemperature = getData(out.UnderTemperature);

%% ------------------------------------------------------------------------
% FIX TIME VECTORS FOR DIFFERENT SAMPLE RATES
% -------------------------------------------------------------------------

if isempty(t)

    if ~isempty(V_battery)
        t = (0:length(V_battery)-1)';
    else
        error("No usable time vector found.");
    end

end

t = t(:);

fprintf("Simulation time: %.2f s\n",t(end));
fprintf("Number of simulation samples: %d\n\n",length(t));

%% ------------------------------------------------------------------------
% FIGURE 1 - BATTERY CURRENT
% -------------------------------------------------------------------------

figure("Name","01 - Battery Current","NumberTitle","off");

plot_signal(t,I_battery,"Battery Current");

grid on;

xlabel("Time (s)");
ylabel("Current (A)");
title("Battery Current");

saveas(gcf,fullfile(plotsDir,"01_Battery_Current.png"));

%% ------------------------------------------------------------------------
% FIGURE 2 - BATTERY VOLTAGE
% -------------------------------------------------------------------------

figure("Name","02 - Battery Voltage","NumberTitle","off");

plot_signal(t,V_battery,"Battery Voltage");

grid on;

xlabel("Time (s)");
ylabel("Voltage (V)");
title("Battery Terminal Voltage");

saveas(gcf,fullfile(plotsDir,"02_Battery_Voltage.png"));

%% ------------------------------------------------------------------------
% FIGURE 3 - TEMPERATURE
% -------------------------------------------------------------------------

figure("Name","03 - Temperature","NumberTitle","off");

plot_signal(t,T_battery,"Battery Temperature");
hold on;

plot_signal(t,T_filtered,"Filtered Temperature");

grid on;

xlabel("Time (s)");
ylabel("Temperature (°C)");
title("Battery Temperature");

legend("Battery Temperature","Filtered Temperature","Location","best");

saveas(gcf,fullfile(plotsDir,"03_Temperature.png"));

%% ------------------------------------------------------------------------
% FIGURE 4 - SOC TRUE VS ESTIMATED
% -------------------------------------------------------------------------

figure("Name","04 - SOC Estimation","NumberTitle","off");

plot_signal(t,SOC_true,"True SOC");
hold on;

plot_signal(t,SOC_estimated,"Estimated SOC");

grid on;

xlabel("Time (s)");
ylabel("SOC");
title("State of Charge Estimation");

legend("True SOC","Estimated SOC","Location","best");

ylim([0 1]);

saveas(gcf,fullfile(plotsDir,"04_SOC_Estimation.png"));

%% ------------------------------------------------------------------------
% FIGURE 5 - SOH TRUE VS ESTIMATED
% -------------------------------------------------------------------------

figure("Name","05 - SOH Estimation","NumberTitle","off");

plot_signal(t,SOH_true,"True SOH");
hold on;

plot_signal(t,SOH_estimated,"Estimated SOH");

grid on;

xlabel("Time (s)");
ylabel("SOH");
title("State of Health Estimation");

legend("True SOH","Estimated SOH","Location","best");

ylim([0.9 1.01]);

saveas(gcf,fullfile(plotsDir,"05_SOH_Estimation.png"));

%% ------------------------------------------------------------------------
% FIGURE 6 - AVAILABLE CAPACITY
% -------------------------------------------------------------------------

figure("Name","06 - Available Capacity","NumberTitle","off");

plot_signal(t,Q_available,"Available Capacity");

grid on;

xlabel("Time (s)");
ylabel("Capacity (Ah)");
title("Available Battery Capacity");

saveas(gcf,fullfile(plotsDir,"06_Available_Capacity.png"));

%% ------------------------------------------------------------------------
% FIGURE 7 - INTERNAL RESISTANCE
% -------------------------------------------------------------------------

figure("Name","07 - Internal Resistance","NumberTitle","off");

plot_signal(t,R0_current,"Dynamic R0");

grid on;

xlabel("Time (s)");
ylabel("Resistance (Ω)");
title("Dynamic Internal Resistance");

saveas(gcf,fullfile(plotsDir,"07_Internal_Resistance.png"));

%% ------------------------------------------------------------------------
% FIGURE 8 - AH THROUGHPUT
% -------------------------------------------------------------------------

figure("Name","08 - Ah Throughput","NumberTitle","off");

plot_signal(t,Ah_throughput,"Ah Throughput");

grid on;

xlabel("Time (s)");
ylabel("Throughput (Ah)");
title("Cumulative Ah Throughput");

saveas(gcf,fullfile(plotsDir,"08_Ah_Throughput.png"));

%% ------------------------------------------------------------------------
% FIGURE 9 - BMS STATE
% -------------------------------------------------------------------------

figure("Name","09 - BMS State","NumberTitle","off");

stairs(t,BMS_State);

grid on;

xlabel("Time (s)");
ylabel("BMS State");
title("BMS Operating State");

yticks([0 1 2 3 4]);

yticklabels({ ...
    "INIT", ...
    "NORMAL", ...
    "LIMITED", ...
    "FAULT", ...
    "EMERGENCY"});

saveas(gcf,fullfile(plotsDir,"09_BMS_State.png"));

%% ------------------------------------------------------------------------
% FIGURE 10 - FAULT CODE
% -------------------------------------------------------------------------

figure("Name","10 - Fault Code","NumberTitle","off");

stairs(t,Fault_Code);

grid on;

xlabel("Time (s)");
ylabel("Fault Code");
title("BMS Fault Code");

saveas(gcf,fullfile(plotsDir,"10_Fault_Code.png"));

%% ------------------------------------------------------------------------
% FIGURE 11 - PROTECTION SIGNALS
% -------------------------------------------------------------------------

figure("Name","11 - Protection Signals","NumberTitle","off");

subplot(3,2,1);
stairs(t,OverVoltage);
grid on;
title("Over Voltage");
xlabel("Time (s)");
ylabel("Fault");

subplot(3,2,2);
stairs(t,UnderVoltage);
grid on;
title("Under Voltage");
xlabel("Time (s)");
ylabel("Fault");

subplot(3,2,3);
stairs(t,ChargeOverCurrent);
grid on;
title("Charge Over Current");
xlabel("Time (s)");
ylabel("Fault");

subplot(3,2,4);
stairs(t,DischargeOverCurrent);
grid on;
title("Discharge Over Current");
xlabel("Time (s)");
ylabel("Fault");

subplot(3,2,5);
stairs(t,OverTemperature);
grid on;
title("Over Temperature");
xlabel("Time (s)");
ylabel("Fault");

subplot(3,2,6);
stairs(t,UnderTemperature);
grid on;
title("Under Temperature");
xlabel("Time (s)");
ylabel("Fault");

sgtitle("BMS Protection Signals");

saveas(gcf,fullfile(plotsDir,"11_Protection_Signals.png"));

%% ------------------------------------------------------------------------
% FIGURE 12 - CURRENT CONTROL
% -------------------------------------------------------------------------

figure("Name","12 - BMS Current Control","NumberTitle","off");

plot_signal(t,I_safe_command,"Safe Command");
hold on;

plot_signal(t,I_battery,"Battery Current");

grid on;

xlabel("Time (s)");
ylabel("Current (A)");
title("BMS Current Command vs Battery Current");

legend( ...
    "BMS Safe Command", ...
    "Actual Battery Current", ...
    "Location","best");

saveas(gcf,fullfile(plotsDir,"12_BMS_Current_Control.png"));

%% ------------------------------------------------------------------------
% FIGURE 13 - REQUESTED VS SAFE VS ACTUAL CURRENT
% -------------------------------------------------------------------------

figure("Name","13 - Current Control Comparison","NumberTitle","off");

if exist("I_input","var")

    I_requested = I_input.Data;

    plot(I_input.Time,I_requested);
    hold on;

else

    I_requested = [];

end

plot_signal(t,I_safe_command,"Safe Command");
plot_signal(t,I_battery,"Battery Current");

grid on;

xlabel("Time (s)");
ylabel("Current (A)");
title("Requested vs Safe vs Actual Battery Current");

if ~isempty(I_requested)

    legend( ...
        "Requested Current", ...
        "Safe Current", ...
        "Actual Battery Current", ...
        "Location","best");

else

    legend( ...
        "Safe Current", ...
        "Actual Battery Current", ...
        "Location","best");

end

saveas(gcf,fullfile(plotsDir,"13_Current_Command_Comparison.png"));

%% ------------------------------------------------------------------------
% FIGURE 14 - BMS STATUS
% -------------------------------------------------------------------------

figure("Name","14 - BMS Status","NumberTitle","off");

subplot(3,1,1);

stairs(t,BMS_Ready);

grid on;

ylabel("Ready");
title("BMS Ready");

subplot(3,1,2);

stairs(t,BMS_Fault);

grid on;

ylabel("Fault");
title("BMS Fault");

subplot(3,1,3);

stairs(t,Emergency_Shutdown);

grid on;

xlabel("Time (s)");
ylabel("Shutdown");
title("Emergency Shutdown");

sgtitle("BMS Status");

saveas(gcf,fullfile(plotsDir,"14_BMS_Status.png"));

%% ------------------------------------------------------------------------
% FIGURE 15 - SOC + TEMPERATURE
% -------------------------------------------------------------------------

figure("Name","15 - SOC and Temperature","NumberTitle","off");

yyaxis left

plot_signal(t,SOC_true,"SOC");

ylabel("SOC");
ylim([0 1]);

yyaxis right

plot_signal(t,T_battery,"Temperature");

ylabel("Temperature (°C)");

grid on;

xlabel("Time (s)");
title("Battery SOC and Temperature");

saveas(gcf,fullfile(plotsDir,"15_SOC_Temperature.png"));

%% ------------------------------------------------------------------------
% FIGURE 16 - COMPLETE BATTERY OVERVIEW
% -------------------------------------------------------------------------

figure("Name","16 - Complete Battery Overview","NumberTitle","off");

subplot(4,1,1);

plot_signal(t,V_battery,"Voltage");

ylabel("Voltage (V)");
grid on;
title("Battery Voltage");

subplot(4,1,2);

plot_signal(t,I_battery,"Current");

ylabel("Current (A)");
grid on;
title("Battery Current");

subplot(4,1,3);

plot_signal(t,SOC_true,"SOC");
hold on;
plot_signal(t,SOC_estimated,"SOC Estimate");

ylabel("SOC");
grid on;
legend("True","Estimated","Location","best");
title("State of Charge");

subplot(4,1,4);

plot_signal(t,T_battery,"Temperature");

ylabel("Temperature (°C)");
xlabel("Time (s)");
grid on;
title("Battery Temperature");

sgtitle("Complete Battery Digital Twin + BMS Overview");

saveas(gcf,fullfile(plotsDir,"16_Complete_Overview.png"));

%% ------------------------------------------------------------------------
% NUMERICAL SUMMARY
% -------------------------------------------------------------------------

fprintf('\n');
fprintf('============================================================\n');
fprintf('                 SIMULATION SUMMARY\n');
fprintf('============================================================\n');

fprintf('\nBATTERY:\n');

fprintf("Initial Voltage       : %.4f V\n",V_battery(1));
fprintf("Final Voltage         : %.4f V\n",V_battery(end));

fprintf("Initial SOC           : %.6f\n",SOC_true(1));
fprintf("Final SOC             : %.6f\n",SOC_true(end));

fprintf("Initial SOH           : %.6f\n",SOH_true(1));
fprintf("Final SOH             : %.6f\n",SOH_true(end));

fprintf("Minimum Temperature   : %.3f °C\n",min(T_battery));
fprintf("Maximum Temperature   : %.3f °C\n",max(T_battery));

fprintf("Minimum Current       : %.3f A\n",min(I_battery));
fprintf("Maximum Current       : %.3f A\n",max(I_battery));

fprintf("Final Available Cap. : %.6f Ah\n",Q_available(end));

fprintf("Final R0              : %.6f Ω\n",R0_current(end));

fprintf("Ah Throughput        : %.6f Ah\n",Ah_throughput(end));

%% ------------------------------------------------------------------------
% BMS SUMMARY
% -------------------------------------------------------------------------

fprintf('\nBMS:\n');

fprintf("Fault samples        : %d\n",nnz(Fault));
fprintf("Emergency samples    : %d\n",nnz(Emergency_Shutdown));

fprintf("\nProtection events:\n");

fprintf("Over Voltage         : %d\n",nnz(OverVoltage));
fprintf("Under Voltage        : %d\n",nnz(UnderVoltage));

fprintf("Charge Over Current  : %d\n",nnz(ChargeOverCurrent));
fprintf("Discharge Over Current : %d\n",nnz(DischargeOverCurrent));

fprintf("Over Temperature     : %d\n",nnz(OverTemperature));
fprintf("Under Temperature    : %d\n",nnz(UnderTemperature));

fprintf("\nCurrent control:\n");

fprintf("Maximum |I_safe - I_battery| = %.6f A\n", ...
    calculate_current_error(I_safe_command,I_battery));

fprintf('\n');
fprintf('============================================================\n');
fprintf('Plots saved to:\n%s\n',plotsDir);
fprintf('============================================================\n');

%% ------------------------------------------------------------------------
% LOCAL FUNCTIONS
% -------------------------------------------------------------------------

function data = extract_signal(signal)

    if isa(signal,"timeseries")

        data = squeeze(signal.Data);

    elseif istimetable(signal)

        data = signal.Variables;

    elseif isstruct(signal)

        if isfield(signal,"signals")

            data = signal.signals.values;

        elseif isfield(signal,"Data")

            data = signal.Data;

        else

            error("Unsupported structure signal format.");

        end

    else

        data = signal;

    end

    data = squeeze(data);
    data = data(:);

end


function plot_signal(t,data,label)

    data = data(:);

    % Handle different signal lengths gracefully.
    if length(data) ~= length(t)

        n = min(length(data),length(t));

        plot(t(1:n),data(1:n),"DisplayName",label);

    else

        plot(t,data,"DisplayName",label);

    end

    hold on;

end


function err = calculate_current_error(a,b)

    n = min(length(a),length(b));

    err = max(abs(a(1:n)-b(1:n)));

end