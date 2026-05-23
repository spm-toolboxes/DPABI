function SFC_Results = MainScript_SFC(SFC_Settings)
% MAINSCRIPT_SFC Main execution function for the SFC Toolbox.
% This function receives all settings from the GUI and coordinates the
% complete SFC analysis workflow.
%
% Required input structure fields:
%   WorkDir, Participants, Initialization, StatCorr, CommunicationModel,
%   DynamicAnalysis, GSP, Methods, ParallelWorkers

%% Add Subfunctions folder to MATLAB path

toolboxRoot = fileparts(mfilename('fullpath'));
subfunctionsDir = fullfile(toolboxRoot, 'Subfunctions');

if exist(subfunctionsDir, 'dir') == 7
    addpath(genpath(subfunctionsDir));
else
    warning('Subfunctions folder was not found: %s', subfunctionsDir);
end

%% Validate required settings

requiredFields = {'WorkDir', 'Participants', 'Initialization', ...
                  'StatCorr', 'CommunicationModel', 'DynamicAnalysis', ...
                  'GSP', 'Methods', 'ParallelWorkers'};

for iField = 1:numel(requiredFields)
    if ~isfield(SFC_Settings, requiredFields{iField})
        error('Missing required setting field: %s', requiredFields{iField});
    end
end

workDir = SFC_Settings.WorkDir;
if isstring(workDir)
    workDir = char(workDir);
end
if exist(workDir, 'dir') ~= 7
    error('Working directory does not exist: %s', workDir);
end

participants = SFC_Settings.Participants;
if isstring(participants)
    participants = cellstr(participants);
elseif ischar(participants)
    participants = cellstr(participants);
end
participants = participants(:);
if isempty(participants)
    error('Participant list is empty.');
end

%% Create Results folder at the same level as the working directory

[parentDir, ~] = fileparts(workDir);
resultsDir = fullfile(parentDir, 'SFC_Results');
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

timeStr = datestr(now, 'yyyy-mm-dd_HHMMSS');

fprintf('\n==========================================================\n');
fprintf('                 SFC TOOLBOX RUN STARTED\n');
fprintf('==========================================================\n');
fprintf('Working Directory : %s\n', workDir);
fprintf('Results Directory : %s\n', resultsDir);
fprintf('Participants      : %d\n', numel(participants));
fprintf('==========================================================\n\n');

%% Configure parallel workers

parallelWorkersRequested = SFC_Settings.ParallelWorkers;
parallelWorkersUsed = 1;
parallelEnabled = false;

if isempty(parallelWorkersRequested) || isnan(parallelWorkersRequested)
    parallelWorkersRequested = 1;
end
if parallelWorkersRequested < 1 || mod(parallelWorkersRequested, 1) ~= 0
    error('Parallel Workers must be a positive integer.');
end

if parallelWorkersRequested > 1
    fprintf('Requested parallel workers: %d\n', parallelWorkersRequested);
    if license('test', 'Distrib_Computing_Toolbox')
        try
            currentPool = gcp('nocreate');
            if isempty(currentPool)
                fprintf('Opening parallel pool with %d workers...\n', parallelWorkersRequested);
                parpool('local', parallelWorkersRequested);
            elseif currentPool.NumWorkers ~= parallelWorkersRequested
                fprintf('Restarting parallel pool: %d -> %d workers...\n', ...
                    currentPool.NumWorkers, parallelWorkersRequested);
                delete(currentPool);
                parpool('local', parallelWorkersRequested);
            else
                fprintf('Using existing parallel pool with %d workers.\n', currentPool.NumWorkers);
            end
            currentPool = gcp('nocreate');
            parallelWorkersUsed = currentPool.NumWorkers;
            parallelEnabled = true;
        catch ME
            warning('Unable to start parallel pool. Serial calculation will be used instead.');
            fprintf('Parallel pool error: %s\n', ME.message);
            parallelWorkersUsed = 1;
            parallelEnabled = false;
        end
    else
        warning('Parallel Computing Toolbox is unavailable. Serial calculation will be used.');
        parallelWorkersUsed = 1;
        parallelEnabled = false;
    end
else
    fprintf('Parallel Workers = 1: serial mode; no parallel pool will be opened.\n');
end

fprintf('Parallel Workers Requested : %d\n', parallelWorkersRequested);
fprintf('Parallel Workers Used      : %d\n\n', parallelWorkersUsed);

%% Save current run settings

SFC_Settings.WorkDir = workDir;
SFC_Settings.Participants = participants;
SFC_Settings.ResultsDir = resultsDir;
SFC_Settings.ParallelWorkersRequested = parallelWorkersRequested;
SFC_Settings.ParallelWorkersUsed = parallelWorkersUsed;
SFC_Settings.ParallelEnabled = parallelEnabled;
SFC_Settings.RunTime = datestr(now, 'yyyy-mm-dd HH:MM:SS');

runSettingsFile = fullfile(resultsDir, sprintf('SFC_Run_Settings_%s.mat', timeStr));
save(runSettingsFile, 'SFC_Settings');

%% Initialization

[structEdgeVec, funcEdgeVec, ids, Initialization_Parameters] = ...
    fcn_SFC_Initialization_hl( ...
        workDir, ...
        participants, ...
        SFC_Settings.Initialization.SCThresholding, ...
        SFC_Settings.Initialization.PreservePercent, ...
        resultsDir);

%% Initialize output structure

SFC_Results = struct;
SFC_Results.ResultsDir = resultsDir;
SFC_Results.RunSettingsFile = runSettingsFile;
SFC_Results.IDs = ids;
SFC_Results.InitializationParameters = Initialization_Parameters;

%% Method 1: Statistical Correlation Method

if isfield(SFC_Settings.Methods, 'StatisticalCorrelation') && SFC_Settings.Methods.StatisticalCorrelation
    fprintf('\n>>> Running Statistical Correlation Method...\n');

    [regional_SFC, StatCorr_SFC_Parameters] = ...
        fcn_calculate_StatCorr_SFC_multilevel_hl( ...
            structEdgeVec, ...
            funcEdgeVec, ...
            SFC_Settings.StatCorr.CorrelationType, ...
            SFC_Settings.StatCorr.MinSCDegree, ...
            resultsDir, ...
            ids, ...
            parallelWorkersUsed);

    r_SFC = regional_SFC; %#ok<NASGU>
    statCorrAggregateFile = fullfile(resultsDir, sprintf('StatCorr_SFC_Results_%s.mat', timeStr));
    save(statCorrAggregateFile, ...
        'regional_SFC', 'r_SFC', 'ids', 'Initialization_Parameters', ...
        'StatCorr_SFC_Parameters', 'SFC_Settings', '-v7.3');

    SFC_Results.StatCorr.RegionalSFC = regional_SFC;
    SFC_Results.StatCorr.Parameters = StatCorr_SFC_Parameters;
    SFC_Results.StatCorr.AggregateFile = statCorrAggregateFile;
else
    fprintf('\n>>> Statistical Correlation Method was not selected. Skipped.\n');
end

%% Method 2: Communication Model Method

if isfield(SFC_Settings.Methods, 'CommunicationModel') && SFC_Settings.Methods.CommunicationModel
    fprintf('\n>>> Running Communication Model Method...\n');

    nreg = infer_node_count_from_edgevec(structEdgeVec);
    [coords, coord_info] = load_coordinate_source(SFC_Settings.CommunicationModel.CoordinateMatrix, ids, nreg);

    comm_opts = normalize_comm_settings(SFC_Settings.CommunicationModel.Settings);
    comm_opts.compute_mode = 'regression';
    comm_opts.save_predictors = true;
    comm_opts.work_dir = workDir;
    comm_opts.sc_dir = fullfile(resultsDir, 'Thresholded_SC');
    comm_opts.fc_dir = fullfile(workDir, 'FC');
    comm_opts.results_dir = resultsDir;
    comm_opts.coordinate_info = coord_info;
    comm_opts.parallel_workers = parallelWorkersUsed;

    [r_coupling, beta_weights, pc_variance, predictor_outputs, CommModel_SFC_Parameters] = ...
        fcn_calculate_CommModel_SFC_RegionalPCA_wy( ...
            resultsDir, ...
            ids, ...
            SFC_Settings.CommunicationModel.PCACumulativeVariance, ...
            coords, ...
            comm_opts);

    commAggregateFile = fullfile(resultsDir, sprintf('CommModel_SFC_Results_%s.mat', timeStr));
    save(commAggregateFile, ...
        'r_coupling', 'beta_weights', 'pc_variance', 'predictor_outputs', ...
        'ids', 'coord_info', 'CommModel_SFC_Parameters', 'SFC_Settings', '-v7.3');

    SFC_Results.CommModel.RegionalSFC = r_coupling;
    SFC_Results.CommModel.Parameters = CommModel_SFC_Parameters;
    SFC_Results.CommModel.AggregateFile = commAggregateFile;
else
    fprintf('\n>>> Communication Model Method was not selected. Skipped.\n');
end

%% Method 3: Dynamic Analysis Method

if isfield(SFC_Settings.Methods, 'DynamicAnalysis') && SFC_Settings.Methods.DynamicAnalysis
    fprintf('\n>>> Running Dynamic Analysis Method...\n');

    if ~isfield(SFC_Settings, 'ROISignalsDir') || exist(SFC_Settings.ROISignalsDir, 'dir') ~= 7
        error('Dynamic Analysis Method requires a valid ROISignals folder.');
    end

    dynamic_opts = struct;
    dynamic_opts.method_selection = SFC_Settings.DynamicAnalysis.MethodSelection;
    dynamic_opts.corr_type = SFC_Settings.StatCorr.CorrelationType;
    dynamic_opts.min_sc_degree = SFC_Settings.StatCorr.MinSCDegree;
    dynamic_opts.parallel_workers = parallelWorkersUsed;

    if contains(lower(dynamic_opts.method_selection), 'communication')
        nreg = infer_node_count_from_edgevec(structEdgeVec);
        [coords_dyn, coord_info_dyn] = load_coordinate_source(SFC_Settings.DynamicAnalysis.CommunicationModel.CoordinateMatrix, ids, nreg);
        dynamic_opts.comm_settings = normalize_comm_settings(SFC_Settings.DynamicAnalysis.CommunicationModel.Settings);
        dynamic_opts.comm_settings.compute_mode = 'regression';
        dynamic_opts.comm_settings.save_predictors = false;
        dynamic_opts.coordinate_info = coord_info_dyn;
    else
        coords_dyn = [];
    end

    [dynamic_SFC, Dynamic_SFC_Parameters] = fcn_calculate_Dynamic_SFC_hl( ...
        structEdgeVec, ...
        resultsDir, ...
        ids, ...
        SFC_Settings.ROISignalsDir, ...
        coords_dyn, ...
        dynamic_opts);

    dynamicAggregateFile = fullfile(resultsDir, sprintf('Dynamic_SFC_Results_%s.mat', timeStr));
    save(dynamicAggregateFile, ...
        'dynamic_SFC', 'Dynamic_SFC_Parameters', 'ids', 'SFC_Settings', '-v7.3');

    SFC_Results.Dynamic.DynamicSFC = dynamic_SFC;
    SFC_Results.Dynamic.Parameters = Dynamic_SFC_Parameters;
    SFC_Results.Dynamic.AggregateFile = dynamicAggregateFile;
else
    fprintf('\n>>> Dynamic Analysis Method was not selected. Skipped.\n');
end

%% Method 4: Graph Signal Processing Method

if isfield(SFC_Settings.Methods, 'GraphSignalProcessing') && SFC_Settings.Methods.GraphSignalProcessing
    fprintf('\n>>> Running Graph Signal Processing Method...\n');

    if ~isfield(SFC_Settings, 'ROISignalsDir') || exist(SFC_Settings.ROISignalsDir, 'dir') ~= 7
        error('Graph Signal Processing Method requires a valid ROISignals folder.');
    end

    gsp_opts = SFC_Settings.GSP;
    gsp_opts.thresholded_sc_dir = fullfile(resultsDir, 'Thresholded_SC');
    gsp_opts.parallel_workers = parallelWorkersUsed;

    [r_SDI, GSP_SFC_Parameters] = fcn_calculate_GSP_SFC_regional_hl( ...
        resultsDir, ...
        ids, ...
        SFC_Settings.ROISignalsDir, ...
        gsp_opts);

    gspAggregateFile = fullfile(resultsDir, sprintf('GSP_SFC_Results_%s.mat', timeStr));
    save(gspAggregateFile, 'r_SDI', 'ids', 'GSP_SFC_Parameters', 'SFC_Settings', '-v7.3');

    SFC_Results.GSP.RegionalSDI = r_SDI;
    SFC_Results.GSP.Parameters = GSP_SFC_Parameters;
    SFC_Results.GSP.AggregateFile = gspAggregateFile;
else
    fprintf('\n>>> Graph Signal Processing Method was not selected. Skipped.\n');
end

%% Results View

nreg_results_view = infer_node_count_from_edgevec(structEdgeVec);
SFC_Results = SFC_generateResultsView(SFC_Results, SFC_Settings, ids, nreg_results_view);

fprintf('\n==========================================================\n');
fprintf('                 SFC TOOLBOX RUN COMPLETE\n');
fprintf('==========================================================\n');
fprintf('Results saved in: %s\n', resultsDir);
fprintf('Run settings saved in: %s\n', runSettingsFile);
if isfield(SFC_Results, 'StatCorr')
    fprintf('Statistical Correlation aggregate file: %s\n', SFC_Results.StatCorr.AggregateFile);
end
if isfield(SFC_Results, 'CommModel')
    fprintf('Communication Model aggregate file: %s\n', SFC_Results.CommModel.AggregateFile);
end
if isfield(SFC_Results, 'Dynamic')
    fprintf('Dynamic Analysis aggregate file: %s\n', SFC_Results.Dynamic.AggregateFile);
end
if isfield(SFC_Results, 'GSP')
    fprintf('GSP aggregate file: %s\n', SFC_Results.GSP.AggregateFile);
end
fprintf('==========================================================\n\n');

end

function nreg = infer_node_count_from_edgevec(edgevec)
    nedge = size(edgevec, 2);
    nreg_float = (1 + sqrt(1 + 8 * nedge)) / 2;
    if abs(nreg_float - round(nreg_float)) > 1e-10
        error('Unable to infer node count from edge vector length: %d.', nedge);
    end
    nreg = round(nreg_float);
end

function comm_settings = normalize_comm_settings(comm_settings)
    if nargin < 1 || isempty(comm_settings)
        comm_settings = struct;
    end
    if ~isfield(comm_settings, 'PredictorList') || isempty(comm_settings.PredictorList)
        comm_settings.PredictorList = {'Path Length', 'Path Transitivity', 'Search Information', ...
            'Flow Graphs', 'Euclidean Distance', 'Navigation', 'Communicability', ...
            'Matching Index', 'Cosine Similarity', 'Mean First Passage Time'};
    end
    if ~isfield(comm_settings, 'GammaValues') || isempty(comm_settings.GammaValues)
        comm_settings.GammaValues = [0.25 0.5 1 2];
    end
    if ~isfield(comm_settings, 'MarkovTimeValues') || isempty(comm_settings.MarkovTimeValues)
        comm_settings.MarkovTimeValues = [1 2.5 5 10];
    end
    if ~isfield(comm_settings, 'SCType') || isempty(comm_settings.SCType)
        comm_settings.SCType = 'Both Binary+Weighted';
    end

    comm_settings.predictor_list = comm_settings.PredictorList;
    comm_settings.gamma_vals = comm_settings.GammaValues;
    comm_settings.t_vals = comm_settings.MarkovTimeValues;
    comm_settings.sc_type = comm_settings.SCType;
end

function [coords, coord_info] = load_coordinate_source(coord_source, ids, nreg)
    coord_info = struct;
    coord_info.Source = coord_source;
    coord_info.Mode = 'None';
    coord_info.FileMap = cell(numel(ids), 1);
    coords = [];

    if nargin < 1 || isempty(coord_source)
        return;
    end
    if isstring(coord_source)
        coord_source = char(coord_source);
    end
    coord_source = strtrim(coord_source);
    if isempty(coord_source)
        return;
    end

    if exist(coord_source, 'file') == 2
        coords = load_coordinate_matrix_3col(coord_source, nreg);
        coord_info.Mode = 'Common single file';
        coord_info.FileMap(:) = {coord_source};
        return;
    end

    if exist(coord_source, 'dir') ~= 7
        error('Coordinate source does not exist: %s', coord_source);
    end

    coord_files = dir(fullfile(coord_source, '*.mat'));
    coord_files = coord_files(~[coord_files.isdir]);
    if isempty(coord_files)
        error('No MAT coordinate files were found in folder: %s', coord_source);
    elseif numel(coord_files) == 1
        coord_fullpath = fullfile(coord_source, coord_files(1).name);
        coords = load_coordinate_matrix_3col(coord_fullpath, nreg);
        coord_info.Mode = 'Common file in folder';
        coord_info.FileMap(:) = {coord_fullpath};
    else
        if numel(coord_files) ~= numel(ids)
            error(['Coordinate file count mismatch: %d files found, but %d subjects were initialized. ' ...
                   'Please provide either one common coordinate file or exactly one file per subject.'], ...
                   numel(coord_files), numel(ids));
        end
        coord_ids = cell(numel(coord_files), 1);
        for i = 1:numel(coord_files)
            token = regexp(coord_files(i).name, '(sub|Sub|SUB)[^_\.]+', 'match', 'once');
            if isempty(token)
                error('Subject ID could not be extracted from coordinate file: %s', coord_files(i).name);
            end
            coord_ids{i} = token;
        end
        coords = cell(numel(ids), 1);
        coord_info.Mode = 'Subject-specific folder';
        ids_lower = lower(ids(:));
        coord_ids_lower = lower(coord_ids(:));
        for i = 1:numel(ids)
            idx = find(strcmp(coord_ids_lower, ids_lower{i}), 1, 'first');
            if isempty(idx)
                error('Coordinate file was not found for subject: %s', ids{i});
            end
            coord_fullpath = fullfile(coord_source, coord_files(idx).name);
            coords{i} = load_coordinate_matrix_3col(coord_fullpath, nreg);
            coord_info.FileMap{i} = coord_fullpath;
        end
    end
end

function coords = load_coordinate_matrix_3col(coord_file, expected_nreg)
    % Load ROI coordinate matrix from a MAT file.
    % A valid coordinate matrix must have expected_nreg rows and at least
    % three columns. If more than three columns are provided, only the first
    % three columns are used as x, y, z coordinates.

    coord_data = load(coord_file);
    coord_vars = fieldnames(coord_data);

    candidate_names = {};
    candidate_row_match = [];

    for i = 1:numel(coord_vars)
        v = coord_data.(coord_vars{i});

        if isnumeric(v) && ismatrix(v) && ~isempty(v) && size(v, 2) >= 3
            candidate_names{end+1} = coord_vars{i}; %#ok<AGROW>
            candidate_row_match(end+1) = size(v, 1) == expected_nreg; %#ok<AGROW>
        end
    end

    if isempty(candidate_names)
        error(['Coordinate file must contain at least one numeric matrix with at least 3 columns: %s\n' ...
               'No eligible [nreg x >=3] matrix was found.'], coord_file);
    end

    % Prefer variables whose row number matches the expected number of regions.
    if any(candidate_row_match)
        candidate_names = candidate_names(logical(candidate_row_match));
    else
        detected_rows = cell(numel(candidate_names), 1);

        for i = 1:numel(candidate_names)
            detected_rows{i} = sprintf('%s: %d rows x %d columns', ...
                candidate_names{i}, ...
                size(coord_data.(candidate_names{i}), 1), ...
                size(coord_data.(candidate_names{i}), 2));
        end

        error(['No coordinate matrix has the expected number of rows in file: %s\n' ...
               'Expected rows: %d\nDetected candidates:\n%s'], ...
               coord_file, expected_nreg, strjoin(detected_rows, newline));
    end

    % If multiple valid variables exist, prefer common coordinate variable names.
    preferred_names = {'CoordinateMatrix', 'XYZCenter', 'ROICenter', ...
                       'Coord', 'Coords', 'coordinates', 'coord'};

    selected_name = '';

    for iPref = 1:numel(preferred_names)
        idx = find(strcmp(candidate_names, preferred_names{iPref}), 1, 'first');

        if ~isempty(idx)
            selected_name = candidate_names{idx};
            break;
        end
    end

    % If no preferred variable name is found, use the first row-matched candidate.
    if isempty(selected_name)
        selected_name = candidate_names{1};

        if numel(candidate_names) > 1
            fprintf(['Warning: Multiple numeric matrices with at least 3 columns and expected row count were found in %s.\n' ...
                     'Using variable "%s".\n'], coord_file, selected_name);
        end
    end

    coords_raw = coord_data.(selected_name);

    if size(coords_raw, 1) ~= expected_nreg
        error('Coordinate row count mismatch in %s: expected %d nodes, detected %d.', ...
              coord_file, expected_nreg, size(coords_raw, 1));
    end

    if size(coords_raw, 2) < 3
        error('Coordinate matrix must have at least 3 columns. Detected: %d in %s', ...
              size(coords_raw, 2), coord_file);
    end

    % Use the first three columns as x, y, z coordinates.
    coords = double(coords_raw(:, 1:3));

    if any(~isfinite(coords(:)))
        error('Coordinate matrix contains NaN or Inf values after extracting the first 3 columns: %s', ...
              coord_file);
    end

    fprintf('Coordinates loaded: %d nodes x %d columns from variable "%s"; using first 3 columns | %s\n', ...
        size(coords_raw, 1), size(coords_raw, 2), selected_name, coord_file);
end


function SFC_Results = SFC_generateResultsView(SFC_Results, SFC_Settings, ids, nreg)
    if ~isfield(SFC_Settings, 'ResultsView') || isempty(SFC_Settings.ResultsView)
        fprintf('\n>>> Results View was not configured. Skipped.\n');
        return;
    end

    view_settings = SFC_Settings.ResultsView;
    if ~isfield(view_settings, 'Enabled') || ~view_settings.Enabled
        fprintf('\n>>> Results View is disabled. Skipped.\n');
        return;
    end

    if ~isfield(SFC_Results, 'ResultsDir') || isempty(SFC_Results.ResultsDir)
        error('ResultsDir is missing from SFC_Results.');
    end

    atlas_info = SFC_prepareResultsViewAtlases(view_settings, nreg);
    view_root = fullfile(SFC_Results.ResultsDir, 'View');
    if ~exist(view_root, 'dir')
        mkdir(view_root);
    end

    fprintf('\n==========================================================\n');
    fprintf('                 RESULTS VIEW STARTED\n');
    fprintf('==========================================================\n');
    fprintf('View Root Directory : %s\n', view_root);
    fprintf('Regions             : %d\n', nreg);
    fprintf('==========================================================\n\n');

    view_outputs = struct;

    if isfield(SFC_Settings.Methods, 'StatisticalCorrelation') && SFC_Settings.Methods.StatisticalCorrelation && isfield(SFC_Results, 'StatCorr')
        method_dir = fullfile(view_root, 'Statistical_Correlation_Method');
        view_outputs.StatCorr = SFC_writeRegionalMatrixView(SFC_Results.StatCorr.RegionalSFC, ids, method_dir, 'StatCorr_Regional_SFC', atlas_info);
    end

    if isfield(SFC_Settings.Methods, 'CommunicationModel') && SFC_Settings.Methods.CommunicationModel && isfield(SFC_Results, 'CommModel')
        method_dir = fullfile(view_root, 'Communication_Model_Method');
        view_outputs.CommModel = SFC_writeRegionalMatrixView(SFC_Results.CommModel.RegionalSFC, ids, method_dir, 'CommModel_Regional_SFC', atlas_info);
    end

    if isfield(SFC_Settings.Methods, 'DynamicAnalysis') && SFC_Settings.Methods.DynamicAnalysis && isfield(SFC_Results, 'Dynamic')
        method_root = fullfile(view_root, 'Dynamic_Analysis_Method');
        mean_dir = fullfile(method_root, 'Regional_Coupling_Mean');
        variability_dir = fullfile(method_root, 'SFC_Variability');

        [dynamic_mean, dynamic_cv] = SFC_summarizeDynamicForView(SFC_Results.Dynamic.DynamicSFC, nreg);
        view_outputs.Dynamic.Mean = SFC_writeRegionalMatrixView(dynamic_mean, ids, mean_dir, 'Dynamic_SFC_Mean', atlas_info);
        view_outputs.Dynamic.Variability = SFC_writeRegionalMatrixView(dynamic_cv, ids, variability_dir, 'Dynamic_SFC_Variability', atlas_info);
    end

    if isfield(SFC_Settings.Methods, 'GraphSignalProcessing') && SFC_Settings.Methods.GraphSignalProcessing && isfield(SFC_Results, 'GSP')
        method_dir = fullfile(view_root, 'Graph_Signal_Processing_Method');
        view_outputs.GSP = SFC_writeRegionalMatrixView(SFC_Results.GSP.RegionalSDI, ids, method_dir, 'GSP_Regional_SDI', atlas_info);
    end

    view_parameter_file = fullfile(view_root, ['Results_View_Parameters_', datestr(now, 'yyyy-mm-dd_HHMMSS'), '.mat']);
    Results_View_Parameters = struct;
    Results_View_Parameters.Timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    Results_View_Parameters.Settings = view_settings;
    Results_View_Parameters.NodeCount = nreg;
    Results_View_Parameters.ViewRoot = view_root;
    Results_View_Parameters.AtlasInfo = atlas_info;
    Results_View_Parameters.Outputs = view_outputs;
    save(view_parameter_file, 'Results_View_Parameters');

    SFC_Results.ResultsView.ViewRoot = view_root;
    SFC_Results.ResultsView.Parameters = Results_View_Parameters;
    SFC_Results.ResultsView.ParameterFile = view_parameter_file;
    SFC_Results.ResultsView.Outputs = view_outputs;

    fprintf('\n==========================================================\n');
    fprintf('                 RESULTS VIEW COMPLETE\n');
    fprintf('==========================================================\n');
    fprintf('View files saved in : %s\n', view_root);
    fprintf('Parameter File      : %s\n', view_parameter_file);
    fprintf('==========================================================\n\n');
end

function atlas_info = SFC_prepareResultsViewAtlases(view_settings, nreg)
    vol_cortex_file = SFC_getOptionalPath(view_settings, 'VolumeSpaceCortexAtlas');
    vol_sub_file = SFC_getOptionalPath(view_settings, 'VolumeSpaceSubcorticalAtlas');
    surf_lh_file = SFC_getOptionalPath(view_settings, 'SurfaceSpaceCortexAtlasLH');
    surf_rh_file = SFC_getOptionalPath(view_settings, 'SurfaceSpaceCortexAtlasRH');

    has_vol_cortex = ~isempty(vol_cortex_file);
    has_sub = ~isempty(vol_sub_file);
    has_surface = ~isempty(surf_lh_file) || ~isempty(surf_rh_file);

    if has_surface && (isempty(surf_lh_file) || isempty(surf_rh_file))
        error('Surface space cortical visualization requires both LH and RH atlas files.');
    end
    if ~has_vol_cortex && ~has_surface
        error('Results View requires at least one cortical atlas.');
    end
    if has_sub && ~(has_vol_cortex || has_surface)
        error('A subcortical atlas cannot be used alone. Please also provide a cortical atlas.');
    end

    atlas_info = struct;
    atlas_info.NodeCount = nreg;
    atlas_info.HasVolumeCortex = has_vol_cortex;
    atlas_info.HasSurfaceCortex = has_surface;
    atlas_info.HasSubcortex = has_sub;

    if has_sub
        SFC_assertFileExists(vol_sub_file, 'Volume space subcortical tissue atlas');
        [sub_data, ~, ~, sub_header] = y_ReadAll(vol_sub_file);
        sub_labels = SFC_getAtlasLabels(sub_data);
        atlas_info.Subcortex.File = vol_sub_file;
        atlas_info.Subcortex.Data = sub_data;
        atlas_info.Subcortex.Header = sub_header;
        atlas_info.Subcortex.Labels = sub_labels;
        atlas_info.Subcortex.Count = numel(sub_labels);
    else
        atlas_info.Subcortex.Count = 0;
    end

    if has_vol_cortex
        SFC_assertFileExists(vol_cortex_file, 'Volume space cortex atlas');
        [vol_cortex_data, ~, ~, vol_cortex_header] = y_ReadAll(vol_cortex_file);
        vol_cortex_labels = SFC_getAtlasLabels(vol_cortex_data);
        vol_total = numel(vol_cortex_labels) + atlas_info.Subcortex.Count;
        if vol_total ~= nreg
            error(['Volume-space atlas region count mismatch. Cortex labels: %d, Subcortical labels: %d, Total: %d, ' ...
                   'but calculated SFC region count is %d.'], numel(vol_cortex_labels), atlas_info.Subcortex.Count, vol_total, nreg);
        end
        atlas_info.VolumeCortex.File = vol_cortex_file;
        atlas_info.VolumeCortex.Data = vol_cortex_data;
        atlas_info.VolumeCortex.Header = vol_cortex_header;
        atlas_info.VolumeCortex.Labels = vol_cortex_labels;
        atlas_info.VolumeCortex.Count = numel(vol_cortex_labels);
    end

    if has_surface
        SFC_assertFileExists(surf_lh_file, 'Surface space cortex atlas LH');
        SFC_assertFileExists(surf_rh_file, 'Surface space cortex atlas RH');
        [surf_lh_data, ~, ~, surf_lh_header] = y_ReadAll(surf_lh_file);
        [surf_rh_data, ~, ~, surf_rh_header] = y_ReadAll(surf_rh_file);
        lh_labels = SFC_getAtlasLabels(surf_lh_data);
        rh_labels = SFC_getAtlasLabels(surf_rh_data);
        [lh_map, rh_map, surface_count] = SFC_buildSurfaceLabelMapping(lh_labels, rh_labels);
        surf_total = surface_count + atlas_info.Subcortex.Count;
        if surf_total ~= nreg
            error(['Surface-space atlas region count mismatch. Surface cortex labels: %d, Subcortical labels: %d, Total: %d, ' ...
                   'but calculated SFC region count is %d.'], surface_count, atlas_info.Subcortex.Count, surf_total, nreg);
        end
        atlas_info.SurfaceCortex.LH.File = surf_lh_file;
        atlas_info.SurfaceCortex.LH.Data = surf_lh_data;
        atlas_info.SurfaceCortex.LH.Header = surf_lh_header;
        atlas_info.SurfaceCortex.LH.Labels = lh_labels;
        atlas_info.SurfaceCortex.LH.IndexMap = lh_map;
        atlas_info.SurfaceCortex.RH.File = surf_rh_file;
        atlas_info.SurfaceCortex.RH.Data = surf_rh_data;
        atlas_info.SurfaceCortex.RH.Header = surf_rh_header;
        atlas_info.SurfaceCortex.RH.Labels = rh_labels;
        atlas_info.SurfaceCortex.RH.IndexMap = rh_map;
        atlas_info.SurfaceCortex.Count = surface_count;
    end
end

function outputs = SFC_writeRegionalMatrixView(regional_matrix, ids, out_dir, prefix, atlas_info)
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    ids = ids(:);
    if isstring(ids)
        ids = cellstr(ids);
    end
    if size(regional_matrix, 1) ~= numel(ids)
        error('Regional result row count does not match participant count for %s.', prefix);
    end
    if size(regional_matrix, 2) ~= atlas_info.NodeCount
        error('Regional result column count does not match atlas node count for %s.', prefix);
    end

    outputs = cell(numel(ids), 1);
    for i = 1:numel(ids)
        sub_id = ids{i};
        value_vector = regional_matrix(i, :)';
        subject_prefix = SFC_cleanFilePart([sub_id, '_', prefix]);
        outputs{i} = SFC_writeSingleVectorView(value_vector, out_dir, subject_prefix, atlas_info);
    end
end

function output_files = SFC_writeSingleVectorView(value_vector, out_dir, prefix, atlas_info)
    value_vector = value_vector(:);
    output_files = {};

    if atlas_info.HasVolumeCortex
        nC = atlas_info.VolumeCortex.Count;
        cortex_values = value_vector(1:nC);
        cortex_out = SFC_fillVolumeAtlas( ...
            atlas_info.VolumeCortex.Data, ...
            atlas_info.VolumeCortex.Labels, ...
            cortex_values);

        out_file = fullfile(out_dir, [prefix, '_Volume_Cortex.nii']);

        % Write continuous regional values as floating-point NIfTI.
        % Do not keep the integer datatype of the atlas label image.
        SFC_writeFloatNifti(cortex_out, atlas_info.VolumeCortex.Header, out_file);

        output_files{end+1, 1} = out_file; %#ok<AGROW>

        if atlas_info.HasSubcortex
            nS = atlas_info.Subcortex.Count;
            sub_values = value_vector(nC+1:nC+nS);
            sub_out = SFC_fillVolumeAtlas( ...
                atlas_info.Subcortex.Data, ...
                atlas_info.Subcortex.Labels, ...
                sub_values);

            out_file = fullfile(out_dir, [prefix, '_Volume_Subcortical.nii']);

            % Write continuous regional values as floating-point NIfTI.
            SFC_writeFloatNifti(sub_out, atlas_info.Subcortex.Header, out_file);

            output_files{end+1, 1} = out_file; %#ok<AGROW>
        end
    end

    if atlas_info.HasSurfaceCortex
        nC = atlas_info.SurfaceCortex.Count;
        cortex_values = value_vector(1:nC);

        lh_out = SFC_fillSurfaceAtlas( ...
            atlas_info.SurfaceCortex.LH.Data, ...
            atlas_info.SurfaceCortex.LH.Labels, ...
            atlas_info.SurfaceCortex.LH.IndexMap, ...
            cortex_values);

        rh_out = SFC_fillSurfaceAtlas( ...
            atlas_info.SurfaceCortex.RH.Data, ...
            atlas_info.SurfaceCortex.RH.Labels, ...
            atlas_info.SurfaceCortex.RH.IndexMap, ...
            cortex_values);

        out_file_lh = fullfile(out_dir, [prefix, '_Surface_LH.func.gii']);
        out_file_rh = fullfile(out_dir, [prefix, '_Surface_RH.func.gii']);

        SFC_writeFunctionalGifti(lh_out, out_file_lh);
        SFC_writeFunctionalGifti(rh_out, out_file_rh);

        output_files{end+1, 1} = out_file_lh; %#ok<AGROW>
        output_files{end+1, 1} = out_file_rh; %#ok<AGROW>

        if atlas_info.HasSubcortex
            nS = atlas_info.Subcortex.Count;
            sub_values = value_vector(nC+1:nC+nS);
            sub_out = SFC_fillVolumeAtlas( ...
                atlas_info.Subcortex.Data, ...
                atlas_info.Subcortex.Labels, ...
                sub_values);

            out_file = fullfile(out_dir, [prefix, '_SurfaceMode_Subcortical.nii']);

            % Write continuous regional values as floating-point NIfTI.
            SFC_writeFloatNifti(sub_out, atlas_info.Subcortex.Header, out_file);

            output_files{end+1, 1} = out_file; %#ok<AGROW>
        end
    end
end

function [dynamic_mean, dynamic_cv] = SFC_summarizeDynamicForView(dynamic_SFC, nreg)
    nsub = numel(dynamic_SFC);
    dynamic_mean = nan(nsub, nreg);
    dynamic_cv = nan(nsub, nreg);
    for i = 1:nsub
        x = dynamic_SFC{i};
        if isempty(x)
            continue;
        end
        if size(x, 2) ~= nreg
            error('Dynamic SFC region count mismatch for subject %d.', i);
        end
        dynamic_mean(i, :) = SFC_nanmean(x, 1);
        dynamic_sd = SFC_nanstd(x, 0, 1);
        dynamic_cv(i, :) = dynamic_sd ./ dynamic_mean(i, :);
    end
end

function labels = SFC_getAtlasLabels(atlas_data)
    labels = unique(atlas_data(:));
    labels = labels(isfinite(labels) & labels > 0);
    labels = sort(labels(:));
    if isempty(labels)
        error('The selected atlas does not contain any positive parcel labels.');
    end
end

function [lh_map, rh_map, surface_count] = SFC_buildSurfaceLabelMapping(lh_labels, rh_labels)
    % Surface cortex mapping must follow the data-vector order, not the raw
    % atlas label values. This is robust to either of the common label styles:
    %   LH: 1-200, RH: 1-200
    %   LH: 1-200, RH: 201-400
    % and also to non-contiguous label values. The first LH label in sorted
    % order maps to Data(1), the first RH label in sorted order maps to
    % Data(numel(LH)+1).
    lh_labels = sort(lh_labels(:));
    rh_labels = sort(rh_labels(:));

    lh_map = containers.Map('KeyType', 'double', 'ValueType', 'double');
    rh_map = containers.Map('KeyType', 'double', 'ValueType', 'double');

    for i = 1:numel(lh_labels)
        lh_map(lh_labels(i)) = i;
    end

    for i = 1:numel(rh_labels)
        rh_map(rh_labels(i)) = numel(lh_labels) + i;
    end

    surface_count = numel(lh_labels) + numel(rh_labels);
end

function out_data = SFC_fillVolumeAtlas(atlas_data, labels, values)
    if numel(labels) ~= numel(values)
        error('Atlas label count and value vector length do not match.');
    end
    out_data = zeros(size(atlas_data));
    for i = 1:numel(labels)
        out_data(atlas_data == labels(i)) = values(i);
    end
end

function out_data = SFC_fillSurfaceAtlas(atlas_data, labels, index_map, values)
    % Fill a surface atlas using the stored label order and index map. The
    % index map is generated from sorted LH/RH labels and maps labels to the
    % corresponding position in the regional result vector.
    out_data = zeros(size(atlas_data));
    labels = labels(:);

    for i = 1:numel(labels)
        this_label = labels(i);
        if ~isKey(index_map, this_label)
            error('Surface atlas label %.6g was not found in the label-to-index map.', this_label);
        end

        idx = index_map(this_label);
        if idx < 1 || idx > numel(values)
            error('Surface atlas label %.6g maps to index %d, but the value vector length is %d.', this_label, idx, numel(values));
        end

        out_data(atlas_data == this_label) = values(idx);
    end
end

function SFC_writeFunctionalGifti(surface_data, out_file)
    % Write continuous surface values as a functional GIfTI overlay.
    % This intentionally avoids reusing label atlas headers.
    surface_data = single(surface_data);
    surface_data(~isfinite(surface_data)) = 0;

    g = gifti(surface_data);
    save(g, out_file, 'Base64Binary', 'RowMajorOrder');
end

function SFC_writeFloatNifti(volume_data, atlas_header, out_file)
% Write continuous regional values as a floating-point NIfTI file.
% Atlas headers often come from label images with integer datatype.
% If that datatype is reused, values such as 0.5365 may be written as 0.
% Therefore, force the output datatype to float32.

volume_data = single(volume_data);
volume_data(~isfinite(volume_data)) = 0;

float_header = atlas_header;

% SPM datatype 16 = float32.
if isfield(float_header, 'dt')
    float_header.dt = [16 0];
end

if isfield(float_header, 'pinfo')
    float_header.pinfo = [1; 0; 0];
end

if isfield(float_header, 'descrip')
    float_header.descrip = 'DPABI SFC continuous regional value map';
end

if isfield(float_header, 'dat')
    try
        float_header.dat.dtype = 'FLOAT32';
    catch
    end
end

y_Write(volume_data, float_header, out_file);
end

function path_value = SFC_getOptionalPath(s, field_name)
    path_value = '';
    if isfield(s, field_name) && ~isempty(s.(field_name))
        v = s.(field_name);
        if isstring(v)
            v = char(v);
        elseif iscell(v)
            v = v{1};
        end
        path_value = strtrim(v);
    end
end

function SFC_assertFileExists(file_path, label)
    if exist(file_path, 'file') ~= 2
        error('%s file does not exist: %s', label, file_path);
    end
end

function clean_name = SFC_cleanFilePart(input_name)
    clean_name = regexprep(input_name, '[^a-zA-Z0-9_\-]', '_');
end

function m = SFC_nanmean(x, dim)
    if nargin < 2
        dim = 1;
    end
    valid = isfinite(x);
    x2 = x;
    x2(~valid) = 0;
    count = sum(valid, dim);
    m = sum(x2, dim) ./ count;
    m(count == 0) = NaN;
end

function s = SFC_nanstd(x, flag, dim)
    if nargin < 2 || isempty(flag)
        flag = 0;
    end
    if nargin < 3
        dim = 1;
    end
    mu = SFC_nanmean(x, dim);
    if dim == 1
        mu_expand = repmat(mu, size(x, 1), 1);
    else
        mu_expand = repmat(mu, 1, size(x, 2));
    end
    valid = isfinite(x);
    dev = x - mu_expand;
    dev(~valid) = 0;
    count = sum(valid, dim);
    if flag == 0
        denom = max(count - 1, 0);
    else
        denom = count;
    end
    s = sqrt(sum(dev .^ 2, dim) ./ denom);
    s(denom == 0) = NaN;
end
