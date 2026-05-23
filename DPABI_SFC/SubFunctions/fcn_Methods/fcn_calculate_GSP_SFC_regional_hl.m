function [regional_SFC, GSP_SFC_Parameters] = fcn_calculate_GSP_SFC_regional_hl(results_dir, common_ids, roi_signals_dir, opts)
% FCN_CALCULATE_GSP_SFC_REGIONAL_HL Regional SFC using Graph Signal Processing.
%
% This toolbox version receives all inputs from SFC_Toolbox and requires SC
% source input to be a folder. It does not open file-selection dialogs.

if nargin < 4 || isempty(opts)
    opts = struct();
end

common_ids = normalize_ids(common_ids);
nsub = numel(common_ids);

if exist(roi_signals_dir, 'dir') ~= 7
    error('ROISignals folder was not found: %s', roi_signals_dir);
end

average_sc_source = get_opt_value(opts, 'AverageSCSource', 'Compute from the Thresholded SC Folder');
sc_source_path = strtrim(get_opt_value(opts, 'GSPSCSource', ''));
thresholded_sc_dir = get_opt_value(opts, 'thresholded_sc_dir', fullfile(results_dir, 'Thresholded_SC'));
auc_cutoff = get_opt_value(opts, 'AUCCutoff', 50);
parallel_workers = get_opt_value(opts, 'parallel_workers', 1);

if isempty(auc_cutoff) || isnan(auc_cutoff)
    auc_cutoff = 50;
end
if auc_cutoff <= 0 || auc_cutoff >= 100
    error('AUC cutoff must be within (0, 100).');
end


if contains(lower(average_sc_source), 'threshold') || isempty(sc_source_path)
    sc_source_path = thresholded_sc_dir;
end

% The SC source can be either a single average-SC MAT file or a folder of SC MAT files.
if exist(sc_source_path, 'file') == 2
    W_avg = load_first_matrix(load(sc_source_path));
    matched_count = 1;
    sc_source_report = sc_source_path;
elseif exist(sc_source_path, 'dir') == 7
    sc_dir = sc_source_path;
    sc_list = dir(fullfile(sc_dir, '*.mat'));
    sc_list = sc_list(~[sc_list.isdir]);
    if isempty(sc_list)
        error('No MAT files were found in GSP SC source folder: %s', sc_dir);
    end

    W_sum = [];
    matched_count = 0;
    for i = 1:nsub
        sub_id = common_ids{i};
        try
            W = load_matrix_for_subject(sc_dir, sub_id, 'SC');
        catch
            continue;
        end
        if isempty(W_sum)
            W_sum = zeros(size(W));
        end
        if size(W, 1) ~= size(W_sum, 1) || size(W, 2) ~= size(W_sum, 2)
            error('SC dimension mismatch in GSP source folder for subject %s.', sub_id);
        end
        W_sum = W_sum + W;
        matched_count = matched_count + 1;
    end

    if matched_count == 0
        fprintf('No subject-matched SC files found. Averaging all MAT files in the selected folder.\n');
        for i = 1:numel(sc_list)
            W = load_first_matrix(load(fullfile(sc_dir, sc_list(i).name)));
            if isempty(W_sum)
                W_sum = zeros(size(W));
            end
            if size(W, 1) ~= size(W_sum, 1) || size(W, 2) ~= size(W_sum, 2)
                error('SC dimension mismatch in selected GSP SC source folder.');
            end
            W_sum = W_sum + W;
        end
        matched_count = numel(sc_list);
    end

    W_avg = W_sum ./ matched_count;
    sc_source_report = sc_dir;
else
    error('GSP SC source must be a valid MAT file or folder. Current value: %s', sc_source_path);
end

W_avg = double(W_avg);
W_avg(~isfinite(W_avg)) = 0;
W_avg(1:size(W_avg, 1)+1:end) = 0;
nreg = size(W_avg, 1);

fprintf('\n==========================================================\n');
fprintf('             GSP SFC CALCULATION STARTED\n');
fprintf('==========================================================\n');
fprintf('SC source            : %s\n', sc_source_report);
fprintf('ROISignals folder     : %s\n', roi_signals_dir);
fprintf('AUC cutoff            : %.2f%%\n', auc_cutoff);
fprintf('Participants          : %d\n', nsub);
fprintf('Regions               : %d\n', nreg);
fprintf('Parallel Workers Used : %d\n', parallel_workers);
fprintf('==========================================================\n\n');

% Symmetric normalization.
degree_vec = sum(W_avg, 2);
degree_vec(degree_vec <= 0) = eps;
D_inv_sqrt = diag(1 ./ sqrt(degree_vec));
W_norm = D_inv_sqrt * W_avg * D_inv_sqrt;
W_norm(~isfinite(W_norm)) = 0;

% Graph Laplacian eigendecomposition.
L = eye(nreg) - W_norm;
[U, Lambda] = eig(L);
[~, ind] = sort(diag(Lambda));
U = U(:, ind);
M = fliplr(U);

% First pass: group energy spectral density.
all_psd = zeros(nreg, 1);
for i = 1:nsub
    raw_fmri = load_roi_timeseries(roi_signals_dir, common_ids{i}, nreg);
    z_fmri = zscore(raw_fmri, 0, 2);
    z_fmri(~isfinite(z_fmri)) = 0;
    X_hat = U' * z_fmri;
    all_psd = all_psd + mean(abs(X_hat).^2, 2);
end
avg_psd = all_psd ./ nsub;

% AUC-based cutoff.
auc_total = trapz(avg_psd);
auc_target = auc_total * (auc_cutoff / 100);
auc_current = 0;
C = 0;
while auc_current < auc_target && C < nreg
    C = C + 1;
    auc_current = trapz(avg_psd(1:C));
end
C = max(1, min(C, nreg - 1));

nnL = nreg - C;
Vlow = zeros(size(M));
Vhigh = zeros(size(M));
Vhigh(:, 1:nnL) = M(:, 1:nnL);
Vlow(:, end-C+1:end) = M(:, end-C+1:end);

regional_SFC = nan(nsub, nreg);
gsp_root = fullfile(results_dir, 'GSP_SFC_Results');
regional_dir = fullfile(gsp_root, 'Regional_Coupling');
if ~exist(gsp_root, 'dir')
    mkdir(gsp_root);
end
if ~exist(regional_dir, 'dir')
    mkdir(regional_dir);
end

use_parfor = parallel_workers > 1 && ~isempty(gcp('nocreate'));

if use_parfor
    fprintf('GSP SFC will be computed with parfor.\n');
    parfor i = 1:nsub
        raw_fmri = load_roi_timeseries(roi_signals_dir, common_ids{i}, nreg);
        regional_SFC(i, :) = compute_sdi_row(raw_fmri, M, Vlow, Vhigh);
    end
else
    fprintf('GSP SFC will be computed with serial for-loop.\n');
    for i = 1:nsub
        sub_id = common_ids{i};
        fprintf('Processing Subject: %-12s (%d/%d)\n', sub_id, i, nsub);
        raw_fmri = load_roi_timeseries(roi_signals_dir, sub_id, nreg);
        regional_SFC(i, :) = compute_sdi_row(raw_fmri, M, Vlow, Vhigh);
    end
end

for i = 1:nsub
    sub_id = common_ids{i};
    r_val = regional_SFC(i, :); %#ok<NASGU>
    save(fullfile(regional_dir, [sub_id, '_Regional.mat']), 'r_val');
end

time_str = datestr(now, 'yyyy-mm-dd_HHMMSS');
GSP_SFC_Parameters = struct;
GSP_SFC_Parameters.Timestamp = time_str;
GSP_SFC_Parameters.SCBackboneSource = average_sc_source;
GSP_SFC_Parameters.SCSource = sc_source_report;
GSP_SFC_Parameters.ROISignalsDir = roi_signals_dir;
GSP_SFC_Parameters.AUCCutoffPercent = auc_cutoff;
GSP_SFC_Parameters.AUCCutoffIndex = C;
GSP_SFC_Parameters.NodeCount = nreg;
GSP_SFC_Parameters.SubjectCount = nsub;
GSP_SFC_Parameters.CalculationMethod = 'Graph Signal Processing Structural-Decoupling Index';
GSP_SFC_Parameters.ResultRootDir = gsp_root;
GSP_SFC_Parameters.RegionalResultDir = regional_dir;
GSP_SFC_Parameters.ParallelWorkersUsed = parallel_workers;

parameter_file = fullfile(gsp_root, sprintf('GSP_SFC_Parameters_%s.mat', time_str));
save(parameter_file, 'GSP_SFC_Parameters', 'W_avg', 'avg_psd', 'C');
GSP_SFC_Parameters.ParameterFile = parameter_file;

fprintf('\n==========================================================\n');
fprintf('        SFC CALCULATION COMPLETE (GSP Method)\n');
fprintf('==========================================================\n');
fprintf('Matched Subjects    : %d\n', nsub);
fprintf('AUC Cutoff Index    : %d\n', C);
fprintf('Regional Result Dir : %s\n', regional_dir);
fprintf('Parameter File      : %s\n', parameter_file);
fprintf('==========================================================\n\n');
end

function sdi_row = compute_sdi_row(raw_fmri, M, Vlow, Vhigh)
    z_fmri = zscore(raw_fmri, 0, 2);
    z_fmri(~isfinite(z_fmri)) = 0;
    X_hat_M = M' * z_fmri;
    Xc = Vlow * X_hat_M;
    Xd = Vhigh * X_hat_M;
    nreg = size(raw_fmri, 1);
    sdi_row = nan(1, nreg);
    for r = 1:nreg
        denom = norm(Xc(r, :));
        if denom > 0
            sdi_row(r) = norm(Xd(r, :)) / denom;
        end
    end
end

function mat = load_matrix_for_subject(data_dir, subject_id, data_type)
    files = dir(fullfile(data_dir, ['*', subject_id, '*.mat']));
    if isempty(files)
        files = dir(fullfile(data_dir, ['*', lower(subject_id), '*.mat']));
    end
    if isempty(files)
        error('%s file was not found for subject %s in %s.', data_type, subject_id, data_dir);
    end
    mat = load_first_matrix(load(fullfile(data_dir, files(1).name)));
    mat = double(mat);
    mat(~isfinite(mat)) = 0;
end

function ts = load_roi_timeseries(roi_dir, subject_id, nreg)
    files = dir(fullfile(roi_dir, ['*', subject_id, '*.mat']));
    if isempty(files)
        files = dir(fullfile(roi_dir, ['*', lower(subject_id), '*.mat']));
    end
    if isempty(files)
        error('ROISignals file was not found for subject %s in %s.', subject_id, roi_dir);
    end
    ts = load_first_matrix(load(fullfile(roi_dir, files(1).name)));
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
