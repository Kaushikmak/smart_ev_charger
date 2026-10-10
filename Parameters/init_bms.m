% =========================================================================
% init_bms.m
% BMS parameters
% =========================================================================

BMS.Ts = 0.1;

% -------------------------------------------------------------------------
% Measurement filtering
% -------------------------------------------------------------------------
BMS.Filter.Alpha = 0.9;

% -------------------------------------------------------------------------
% SOC estimation
% -------------------------------------------------------------------------
BMS.SOC.Initial = Battery.SOC_initial;
BMS.SOC.Min = 0;
BMS.SOC.Max = 1;

% SOH estimation parameters
BMS.SOH.Initial = Battery.Aging.SOH_initial;
BMS.SOH.Min = 0;
BMS.SOH.Max = 1;

% SOH stress-model weights
BMS.SOH.VoltageStressWeight = 1.0;
BMS.SOH.TemperatureStressWeight = 1.0;

% Coulomb-counting efficiency
BMS.SOC.Efficiency = Battery.eta_discharge;

% -------------------------------------------------------------------------
% Protection
% -------------------------------------------------------------------------
BMS.Protection.Enable = true;

% -------------------------------------------------------------------------
% BMS control
% -------------------------------------------------------------------------
BMS.Control.Enable = true;

% -------------------------------------------------------------------------
% Fault handling
% -------------------------------------------------------------------------
BMS.Fault.ResetEnable = true;