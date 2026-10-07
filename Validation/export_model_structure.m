%% =========================================================
% EXPORT SIMULINK MODEL FOR CHATGPT VERIFICATION
% FYP - Battery Digital Twin
% ==========================================================

clc;

model = 'Battery_Digital_Twin';

%% ---------------------------------------------------------
% Load model
% ----------------------------------------------------------

load_system(model);

%% ---------------------------------------------------------
% Create Validation folder if it does not exist
% ----------------------------------------------------------

validationFolder = fullfile(pwd, 'Validation');

if ~exist(validationFolder, 'dir')
    mkdir(validationFolder);
end

%% ---------------------------------------------------------
% Output file
% ----------------------------------------------------------

outputFile = fullfile(validationFolder, 'model_structure.txt');

fid = fopen(outputFile, 'w');

if fid == -1
    error('Could not create output file: %s', outputFile);
end

fprintf('Writing model information to:\n%s\n\n', outputFile);

%% =========================================================
% 1. MODEL BLOCK HIERARCHY
% ==========================================================

fprintf(fid,'=========================================================\n');
fprintf(fid,' FYP BATTERY DIGITAL TWIN - MODEL EXPORT\n');
fprintf(fid,'=========================================================\n\n');

fprintf(fid,'MATLAB Current Folder:\n%s\n\n',pwd);

blocks = find_system(model,'Type','Block');

fprintf(fid,'Total blocks found: %d\n\n',length(blocks));

for k = 1:length(blocks)

    blk = blocks{k};

    fprintf(fid,'\n--------------------------------------------\n');
    fprintf(fid,'BLOCK %d\n',k);
    fprintf(fid,'--------------------------------------------\n');

    fprintf(fid,'Path: %s\n',blk);

    try
        fprintf(fid,'Name: %s\n',get_param(blk,'Name'));
    catch
    end

    try
        fprintf(fid,'BlockType: %s\n',get_param(blk,'BlockType'));
    catch
    end

end


%% =========================================================
% 2. IMPORTANT BLOCK PARAMETERS
% ==========================================================

fprintf(fid,'\n\n=========================================================\n');
fprintf(fid,'2. IMPORTANT BLOCK PARAMETERS\n');
fprintf(fid,'=========================================================\n\n');

for k = 1:length(blocks)

    blk = blocks{k};

    try
        blockType = get_param(blk,'BlockType');
    catch
        continue;
    end

    importantBlock = ismember(blockType, ...
        {'Gain','Integrator','Sum','Product',...
         'Constant','Lookup_n-D','LookupTable',...
         'Math','Saturate','Inport','Outport'});

    if ~importantBlock
        continue;
    end

    fprintf(fid,'\n--------------------------------------------\n');
    fprintf(fid,'Path: %s\n',blk);
    fprintf(fid,'Type: %s\n',blockType);

    %% Gain
    if strcmp(blockType,'Gain')
        try
            fprintf(fid,'Gain: %s\n',get_param(blk,'Gain'));
        catch
        end
    end

    %% Integrator
    if strcmp(blockType,'Integrator')
        try
            fprintf(fid,'InitialCondition: %s\n',...
                get_param(blk,'InitialCondition'));
        catch
        end
    end

    %% Sum
    if strcmp(blockType,'Sum')
        try
            fprintf(fid,'Inputs: %s\n',...
                get_param(blk,'Inputs'));
        catch
        end
    end

    %% Product
    if strcmp(blockType,'Product')
        try
            fprintf(fid,'Inputs: %s\n',...
                get_param(blk,'Inputs'));
        catch
        end
    end

    %% Constant
    if strcmp(blockType,'Constant')
        try
            fprintf(fid,'Value: %s\n',...
                get_param(blk,'Value'));
        catch
        end
    end

    %% Saturation
    if strcmp(blockType,'Saturate')
        try
            fprintf(fid,'LowerLimit: %s\n',...
                get_param(blk,'LowerLimit'));
        catch
        end

        try
            fprintf(fid,'UpperLimit: %s\n',...
                get_param(blk,'UpperLimit'));
        catch
        end
    end

end


%% =========================================================
% 3. SIGNAL CONNECTIONS
% ==========================================================

fprintf(fid,'\n\n=========================================================\n');
fprintf(fid,'3. SIGNAL CONNECTIONS\n');
fprintf(fid,'=========================================================\n\n');

systems = find_system(model,'BlockType','SubSystem');

% Include top-level model
systems = [{model}; systems(:)];

for s = 1:length(systems)

    system = systems{s};

    fprintf(fid,'\n============================================\n');
    fprintf(fid,'SYSTEM: %s\n',system);
    fprintf(fid,'============================================\n');

    try

        lines = get_param(system,'LineHandles');

        signalLines = lines.Outport;

        for n = 1:length(signalLines)

            line = signalLines(n);

            if line == -1
                continue;
            end

            try

                srcPort = get_param(line,'SrcPortHandle');

                if srcPort == -1
                    continue;
                end

                srcBlock = get_param(srcPort,'Parent');
                srcName = get_param(srcBlock,'Name');

                dstPorts = get_param(line,'DstPortHandle');

                fprintf(fid,'\nSOURCE: %s\n',srcName);

                for d = 1:length(dstPorts)

                    if dstPorts(d) == -1
                        continue;
                    end

                    dstBlock = get_param(dstPorts(d),'Parent');
                    dstName = get_param(dstBlock,'Name');

                    fprintf(fid,'    --> DESTINATION: %s\n',dstName);

                end

            catch
            end

        end

    catch
    end

end


%% =========================================================
% 4. MODEL INPUTS AND OUTPUTS
% ==========================================================

fprintf(fid,'\n\n=========================================================\n');
fprintf(fid,'4. MODEL INPUTS AND OUTPUTS\n');
fprintf(fid,'=========================================================\n\n');

inports = find_system(model,...
    'SearchDepth',Inf,...
    'BlockType','Inport');

outports = find_system(model,...
    'SearchDepth',Inf,...
    'BlockType','Outport');

fprintf(fid,'INPUT PORTS:\n\n');

for k = 1:length(inports)
    fprintf(fid,'  %s\n',inports{k});
end

fprintf(fid,'\nOUTPUT PORTS:\n\n');

for k = 1:length(outports)
    fprintf(fid,'  %s\n',outports{k});
end


%% =========================================================
% 5. CLOSE FILE
% ==========================================================

fclose(fid);

fprintf('\n=========================================================\n');
fprintf(' MODEL EXPORT COMPLETE\n');
fprintf('=========================================================\n');
fprintf('File:\n%s\n',outputFile);
fprintf('\nYou can now upload model_structure.txt here.\n');