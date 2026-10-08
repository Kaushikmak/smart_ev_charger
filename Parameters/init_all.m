%% =========================================================
% FYP BATTERY DIGITAL TWIN
% MASTER PARAMETER INITIALIZATION
%
% Automatically discovers battery profiles and asks the user
% which battery model should be loaded.
%
% To add a new battery:
%   1. Create a new .m file in Parameters/Battery_Profiles/
%   2. Define the Battery structure
%   3. Run:
%
%      run("Parameters/init_all.m")
%
% ==========================================================

clc;

fprintf("\n");
fprintf("============================================================\n");
fprintf("             FYP BATTERY DIGITAL TWIN\n");
fprintf("             MASTER INITIALIZATION\n");
fprintf("============================================================\n\n");

%% ---------------------------------------------------------
% Locate battery profile directory
% ----------------------------------------------------------

rootDir = fileparts(mfilename("fullpath"));
profileDir = fullfile(rootDir,"Battery_Profiles");

if ~isfolder(profileDir)
    error("Battery profile folder not found:\n%s",profileDir);
end

%% ---------------------------------------------------------
% Discover battery profile files
% ----------------------------------------------------------

files = dir(fullfile(profileDir,"*.m"));

% Remove hidden/system files if necessary
files = files(~startsWith({files.name},"."));

if isempty(files)
    error("No battery profile .m files found in:\n%s",profileDir);
end

%% ---------------------------------------------------------
% Build profile list
% ----------------------------------------------------------

profileNames = erase({files.name},".m");

fprintf("Available battery models:\n\n");

for k = 1:numel(profileNames)
    fprintf("  %d. %s\n",k,profileNames{k});
end

fprintf("\n");
fprintf("  A. Load ALL battery models into BatteryLibrary\n");
fprintf("  Q. Quit\n\n");

%% ---------------------------------------------------------
% Ask user for selection
% ----------------------------------------------------------

selection = input("Select battery model [1-" + ...
    num2str(numel(profileNames)) + ...
    ", A=All, Q=Quit]: ","s");

selection = upper(strtrim(selection));

%% ---------------------------------------------------------
% Quit
% ----------------------------------------------------------

if strcmp(selection,"Q")
    fprintf("\nInitialization cancelled by user.\n");
    return;
end

%% ---------------------------------------------------------
% Load ALL profiles
% ----------------------------------------------------------

if strcmp(selection,"A")

    clear BatteryLibrary

    BatteryLibrary = struct();

    fprintf("\nLoading all battery models...\n\n");

    for k = 1:numel(profileNames)

        fprintf("Loading: %s\n",profileNames{k});

        % Run profile in temporary workspace
        Battery = struct();

        run(fullfile(profileDir,files(k).name));

        BatteryLibrary.(matlab.lang.makeValidName(profileNames{k})) = Battery;

    end

    fprintf("\n");
    fprintf("============================================================\n");
    fprintf("All battery models loaded into BatteryLibrary.\n");
    fprintf("============================================================\n");

    fprintf("\nAvailable BatteryLibrary entries:\n");

    disp(fieldnames(BatteryLibrary));

    fprintf("\nNo single Battery model selected.\n");
    fprintf("Select a specific model when running a battery simulation.\n\n");

    return;
end

%% ---------------------------------------------------------
% Convert selection to number
% ----------------------------------------------------------

modelIndex = str2double(selection);

if isnan(modelIndex) || ...
        modelIndex < 1 || ...
        modelIndex > numel(profileNames) || ...
        floor(modelIndex) ~= modelIndex

    error("Invalid battery model selection.");
end

%% ---------------------------------------------------------
% Load selected battery
% ----------------------------------------------------------

selectedFile = files(modelIndex).name;
selectedName = profileNames{modelIndex};

fprintf("\nLoading battery model:\n");
fprintf("  %s\n\n",selectedName);

clear Battery

run(fullfile(profileDir,selectedFile));

%% ---------------------------------------------------------
% Load sensor parameters
% ----------------------------------------------------------

run(fullfile(rootDir,"init_sensors.m"));

%% ---------------------------------------------------------
% Display loaded configuration
% ----------------------------------------------------------

fprintf("\n");
fprintf("============================================================\n");
fprintf("             BATTERY MODEL LOADED\n");
fprintf("============================================================\n");

if isfield(Battery,"Manufacturer")
    fprintf("Manufacturer       : %s\n",Battery.Manufacturer);
end

if isfield(Battery,"PartNumber")
    fprintf("Part Number        : %s\n",Battery.PartNumber);
end

if isfield(Battery,"Name")
    fprintf("Name               : %s\n",Battery.Name);
end

if isfield(Battery,"Chemistry")
    fprintf("Chemistry          : %s\n",Battery.Chemistry);
end

fprintf("\n");

if isfield(Battery,"Q_nom_Ah")
    fprintf("Nominal Capacity   : %.3f Ah\n",Battery.Q_nom_Ah);
end

if isfield(Battery,"V_nom")
    fprintf("Nominal Voltage    : %.2f V\n",Battery.V_nom);
end

if isfield(Battery,"V_max")
    fprintf("Maximum Voltage    : %.2f V\n",Battery.V_max);
end

if isfield(Battery,"V_min")
    fprintf("Minimum Voltage    : %.2f V\n",Battery.V_min);
end

fprintf("\n");

if isfield(Battery,"I_max_charge")
    fprintf("Maximum Charge     : %.2f A\n",Battery.I_max_charge);
end

if isfield(Battery,"I_max_discharge")
    fprintf("Maximum Discharge  : %.2f A\n",Battery.I_max_discharge);
end

fprintf("\n");

if isfield(Battery,"SOC_initial")
    fprintf("Initial SOC        : %.2f\n",Battery.SOC_initial);
end

if isfield(Battery,"T_initial_C")
    fprintf("Initial Temperature: %.2f °C\n",Battery.T_initial_C);
end

fprintf("============================================================\n");
fprintf("Parameter initialization complete.\n");
fprintf("============================================================\n\n");