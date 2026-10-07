%% =========================================================
% SENSOR PARAMETERS
% FYP - Battery Digital Twin
% ==========================================================

%% Voltage Sensor
Sensors.Voltage.Bias_V = 0.005;
Sensors.Voltage.Noise_Mean_V = 0;
Sensors.Voltage.Noise_Variance_V2 = 0.000025;
Sensors.Voltage.SampleTime = 0.1;

%% Current Sensor
Sensors.Current.Bias_A = 0.005;
Sensors.Current.Noise_Mean_A = 0;
Sensors.Current.Noise_Variance_A2 = 0.000025;
Sensors.Current.SampleTime = 0.1;

%% Temperature Sensor
Sensors.Temperature.Bias_C = 0.1;
Sensors.Temperature.Noise_Mean_C = 0;
Sensors.Temperature.Noise_Variance_C2 = 0.01;
Sensors.Temperature.SampleTime = 0.1;

disp("Sensor parameters loaded successfully.");
disp(Sensors);