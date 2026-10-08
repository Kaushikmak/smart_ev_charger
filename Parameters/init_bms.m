BMS.Ts = 0.1;

BMS.Filter.Alpha = 0.9;

BMS.SOC.Initial = Battery.SOC_initial;

BMS.Protection.Enable = true;

BMS.Control.Enable = true;

BMS.SOH.CapacityFadePerAh = Battery.Aging.capacity_fade_per_Ah;
BMS.SOH.Min = 0;
BMS.SOH.Max = 1;
BMS.SOH.VoltageStressWeight = 0.001;

BMS.SOC.Min = 0;
BMS.SOC.Max = 1;

BMS.Fault.ResetEnable = true;

BMS.SOH.TemperatureStressWeight = 0.0001;