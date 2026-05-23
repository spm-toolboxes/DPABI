function [r_coupling, beta_weights, pc_variance, predictor_outputs, CommModel_SFC_Parameters] = ...
    fcn_calculate_CommModel_SFC_RegionalPCA_wy(results_dir, ids, cs, coords, opts)
% FCN_CALCULATE_COMMMODEL_SFC_REGIONALPCA_WY
% Compute regional SFC using selected communication-model predictors.
%
% This toolbox version saves selected communication-model predictor maps as
% one MAT file per subject, with one variable per selected generated model.

if nargin < 5 || isempty(opts)
    opts = struct();
end
if nargin < 4
    coords = [];
end

% Ensure local communication-model helpers are used before toolbox variants.
this_dir = fileparts(mfilename('fullpath'));
commmodel_dir = fullfile(this_dir, 'fcn_CommModel');
if exist(commmodel_dir, 'dir') == 7
    addpath(commmodel_dir, '-begin');
end

ids = normalize_ids(ids);
num_subjects = numel(ids);

if isempty(cs) || isnan(cs)
    cs = 80;
end
if cs <= 0 || cs > 100
    error('PCA cumulative variance must be within (0, 100].');
end

compute_mode = lower(strtrim(get_opt_value(opts, 'compute_mode', 'regression')));
if contains(compute_mode, 'predictor')
    compute_mode = 'predictors_only';
else
    compute_mode = 'regression';
end

save_predictors = logical(get_opt_value(opts, 'save_predictors', true));
sc_dir = get_opt_value(opts, 'sc_dir', fullfile(results_dir, 'Thresholded_SC'));
fc_dir = get_opt_value(opts, 'fc_dir', '');
parallel_workers = get_opt_value(opts, 'parallel_workers', 1);

predictor_cfg = struct();
predictor_cfg.predictor_list = get_opt_value(opts, 'predictor_list', get_opt_value(opts, 'PredictorList', { ...
    'Path Length', 'Path Transitivity', 'Search Information', ...
    'Flow Graphs', 'Euclidean Distance', 'Navigation', 'Communicability', ...
    'Matching Index', 'Cosine Similarity', 'Mean First Passage Time'}));
predictor_cfg.sc_type = get_opt_value(opts, 'sc_type', get_opt_value(opts, 'SCType', 'Both Binary+Weighted'));
predictor_cfg.gamma_vals = get_opt_value(opts, 'gamma_vals', get_opt_value(opts, 'GammaValues', [0.25, 0.5, 1, 2]));
predictor_cfg.t_vals = get_opt_value(opts, 't_vals', get_opt_value(opts, 'MarkovTimeValues', [1, 2.5, 5, 10]));

if isstring(predictor_cfg.predictor_list)
    predictor_cfg.predictor_list = cellstr(predictor_cfg.predictor_list);
end

if exist(sc_dir, 'dir') ~= 7
    error('SC folder for communication model was not found: %s', sc_dir);
end
if strcmp(compute_mode, 'regression') && exist(fc_dir, 'dir') ~= 7
    error('FC folder for communication model was not found: %s', fc_dir);
end

res_base = fullfile(results_dir, 'CommModel_SFC_Results');
regional_dir = fullfile(res_base, 'Regional_Coupling');
predictor_dir = fullfile(results_dir, 'CommModel_Predictor_Results');
if ~exist(res_base, 'dir'), mkdir(res_base); end
if ~exist(regional_dir, 'dir'), mkdir(regional_dir); end
if save_predictors && ~exist(predictor_dir, 'dir'), mkdir(predictor_dir); end

fprintf('\n----------------------------------------------------------\n');
fprintf('Method 2: Communication Model Started\n');
fprintf('Mode: %s\n', compute_mode);
if strcmp(compute_mode, 'regression')
    fprintf('PCA cumulative variance threshold: %.2f%%\n', cs);
end
fprintf('Selected model families: %s\n', strjoin(predictor_cfg.predictor_list, ', '));
fprintf('SC source: %s\n', sc_dir);
if strcmp(compute_mode, 'regression')
    fprintf('FC source: %s\n', fc_dir);
end
fprintf('----------------------------------------------------------\n');

r_coupling = [];
beta_weights = cell(num_subjects, 1);
pc_variance = cell(num_subjects, 1);
predictor_outputs = cell(num_subjects, 1);

% First pass determines node count and allocates SFC output when needed.
first_sc = load_matrix_for_subject(sc_dir, ids{1}, 'SC');
nreg = size(first_sc, 1);
if strcmp(compute_mode, 'regression')
    r_coupling = nan(num_subjects, nreg);
end

use_parfor = parallel_workers > 1 && ~isempty(gcp('nocreate'));

if use_parfor
    fprintf('Communication Model will be computed with parfor. Predictor saving is performed after parfor.\n');
    tmp_predictor_maps = cell(num_subjects, 1);
    tmp_predictor_labels = cell(num_subjects, 1);
    tmp_r = cell(num_subjects, 1);
    tmp_beta = cell(num_subjects, 1);
    tmp_var = cell(num_subjects, 1);

    parfor sub_idx = 1:num_subjects
        cur_id = ids{sub_idx};
        sc = load_matrix_for_subject(sc_dir, cur_id, 'SC');
        n = size(sc, 1);
        coords_this_sub = get_coords_for_subject(coords, sub_idx, num_subjects, cur_id, n);
        [predictor_maps, predictor_labels] = fcn_generate_CommModel_Predictors_wy(sc, coords_this_sub, predictor_cfg);
        tmp_predictor_maps{sub_idx} = predictor_maps;
        tmp_predictor_labels{sub_idx} = predictor_labels;

        if strcmp(compute_mode, 'regression')
            fc = load_matrix_for_subject(fc_dir, cur_id, 'FC');
            [tmp_r{sub_idx}, tmp_beta{sub_idx}, tmp_var{sub_idx}] = compute_regional_pca_sfc(fc, predictor_maps, cs);
        end
    end

    for sub_idx = 1:num_subjects
        cur_id = ids{sub_idx};
        predictor_maps = tmp_predictor_maps{sub_idx};
        predictor_labels = tmp_predictor_labels{sub_idx};
        predictor_outputs{sub_idx} = struct('subject_id', cur_id, ...
            'predictor_labels', {predictor_labels}, 'predictor_maps', predictor_maps);
        if save_predictors
            save_predictor_file(predictor_dir, cur_id, predictor_maps, predictor_labels);
        end
        if strcmp(compute_mode, 'regression')
            r_coupling(sub_idx, :) = tmp_r{sub_idx};
            beta_weights{sub_idx} = tmp_beta{sub_idx};
            pc_variance{sub_idx} = tmp_var{sub_idx};
            r_val = tmp_r{sub_idx}; %#ok<NASGU>
            save(fullfile(regional_dir, [cur_id, '_Regional.mat']), 'r_val');
        end
    end
else
    fprintf('Communication Model will be computed with serial for-loop.\n');
    for sub_idx = 1:num_subjects
        cur_id = ids{sub_idx};
        fprintf('Processing %-12s (%d/%d)\n', cur_id, sub_idx, num_subjects);
        sc = load_matrix_for_subject(sc_dir, cur_id, 'SC');
        n = size(sc, 1);
        coords_this_sub = get_coords_for_subject(coords, sub_idx, num_subjects, cur_id, n);
        [predictor_maps, predictor_labels] = fcn_generate_CommModel_Predictors_wy(sc, coords_this_sub, predictor_cfg);
        predictor_outputs{sub_idx} = struct('subject_id', cur_id, ...
            'predictor_labels', {predictor_labels}, 'predictor_maps', predictor_maps);
        if save_predictors
            save_predictor_file(predictor_dir, cur_id, predictor_maps, predictor_labels);
        end
        if strcmp(compute_mode, 'regression')
            fc = load_matrix_for_subject(fc_dir, cur_id, 'FC');
            [r_coupling_map, beta_cells, var_cells] = compute_regional_pca_sfc(fc, predictor_maps, cs);
            r_coupling(sub_idx, :) = r_coupling_map;
            beta_weights{sub_idx} = beta_cells;
            pc_variance{sub_idx} = var_cells;
            r_val = r_coupling_map; %#ok<NASGU>
            save(fullfile(regional_dir, [cur_id, '_Regional.mat']), 'r_val');
        end
    end
end

if strcmp(compute_mode, 'predictors_only')
    beta_weights = [];
    pc_variance = [];
end

time_str = datestr(now, 'yyyy-mm-dd_HHMMSS');
CommModel_SFC_Parameters = struct;
CommModel_SFC_Parameters.Timestamp = time_str;
CommModel_SFC_Parameters.ComputeMode = compute_mode;
CommModel_SFC_Parameters.PCACumulativeVariance = cs;
CommModel_SFC_Parameters.PredictorList = predictor_cfg.predictor_list;
CommModel_SFC_Parameters.SCType = predictor_cfg.sc_type;
CommModel_SFC_Parameters.GammaValues = predictor_cfg.gamma_vals;
CommModel_SFC_Parameters.MarkovTimeValues = predictor_cfg.t_vals;
CommModel_SFC_Parameters.SavePredictors = save_predictors;
CommModel_SFC_Parameters.SCSourceDir = sc_dir;
CommModel_SFC_Parameters.FCSourceDir = fc_dir;
CommModel_SFC_Parameters.PredictorResultDir = predictor_dir;
CommModel_SFC_Parameters.RegionalResultDir = regional_dir;
CommModel_SFC_Parameters.ParallelWorkersUsed = parallel_workers;

parameter_file = fullfile(res_base, sprintf('CommModel_SFC_Parameters_%s.mat', time_str));
save(parameter_file, 'CommModel_SFC_Parameters');
CommModel_SFC_Parameters.ParameterFile = parameter_file;

fprintf('\n==========================================================\n');
fprintf('  SFC CALCULATION COMPLETE (Communication Model) (%s)\n', time_str);
fprintf('==========================================================\n');
fprintf('Subjects Processed   : %d\n', num_subjects);
fprintf('Compute Mode         : %s\n', compute_mode);
fprintf('Predictor Save Dir   : %s\n', predictor_dir);
if strcmp(compute_mode, 'regression')
    fprintf('Regional Result Dir  : %s\n', regional_dir);
end
fprintf('Parameter File       : %s\n', parameter_file);
fprintf('==========================================================\n\n');
end

function [r_coupling_map, beta_cells, var_cells] = compute_regional_pca_sfc(fc, predictor_maps, cs)
    n = size(fc, 1);
    if size(fc, 2) ~= n
        error('FC matrix must be square.');
    end
    if size(predictor_maps, 1) ~= n || size(predictor_maps, 2) ~= n
        error('Predictor map dimensions do not match FC.');
    end
    r_coupling_map = nan(1, n);
    beta_cells = cell(n, 1);
    var_cells = cell(n, 1);
    for i = 1:n
        y = fc(i, :)';
        y(i) = [];
        X_raw = squeeze(predictor_maps(i, :, :));
        X_raw(i, :) = [];
        X_raw(~isfinite(X_raw)) = 0;
        y(~isfinite(y)) = 0;

        X_z = zscore(X_raw);
        X_z(~isfinite(X_z)) = 0;
        zero_cols = std(X_z, 0, 1) == 0;
        X_z(:, zero_cols) = 0;

        if size(X_z, 2) == 1
            score = X_z;
            explained = 100;
        else
            [~, score, ~, ~, explained] = pca(X_z);
        end

        cum_explained = cumsum(explained);
        num_comps = find(cum_explained >= cs, 1, 'first');
        if isempty(num_comps)
            num_comps = size(score, 2);
        end
        X_pca = score(:, 1:num_comps);

        if size(X_pca, 1) > num_comps + 2
            mdl = fitlm(X_pca, y);
            r_coupling_map(i) = sqrt(max(mdl.Rsquared.Ordinary, 0));
            if numel(mdl.Coefficients.Estimate) > 1
                beta_cells{i} = mdl.Coefficients.Estimate(2:end)';
            end
            var_cells{i} = explained(1:num_comps);
        end
    end
end

function save_predictor_file(predictor_dir, subject_id, predictor_maps, predictor_labels)
    predictor_struct = struct;
    for k = 1:numel(predictor_labels)
        var_name = matlab.lang.makeValidName(predictor_labels{k});
        predictor_struct.(var_name) = predictor_maps(:, :, k);
    end
    predictor_labels_saved = predictor_labels; %#ok<NASGU>
    predictor_struct.predictor_labels = predictor_labels_saved;
    predictor_file = fullfile(predictor_dir, [subject_id, '_CommModels.mat']);
    save(predictor_file, '-struct', 'predictor_struct', '-v7.3');
end

function mat = load_matrix_for_subject(data_dir, subject_id, data_type)
    files = dir(fullfile(data_dir, ['*', subject_id, '*.mat']));
    if isempty(files)
        files = dir(fullfile(data_dir, ['*', lower(subject_id), '*.mat']));
    end
    if isempty(files)
        error('%s file was not found for subject %s in %s.', data_type, subject_id, data_dir);
    end
    data = load(fullfile(data_dir, files(1).name));
    mat = load_first_matrix(data);
    if ~isnumeric(mat) || ndims(mat) ~= 2
        error('%s file for subject %s does not contain a numeric 2-D matrix.', data_type, subject_id);
    end
    if size(mat, 1) ~= size(mat, 2)
        error('%s matrix for subject %s must be square.', data_type, subject_id);
    end
    mat = double(mat);
    mat(~isfinite(mat)) = 0;
end

function value = load_first_matrix(data_struct)
    fn = fieldnames(data_struct);
    value = [];
    for i = 1:numel(fn)
        v = data_struct.(fn{i});
        if isnumeric(v) && ndims(v) == 2 && ~isempty(v)
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
        return;
    end
    if ~isnumeric(coords_this_sub) || ~ismatrix(coords_this_sub) || size(coords_this_sub, 2) < 3
        error('Coordinate input for subject %s must be a numeric matrix with at least 3 columns.', cur_id);
    end
    if size(coords_this_sub, 1) ~= expected_nreg
        error('Coordinate row count mismatch for subject %s: expected %d, detected %d.', ...
            cur_id, expected_nreg, size(coords_this_sub, 1));
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
