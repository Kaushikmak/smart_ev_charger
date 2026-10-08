function ComparisonTable = compare_battery_results(comparisonResults, comparisonDir)
%COMPARE_BATTERY_RESULTS Compare validation results across battery profiles.

fprintf('\n');
fprintf('============================================================\n');
fprintf('              BATTERY COMPARISON ANALYSIS\n');
fprintf('============================================================\n');

if nargin < 2 || isempty(comparisonDir)
    comparisonDir = fullfile(pwd,"Results","Comparison");
end

if ~exist(comparisonDir,"dir")
    mkdir(comparisonDir);
end

if isempty(comparisonResults)

    warning("No comparison results were supplied.");

    ComparisonTable = table();

    return;
end

comparisonResults = comparisonResults(:);

N = numel(comparisonResults);

fprintf("Number of batteries compared: %d\n\n",N);


%% ============================================================
% PREALLOCATE
% =============================================================

Battery = strings(N,1);

FinalSOC = nan(N,1);
FinalSOH = nan(N,1);

FinalTemperature_C = nan(N,1);
MaximumTemperature_C = nan(N,1);

FinalCapacity_Ah = nan(N,1);

VoltageRMSE_V = nan(N,1);
CurrentRMSE_A = nan(N,1);
TemperatureRMSE_C = nan(N,1);


%% ============================================================
% EXTRACT RESULTS
% =============================================================

for k = 1:N

    result = comparisonResults(k);

    % ---------------------------------------------------------
    % Battery name
    % ---------------------------------------------------------

    Battery(k) = extract_battery_name(result,k);


    % ---------------------------------------------------------
    % Determine where metrics are stored
    % ---------------------------------------------------------

    metrics = result;

    if isfield(result,"Metrics")

        if isstruct(result.Metrics)

            metrics = result.Metrics;

        end

    elseif isfield(result,"ValidationMetrics")

        if isstruct(result.ValidationMetrics)

            metrics = result.ValidationMetrics;

        end

    end


    % ---------------------------------------------------------
    % Final SOC
    % ---------------------------------------------------------

    FinalSOC(k) = extract_metric( ...
        metrics, ...
        { ...
        "FinalSOC", ...
        "SOC_final", ...
        "Final_SOC", ...
        "SOCFinal" ...
        });


    % ---------------------------------------------------------
    % Final SOH
    % ---------------------------------------------------------

    FinalSOH(k) = extract_metric( ...
        metrics, ...
        { ...
        "FinalSOH", ...
        "SOH_final", ...
        "Final_SOH", ...
        "SOHFinal" ...
        });


    % ---------------------------------------------------------
    % Final temperature
    % ---------------------------------------------------------

    FinalTemperature_C(k) = extract_metric( ...
        metrics, ...
        { ...
        "FinalTemperature_C", ...
        "FinalTemp_C", ...
        "FinalTemperature", ...
        "Temperature_final", ...
        "T_final" ...
        });


    % ---------------------------------------------------------
    % Maximum temperature
    % ---------------------------------------------------------

    MaximumTemperature_C(k) = extract_metric( ...
        metrics, ...
        { ...
        "MaximumTemperature_C", ...
        "MaxTemperature_C", ...
        "MaximumTemperature", ...
        "MaxTemp_C", ...
        "T_max" ...
        });


    % ---------------------------------------------------------
    % Final capacity
    % ---------------------------------------------------------

    FinalCapacity_Ah(k) = extract_metric( ...
        metrics, ...
        { ...
        "FinalCapacity_Ah", ...
        "FinalCapacity", ...
        "Capacity_final_Ah", ...
        "Q_available_final", ...
        "FinalQ_Ah" ...
        });


    % ---------------------------------------------------------
    % Voltage RMSE
    % ---------------------------------------------------------

    VoltageRMSE_V(k) = extract_metric( ...
        metrics, ...
        { ...
        "VoltageRMSE_V", ...
        "VoltageRMSE", ...
        "V_RMSE", ...
        "Voltage_RMSE" ...
        });


    % ---------------------------------------------------------
    % Current RMSE
    % ---------------------------------------------------------

    CurrentRMSE_A(k) = extract_metric( ...
        metrics, ...
        { ...
        "CurrentRMSE_A", ...
        "CurrentRMSE", ...
        "I_RMSE", ...
        "Current_RMSE" ...
        });


    % ---------------------------------------------------------
    % Temperature RMSE
    % ---------------------------------------------------------

    TemperatureRMSE_C(k) = extract_metric( ...
        metrics, ...
        { ...
        "TemperatureRMSE_C", ...
        "TemperatureRMSE", ...
        "T_RMSE", ...
        "Temperature_RMSE" ...
        });

end


%% ============================================================
% CREATE TABLE
% =============================================================

ComparisonTable = table( ...
    Battery, ...
    FinalSOC, ...
    FinalSOH, ...
    FinalTemperature_C, ...
    MaximumTemperature_C, ...
    FinalCapacity_Ah, ...
    VoltageRMSE_V, ...
    CurrentRMSE_A, ...
    TemperatureRMSE_C, ...
    'VariableNames', ...
    { ...
    'Battery', ...
    'FinalSOC', ...
    'FinalSOH', ...
    'FinalTemperature_C', ...
    'MaximumTemperature_C', ...
    'FinalCapacity_Ah', ...
    'VoltageRMSE_V', ...
    'CurrentRMSE_A', ...
    'TemperatureRMSE_C' ...
    });


%% ============================================================
% DISPLAY
% =============================================================

fprintf('\n');
fprintf('BATTERY COMPARISON RESULTS\n');
fprintf('------------------------------------------------------------\n');

disp(ComparisonTable);


%% ============================================================
% SAVE
% =============================================================

save( ...
    fullfile(comparisonDir,"comparison_results.mat"), ...
    "comparisonResults", ...
    "ComparisonTable");


writetable( ...
    ComparisonTable, ...
    fullfile(comparisonDir,"comparison_summary.csv"));


%% ============================================================
% PLOTS
% =============================================================

create_comparison_plot( ...
    Battery, ...
    FinalSOC, ...
    "Final SOC Comparison", ...
    "Final SOC", ...
    fullfile(comparisonDir,"final_soc_comparison.png"));


create_comparison_plot( ...
    Battery, ...
    FinalSOH, ...
    "Final SOH Comparison", ...
    "Final SOH", ...
    fullfile(comparisonDir,"final_soh_comparison.png"));


create_comparison_plot( ...
    Battery, ...
    MaximumTemperature_C, ...
    "Maximum Temperature Comparison", ...
    "Maximum Temperature (°C)", ...
    fullfile(comparisonDir,"maximum_temperature_comparison.png"));


create_comparison_plot( ...
    Battery, ...
    FinalCapacity_Ah, ...
    "Final Available Capacity Comparison", ...
    "Capacity (Ah)", ...
    fullfile(comparisonDir,"capacity_comparison.png"));


fprintf('\n');
fprintf('Comparison analysis completed successfully.\n');
fprintf('Results saved to:\n');
fprintf('%s\n',comparisonDir);

end


%% ========================================================================
% EXTRACT BATTERY NAME
% ========================================================================

function name = extract_battery_name(result,k)

name = "Battery_" + string(k);

if isfield(result,"Battery")

    battery = result.Battery;

    if isstruct(battery)

        if isfield(battery,"Name")
            name = string(battery.Name);
            return;
        end

        if isfield(battery,"PartNumber")
            name = string(battery.PartNumber);
            return;
        end

    else

        try
            name = string(battery);
            return;
        catch
        end

    end

end


if isfield(result,"BatteryName")

    try
        name = string(result.BatteryName);
        return;
    catch
    end

end


if isfield(result,"Name")

    try
        name = string(result.Name);
        return;
    catch
    end

end

end


%% ========================================================================
% EXTRACT METRIC
% ========================================================================

function value = extract_metric(structure,fieldNames)

value = NaN;

if ~isstruct(structure)
    return;
end

for k = 1:numel(fieldNames)

    fieldName = fieldNames{k};

    if isfield(structure,fieldName)

        value = convert_to_scalar(structure.(fieldName));

        if ~isnan(value)
            return;
        end

    end

end

end


%% ========================================================================
% CONVERT VALUE TO SCALAR
% ========================================================================

function value = convert_to_scalar(x)

value = NaN;

if isempty(x)
    return;
end


% Numeric

if isnumeric(x)

    x = x(:);

    if ~isempty(x)
        value = double(x(end));
    end

    return;

end


% Logical

if islogical(x)

    x = x(:);

    if ~isempty(x)
        value = double(x(end));
    end

    return;

end


% Timeseries

if isa(x,"timeseries")

    data = x.Data;

    data = data(:);

    if ~isempty(data)
        value = double(data(end));
    end

    return;

end


% Struct containing another value

if isstruct(x)

    candidateFields = ...
        {"Value","Data","Final","FinalValue"};

    for n = 1:numel(candidateFields)

        fieldName = candidateFields{n};

        if isfield(x,fieldName)

            value = convert_to_scalar(x.(fieldName));

            if ~isnan(value)
                return;
            end

        end

    end

end


% Generic conversion

try

    x = double(x);

    x = x(:);

    if ~isempty(x)
        value = x(end);
    end

catch

    value = NaN;

end

end


%% ========================================================================
% COMPARISON PLOT
% ========================================================================

function create_comparison_plot( ...
    Battery, ...
    Values, ...
    PlotTitle, ...
    YLabelText, ...
    FileName)

fig = figure( ...
    "Visible","off", ...
    "Color","white");

bar(Values);

grid on;

title(PlotTitle,"Interpreter","none");

ylabel(YLabelText);

xticks(1:numel(Battery));

xticklabels(Battery);

xtickangle(30);

set(gca,"FontSize",10);

saveas(fig,FileName);

close(fig);

end