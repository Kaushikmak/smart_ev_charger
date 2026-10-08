%% =========================================================
% PHYSICAL BATTERY VALIDATION PROFILE
% FYP - Battery Digital Twin
% ==========================================================

clearvars -except Battery Plant
clc;

%% ---------------------------------------------------------
% LOAD SELECTED BATTERY PROFILE
% ---------------------------------------------------------

run("../Parameters/init_molicel_M35A.m");
run("../Parameters/init_sensors.m");

%% Initialize physical plant variables
run("../Physical_battery/battery_plant.m");

%% ---------------------------------------------------------
% SIMULATION SETTINGS
% ---------------------------------------------------------

Ts = 0.1;
T_end = 300;

t = (0:Ts:T_end)';

%% ---------------------------------------------------------
% CURRENT PROFILE
% ---------------------------------------------------------

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

%% ---------------------------------------------------------
% AMBIENT TEMPERATURE
% ---------------------------------------------------------
%
% IMPORTANT:
% Ambient temperature comes from the selected battery profile.
%
% For Molicel M35A:
% Battery.Thermal.T_ambient_C = 42 °C

T_ambient = Battery.Thermal.T_ambient_C * ones(size(t));

%% ---------------------------------------------------------
% CREATE SIMULINK INPUTS
% ---------------------------------------------------------

I_input = timeseries(I_command,t);

T_ambient_input = timeseries(T_ambient,t);

%% ---------------------------------------------------------
% DISPLAY VALIDATION PROFILE
% ---------------------------------------------------------

fprintf('\n');
fprintf('============================================================\n');
fprintf('             VALIDATION PROFILE CREATED\n');
fprintf('============================================================\n');

fprintf('Simulation time       : %.1f s\n', T_end);
fprintf('Sample time           : %.2f s\n', Ts);

fprintf('\n');
fprintf('Battery               : %s\n', Battery.PartNumber);

fprintf('Initial SOC           : %.2f\n', ...
    Battery.SOC_initial);

fprintf('Initial temperature   : %.2f °C\n', ...
    Battery.T_initial_C);

fprintf('Ambient temperature   : %.2f °C\n', ...
    Battery.Thermal.T_ambient_C);

fprintf('\n');
fprintf('Current profile:\n');
fprintf('0-50 s                : 0 A\n');
fprintf('50-150 s              : +1 A discharge\n');
fprintf('150-200 s             : 0 A\n');
fprintf('200-250 s             : -1 A charge\n');
fprintf('250-300 s             : 0 A\n');

fprintf('\n');
fprintf('Simulink input variables created:\n');
fprintf('I_input\n');
fprintf('T_ambient_input\n');

fprintf('============================================================\n');