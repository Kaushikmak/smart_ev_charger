%% =========================================================
% FYP BATTERY DIGITAL TWIN
% SYSTEM RESULTS AND PARAMETER VISUALIZATION
% =========================================================

clc;

fprintf('\n');
fprintf('============================================================\n');
fprintf('       FYP BATTERY DIGITAL TWIN - RESULTS\n');
fprintf('============================================================\n\n');

%% ---------------------------------------------------------
% CHECK OUTPUT
% ---------------------------------------------------------

if ~exist('out','var')
    error('Simulation output "out" does not exist. Run the Simulink model first.');
end

%% ---------------------------------------------------------
% EXTRACT SIGNALS
% ---------------------------------------------------------

V_true      = out.V_battery;
V_measured  = out.V_battery_measured;

I_true      = out.I_battery;
I_measured  = out.I_battery_measured;

T_true      = out.T_battery;
T_measured  = out.T_battery_measured;

SOC_true    = out.SOC_true;
SOH_true    = out.SOH_true;

Q_available = out.Q_available;
R0_current  = out.R0_current;
Ah_throughput = out.Ah_throughput;

t = V_true.Time;

%% ---------------------------------------------------------
% SENSOR ERRORS
% ---------------------------------------------------------

V_error = V_measured.Data - V_true.Data;
I_error = I_measured.Data - I_true.Data;
T_error = T_measured.Data - T_true.Data;

%% ---------------------------------------------------------
% PRINT SUMMARY
% ---------------------------------------------------------

fprintf('BATTERY PARAMETERS\n');
fprintf('------------------------------------------------------------\n');
fprintf('Nominal Capacity       = %.3f Ah\n', Battery.Q_nom_Ah);
fprintf('Nominal Voltage       = %.3f V\n', Battery.V_nom);
fprintf('Maximum Voltage       = %.3f V\n', Battery.V_max);
fprintf('Minimum Voltage       = %.3f V\n', Battery.V_min);
fprintf('Maximum Charge Current = %.3f A\n', Battery.I_max_charge);
fprintf('Maximum Discharge     = %.3f A\n', Battery.I_max_discharge);
fprintf('Initial SOC            = %.3f\n', Battery.SOC_initial);
fprintf('Initial Temperature    = %.3f °C\n', Battery.T_initial_C);
fprintf('Initial R0             = %.4f Ohm\n', Battery.R0);

fprintf('\n');

fprintf('SENSOR PERFORMANCE\n');
fprintf('------------------------------------------------------------\n');

fprintf('Voltage Mean Error     = %.6f V\n', mean(V_error));
fprintf('Voltage RMS Error      = %.6f V\n', rms(V_error));
fprintf('Voltage Max Error      = %.6f V\n', max(abs(V_error)));

fprintf('\n');

fprintf('Current Mean Error     = %.6f A\n', mean(I_error));
fprintf('Current RMS Error      = %.6f A\n', rms(I_error));
fprintf('Current Max Error      = %.6f A\n', max(abs(I_error)));

fprintf('\n');

fprintf('Temperature Mean Error = %.6f °C\n', mean(T_error));
fprintf('Temperature RMS Error  = %.6f °C\n', rms(T_error));
fprintf('Temperature Max Error  = %.6f °C\n', max(abs(T_error)));

fprintf('\n');

fprintf('BATTERY STATE\n');
fprintf('------------------------------------------------------------\n');

fprintf('Initial SOC            = %.6f\n', SOC_true.Data(1));
fprintf('Final SOC              = %.6f\n', SOC_true.Data(end));

fprintf('Initial SOH            = %.6f\n', SOH_true.Data(1));
fprintf('Final SOH              = %.6f\n', SOH_true.Data(end));

fprintf('Initial Temperature    = %.6f °C\n', T_true.Data(1));
fprintf('Maximum Temperature    = %.6f °C\n', max(T_true.Data));

fprintf('Initial Capacity       = %.6f Ah\n', Q_available.Data(1));
fprintf('Final Capacity         = %.6f Ah\n', Q_available.Data(end));

fprintf('Initial R0             = %.6f Ohm\n', R0_current.Data(1));
fprintf('Final R0               = %.6f Ohm\n', R0_current.Data(end));

fprintf('Total Ah Throughput    = %.6f Ah\n', Ah_throughput.Data(end));

%% =========================================================
% FIGURE 1 - VOLTAGE
% ==========================================================

figure('Name','Voltage Validation');

plot(V_true.Time,V_true.Data,'LineWidth',1.2);
hold on;

plot(V_measured.Time,V_measured.Data,'LineWidth',1.0);

grid on;

xlabel('Time (s)');
ylabel('Voltage (V)');

legend('True Voltage','Measured Voltage');

title('Voltage Sensor Validation');

%% =========================================================
% FIGURE 2 - CURRENT
% ==========================================================

figure('Name','Current Validation');

plot(I_true.Time,I_true.Data,'LineWidth',1.2);
hold on;

plot(I_measured.Time,I_measured.Data,'LineWidth',1.0);

grid on;

xlabel('Time (s)');
ylabel('Current (A)');

legend('True Current','Measured Current');

title('Current Sensor Validation');

%% =========================================================
% FIGURE 3 - TEMPERATURE
% ==========================================================

figure('Name','Temperature Validation');

plot(T_true.Time,T_true.Data,'LineWidth',1.5);
hold on;

plot(T_measured.Time,T_measured.Data,'LineWidth',1.0);

grid on;

xlabel('Time (s)');
ylabel('Temperature (°C)');

legend('True Temperature','Measured Temperature');

title('Temperature Sensor Validation');

%% =========================================================
% FIGURE 4 - SOC
% ==========================================================

figure('Name','SOC');

plot(SOC_true.Time,SOC_true.Data,'LineWidth',1.5);

grid on;

xlabel('Time (s)');
ylabel('SOC');

ylim([0 1]);

title('Battery State of Charge');

%% =========================================================
% FIGURE 5 - SOH
% ==========================================================

figure('Name','SOH');

plot(SOH_true.Time,SOH_true.Data,'LineWidth',1.5);

grid on;

xlabel('Time (s)');
ylabel('SOH');

ylim([0 1.01]);

title('Battery State of Health');

%% =========================================================
% FIGURE 6 - AVAILABLE CAPACITY
% ==========================================================

figure('Name','Available Capacity');

plot(Q_available.Time,Q_available.Data,'LineWidth',1.5);

grid on;

xlabel('Time (s)');
ylabel('Available Capacity (Ah)');

title('Battery Available Capacity');

%% =========================================================
% FIGURE 7 - INTERNAL RESISTANCE
% ==========================================================

figure('Name','Internal Resistance');

plot(R0_current.Time,R0_current.Data,'LineWidth',1.5);

grid on;

xlabel('Time (s)');
ylabel('R0 (Ohm)');

title('Battery Internal Resistance');

%% =========================================================
% FIGURE 8 - AH THROUGHPUT
% ==========================================================

figure('Name','Ah Throughput');

plot(Ah_throughput.Time,Ah_throughput.Data,'LineWidth',1.5);

grid on;

xlabel('Time (s)');
ylabel('Ah');

title('Cumulative Ah Throughput');

%% =========================================================
% FIGURE 9 - BATTERY STATE OVERVIEW
% ==========================================================

figure('Name','Battery State Overview');

subplot(3,1,1);

plot(SOC_true.Time,SOC_true.Data,'LineWidth',1.3);

grid on;

ylabel('SOC');

title('Battery State Overview');

subplot(3,1,2);

plot(SOH_true.Time,SOH_true.Data,'LineWidth',1.3);

grid on;

ylabel('SOH');

subplot(3,1,3);

plot(T_true.Time,T_true.Data,'LineWidth',1.3);

grid on;

xlabel('Time (s)');
ylabel('Temperature (°C)');

%% =========================================================
% FIGURE 10 - SENSOR ERROR
% ==========================================================

figure('Name','Sensor Errors');

subplot(3,1,1);

plot(t,V_error,'LineWidth',1.0);

grid on;

ylabel('V Error (V)');

title('Sensor Measurement Errors');

subplot(3,1,2);

plot(t,I_error,'LineWidth',1.0);

grid on;

ylabel('I Error (A)');

subplot(3,1,3);

plot(t,T_error,'LineWidth',1.0);

grid on;

xlabel('Time (s)');
ylabel('T Error (°C)');

%% =========================================================
% FINAL MESSAGE
% ==========================================================

fprintf('\n============================================================\n');
fprintf('             RESULTS PLOTTING COMPLETE\n');
fprintf('============================================================\n');

fprintf('\nGenerated plots:\n');
fprintf('1. Voltage validation\n');
fprintf('2. Current validation\n');
fprintf('3. Temperature validation\n');
fprintf('4. SOC\n');
fprintf('5. SOH\n');
fprintf('6. Available capacity\n');
fprintf('7. Internal resistance\n');
fprintf('8. Ah throughput\n');
fprintf('9. Battery state overview\n');
fprintf('10. Sensor errors\n');

fprintf('\nAll available physical-battery results have been plotted.\n');