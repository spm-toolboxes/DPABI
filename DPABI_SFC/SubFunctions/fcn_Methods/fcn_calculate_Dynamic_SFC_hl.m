function [dynamic_SFC, Dynamic_SFC_Parameters] = fcn_calculate_Dynamic_SFC_hl(struct_edgevec, results_dir, common_ids, roi_signals_dir, coords, opts)
% FCN_CALCULATE_DYNAMIC_SFC_HL Time-resolved regional SFC.
%
% This toolbox version does not open interactive dialogs. All settings are
% passed from SFC_Toolbox/MainScript_SFC. If the communication-model path is
% selected, communication-model predictors are generated in memory only and
% are not saved.

if nargin < 6 || isempty(opts)
    opts = struct();
end
if nargin < 5
    coords = [];
end

common_ids = normalize_ids(common_ids);
nsub = numel(common_ids);
nreg_float = (1 + sqrt(1 + 8 * size(struct_edgevec, 2))) / 2;
if abs(nreg_float - round(nreg_float)) > 1e-10
    error('Unable to infer node count from edge vector length.');
end
nreg = round(nreg_float);

if exist(roi_signals_dir, 'dir') ~= 7
    error('ROISignals folder was not found: %s', roi_signals_dir);
end

method_choice = get_opt_value(opts, 'method_selection', 'Statistical Correlation');
if contains(lower(method_choice), 'communication')
    calc_mode = 'CommModel';
else
    calc_mode = 'StatCorr';
end

corr_type = get_opt_value(opts, 'corr_type', 'Spearman');
min_sc_degree = get_opt_value(opts, 'min_sc_degree', 10);
parallel_workers = get_opt_value(opts, 'parallel_workers', 1);

% Initialize communication-model predictor settings before parfor.
% MATLAB parfor requires every broadcast variable referenced inside the parfor
% body to exist before the loop, even when the active branch is StatCorr.
predictor_cfg = struct;

if strcmp(calc_mode, 'CommModel')
    comm_settings = get_opt_value(opts, 'comm_settings', struct);
    predictor_cfg.predictor_list = get_opt_value(comm_settings, 'predictor_list', get_opt_value(comm_settings, 'PredictorList', { ...
        'Path Length', 'Path Transitivity', 'Search Information', ...
        'Flow Graphs', 'Euclidean Distance', 'Navigation', 'Communicability', ...
        'Matching Index', 'Cosine Similarity', 'Mean First Passage Time'}));
    predictor_cfg.sc_type = get_opt_value(comm_settings, 'sc_type', get_opt_value(comm_settings, 'SCType', 'Both Binary+Weighted'));
    predictor_cfg.gamma_vals = get_opt_value(comm_settings, 'gamma_vals', get_opt_value(comm_settings, 'GammaValues', [0.25 0.5 1 2]));
    predictor_cfg.t_vals = get_opt_value(comm_settings, 't_vals', get_opt_value(comm_settings, 'MarkovTimeValues', [1 2.5 5 10]));
end

res_base = fullfile(results_dir, 'Dynamic_SFC_Results');
regional_dir = fullfile(res_base, 'Regional_Coupling');
regional_mean_dir = fullfile(res_base, 'Regional_Coupling_Mean');
variability_dir = fullfile(res_base, 'SFC_Variability_Results');
if ~exist(res_base, 'dir')
    mkdir(res_base);
end
if ~exist(regional_dir, 'dir')
    mkdir(regional_dir);
end
if ~exist(regional_mean_dir, 'dir')
    mkdir(regional_mean_dir);
end
if ~exist(variability_dir, 'dir')
    mkdir(variability_dir);
end

dynamic_SFC = cell(nsub, 1);

fprintf('\n==========================================================\n');
fprintf('             DYNAMIC SFC CALCULATION STARTED\n');
fprintf('==========================================================\n');
fprintf('Method               : %s\n', method_choice);
fprintf('ROISignals folder    : %s\n', roi_signals_dir);
fprintf('Participants         : %d\n', nsub);
fprintf('Regions              : %d\n', nreg);
fprintf('Parallel Workers Used: %d\n', parallel_workers);
fprintf('==========================================================\n\n');

use_parfor = parallel_workers > 1 && ~isempty(gcp('nocreate'));

if use_parfor
    fprintf('Dynamic SFC will be computed with parfor.\n');
    parfor i = 1:nsub
        sub_id = common_ids{i};
        sc_mat = squareform(struct_edgevec(i, :));
        ts = load_roi_timeseries(roi_signals_dir, sub_id, nreg);
        if strcmp(calc_mode, 'StatCorr')
            sub_dyn_map = compute_dynamic_statcorr(sc_mat, ts, corr_type, min_sc_degree);
        else
            coords_this_sub = get_coords_for_subject(coords, i, nsub, sub_id, nreg);
            [predictor_maps, ~] = fcn_generate_CommModel_Predictors_wy(sc_mat, coords_this_sub, predictor_cfg);
            sub_dyn_map = compute_dynamic_commmodel(ts, predictor_maps);
        end
        dynamic_SFC{i} = sub_dyn_map;
    end
else
    fprintf('Dynamic SFC will be computed with serial for-loop.\n');
    for i = 1:nsub
        sub_id = common_ids{i};
        fprintf('Processing Subject: %-12s (%d/%d)\n', sub_id, i, nsub);
        sc_mat = squareform(struct_edgevec(i, :));
        ts = load_roi_timeseries(roi_signals_dir, sub_id, nreg);
        if strcmp(calc_mode, 'StatCorr')
            sub_dyn_map = compute_dynamic_statcorr(sc_mat, ts, corr_type, min_sc_degree);
        else
            coords_this_sub = get_coords_for_subject(coords, i, nsub, sub_id, nreg);
            [predictor_maps, ~] = fcn_generate_CommModel_Predictors_wy(sc_mat, coords_this_sub, predictor_cfg);
            sub_dyn_map = compute_dynamic_commmodel(ts, predictor_maps);
        end
        dynamic_SFC{i} = sub_dyn_map;
    end
end

for i = 1:nsub
    sub_id = common_ids{i};
    sub_dyn_map = dynamic_SFC{i}; %#ok<NASGU>
    save(fullfile(regional_dir, [sub_id, '_Dynamic_SFC.mat']), 'sub_dyn_map', '-v7.3');
    dynamic_sfc_mean = mean(sub_dyn_map, 1, 'omitnan'); %#ok<NASGU>
    save(fullfile(regional_mean_dir, [sub_id, '_Dynamic_SFC_Mean.mat']), 'dynamic_sfc_mean');
    sfc_cv = std(sub_dyn_map, 0, 1, 'omitnan') ./ mean(sub_dyn_map, 1, 'omitnan'); %#ok<NASGU>
    save(fullfile(variability_dir, [sub_id, '_Dynamic_SFC_Variability.mat']), 'sfc_cv');
end

time_str = datestr(now, 'yyyy-mm-dd_HHMMSS');
Dynamic_SFC_Parameters = struct;
Dynamic_SFC_Parameters.Timestamp = time_str;
Dynamic_SFC_Parameters.Method = method_choice;
Dynamic_SFC_Parameters.CalculationMode = calc_mode;
Dynamic_SFC_Parameters.ROISignalsDir = roi_signals_dir;
Dynamic_SFC_Parameters.ResultRootDir = res_base;
Dynamic_SFC_Parameters.RegionalResultDir = regional_dir;
Dynamic_SFC_Parameters.RegionalMeanResultDir = regional_mean_dir;
Dynamic_SFC_Parameters.VariabilityResultDir = variability_dir;
Dynamic_SFC_Parameters.SubjectCount = nsub;
Dynamic_SFC_Parameters.RegionCount = nreg;
Dynamic_SFC_Parameters.ParallelWorkersUsed = parallel_workers;
if strcmp(calc_mode, 'StatCorr')
    Dynamic_SFC_Parameters.CorrelationType = corr_type;
    Dynamic_SFC_Parameters.MinSCDegree = min_sc_degree;
else
    Dynamic_SFC_Parameters.CommunicationModelSettings = predictor_cfg;
    Dynamic_SFC_Parameters.CommunicationPredictorsSaved = false;
end

parameter_file = fullfile(res_base, ['Dynamic_SFC_Parameters_', time_str, '.mat']);
save(parameter_file, 'Dynamic_SFC_Parameters');
Dynamic_SFC_Parameters.ParameterFile = parameter_file;

fprintf('\n==========================================================\n');
fprintf('        SFC CALCULATION COMPLETE (Dynamic Analysis)\n');
fprintf('==========================================================\n');
fprintf('Matched Subjects    : %d\n', nsub);
fprintf('Calculation Method  : %s\n', method_choice);
fprintf('Dynamic Result Dir  : %s\n', regional_dir);
fprintf('Dynamic Mean Dir    : %s\n', regional_mean_dir);
fprintf('Variability Dir     : %s\n', variability_dir);
fprintf('Parameter File      : %s\n', parameter_file);
fprintf('==========================================================\n\n');
end

function sub_dyn_map = compute_dynamic_statcorr(sc_mat, raw_ts, corr_type, min_deg)
    z_ts = zscore(raw_ts, 0, 2);
    z_ts(~isfinite(z_ts)) = 0;
    nreg = size(z_ts, 1);
    ntime = size(z_ts, 2);
    sub_dyn_map = nan(ntime, nreg);
    for t = 1:ntime
        curr_z = z_ts(:, t);
        co_fluct_matrix = curr_z * curr_z';
        for r = 1:nreg
            sc_profile = sc_mat(r, :)';
            y = co_fluct_matrix(r, :)';
            idx = find(sc_profile > 0);
            if numel(idx) >= min_deg
                sub_dyn_map(t, r) = corr(sc_profile(idx), y(idx), 'type', corr_type, 'rows', 'complete');
            end
        end
    end
end

function sub_dyn_map = compute_dynamic_commmodel(raw_ts, predictor_maps)
    z_ts = zscore(raw_ts, 0, 2);
    z_ts(~isfinite(z_ts)) = 0;
    nreg = size(z_ts, 1);
    ntime = size(z_ts, 2);
    sub_dyn_map = nan(ntime, nreg);
    for t = 1:ntime
        curr_z = z_ts(:, t);
        co_fluct_matrix = curr_z * curr_z';
        for r = 1:nreg
            y = co_fluct_matrix(r, :)';
            y(r) = [];
            X_raw = squeeze(predictor_maps(r, :, :));
            X_raw(r, :) = [];
            X_raw(~isfinite(X_raw)) = 0;
            y(~isfinite(y)) = 0;
            if size(X_raw, 1) > size(X_raw, 2) + 2
                mdl = fitlm(X_raw, y);
                sub_dyn_map(t, r) = mdl.Rsquared.Ordinary;
            end
        end
    end
end

function ts = load_roi_timeseries(roi_dir, subject_id, nreg)
    files = dir(fullfile(roi_dir, ['*', subject_id, '*.mat']));
    if isempty(files)
        files = dir(fullfile(roi_dir, ['*', lower(subject_id), '*.mat']));
    end
    if isempty(files)
        error('ROISignals file was not found for subject %s in %s.', subject_id, roi_dir);
    end
    data = load(fullfile(roi_dir, files(1).name));
    ts = load_first_matrix(data);
    if size(ts, 1) ~= nreg && size(ts, 2) == nreg
        ts = ts';
    end
    if size(ts, 1) ~= nreg
        error('ROISignals dimension mismatch for subject %s. Expected %d rows or columns.', subject_id, nreg);
    end
    ts = double(ts);
    ts(~isfinite(ts)) = 0;
end

function value = load_first_matrix(data_struct)
    fn = fieldnames(data_struct);
    for i = 1:numel(fn)
        v = data_struct.(fn{i});
        if isnumeric(v) && ismatrix(v) && ~isempty(v)
            value = v;
            return;
        end
    end
    error('No numeric matrix variable found in MAT file.');
end

function coords_this_sub = get_coords_for_subject(coords, sub_idx, num_subjects, cur_id, expected_nreg)
    if iscell(coords)
        if numel(coords) ~= num_subjects
            error('Subject-specific coordinates must contain one entry per subject.');
        end
        coords_this_sub = coords{sub_idx};
    else
        coords_this_sub = coords;
    end
    if isempty(coords_this_sub)
        error('Communication-model dynamic analysis requires coordinate matrix for subject %s.', cur_id);
    end
    if ~isnumeric(coords_this_sub) || ~ismatrix(coords_this_sub) || size(coords_this_sub, 2) < 3
        error('Coordinate input for subject %s must be a numeric matrix with at least 3 columns.', cur_id);
    end
    if size(coords_this_sub, 1) ~= expected_nreg
        error('Coordinate row count mismatch for subject %s: expected %d, detected %d.', cur_id, expected_nreg, size(coords_this_sub, 1));
    end
    coords_this_sub = coords_this_sub(:, 1:3);
end

function ids = normalize_ids(ids)
    if isstring(ids)
        ids = cellstr(ids);
    elseif ischar(ids)
        ids = cellstr(ids);
    end
    ids = ids(:);
end

function value = get_opt_value(opts, field_name, default_value)
    if isfield(opts, field_name)
        value = opts.(field_name);
    else
        value = default_value;
    end
end
