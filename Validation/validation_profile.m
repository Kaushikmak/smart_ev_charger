%% =========================================================
% PHYSICAL BATTERY VALIDATION PROFILE
% FYP - Battery Digital Twin
% ==========================================================

clearvars -except Battery Plant
clc;

%% Load parameters
run("../Parameters/init_all.m");
run("../Physical_battery/battery_plant.m");

%% Simulation settings
Ts = 0.1;
T_end = 300;

t = (0:Ts:T_end)';

%% Current profile
I_command = zeros(size(t));

% 0-50 s : Rest
I_command(t >= 0 & t < 50) = 0;

% 50-150 s : 1 A discharge
I_command(t >= 50 & t < 150) = 1;

% 150-200 s : Rest
I_command(t >= 150 & t < 200) = 0;

% 200-250 s : 1 A charge
I_command(t >= 200 & t < 250) = -1;

% 250-300 s : Rest
I_command(t >= 250) = 0;

%% Ambient temperature
T_ambient = ...
    Battery.Thermal.T_ambient_C * ones(size(t));

%% Create Simulink input timeseries
I_input = timeseries(I_command, t);
T_ambient_input = timeseries(T_ambient, t);

disp("Validation profile created.");