function [isValid, missingFields] = validate_battery_profile(Battery)
%% =========================================================
% VALIDATE BATTERY PROFILE
% FYP - Battery Digital Twin
%
% Checks whether a Battery structure contains the minimum
% fields required by the physical battery model.
%
% Usage:
%   [isValid, missingFields] = validate_battery_profile(Battery)
% ==========================================================

requiredFields = {
    "Name"
    "Chemistry"
    "Q_nom_Ah"
    "V_nom"
    "V_max"
    "V_min"
    "I_max_charge"
    "I_max_discharge"
    "SOC_initial"
    "T_initial_C"
    "R0"
    "R1"
    "C1"
    "R2"
    "C2"
    "eta_charge"
    "eta_discharge"
    "Thermal"
    "Aging"
    "OCV"
    "Model"
    };

missingFields = strings(0,1);

for k = 1:numel(requiredFields)

    fieldName = requiredFields{k};

    if ~isfield(Battery,fieldName)
        missingFields(end+1,1) = fieldName;
    end

end

isValid = isempty(missingFields);

end