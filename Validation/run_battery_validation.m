%% =========================================================
% FYP BATTERY DIGITAL TWIN
% MASTER BATTERY VALIDATION RUNNER
% =========================================================
%
% Workflow:
%
% Scan profiles
%      ↓
% Select battery / multiple / all
%      ↓
% Select display / plot mode
%      ↓
% Validate profile
%      ↓
% Load battery
%      ↓
% Load sensors
%      ↓
% Create validation inputs
%      ↓
% Run Simulink
%      ↓
% Calculate metrics
%      ↓
% Save raw results
%      ↓
% Generate / display plots according to selected mode
%      ↓
% Generate comparison
%
% Display modes:
%
% 1. Run + save plots in background
% 2. Run + open Simulink + show plots
% 3. Run + open Simulink + show plots + save plots
% 4. Run only - no plots
%
% =========================================================

clearvars -except BatteryLibrary
clc

fprintf("\n");
fprintf("============================================================\n");
fprintf("        FYP BATTERY DIGITAL TWIN\n");
fprintf("        MASTER BATTERY VALIDATION RUNNER\n");
fprintf("============================================================\n\n");


%% =========================================================
% PROJECT PATHS
% =========================================================

projectRoot = fileparts(fileparts(mfilename("fullpath")));

parameterDir = fullfile( ...
    projectRoot, ...
    "Parameters");

profileDir = fullfile( ...
    parameterDir, ...
    "Battery_Profiles");

validationDir = fullfile( ...
    projectRoot, ...
    "Validation");

resultsRoot = fullfile( ...
    projectRoot, ...
    "Results");

modelPath = fullfile( ...
    projectRoot, ...
    "Battery_Digital_Twin.slx");


%% =========================================================
% CHECK DIRECTORIES / FILES
% =========================================================

if ~isfolder(profileDir)

    error( ...
        "Battery profile directory not found:\n%s", ...
        profileDir);

end


if ~isfolder(resultsRoot)

    mkdir(resultsRoot);

end


if ~isfile(modelPath)

    error( ...
        "Simulink model not found:\n%s", ...
        modelPath);

end


if ~isfile(fullfile(validationDir, ...
        "validate_battery_profile.m"))

    error( ...
        "Battery profile validation function not found:\n%s", ...
        fullfile(validationDir, ...
        "validate_battery_profile.m"));

end


if ~isfile(fullfile(validationDir, ...
        "plot_battery_results.m"))

    error( ...
        "Battery plotting function not found:\n%s", ...
        fullfile(validationDir, ...
        "plot_battery_results.m"));

end


if ~isfile(fullfile(validationDir, ...
        "compare_battery_results.m"))

    error( ...
        "Battery comparison function not found:\n%s", ...
        fullfile(validationDir, ...
        "compare_battery_results.m"));

end


%% =========================================================
% MAKE VALIDATION FUNCTIONS AVAILABLE
% =========================================================

addpath(validationDir);


%% =========================================================
% DISCOVER BATTERY PROFILES
% =========================================================

files = dir(fullfile(profileDir,"*.m"));

files = files(~startsWith({files.name},"."));


if isempty(files)

    error("No battery profiles found.");

end


profileNames = erase( ...
    {files.name}, ...
    ".m");


fprintf("Available battery models:\n\n");


for k = 1:numel(profileNames)

    fprintf( ...
        "  %d. %s\n", ...
        k, ...
        profileNames{k});

end


fprintf("\n");
fprintf("  M. Select multiple batteries\n");
fprintf("  A. All batteries\n");
fprintf("  Q. Quit\n\n");


%% =========================================================
% BATTERY SELECTION
% =========================================================

selection = upper(strtrim(input( ...
    "Select [1-" + ...
    num2str(numel(profileNames)) + ...
    ", M=Multiple, A=All, Q=Quit]: ", ...
    "s")));


if strcmp(selection,"Q")

    fprintf("\nValidation cancelled.\n");

    return;

end


%% =========================================================
% DETERMINE SELECTED PROFILES
% =========================================================

selectedIndices = [];


if strcmp(selection,"A")

    selectedIndices = 1:numel(profileNames);


elseif strcmp(selection,"M")

    userInput = input( ...
        "Enter battery numbers separated by spaces: ", ...
        "s");

    selectedIndices = str2num(userInput); %#ok<ST2NM>


    if isempty(selectedIndices)

        error("No battery profiles selected.");

    end


    if any(selectedIndices < 1) || ...
       any(selectedIndices > numel(profileNames)) || ...
       any(mod(selectedIndices,1) ~= 0)

        error("Invalid battery selection.");

    end


else

    index = str2double(selection);


    if isnan(index) || ...
       index < 1 || ...
       index > numel(profileNames) || ...
       mod(index,1) ~= 0

        error("Invalid battery selection.");

    end


    selectedIndices = index;

end


selectedIndices = unique( ...
    selectedIndices, ...
    "stable");


%% =========================================================
% DISPLAY SELECTED BATTERIES
% =========================================================

fprintf("\nSelected battery models:\n\n");


for k = selectedIndices

    fprintf( ...
        "  %d. %s\n", ...
        k, ...
        profileNames{k});

end


fprintf("\n");


%% =========================================================
% DISPLAY / PLOT MODE
% =========================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("              VALIDATION DISPLAY MODE\n");
fprintf("============================================================\n");

fprintf("\n");

fprintf("  1. Run + save plots in background\n");
fprintf("  2. Run + open Simulink + show plots\n");
fprintf("  3. Run + open Simulink + show plots + save plots\n");
fprintf("  4. Run only - no plots\n");
fprintf("  Q. Quit\n");


displayChoice = upper(strtrim(input( ...
    "\nSelect [1-4, Q=Quit]: ", ...
    "s")));


switch displayChoice

    case "1"

        displayMode = "save";


    case "2"

        displayMode = "open";


    case "3"

        displayMode = "open_save";


    case "4"

        displayMode = "none";


    case "Q"

        fprintf("\nValidation cancelled by user.\n");

        return;


    otherwise

        error("Invalid display mode selection.");

end


fprintf("\n");
fprintf("Selected mode: %s\n",displayMode);


%% =========================================================
% PREPARE COMPARISON RESULTS
% =========================================================

comparisonResults = struct([]);


%% =========================================================
% MAIN BATTERY LOOP
% =========================================================

for runIndex = 1:numel(selectedIndices)


    %% -----------------------------------------------------
    % Current profile
    % ------------------------------------------------------

    profileIndex = selectedIndices(runIndex);

    profileName = profileNames{profileIndex};

    profileFile = files(profileIndex).name;


    fprintf("\n");
    fprintf("============================================================\n");
    fprintf("RUN %d OF %d\n", ...
        runIndex, ...
        numel(selectedIndices));

    fprintf("Battery profile: %s\n", ...
        profileName);

    fprintf("============================================================\n\n");


    %% -----------------------------------------------------
    % Load battery profile
    % ------------------------------------------------------

    clear Battery

    run(fullfile( ...
        profileDir, ...
        profileFile));


    %% -----------------------------------------------------
    % Validate battery profile
    % ------------------------------------------------------

    [isValid,missingFields] = ...
        validate_battery_profile(Battery);


    if ~isValid

        fprintf("\n");
        fprintf("ERROR: Battery profile validation failed.\n");
        fprintf("Profile: %s\n\n",profileName);

        fprintf("Missing fields:\n");


        for k = 1:numel(missingFields)

            fprintf( ...
                "  - %s\n", ...
                missingFields(k));

        end


        error( ...
            "Invalid battery profile: %s", ...
            profileName);

    end


    fprintf( ...
        "Battery profile validation: PASS\n");


    %% -----------------------------------------------------
    % Load sensors
    % ------------------------------------------------------

    run(fullfile( ...
        parameterDir, ...
        "init_sensors.m"));


    fprintf("Sensor parameters loaded successfully.\n");

    fprintf("       Voltage: [1x1 struct]\n");
    fprintf("       Current: [1x1 struct]\n");
    fprintf("   Temperature: [1x1 struct]\n");


    %% -----------------------------------------------------
    % Create validation simulation inputs
    % ------------------------------------------------------

%% ========================================================================
% VALIDATION TEST SETUP
% ========================================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("             VALIDATION TEST SETUP\n");
fprintf("============================================================\n");

%% Simulation duration

fprintf("\n");
fprintf("Enter simulation duration in seconds.\n");
fprintf("\n");
fprintf("Examples:\n");
fprintf("  300   = 5 minutes\n");
fprintf("  1800  = 30 minutes\n");
fprintf("  3600  = 1 hour\n");
fprintf("  7200  = 2 hours\n");
fprintf("  86400 = 24 hours\n");

T_end = input("\nSimulation duration [seconds]: ");

while isempty(T_end) || ...
        ~isnumeric(T_end) || ...
        ~isscalar(T_end) || ...
        ~isfinite(T_end) || ...
        T_end <= 0

    fprintf("\nInvalid duration.\n");

    T_end = input("Please enter a positive duration [seconds]: ");
end


%% Sample time

Ts = 0.1;

fprintf("\nSelected simulation duration: %.1f seconds\n", T_end);
fprintf("Sample time: %.2f seconds\n", Ts);


%% ========================================================================
% SELECT CURRENT PROFILE
% ========================================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("             CURRENT PROFILE\n");
fprintf("============================================================\n");

fprintf("\n");
fprintf("  1. Standard Dynamic Load\n");
fprintf("  2. High Load\n");
fprintf("  3. Charge/Discharge Cycling\n");

profileChoice = input("\nSelect [1-3]: ", "s");

while ~ismember(upper(strtrim(profileChoice)), ["1","2","3"])

    fprintf("\nInvalid selection.\n");

    profileChoice = input("Select [1-3]: ", "s");
end

profileChoice = str2double(profileChoice);

switch profileChoice

    case 1
        currentProfileName = "Standard Dynamic Load";

    case 2
        currentProfileName = "High Load";

    case 3
        currentProfileName = "Charge/Discharge Cycling";

end

fprintf("\nSelected profile: %s\n", currentProfileName);


%% ========================================================================
% CREATE TIME VECTOR
% ========================================================================

t = (0:Ts:T_end)';


%% ========================================================================
% GENERATE CURRENT PROFILE
% ========================================================================

I_command = zeros(size(t));


switch profileChoice

    %% --------------------------------------------------------------------
    % 1. STANDARD DYNAMIC LOAD
    % ---------------------------------------------------------------------

    case 1

        % Divide the simulation into repeated operating cycles.
        %
        % Each cycle:
        %
        %   20% rest
        %   30% medium discharge
        %   15% rest
        %   20% light discharge
        %   15% regenerative charge
        %
        % The cycle automatically repeats for the entire simulation.

        cycleDuration = 600;       % 10 minutes

        cycleTime = mod(t, cycleDuration);

        % Rest
        I_command( ...
            cycleTime < 120) = 0;

        % Medium discharge
        I_command( ...
            cycleTime >= 120 & ...
            cycleTime < 300) = 1.0;

        % Rest
        I_command( ...
            cycleTime >= 300 & ...
            cycleTime < 390) = 0;

        % Light discharge
        I_command( ...
            cycleTime >= 390 & ...
            cycleTime < 510) = 0.5;

        % Charge
        I_command( ...
            cycleTime >= 510 & ...
            cycleTime < 600) = -0.75;


    %% --------------------------------------------------------------------
    % 2. HIGH LOAD
    % ---------------------------------------------------------------------

    case 2

        % More aggressive load profile.
        %
        % Positive current = discharge
        % Negative current = charge

        cycleDuration = 600;

        cycleTime = mod(t, cycleDuration);

        % Rest
        I_command( ...
            cycleTime < 60) = 0;

        % High discharge
        I_command( ...
            cycleTime >= 60 & ...
            cycleTime < 240) = 2.0;

        % Rest
        I_command( ...
            cycleTime >= 240 & ...
            cycleTime < 300) = 0;

        % Peak load
        I_command( ...
            cycleTime >= 300 & ...
            cycleTime < 450) = 2.5;

        % Regenerative charging
        I_command( ...
            cycleTime >= 450 & ...
            cycleTime < 600) = -1.0;


    %% --------------------------------------------------------------------
    % 3. CHARGE/DISCHARGE CYCLING
    % ---------------------------------------------------------------------

    case 3

        % Longer charge/discharge cycling profile.

        cycleDuration = 1200;      % 20 minutes

        cycleTime = mod(t, cycleDuration);

        % Rest
        I_command( ...
            cycleTime < 120) = 0;

        % Discharge
        I_command( ...
            cycleTime >= 120 & ...
            cycleTime < 420) = 1.0;

        % Rest
        I_command( ...
            cycleTime >= 420 & ...
            cycleTime < 540) = 0;

        % Higher discharge
        I_command( ...
            cycleTime >= 540 & ...
            cycleTime < 840) = 1.5;

        % Rest
        I_command( ...
            cycleTime >= 840 & ...
            cycleTime < 960) = 0;

        % Charge
        I_command( ...
            cycleTime >= 960 & ...
            cycleTime < 1200) = -1.0;

end


%% ========================================================================
% AMBIENT TEMPERATURE
% ========================================================================

T_ambient = Battery.Thermal.T_ambient_C * ones(size(t));


%% ========================================================================
% CREATE SIMULINK INPUT TIMESERIES
% ========================================================================

I_input = timeseries(I_command, t);

T_ambient_input = timeseries(T_ambient, t);


%% ========================================================================
% DISPLAY TEST INFORMATION
% ========================================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("             TEST CONFIGURATION\n");
fprintf("============================================================\n");

fprintf("Simulation duration : %.1f s\n", T_end);
fprintf("Simulation duration : %.2f min\n", T_end/60);
fprintf("Simulation duration : %.2f h\n", T_end/3600);

fprintf("Sample time         : %.2f s\n", Ts);

fprintf("Current profile     : %s\n", currentProfileName);

fprintf("Maximum discharge   : %.2f A\n", max(I_command));

fprintf("Maximum charge      : %.2f A\n", min(I_command));

fprintf("Ambient temperature : %.2f °C\n", ...
    Battery.Thermal.T_ambient_C);

fprintf("Number of samples   : %d\n", numel(t));

fprintf("============================================================\n");

    fprintf("\n");
    fprintf("Validation inputs created:\n");

    fprintf( ...
        "  Simulation time : %.1f s\n", ...
        T_end);

    fprintf( ...
        "  Sample time     : %.2f s\n", ...
        Ts);

    fprintf( ...
        "  Initial ambient : %.2f °C\n", ...
        T_ambient_input.Data(1));

    fprintf( ...
        "  Final ambient   : %.2f °C\n", ...
        T_ambient_input.Data(end));


    %% -----------------------------------------------------
    % Create result directories
    % ------------------------------------------------------

    batteryResultsDir = ...
        fullfile( ...
        resultsRoot, ...
        profileName);


    simulationDir = ...
        fullfile( ...
        batteryResultsDir, ...
        "simulation");


    dataDir = ...
        fullfile( ...
        batteryResultsDir, ...
        "data");


    plotsDir = ...
        fullfile( ...
        batteryResultsDir, ...
        "plots");


    if ~isfolder(simulationDir)

        mkdir(simulationDir);

    end


    if ~isfolder(dataDir)

        mkdir(dataDir);

    end


    if ~isfolder(plotsDir)

        mkdir(plotsDir);

    end


    %% -----------------------------------------------------
    % Save battery configuration
    % ------------------------------------------------------

    save( ...
        fullfile( ...
        dataDir, ...
        "battery_configuration.mat"), ...
        "Battery", ...
        "Sensors");


    %% =====================================================
    % RUN SIMULINK
    % ======================================================

    fprintf("\n");


    %% Open Simulink when requested

    if displayMode == "open" || ...
       displayMode == "open_save"

        fprintf( ...
            "Opening Simulink model...\n");

        open_system(modelPath);

    end


    %% Run simulation

    fprintf( ...
        "Running Simulink model...\n");


    out = sim(modelPath);


    fprintf( ...
        "Simulation completed successfully.\n");


    %% -----------------------------------------------------
    % Check simulation
    % ------------------------------------------------------

    if ~isempty(out.ErrorMessage)

        error( ...
            "Simulation failed for %s:\n%s", ...
            profileName, ...
            out.ErrorMessage);

    end


    %% -----------------------------------------------------
    % Save raw simulation output
    % ------------------------------------------------------

    save( ...
        fullfile( ...
        simulationDir, ...
        "simulation_output.mat"), ...
        "out", ...
        "-v7.3");


    %% =====================================================
    % CALCULATE VALIDATION METRICS
    % ======================================================

    V_error = ...
        out.V_battery_measured.Data - ...
        out.V_battery.Data;


    I_error = ...
        out.I_battery_measured.Data - ...
        out.I_battery.Data;


    T_error = ...
        out.T_battery_measured.Data - ...
        out.T_battery.Data;


    Metrics = struct();


    %% -----------------------------------------------------
    % SOC
    % ------------------------------------------------------

    Metrics.InitialSOC = ...
        out.SOC_true.Data(1);

    Metrics.FinalSOC = ...
        out.SOC_true.Data(end);


    %% -----------------------------------------------------
    % Temperature
    % ------------------------------------------------------

    Metrics.InitialTemperature = ...
        out.T_battery.Data(1);

    Metrics.FinalTemperature = ...
        out.T_battery.Data(end);

    Metrics.MaximumTemperature = ...
        max(out.T_battery.Data);


    %% -----------------------------------------------------
    % SOH
    % ------------------------------------------------------

    Metrics.InitialSOH = ...
        out.SOH_true.Data(1);

    Metrics.FinalSOH = ...
        out.SOH_true.Data(end);


    %% -----------------------------------------------------
    % Capacity
    % ------------------------------------------------------

    Metrics.InitialCapacity_Ah = ...
        out.Q_available.Data(1);

    Metrics.FinalCapacity_Ah = ...
        out.Q_available.Data(end);


    %% -----------------------------------------------------
    % Ah throughput
    % ------------------------------------------------------

    Metrics.FinalAhThroughput = ...
        out.Ah_throughput.Data(end);


    %% -----------------------------------------------------
    % Voltage sensor error
    % ------------------------------------------------------

    Metrics.VoltageMeanError_V = ...
        mean(V_error);

    Metrics.VoltageRMSError_V = ...
        rms(V_error);

    Metrics.VoltageMaxError_V = ...
        max(abs(V_error));


    %% -----------------------------------------------------
    % Current sensor error
    % ------------------------------------------------------

    Metrics.CurrentMeanError_A = ...
        mean(I_error);

    Metrics.CurrentRMSError_A = ...
        rms(I_error);

    Metrics.CurrentMaxError_A = ...
        max(abs(I_error));


    %% -----------------------------------------------------
    % Temperature sensor error
    % ------------------------------------------------------

    Metrics.TemperatureMeanError_C = ...
        mean(T_error);

    Metrics.TemperatureRMSError_C = ...
        rms(T_error);

    Metrics.TemperatureMaxError_C = ...
        max(abs(T_error));


    %% -----------------------------------------------------
    % Save metrics
    % ------------------------------------------------------

    save( ...
        fullfile( ...
        dataDir, ...
        "validation_metrics.mat"), ...
        "Metrics");


    %% =====================================================
    % PLOT / DISPLAY CONTROL
    % ======================================================

    switch displayMode


        %% -------------------------------------------------
        % MODE 1
        % --------------------------------------------------

        case "save"

            fprintf("\n");
            fprintf( ...
                "Generating plots in background...\n");


            plot_battery_results( ...
                out, ...
                Battery, ...
                Sensors, ...
                Metrics, ...
                plotsDir, ...
                false, ...
                true);


            fprintf( ...
                "Plots generated and saved.\n");


        %% -------------------------------------------------
        % MODE 2
        % --------------------------------------------------

        case "open"

            fprintf("\n");
            fprintf( ...
                "Opening validation plots...\n");


            plot_battery_results( ...
                out, ...
                Battery, ...
                Sensors, ...
                Metrics, ...
                plotsDir, ...
                true, ...
                false);


            fprintf( ...
                "Plots displayed. Files were not saved.\n");


        %% -------------------------------------------------
        % MODE 3
        % --------------------------------------------------

        case "open_save"

            fprintf("\n");
            fprintf( ...
                "Generating, displaying and saving plots...\n");


            plot_battery_results( ...
                out, ...
                Battery, ...
                Sensors, ...
                Metrics, ...
                plotsDir, ...
                true, ...
                true);


            fprintf( ...
                "Plots displayed and saved.\n");


        %% -------------------------------------------------
        % MODE 4
        % --------------------------------------------------

        case "none"

            fprintf("\n");
            fprintf( ...
                "Plot generation skipped.\n");

    end


    %% =====================================================
    % STORE COMPARISON INFORMATION
    % ======================================================

    comparisonResults(runIndex).Profile = ...
        profileName;


    comparisonResults(runIndex).Battery = ...
        Battery;


    comparisonResults(runIndex).Metrics = ...
        Metrics;


    fprintf("\n");
    fprintf( ...
        "Completed: %s\n", ...
        profileName);

end


%% =========================================================
% SAVE / GENERATE COMPARISON
% =========================================================

if numel(selectedIndices) > 1


    comparisonDir = ...
        fullfile( ...
        resultsRoot, ...
        "Comparison");


    if ~isfolder(comparisonDir)

        mkdir(comparisonDir);

    end


    %% -----------------------------------------------------
    % Save comparison raw data
    % ------------------------------------------------------

    save( ...
        fullfile( ...
        comparisonDir, ...
        "comparison_results.mat"), ...
        "comparisonResults", ...
        "-v7.3");


    %% -----------------------------------------------------
    % Generate comparison
    % ------------------------------------------------------

    fprintf("\n");
    fprintf("============================================================\n");
    fprintf("              BATTERY COMPARISON ANALYSIS\n");
    fprintf("============================================================\n");


    compare_battery_results( ...
        comparisonResults, ...
        comparisonDir);

end


%% =========================================================
% FINAL SUMMARY
% =========================================================

fprintf("\n");
fprintf("============================================================\n");
fprintf("             VALIDATION COMPLETE\n");
fprintf("============================================================\n");


fprintf("\n");
fprintf("Results saved under:\n");
fprintf("  %s\n",resultsRoot);


fprintf("\n");
fprintf("Batteries processed:\n");


for k = 1:numel(selectedIndices)

    fprintf( ...
        "  - %s\n", ...
        comparisonResults(k).Profile);

end


fprintf("\n");
fprintf("============================================================\n");