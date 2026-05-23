function [regional_SFC, StatCorr_SFC_Parameters] = ...
    fcn_calculate_StatCorr_SFC_multilevel_hl(struct_edgevec, func_edgevec, corr_type, min_sc_degree, results_dir, common_ids, parallel_workers)
% FCN_CALCULATE_STATCORR_SFC_MULTILEVEL_HL
% Regional-only SFC analysis using statistical correlation.

[nsub, nedge] = size(struct_edgevec);
if size(func_edgevec, 1) ~= nsub || size(func_edgevec, 2) ~= nedge
    error('SC and FC edge-vector dimensions do not match.');
end
nreg_float = (1 + sqrt(1 + 8 * nedge)) / 2;
if abs(nreg_float - round(nreg_float)) > 1e-10
    error('Unable to infer node count from edge vector length: %d.', nedge);
end
nreg = round(nreg_float);
if nargin < 7 || isempty(parallel_workers), parallel_workers = 1; end
if isstring(corr_type), corr_type = char(corr_type); end
if ~ismember(corr_type, {'Spearman', 'Pearson'})
    error('Unsupported correlation type: %s', corr_type);
end
if isnan(min_sc_degree) || min_sc_degree < 1 || mod(min_sc_degree, 1) ~= 0
    error('Min SC Degree must be a positive integer.');
end
if isstring(common_ids)
    common_ids = cellstr(common_ids);
elseif ischar(common_ids)
    common_ids = cellstr(common_ids);
end
common_ids = common_ids(:);
if numel(common_ids) ~= nsub
    error('The number of participant IDs does not match the number of subjects.');
end

statcorr_root = fullfile(results_dir, 'StatCorr_SFC_Results');
regional_dir = fullfile(statcorr_root, 'Regional_Coupling');
if ~exist(regional_dir, 'dir'), mkdir(regional_dir); end

fprintf('\n==========================================================\n');
fprintf('      STATISTICAL CORRELATION SFC CALCULATION STARTED\n');
fprintf('==========================================================\n');
fprintf('Calculation Level     : Regional only\n');
fprintf('Correlation Type      : %s\n', corr_type);
fprintf('Min SC Degree         : %d\n', min_sc_degree);
fprintf('Participants          : %d\n', nsub);
fprintf('Regions               : %d\n', nreg);
fprintf('Parallel Workers Used : %d\n', parallel_workers);
fprintf('==========================================================\n\n');

regional_SFC = nan(nsub, nreg);
currentPool = gcp('nocreate');
if parallel_workers > 1 && ~isempty(currentPool)
    fprintf('Regional SFC will be computed with parfor.\n');
    parfor i = 1:nsub
        regional_SFC(i, :) = compute_one_subject(struct_edgevec(i, :), func_edgevec(i, :), nreg, corr_type, min_sc_degree);
    end
else
    fprintf('Regional SFC will be computed with serial for-loop.\n');
    for i = 1:nsub
        fprintf('Processing Participant: %-20s (%d/%d)\n', common_ids{i}, i, nsub);
        regional_SFC(i, :) = compute_one_subject(struct_edgevec(i, :), func_edgevec(i, :), nreg, corr_type, min_sc_degree);
    end
end

for i = 1:nsub
    r_val = regional_SFC(i, :); %#ok<NASGU>
    save(fullfile(regional_dir, [common_ids{i}, '_Regional.mat']), 'r_val');
end

time_str = datestr(now, 'yyyy-mm-dd_HHMMSS');
StatCorr_SFC_Parameters = struct;
StatCorr_SFC_Parameters.Timestamp = time_str;
StatCorr_SFC_Parameters.CalculationMethod = 'Statistical Correlation';
StatCorr_SFC_Parameters.CalculationLevel = 'Regional only';
StatCorr_SFC_Parameters.CorrelationType = corr_type;
StatCorr_SFC_Parameters.MinSCDegreeThreshold = min_sc_degree;
StatCorr_SFC_Parameters.SubjectCount = nsub;
StatCorr_SFC_Parameters.RegionCount = nreg;
StatCorr_SFC_Parameters.ParallelWorkersUsed = parallel_workers;
StatCorr_SFC_Parameters.RegionalResultDir = regional_dir;
parameter_file = fullfile(statcorr_root, sprintf('StatCorr_SFC_Parameters_%s.mat', time_str));
save(parameter_file, 'StatCorr_SFC_Parameters');
StatCorr_SFC_Parameters.ParameterFile = parameter_file;

fprintf('\n==========================================================\n');
fprintf('      STATISTICAL CORRELATION SFC CALCULATION COMPLETE\n');
fprintf('==========================================================\n');
fprintf('Regional Result Dir : %s\n', regional_dir);
fprintf('Parameter File      : %s\n', parameter_file);
fprintf('==========================================================\n\n');
end

function regional_row = compute_one_subject(sc_vec, fc_vec, nreg, corr_type, min_sc_degree)
sc_mat = squareform(sc_vec);
fc_mat = squareform(fc_vec);
regional_row = nan(1, nreg);
for j = 1:nreg
    idx_p = find(sc_mat(:, j) > 0);
    if numel(idx_p) >= min_sc_degree
        regional_row(j) = corr(sc_mat(idx_p, j), fc_mat(idx_p, j), 'type', corr_type, 'rows', 'complete');
    end
end
end
