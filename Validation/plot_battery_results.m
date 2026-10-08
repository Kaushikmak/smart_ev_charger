function plot_battery_results( ...
    out, ...
    Battery, ...
    Sensors, ...
    Metrics, ...
    plotsDir, ...
    showPlots, ...
    savePlots)

% =========================================================================
% plot_battery_results.m
%
% Purpose:
%   Generate validation and battery-state plots for one battery profile.
%
% IMPORTANT:
%   Every plot explicitly displays the battery name.
%
%   This version supports Simulink outputs stored as either:
%       1. timeseries
%       2. numeric double arrays
%
% Inputs:
%   out        - Simulink.SimulationOutput
%   Battery    - Battery parameter structure
%   Sensors    - Sensor parameter structure
%   Metrics    - Validation metrics structure
%   plotsDir   - Directory where plots are saved
%   showPlots  - true  -> figures remain visible
%                false -> figures are created invisibly
%   savePlots  - true  -> save PNG files
%                false -> do not save PNG files
%
% =========================================================================


%% ------------------------------------------------------------------------
% Default arguments
% -------------------------------------------------------------------------

if nargin < 6 || isempty(showPlots)
    showPlots = false;
end

if nargin < 7 || isempty(savePlots)
    savePlots = true;
end


%% ------------------------------------------------------------------------
% Validate plot directory
% -------------------------------------------------------------------------

if savePlots && ~exist(plotsDir, "dir")
    mkdir(plotsDir);
end


%% ------------------------------------------------------------------------
% Determine battery name
% -------------------------------------------------------------------------

if isstruct(Battery)

    if isfield(Battery, "Name")
        batteryName = string(Battery.Name);

    elseif isfield(Battery, "PartNumber")
        batteryName = string(Battery.PartNumber);

    else
        batteryName = "Unknown Battery";
    end

else

    batteryName = "Unknown Battery";

end


%% ------------------------------------------------------------------------
% Extract all simulation signals
%
% The helper function getSignalData() below handles both:
%
%   timeseries
%   double
%
% -------------------------------------------------------------------------

t = getSignalData(out, "tout");

V_true        = getSignalData(out, "V_battery");
V_measured    = getSignalData(out, "V_battery_measured");

I_true        = getSignalData(out, "I_battery");
I_measured    = getSignalData(out, "I_battery_measured");

T_true        = getSignalData(out, "T_battery");
T_measured    = getSignalData(out, "T_battery_measured");

SOC           = getSignalData(out, "SOC_true");
SOH           = getSignalData(out, "SOH_true");

Q_available   = getSignalData(out, "Q_available");
R0_current    = getSignalData(out, "R0_current");
Ah_throughput = getSignalData(out, "Ah_throughput");


%% ------------------------------------------------------------------------
% Convert all signals to column vectors
% -------------------------------------------------------------------------

t             = t(:);

V_true        = V_true(:);
V_measured    = V_measured(:);

I_true        = I_true(:);
I_measured    = I_measured(:);

T_true        = T_true(:);
T_measured    = T_measured(:);

SOC           = SOC(:);
SOH           = SOH(:);

Q_available   = Q_available(:);
R0_current    = R0_current(:);
Ah_throughput = Ah_throughput(:);


%% ------------------------------------------------------------------------
% Make sure time and signal lengths are compatible
% -------------------------------------------------------------------------

N = min([ ...
    numel(t), ...
    numel(V_true), ...
    numel(V_measured), ...
    numel(I_true), ...
    numel(I_measured), ...
    numel(T_true), ...
    numel(T_measured), ...
    numel(SOC), ...
    numel(SOH), ...
    numel(Q_available), ...
    numel(R0_current), ...
    numel(Ah_throughput)]);


t             = t(1:N);

V_true        = V_true(1:N);
V_measured    = V_measured(1:N);

I_true        = I_true(1:N);
I_measured    = I_measured(1:N);

T_true        = T_true(1:N);
T_measured    = T_measured(1:N);

SOC           = SOC(1:N);
SOH           = SOH(1:N);

Q_available   = Q_available(1:N);
R0_current    = R0_current(1:N);
Ah_throughput = Ah_throughput(1:N);


%% ------------------------------------------------------------------------
% Calculate sensor errors
% -------------------------------------------------------------------------

V_error = V_measured - V_true;
I_error = I_measured - I_true;
T_error = T_measured - T_true;


%% ------------------------------------------------------------------------
% Display information
% -------------------------------------------------------------------------

fprintf("\n");
fprintf("============================================================\n");
fprintf("Generating plots\n");
fprintf("Battery: %s\n", batteryName);
fprintf("============================================================\n");


%% ========================================================================
% 1. VOLTAGE VALIDATION
% ========================================================================

fig = createFigure(showPlots);

plot(t, V_true, "LineWidth", 1.5);
hold on;

plot(t, V_measured, "--", "LineWidth", 1.0);

grid on;

xlabel("Time (s)");
ylabel("Voltage (V)");

title( ...
    "Voltage Validation — " + batteryName, ...
    "Interpreter", "none");

legend( ...
    "True Voltage", ...
    "Measured Voltage", ...
    "Location", "best");

saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    "01_voltage_validation.png", ...
    showPlots, ...
    savePlots);


%% ========================================================================
% 2. CURRENT VALIDATION
% ========================================================================

fig = createFigure(showPlots);

plot(t, I_true, "LineWidth", 1.5);
hold on;

plot(t, I_measured, "--", "LineWidth", 1.0);

grid on;

xlabel("Time (s)");
ylabel("Current (A)");

title( ...
    "Current Validation — " + batteryName, ...
    "Interpreter", "none");

legend( ...
    "True Current", ...
    "Measured Current", ...
    "Location", "best");

saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    "02_current_validation.png", ...
    showPlots, ...
    savePlots);


%% ========================================================================
% 3. TEMPERATURE VALIDATION
% ========================================================================

fig = createFigure(showPlots);

plot(t, T_true, "LineWidth", 1.5);
hold on;

plot(t, T_measured, "--", "LineWidth", 1.0);

grid on;

xlabel("Time (s)");
ylabel("Temperature (°C)");

title( ...
    "Temperature Validation — " + batteryName, ...
    "Interpreter", "none");

legend( ...
    "True Temperature", ...
    "Measured Temperature", ...
    "Location", "best");

saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    "03_temperature_validation.png", ...
    showPlots, ...
    savePlots);


%% ========================================================================
% 4. STATE OF CHARGE
% ========================================================================

fig = createFigure(showPlots);

plot(t, SOC, "LineWidth", 1.5);

grid on;

xlabel("Time (s)");
ylabel("SOC");

title( ...
    "State of Charge (SOC) — " + batteryName, ...
    "Interpreter", "none");

ylim([0 1]);

saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    "04_soc.png", ...
    showPlots, ...
    savePlots);


%% ========================================================================
% 5. STATE OF HEALTH
% ========================================================================

fig = createFigure(showPlots);

plot(t, SOH, "LineWidth", 1.5);

grid on;

xlabel("Time (s)");
ylabel("SOH");

title( ...
    "State of Health (SOH) — " + batteryName, ...
    "Interpreter", "none");

ylim([0 1.01]);

saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    "05_soh.png", ...
    showPlots, ...
    savePlots);


%% ========================================================================
% 6. AVAILABLE CAPACITY
% ========================================================================

fig = createFigure(showPlots);

plot(t, Q_available, "LineWidth", 1.5);

grid on;

xlabel("Time (s)");
ylabel("Available Capacity (Ah)");

title( ...
    "Available Capacity — " + batteryName, ...
    "Interpreter", "none");

saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    "06_available_capacity.png", ...
    showPlots, ...
    savePlots);


%% ========================================================================
% 7. DYNAMIC INTERNAL RESISTANCE
% ========================================================================

fig = createFigure(showPlots);

plot(t, R0_current, "LineWidth", 1.5);

grid on;

xlabel("Time (s)");
ylabel("Internal Resistance (Ω)");

title( ...
    "Dynamic Internal Resistance — " + batteryName, ...
    "Interpreter", "none");

saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    "07_internal_resistance.png", ...
    showPlots, ...
    savePlots);


%% ========================================================================
% 8. AH THROUGHPUT
% ========================================================================

fig = createFigure(showPlots);

plot(t, Ah_throughput, "LineWidth", 1.5);

grid on;

xlabel("Time (s)");
ylabel("Ah Throughput (Ah)");

title( ...
    "Cumulative Ah Throughput — " + batteryName, ...
    "Interpreter", "none");

saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    "08_ah_throughput.png", ...
    showPlots, ...
    savePlots);


%% ========================================================================
% 9. BATTERY STATE — SOC + TEMPERATURE
% ========================================================================

fig = createFigure(showPlots);

yyaxis left

plot(t, SOC, "LineWidth", 1.5);

ylabel("SOC");

ylim([0 1]);


yyaxis right

plot(t, T_true, "--", "LineWidth", 1.5);

ylabel("Temperature (°C)");

grid on;

xlabel("Time (s)");

title( ...
    "Battery State: SOC and Temperature — " + batteryName, ...
    "Interpreter", "none");

legend( ...
    "SOC", ...
    "Temperature", ...
    "Location", "best");

saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    "09_battery_state.png", ...
    showPlots, ...
    savePlots);


%% ========================================================================
% 10. SENSOR ERRORS
% ========================================================================

fig = createFigure(showPlots);

plot(t, V_error, "LineWidth", 1.2);
hold on;

plot(t, I_error, "LineWidth", 1.2);

plot(t, T_error, "LineWidth", 1.2);

grid on;

xlabel("Time (s)");
ylabel("Sensor Error");

title( ...
    "Sensor Measurement Errors — " + batteryName, ...
    "Interpreter", "none");

legend( ...
    "Voltage Error (V)", ...
    "Current Error (A)", ...
    "Temperature Error (°C)", ...
    "Location", "best");

saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    "10_sensor_errors.png", ...
    showPlots, ...
    savePlots);


%% ========================================================================
% FINAL MESSAGE
% ========================================================================

fprintf("\n");
fprintf("Plot generation completed successfully.\n");
fprintf("Battery: %s\n", batteryName);

if savePlots
    fprintf("Plots saved to:\n");
    fprintf("%s\n", plotsDir);
end

fprintf("============================================================\n");


end


%% =========================================================================
% LOCAL FUNCTION: GET SIGNAL DATA
% =========================================================================

function data = getSignalData(out, signalName)

% -------------------------------------------------------------------------
% Check that signal exists
% -------------------------------------------------------------------------

if ~isprop(out, signalName)

    error( ...
        "Simulation output does not contain signal '%s'.", ...
        signalName);

end


% -------------------------------------------------------------------------
% Get signal
% -------------------------------------------------------------------------

signal = out.(signalName);


% -------------------------------------------------------------------------
% Handle timeseries
% -------------------------------------------------------------------------

if isa(signal, "timeseries")

    data = signal.Data;

    return;

end


% -------------------------------------------------------------------------
% Handle numeric data
% -------------------------------------------------------------------------

if isnumeric(signal)

    data = signal;

    return;

end


% -------------------------------------------------------------------------
% Handle timetable
% -------------------------------------------------------------------------

if istimetable(signal)

    data = signal.Variables;

    return;

end


% -------------------------------------------------------------------------
% Handle structure with Data field
% -------------------------------------------------------------------------

if isstruct(signal)

    if isfield(signal, "Data")

        data = signal.Data;

        return;

    end

end


% -------------------------------------------------------------------------
% Unsupported signal type
% -------------------------------------------------------------------------

error( ...
    "Unsupported signal type for '%s'. Type: %s", ...
    signalName, ...
    class(signal));

end


%% =========================================================================
% LOCAL FUNCTION: CREATE FIGURE
% =========================================================================

function fig = createFigure(showPlots)

if showPlots

    fig = figure( ...
        "Color", "w", ...
        "Visible", "on");

else

    fig = figure( ...
        "Color", "w", ...
        "Visible", "off");

end

end


%% =========================================================================
% LOCAL FUNCTION: SAVE OR CLOSE FIGURE
% =========================================================================

function saveOrCloseFigure( ...
    fig, ...
    plotsDir, ...
    fileName, ...
    showPlots, ...
    savePlots)

% -------------------------------------------------------------------------
% Save figure
% -------------------------------------------------------------------------

if savePlots

    exportgraphics( ...
        fig, ...
        fullfile(plotsDir, fileName), ...
        "Resolution", 300);

end


% -------------------------------------------------------------------------
% Close if background mode
% -------------------------------------------------------------------------

if ~showPlots

    close(fig);

end

end