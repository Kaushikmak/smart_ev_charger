%% =========================================================================
% plot_all_battery_results.m
%
% COMPLETE BATTERY DIGITAL TWIN + BMS DIAGNOSTIC PLOTTER
%
% Run AFTER:
%
%     out = sim("Battery_Digital_Twin");
%
% Then:
%
%     run("Validation/plot_all_battery_results.m")
%
% This script generates:
%
%   01  Battery voltage
%   02  Battery current
%   03  Battery temperature
%   04  Voltage measured vs true
%   05  Current measured vs true
%   06  Temperature measured vs true
%   07  Sensor voltage error
%   08  Sensor current error
%   09  Sensor temperature error
%
%   10  SOC true vs estimated
%   11  SOC estimation error
%   12  SOH true vs estimated
%   13  SOH estimation error
%
%   14  Available capacity
%   15  Internal resistance
%   16  Ah throughput
%
%   17  Requested vs safe vs actual current
%   18  Current limiting
%   19  Charge/discharge permissions
%   20  Charge/discharge current limits
%
%   21  BMS state
%   22  BMS state transition timeline
%   23  Fault type timeline
%   24  Fault code
%   25  Fault occurrence summary
%   26  Emergency shutdown
%
%   27  All protection signals
%   28  Protection event timeline
%   29  Protection event count
%
%   30  SOC + temperature
%   31  SOC + SOH
%   32  Voltage + current
%   33  Battery operating envelope
%   34  Complete BMS overview
%   35  Complete battery overview
%
%   36+ Automatic plots for any additional numeric signals
%
% All plots are saved automatically.
%
%% =========================================================================

clc;

fprintf("\n");
fprintf("====================================================================\n");
fprintf("       BATTERY DIGITAL TWIN + BMS COMPLETE DIAGNOSTICS\n");
fprintf("====================================================================\n");

%% =========================================================================
% 1. CHECK SIMULATION OUTPUT
% =========================================================================

if ~exist("out","var")

    error([ ...
        "Simulation output 'out' was not found." newline ...
        "Run the Simulink model first:" newline ...
        "    out = sim(""Battery_Digital_Twin"");" ...
        ]);

end

fprintf("\nSimulation output detected.\n");

%% =========================================================================
% 2. PROJECT / RESULTS DIRECTORIES
% =========================================================================

projectRoot = fileparts(fileparts(mfilename("fullpath")));

resultsDir = fullfile(projectRoot,"Results","Complete_Run");
plotsDir   = fullfile(resultsDir,"plots");

if ~exist(resultsDir,"dir")
    mkdir(resultsDir);
end

if ~exist(plotsDir,"dir")
    mkdir(plotsDir);
end

fprintf("Results directory:\n%s\n",plotsDir);

%% =========================================================================
% 3. EXTRACT MAIN SIGNALS
% =========================================================================

% -------------------------------------------------------------------------
% Physical battery
% -------------------------------------------------------------------------

V_battery = getSignal(out,"V_battery");
I_battery = getSignal(out,"I_battery");
T_battery = getSignal(out,"T_battery");

SOC_true = getSignal(out,"SOC_true");
SOH_true = getSignal(out,"SOH_true");

Q_available = getSignal(out,"Q_available");
R0_current = getSignal(out,"R0_current");
Ah_throughput = getSignal(out,"Ah_throughput");

% -------------------------------------------------------------------------
% Measured signals
% -------------------------------------------------------------------------

V_measured = getSignal(out,"V_battery_measured");
I_measured = getSignal(out,"I_battery_measured");
T_measured = getSignal(out,"T_battery_measured");

% -------------------------------------------------------------------------
% Filtered signals
% -------------------------------------------------------------------------

V_filtered = getSignal(out,"V_filtered");
I_filtered = getSignal(out,"I_filtered");
T_filtered = getSignal(out,"T_filtered");

% -------------------------------------------------------------------------
% Estimated states
% -------------------------------------------------------------------------

SOC_estimated = getSignal(out,"SOC_estimated");
SOH_estimated = getSignal(out,"SOH_estimated");

% -------------------------------------------------------------------------
% BMS control
% -------------------------------------------------------------------------

I_safe_command = getSignal(out,"I_safe_command");

I_charge_limit = getSignal(out,"I_charge_limit");
I_discharge_limit = getSignal(out,"I_discharge_limit");

Charge_Allowed = getSignal(out,"Charge_Allowed");
Discharge_Allowed = getSignal(out,"Discharge_Allowed");

% -------------------------------------------------------------------------
% BMS state
% -------------------------------------------------------------------------

BMS_State = getSignal(out,"BMS_State");
BMS_Ready = getSignal(out,"BMS_Ready");
BMS_Fault = getSignal(out,"BMS_Fault");

% -------------------------------------------------------------------------
% Faults
% -------------------------------------------------------------------------

Fault = getSignal(out,"Fault");
Fault_Code = getSignal(out,"Fault_Code");

Emergency_Shutdown = getSignal(out,"Emergency_Shutdown");

% -------------------------------------------------------------------------
% Protection
% -------------------------------------------------------------------------

OverVoltage = getSignal(out,"OverVoltage");
UnderVoltage = getSignal(out,"UnderVoltage");

ChargeOverCurrent = getSignal(out,"ChargeOverCurrent");
DischargeOverCurrent = getSignal(out,"DischargeOverCurrent");

OverTemperature = getSignal(out,"OverTemperature");
UnderTemperature = getSignal(out,"UnderTemperature");

%% =========================================================================
% 4. DETERMINE TIME VECTOR
% =========================================================================

if isprop(out,"tout")

    t = out.tout;

elseif ~isempty(V_battery)

    t = (0:length(V_battery)-1)' * 0.1;

else

    error("Could not determine simulation time.");

end

t = t(:);

fprintf("Simulation duration : %.3f s\n",t(end));
fprintf("Samples             : %d\n",length(t));

%% =========================================================================
% 5. BATTERY VOLTAGE
% =========================================================================

figure("Name","01 Battery Voltage","NumberTitle","off");

plotAligned(t,V_battery,"Battery Voltage");

hold on;

plotAligned(t,V_filtered,"Filtered Voltage");
plotAligned(t,V_measured,"Measured Voltage");

grid on;

xlabel("Time (s)");
ylabel("Voltage (V)");
title("Battery Voltage");

legend("True Battery Voltage", ...
       "Filtered Voltage", ...
       "Measured Voltage", ...
       "Location","best");

savePlot(plotsDir,"01_Battery_Voltage");

%% =========================================================================
% 6. BATTERY CURRENT
% =========================================================================

figure("Name","02 Battery Current","NumberTitle","off");

plotAligned(t,I_battery,"Battery Current");

hold on;

plotAligned(t,I_filtered,"Filtered Current");
plotAligned(t,I_measured,"Measured Current");

grid on;

xlabel("Time (s)");
ylabel("Current (A)");
title("Battery Current");

legend("True Battery Current", ...
       "Filtered Current", ...
       "Measured Current", ...
       "Location","best");

savePlot(plotsDir,"02_Battery_Current");

%% =========================================================================
% 7. BATTERY TEMPERATURE
% =========================================================================

figure("Name","03 Battery Temperature","NumberTitle","off");

plotAligned(t,T_battery,"Battery Temperature");

hold on;

plotAligned(t,T_filtered,"Filtered Temperature");
plotAligned(t,T_measured,"Measured Temperature");

grid on;

xlabel("Time (s)");
ylabel("Temperature (°C)");
title("Battery Temperature");

legend("True Temperature", ...
       "Filtered Temperature", ...
       "Measured Temperature", ...
       "Location","best");

savePlot(plotsDir,"03_Battery_Temperature");

%% =========================================================================
% 8. VOLTAGE SENSOR VALIDATION
% =========================================================================

figure("Name","04 Voltage Measurement Validation","NumberTitle","off");

plotAligned(t,V_battery,"True");
hold on;

plotAligned(t,V_measured,"Measured");
plotAligned(t,V_filtered,"Filtered");

grid on;

xlabel("Time (s)");
ylabel("Voltage (V)");
title("Voltage Sensor Validation");

legend("True","Measured","Filtered","Location","best");

savePlot(plotsDir,"04_Voltage_Measurement_Validation");

%% =========================================================================
% 9. CURRENT SENSOR VALIDATION
% =========================================================================

figure("Name","05 Current Measurement Validation","NumberTitle","off");

plotAligned(t,I_battery,"True");
hold on;

plotAligned(t,I_measured,"Measured");
plotAligned(t,I_filtered,"Filtered");

grid on;

xlabel("Time (s)");
ylabel("Current (A)");
title("Current Sensor Validation");

legend("True","Measured","Filtered","Location","best");

savePlot(plotsDir,"05_Current_Measurement_Validation");

%% =========================================================================
% 10. TEMPERATURE SENSOR VALIDATION
% =========================================================================

figure("Name","06 Temperature Measurement Validation","NumberTitle","off");

plotAligned(t,T_battery,"True");
hold on;

plotAligned(t,T_measured,"Measured");
plotAligned(t,T_filtered,"Filtered");

grid on;

xlabel("Time (s)");
ylabel("Temperature (°C)");
title("Temperature Sensor Validation");

legend("True","Measured","Filtered","Location","best");

savePlot(plotsDir,"06_Temperature_Measurement_Validation");

%% =========================================================================
% 11. VOLTAGE SENSOR ERROR
% =========================================================================

if ~isempty(V_measured) && ~isempty(V_battery)

    figure("Name","07 Voltage Sensor Error","NumberTitle","off");

    [tt,yy] = alignSignals(t,V_battery,V_measured);

    plot(tt,yy(:,2)-yy(:,1));

    yline(0,"--");

    grid on;

    xlabel("Time (s)");
    ylabel("Error (V)");
    title("Voltage Sensor Error");

    savePlot(plotsDir,"07_Voltage_Sensor_Error");

end

%% =========================================================================
% 12. CURRENT SENSOR ERROR
% =========================================================================

if ~isempty(I_measured) && ~isempty(I_battery)

    figure("Name","08 Current Sensor Error","NumberTitle","off");

    [tt,yy] = alignSignals(t,I_battery,I_measured);

    plot(tt,yy(:,2)-yy(:,1));

    yline(0,"--");

    grid on;

    xlabel("Time (s)");
    ylabel("Error (A)");
    title("Current Sensor Error");

    savePlot(plotsDir,"08_Current_Sensor_Error");

end

%% =========================================================================
% 13. TEMPERATURE SENSOR ERROR
% =========================================================================

if ~isempty(T_measured) && ~isempty(T_battery)

    figure("Name","09 Temperature Sensor Error","NumberTitle","off");

    [tt,yy] = alignSignals(t,T_battery,T_measured);

    plot(tt,yy(:,2)-yy(:,1));

    yline(0,"--");

    grid on;

    xlabel("Time (s)");
    ylabel("Error (°C)");
    title("Temperature Sensor Error");

    savePlot(plotsDir,"09_Temperature_Sensor_Error");

end

%% =========================================================================
% 14. SOC TRUE VS ESTIMATED
% =========================================================================

figure("Name","10 SOC Estimation","NumberTitle","off");

plotAligned(t,SOC_true,"True SOC");

hold on;

plotAligned(t,SOC_estimated,"Estimated SOC");

grid on;

xlabel("Time (s)");
ylabel("SOC");
title("State of Charge Estimation");

legend("True SOC","Estimated SOC","Location","best");

ylim([0 1]);

savePlot(plotsDir,"10_SOC_Estimation");

%% =========================================================================
% 15. SOC ERROR
% =========================================================================

if ~isempty(SOC_estimated) && ~isempty(SOC_true)

    figure("Name","11 SOC Estimation Error","NumberTitle","off");

    [tt,yy] = alignSignals(t,SOC_true,SOC_estimated);

    errorSOC = yy(:,2)-yy(:,1);

    plot(tt,errorSOC);

    yline(0,"--");

    grid on;

    xlabel("Time (s)");
    ylabel("SOC Error");
    title("SOC Estimation Error");

    savePlot(plotsDir,"11_SOC_Estimation_Error");

end

%% =========================================================================
% 16. SOH TRUE VS ESTIMATED
% =========================================================================

figure("Name","12 SOH Estimation","NumberTitle","off");

plotAligned(t,SOH_true,"True SOH");

hold on;

plotAligned(t,SOH_estimated,"Estimated SOH");

grid on;

xlabel("Time (s)");
ylabel("SOH");
title("State of Health Estimation");

legend("True SOH","Estimated SOH","Location","best");

savePlot(plotsDir,"12_SOH_Estimation");

%% =========================================================================
% 17. SOH ERROR
% =========================================================================

if ~isempty(SOH_estimated) && ~isempty(SOH_true)

    figure("Name","13 SOH Estimation Error","NumberTitle","off");

    [tt,yy] = alignSignals(t,SOH_true,SOH_estimated);

    errorSOH = yy(:,2)-yy(:,1);

    plot(tt,errorSOH);

    yline(0,"--");

    grid on;

    xlabel("Time (s)");
    ylabel("SOH Error");
    title("SOH Estimation Error");

    savePlot(plotsDir,"13_SOH_Estimation_Error");

end

%% =========================================================================
% 18. AVAILABLE CAPACITY
% =========================================================================

figure("Name","14 Available Capacity","NumberTitle","off");

plotAligned(t,Q_available,"Available Capacity");

grid on;

xlabel("Time (s)");
ylabel("Capacity (Ah)");
title("Available Battery Capacity");

savePlot(plotsDir,"14_Available_Capacity");

%% =========================================================================
% 19. INTERNAL RESISTANCE
% =========================================================================

figure("Name","15 Dynamic Internal Resistance","NumberTitle","off");

plotAligned(t,R0_current,"R0");

grid on;

xlabel("Time (s)");
ylabel("Resistance (Ω)");
title("Dynamic Internal Resistance");

savePlot(plotsDir,"15_Dynamic_Internal_Resistance");

%% =========================================================================
% 20. AH THROUGHPUT
% =========================================================================

figure("Name","16 Ah Throughput","NumberTitle","off");

plotAligned(t,Ah_throughput,"Ah Throughput");

grid on;

xlabel("Time (s)");
ylabel("Ah");
title("Cumulative Ah Throughput");

savePlot(plotsDir,"16_Ah_Throughput");

%% =========================================================================
% 21. REQUESTED VS SAFE VS ACTUAL CURRENT
% =========================================================================

figure("Name","17 Current Control","NumberTitle","off");

if exist("I_input","var") && isa(I_input,"timeseries")

    plot(I_input.Time,I_input.Data,"DisplayName","Requested Current");

    hold on;

end

plotAligned(t,I_safe_command,"BMS Safe Command");
plotAligned(t,I_battery,"Actual Battery Current");

grid on;

xlabel("Time (s)");
ylabel("Current (A)");
title("BMS Current Control");

legend("Location","best");

savePlot(plotsDir,"17_Current_Control");

%% =========================================================================
% 22. CURRENT LIMITING
% =========================================================================

figure("Name","18 Current Limits","NumberTitle","off");

plotAligned(t,I_safe_command,"Safe Command");

hold on;

plotAligned(t,I_discharge_limit,"Discharge Limit");
plotAligned(t,-I_charge_limit,"Charge Limit");

grid on;

xlabel("Time (s)");
ylabel("Current (A)");
title("BMS Current Limits");

legend("Safe Command", ...
       "Discharge Limit", ...
       "Charge Limit", ...
       "Location","best");

savePlot(plotsDir,"18_Current_Limits");

%% =========================================================================
% 23. CHARGE / DISCHARGE PERMISSIONS
% =========================================================================

figure("Name","19 Charge Discharge Permissions","NumberTitle","off");

subplot(2,1,1);

stairs(t,Charge_Allowed);

ylim([-0.1 1.1]);

grid on;

ylabel("Allowed");
title("Charge Permission");

subplot(2,1,2);

stairs(t,Discharge_Allowed);

ylim([-0.1 1.1]);

grid on;

xlabel("Time (s)");
ylabel("Allowed");
title("Discharge Permission");

sgtitle("BMS Charge / Discharge Permissions");

savePlot(plotsDir,"19_Charge_Discharge_Permissions");

%% =========================================================================
% 24. BMS STATE
% =========================================================================

figure("Name","20 BMS State","NumberTitle","off");

stairs(t,BMS_State);

grid on;

xlabel("Time (s)");
ylabel("State");

yticks([0 1 2 3 4]);

yticklabels({ ...
    "INIT", ...
    "NORMAL", ...
    "LIMITED", ...
    "FAULT", ...
    "EMERGENCY"});

title("BMS Operating State");

savePlot(plotsDir,"20_BMS_State");

%% =========================================================================
% 25. BMS STATE TRANSITIONS
% =========================================================================

figure("Name","21 BMS State Transitions","NumberTitle","off");

stairs(t,BMS_State,"LineWidth",1.5);

grid on;

xlabel("Time (s)");
ylabel("BMS State");

yticks([0 1 2 3 4]);

yticklabels({ ...
    "INIT", ...
    "NORMAL", ...
    "LIMITED", ...
    "FAULT", ...
    "EMERGENCY"});

title("BMS State Transition Timeline");

savePlot(plotsDir,"21_BMS_State_Transitions");

%% =========================================================================
% 26. FAULT TYPE TIMELINE
% =========================================================================
%
% THIS IS THE IMPORTANT ONE.
%
% Instead of showing only:
%
% 0, 1, 2, 3, 4, 5, 6, 7
%
% the Y axis explicitly tells you what each number means.
%
% Fault mapping:
%
% 0 = No Fault
% 1 = Over Voltage
% 2 = Under Voltage
% 3 = Charge Over Current
% 4 = Discharge Over Current
% 5 = Over Temperature
% 6 = Under Temperature
% 7 = Multiple Faults
%
% =========================================================================

figure("Name","22 Fault Type Timeline","NumberTitle","off");

stairs(t,Fault_Code,"LineWidth",1.5);

grid on;

xlabel("Time (s)");
ylabel("Fault Type");

yticks(0:7);

yticklabels({ ...
    "NO FAULT", ...
    "OVER VOLTAGE", ...
    "UNDER VOLTAGE", ...
    "CHARGE OVERCURRENT", ...
    "DISCHARGE OVERCURRENT", ...
    "OVER TEMPERATURE", ...
    "UNDER TEMPERATURE", ...
    "MULTIPLE FAULTS"});

title("BMS Fault Type Timeline");

savePlot(plotsDir,"22_Fault_Type_Timeline");

%% =========================================================================
% 27. FAULT CODE
% =========================================================================

figure("Name","23 Fault Code","NumberTitle","off");

stairs(t,Fault_Code);

grid on;

xlabel("Time (s)");
ylabel("Fault Code");

yticks(0:7);

yticklabels({ ...
    "0 - None", ...
    "1 - OV", ...
    "2 - UV", ...
    "3 - Charge OC", ...
    "4 - Discharge OC", ...
    "5 - OT", ...
    "6 - UT", ...
    "7 - Multiple"});

title("BMS Fault Code");

savePlot(plotsDir,"23_Fault_Code");

%% =========================================================================
% 28. FAULT SIGNAL
% =========================================================================

figure("Name","24 Fault Signal","NumberTitle","off");

stairs(t,Fault,"LineWidth",1.5);

ylim([-0.1 1.1]);

grid on;

xlabel("Time (s)");
ylabel("Fault");
title("BMS Fault Signal");

yticks([0 1]);
yticklabels({"NO FAULT","FAULT"});

savePlot(plotsDir,"24_Fault_Signal");

%% =========================================================================
% 29. EMERGENCY SHUTDOWN
% =========================================================================

figure("Name","25 Emergency Shutdown","NumberTitle","off");

stairs(t,Emergency_Shutdown,"LineWidth",1.5);

ylim([-0.1 1.1]);

grid on;

xlabel("Time (s)");
ylabel("Shutdown");

yticks([0 1]);
yticklabels({"OFF","ACTIVE"});

title("BMS Emergency Shutdown");

savePlot(plotsDir,"25_Emergency_Shutdown");

%% =========================================================================
% 30. ALL PROTECTION SIGNALS
% =========================================================================

figure("Name","26 Protection Signals","NumberTitle","off");

% -------------------------------------------------------------------------
% Over Voltage
% -------------------------------------------------------------------------

subplot(3,2,1);

plotAligned(t,OverVoltage,"Over Voltage");

ylim([-0.1 1.1]);

grid on;

title("Over Voltage");
xlabel("Time (s)");
ylabel("Fault");

% -------------------------------------------------------------------------
% Under Voltage
% -------------------------------------------------------------------------

subplot(3,2,2);

plotAligned(t,UnderVoltage,"Under Voltage");

ylim([-0.1 1.1]);

grid on;

title("Under Voltage");
xlabel("Time (s)");
ylabel("Fault");

% -------------------------------------------------------------------------
% Charge Over Current
% -------------------------------------------------------------------------

subplot(3,2,3);

plotAligned(t,ChargeOverCurrent,"Charge Over Current");

ylim([-0.1 1.1]);

grid on;

title("Charge Over Current");
xlabel("Time (s)");
ylabel("Fault");

% -------------------------------------------------------------------------
% Discharge Over Current
% -------------------------------------------------------------------------

subplot(3,2,4);

plotAligned(t,DischargeOverCurrent,"Discharge Over Current");

ylim([-0.1 1.1]);

grid on;

title("Discharge Over Current");
xlabel("Time (s)");
ylabel("Fault");

% -------------------------------------------------------------------------
% Over Temperature
% -------------------------------------------------------------------------

subplot(3,2,5);

plotAligned(t,OverTemperature,"Over Temperature");

ylim([-0.1 1.1]);

grid on;

title("Over Temperature");
xlabel("Time (s)");
ylabel("Fault");

% -------------------------------------------------------------------------
% Under Temperature
% -------------------------------------------------------------------------

subplot(3,2,6);

plotAligned(t,UnderTemperature,"Under Temperature");

ylim([-0.1 1.1]);

grid on;

title("Under Temperature");
xlabel("Time (s)");
ylabel("Fault");

sgtitle("BMS Protection Signals");

savePlot(plotsDir,"26_All_Protection_Signals");

%% =========================================================================
% 31. PROTECTION EVENT TIMELINE
% =========================================================================

figure("Name","27 Protection Event Timeline","NumberTitle","off");

hold on;

plotProtection(t,OverVoltage,1,"Over Voltage");
plotProtection(t,UnderVoltage,2,"Under Voltage");
plotProtection(t,ChargeOverCurrent,3,"Charge Over Current");
plotProtection(t,DischargeOverCurrent,4,"Discharge Over Current");
plotProtection(t,OverTemperature,5,"Over Temperature");
plotProtection(t,UnderTemperature,6,"Under Temperature");

grid on;

xlabel("Time (s)");
ylabel("Protection Event");

yticks(1:6);

yticklabels({ ...
    "Over Voltage", ...
    "Under Voltage", ...
    "Charge Overcurrent", ...
    "Discharge Overcurrent", ...
    "Over Temperature", ...
    "Under Temperature"});

title("BMS Protection Event Timeline");

savePlot(plotsDir,"27_Protection_Event_Timeline");

%% =========================================================================
% 32. PROTECTION EVENT COUNT
% =========================================================================

protectionCounts = [ ...
    nnz(OverVoltage), ...
    nnz(UnderVoltage), ...
    nnz(ChargeOverCurrent), ...
    nnz(DischargeOverCurrent), ...
    nnz(OverTemperature), ...
    nnz(UnderTemperature)];

figure("Name","28 Protection Event Count","NumberTitle","off");

bar(protectionCounts);

grid on;

xticks(1:6);

xticklabels({ ...
    "Over V", ...
    "Under V", ...
    "Charge OC", ...
    "Discharge OC", ...
    "Over T", ...
    "Under T"});

ylabel("Number of Samples");
title("BMS Protection Event Counts");

savePlot(plotsDir,"28_Protection_Event_Count");

%% =========================================================================
% 33. SOC + TEMPERATURE
% =========================================================================

figure("Name","29 SOC Temperature","NumberTitle","off");

yyaxis left;

plotAligned(t,SOC_true,"SOC");

ylabel("SOC");

ylim([0 1]);

yyaxis right;

plotAligned(t,T_battery,"Temperature");

ylabel("Temperature (°C)");

grid on;

xlabel("Time (s)");

title("Battery SOC and Temperature");

savePlot(plotsDir,"29_SOC_Temperature");

%% =========================================================================
% 34. SOC + SOH
% =========================================================================

figure("Name","30 SOC SOH","NumberTitle","off");

plotAligned(t,SOC_true,"SOC");

hold on;

plotAligned(t,SOH_true,"SOH");

plotAligned(t,SOC_estimated,"SOC Estimated");
plotAligned(t,SOH_estimated,"SOH Estimated");

grid on;

xlabel("Time (s)");
ylabel("State");

title("Battery SOC and SOH");

legend("SOC True", ...
       "SOH True", ...
       "SOC Estimated", ...
       "SOH Estimated", ...
       "Location","best");

savePlot(plotsDir,"30_SOC_SOH");

%% =========================================================================
% 35. VOLTAGE + CURRENT
% =========================================================================

figure("Name","31 Voltage Current","NumberTitle","off");

yyaxis left;

plotAligned(t,V_battery,"Voltage");

ylabel("Voltage (V)");

yyaxis right;

plotAligned(t,I_battery,"Current");

ylabel("Current (A)");

grid on;

xlabel("Time (s)");

title("Battery Voltage and Current");

savePlot(plotsDir,"31_Voltage_Current");

%% =========================================================================
% 36. BATTERY OPERATING ENVELOPE
% =========================================================================

figure("Name","32 Battery Operating Envelope","NumberTitle","off");

X = I_battery(:);
Y = T_battery(:);

N = min(length(X),length(Y));

X = X(1:N);
Y = Y(1:N);

valid = isfinite(X) & isfinite(Y);

X = X(valid);
Y = Y(valid);

scatter(X,Y,8,"filled");

grid on;

xlabel("Battery Current (A)");
ylabel("Battery Temperature (°C)");

title("Battery Current vs Temperature Operating Envelope");

savePlot(plotsDir,"32_Battery_Operating_Envelope");

%% =========================================================================
% 37. BMS READINESS / FAULT
% =========================================================================

figure("Name","33 BMS Status","NumberTitle","off");

subplot(3,1,1);

stairs(t,BMS_Ready);

ylim([-0.1 1.1]);

grid on;

ylabel("Ready");

yticks([0 1]);
yticklabels({"NOT READY","READY"});

title("BMS Ready");

subplot(3,1,2);

stairs(t,BMS_Fault);

ylim([-0.1 1.1]);

grid on;

ylabel("Fault");

yticks([0 1]);
yticklabels({"NO FAULT","FAULT"});

title("BMS Fault");

subplot(3,1,3);

stairs(t,Emergency_Shutdown);

ylim([-0.1 1.1]);

grid on;

xlabel("Time (s)");
ylabel("Shutdown");

yticks([0 1]);
yticklabels({"OFF","ACTIVE"});

title("Emergency Shutdown");

sgtitle("BMS Status");

savePlot(plotsDir,"33_BMS_Status");

%% =========================================================================
% 38. COMPLETE BMS OVERVIEW
% =========================================================================

figure("Name","34 Complete BMS Overview","NumberTitle","off");

subplot(5,1,1);

plotAligned(t,V_filtered,"Voltage");

ylabel("V");

grid on;

title("Filtered Voltage");

subplot(5,1,2);

plotAligned(t,I_filtered,"Current");

ylabel("A");

grid on;

title("Filtered Current");

subplot(5,1,3);

plotAligned(t,T_filtered,"Temperature");

ylabel("°C");

grid on;

title("Filtered Temperature");

subplot(5,1,4);

stairs(t,BMS_State);

ylabel("State");

grid on;

title("BMS State");

subplot(5,1,5);

stairs(t,Fault_Code);

ylabel("Fault");
xlabel("Time (s)");

grid on;

title("Fault Type");

sgtitle("Complete BMS Diagnostic Overview");

savePlot(plotsDir,"34_Complete_BMS_Overview");

%% =========================================================================
% 39. COMPLETE BATTERY OVERVIEW
% =========================================================================

figure("Name","35 Complete Battery Overview","NumberTitle","off");

subplot(5,1,1);

plotAligned(t,V_battery,"Voltage");

ylabel("V");
grid on;

title("Battery Voltage");

subplot(5,1,2);

plotAligned(t,I_battery,"Current");

ylabel("A");
grid on;

title("Battery Current");

subplot(5,1,3);

plotAligned(t,T_battery,"Temperature");

ylabel("°C");
grid on;

title("Battery Temperature");

subplot(5,1,4);

plotAligned(t,SOC_true,"SOC");

hold on;

plotAligned(t,SOC_estimated,"SOC Estimated");

ylabel("SOC");
grid on;

title("SOC");

subplot(5,1,5);

plotAligned(t,SOH_true,"SOH");

hold on;

plotAligned(t,SOH_estimated,"SOH Estimated");

ylabel("SOH");
xlabel("Time (s)");

grid on;

title("SOH");

sgtitle("Complete Battery Digital Twin Overview");

savePlot(plotsDir,"35_Complete_Battery_Overview");

%% =========================================================================
% 40. CURRENT CONTROL ERROR
% =========================================================================

if ~isempty(I_safe_command) && ~isempty(I_battery)

    figure("Name","36 Current Control Error","NumberTitle","off");

    [tt,yy] = alignSignals(t,I_safe_command,I_battery);

    currentError = yy(:,2)-yy(:,1);

    plot(tt,currentError);

    yline(0,"--");

    grid on;

    xlabel("Time (s)");
    ylabel("Current Error (A)");

    title("BMS Safe Command vs Actual Battery Current Error");

    savePlot(plotsDir,"36_Current_Control_Error");

end

%% =========================================================================
% 41. BATTERY CURRENT VS SOC
% =========================================================================

figure("Name","37 Current SOC Relationship","NumberTitle","off");

X = SOC_true(:);
Y = I_battery(:);

N = min(length(X),length(Y));

X = X(1:N);
Y = Y(1:N);

valid = isfinite(X) & isfinite(Y);

X = X(valid);
Y = Y(valid);

scatter(X,Y,8,"filled");

grid on;

xlabel("SOC");
ylabel("Battery Current (A)");

title("Battery Current vs SOC");

savePlot(plotsDir,"37_Current_vs_SOC");

%% =========================================================================
% 42. TEMPERATURE VS SOC
% =========================================================================

figure("Name","38 Temperature SOC Relationship","NumberTitle","off");

X = SOC_true(:);
Y = T_battery(:);

N = min(length(X),length(Y));

X = X(1:N);
Y = Y(1:N);

valid = isfinite(X) & isfinite(Y);

X = X(valid);
Y = Y(valid);

scatter(X,Y,8,"filled");

grid on;

xlabel("SOC");
ylabel("Temperature (°C)");

title("Battery Temperature vs SOC");

savePlot(plotsDir,"38_Temperature_vs_SOC");

%% =========================================================================
% 43. TEMPERATURE VS CURRENT
% =========================================================================

figure("Name","39 Temperature Current Relationship","NumberTitle","off");

% Make both signals the same length
I_plot = I_battery(:);
T_plot = T_battery(:);

N = min(length(I_plot),length(T_plot));

I_plot = I_plot(1:N);
T_plot = T_plot(1:N);

% Remove invalid values
valid = isfinite(I_plot) & isfinite(T_plot);

I_plot = I_plot(valid);
T_plot = T_plot(valid);

scatter(I_plot,T_plot,8,"filled");

grid on;

xlabel("Battery Current (A)");
ylabel("Temperature (°C)");

title("Battery Temperature vs Current");

savePlot(plotsDir,"39_Temperature_vs_Current");

%% =========================================================================
% 44. AUTOMATIC PLOT OF EVERY ADDITIONAL NUMERIC SIGNAL
% =========================================================================
%
% This section automatically searches the Simulink output object and plots
% any numeric/time-series signals that were not already handled above.
%
% This means if later you expose:
%
%   OCV
%   V1
%   V2
%   P_generated
%   P_loss
%   F_stress
%   D_Q
%   D_R
%   etc.
%
% they will automatically be plotted.
%
% =========================================================================

fprintf("\n");
fprintf("Searching for additional output signals...\n");

handledSignals = { ...
    "V_battery", ...
    "I_battery", ...
    "T_battery", ...
    "SOC_true", ...
    "SOH_true", ...
    "Q_available", ...
    "R0_current", ...
    "Ah_throughput", ...
    "V_battery_measured", ...
    "I_battery_measured", ...
    "T_battery_measured", ...
    "V_filtered", ...
    "I_filtered", ...
    "T_filtered", ...
    "SOC_estimated", ...
    "SOH_estimated", ...
    "I_safe_command", ...
    "I_charge_limit", ...
    "I_discharge_limit", ...
    "Charge_Allowed", ...
    "Discharge_Allowed", ...
    "BMS_State", ...
    "BMS_Ready", ...
    "BMS_Fault", ...
    "Fault", ...
    "Fault_Code", ...
    "Emergency_Shutdown", ...
    "OverVoltage", ...
    "UnderVoltage", ...
    "ChargeOverCurrent", ...
    "DischargeOverCurrent", ...
    "OverTemperature", ...
    "UnderTemperature" ...
    };

outputNames = out.who;

extraCount = 0;

for k = 1:numel(outputNames)

    signalName = outputNames{k};

    if any(strcmp(signalName,handledSignals))
        continue;
    end

    try

        data = getSignal(out,signalName);

        if isempty(data)
            continue;
        end

        if ~isnumeric(data)
            continue;
        end

        if ~isvector(data)
            continue;
        end

        figure( ...
            "Name", ...
            "Auto - " + signalName, ...
            "NumberTitle","off");

        plotAligned(t,data,signalName);

        grid on;

        xlabel("Time (s)");
        ylabel(signalName);

        title("Additional Simulation Signal: " + signalName);

        safeName = regexprep(signalName,"[^a-zA-Z0-9_]","_");

        savePlot( ...
            plotsDir, ...
            "Auto_" + safeName);

        extraCount = extraCount + 1;

    catch

        fprintf("Skipped non-plotable signal: %s\n",signalName);

    end

end

fprintf("Additional signals plotted: %d\n",extraCount);

%% =========================================================================
% 45. FAULT SUMMARY TABLE IN COMMAND WINDOW
% =========================================================================

fprintf("\n");
fprintf("====================================================================\n");
fprintf("                     BMS FAULT SUMMARY\n");
fprintf("====================================================================\n");

fprintf("\n");
fprintf("%-25s %10s\n","Fault Type","Samples");
fprintf("%s\n",repmat("-",1,38));

fprintf("%-25s %10d\n","No Fault",nnz(Fault_Code == 0));
fprintf("%-25s %10d\n","Over Voltage",nnz(Fault_Code == 1));
fprintf("%-25s %10d\n","Under Voltage",nnz(Fault_Code == 2));
fprintf("%-25s %10d\n","Charge Over Current",nnz(Fault_Code == 3));
fprintf("%-25s %10d\n","Discharge Over Current",nnz(Fault_Code == 4));
fprintf("%-25s %10d\n","Over Temperature",nnz(Fault_Code == 5));
fprintf("%-25s %10d\n","Under Temperature",nnz(Fault_Code == 6));
fprintf("%-25s %10d\n","Multiple Faults",nnz(Fault_Code == 7));

%% =========================================================================
% 46. BATTERY SUMMARY
% =========================================================================

fprintf("\n");
fprintf("====================================================================\n");
fprintf("                    BATTERY SUMMARY\n");
fprintf("====================================================================\n");

fprintf("\n");

fprintf("Voltage:\n");
fprintf("  Initial : %.4f V\n",firstValue(V_battery));
fprintf("  Final   : %.4f V\n",lastValue(V_battery));
fprintf("  Minimum : %.4f V\n",min(V_battery));
fprintf("  Maximum : %.4f V\n",max(V_battery));

fprintf("\n");

fprintf("Current:\n");
fprintf("  Minimum : %.4f A\n",min(I_battery));
fprintf("  Maximum : %.4f A\n",max(I_battery));

fprintf("\n");

fprintf("Temperature:\n");
fprintf("  Initial : %.4f °C\n",firstValue(T_battery));
fprintf("  Final   : %.4f °C\n",lastValue(T_battery));
fprintf("  Minimum : %.4f °C\n",min(T_battery));
fprintf("  Maximum : %.4f °C\n",max(T_battery));

fprintf("\n");

fprintf("SOC:\n");
fprintf("  Initial : %.6f\n",firstValue(SOC_true));
fprintf("  Final   : %.6f\n",lastValue(SOC_true));

fprintf("\n");

fprintf("SOH:\n");
fprintf("  Initial : %.6f\n",firstValue(SOH_true));
fprintf("  Final   : %.6f\n",lastValue(SOH_true));

fprintf("\n");

fprintf("Aging:\n");
fprintf("  Final Capacity : %.6f Ah\n",lastValue(Q_available));
fprintf("  Final R0       : %.6f Ohm\n",lastValue(R0_current));
fprintf("  Ah Throughput  : %.6f Ah\n",lastValue(Ah_throughput));

%% =========================================================================
% 47. BMS SUMMARY
% =========================================================================

fprintf("\n");
fprintf("====================================================================\n");
fprintf("                       BMS SUMMARY\n");
fprintf("====================================================================\n");

fprintf("\n");

fprintf("Fault samples           : %d\n",nnz(Fault));
fprintf("Emergency shutdown      : %d\n",nnz(Emergency_Shutdown));

fprintf("\nProtection events:\n");

fprintf("  Over Voltage          : %d\n",nnz(OverVoltage));
fprintf("  Under Voltage         : %d\n",nnz(UnderVoltage));
fprintf("  Charge Over Current   : %d\n",nnz(ChargeOverCurrent));
fprintf("  Discharge Over Current: %d\n",nnz(DischargeOverCurrent));
fprintf("  Over Temperature      : %d\n",nnz(OverTemperature));
fprintf("  Under Temperature     : %d\n",nnz(UnderTemperature));

fprintf("\n");

if ~isempty(I_safe_command) && ~isempty(I_battery)

    [~,yy] = alignSignals(t,I_safe_command,I_battery);

    currentControlError = yy(:,2)-yy(:,1);

    fprintf("Maximum current control error: %.8f A\n", ...
        max(abs(currentControlError)));

end

fprintf("\n");
fprintf("Plots saved to:\n%s\n",plotsDir);

fprintf("\n");
fprintf("====================================================================\n");
fprintf("                    PLOTTING COMPLETE\n");
fprintf("====================================================================\n");

%% =========================================================================
% LOCAL FUNCTIONS
% =========================================================================

function data = getSignal(out,signalName)

    data = [];

    try

        signal = out.(signalName);

    catch

        return;

    end

    if isa(signal,"timeseries")

        data = signal.Data;

    elseif istimetable(signal)

        data = signal.Variables;

    elseif isstruct(signal)

        if isfield(signal,"signals")

            data = signal.signals.values;

        elseif isfield(signal,"Data")

            data = signal.Data;

        elseif isfield(signal,"values")

            data = signal.values;

        end

    elseif isnumeric(signal)

        data = signal;

    end

    if isempty(data)
        return;
    end

    data = squeeze(data);

    if ismatrix(data) && size(data,2) > 1

        % Only accept first column for a single-vector diagnostic plot.
        data = data(:,1);

    end

    data = data(:);

end


function plotAligned(t,data,label)

    if isempty(data)
        return;
    end

    data = data(:);

    n = min(length(t),length(data));

    plot(t(1:n),data(1:n), ...
        "LineWidth",1.1, ...
        "DisplayName",label);

    hold on;

end


function [tt,yy] = alignSignals(t,a,b)

    a = a(:);
    b = b(:);

    n = min([length(t),length(a),length(b)]);

    tt = t(1:n);

    yy = [a(1:n),b(1:n)];

end


function savePlot(folder,name)

    filename = fullfile(folder,name + ".png");

    exportgraphics(gcf,filename,"Resolution",200);

end


function plotProtection(t,data,row,label)

    data = data(:);

    n = min(length(t),length(data));

    event = logical(data(1:n));

    if any(event)

        plot(t(1:n), ...
             row*double(event), ...
             "LineWidth",2, ...
             "DisplayName",label);

    else

        plot(t(1:n), ...
             row*double(event), ...
             "LineWidth",1, ...
             "DisplayName",label);

    end

end


function value = firstValue(data)

    if isempty(data)

        value = NaN;

    else

        value = data(1);

    end

end


function value = lastValue(data)

    if isempty(data)

        value = NaN;

    else

        value = data(end);

    end

end