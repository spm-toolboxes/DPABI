function [struct_edgevec, func_edgevec, common_ids, Initialization_Parameters] = ...
    fcn_SFC_Initialization_hl(work_dir, expected_ids, thresh_mode, preserve_percent, results_dir)
% FCN_SFC_INITIALIZATION_HL Prepare SC and FC data for the SFC Toolbox.
% This function receives all settings from the GUI, verifies SC/FC files,
% performs SC thresholding, and vectorizes matrices for downstream methods.

sc_dir = fullfile(work_dir, 'SC');
fc_dir = fullfile(work_dir, 'FC');
if exist(sc_dir, 'dir') ~= 7
    error('SC folder was not found: %s', sc_dir);
end
if exist(fc_dir, 'dir') ~= 7
    error('FC folder was not found: %s', fc_dir);
end

if isstring(expected_ids)
    expected_ids = cellstr(expected_ids);
elseif ischar(expected_ids)
    expected_ids = cellstr(expected_ids);
end
expected_ids = expected_ids(:);
if isempty(expected_ids)
    error('Expected participant list is empty.');
end

if strcmpi(thresh_mode, 'Pre-thresholded') || strcmpi(thresh_mode, 'Skip Thresholding')
    p_preserve = 1;
else
    if preserve_percent > 1
        p_preserve = preserve_percent / 100;
    else
        p_preserve = preserve_percent;
    end
    if isnan(p_preserve) || p_preserve <= 0 || p_preserve > 1
        error('Preserve percent must correspond to a proportion within (0, 1].');
    end
end

sc_all = dir(fullfile(sc_dir, '*.mat'));
fc_all = dir(fullfile(fc_dir, '*.mat'));
if isempty(sc_all), error('No MAT files were found in SC folder: %s', sc_dir); end
if isempty(fc_all), error('No MAT files were found in FC folder: %s', fc_dir); end

sc_ids = cell(numel(sc_all), 1);
fc_ids = cell(numel(fc_all), 1);
for i = 1:numel(sc_all)
    [~, baseName] = fileparts(sc_all(i).name);
    token = regexpi(baseName, '(sub.*)$', 'tokens', 'once');
    if isempty(token) || isempty(strtrim(token{1}))
        error('Unable to extract participant ID from SC file: %s', sc_all(i).name);
    end
    sc_ids{i} = strtrim(token{1});
end
for i = 1:numel(fc_all)
    [~, baseName] = fileparts(fc_all(i).name);
    token = regexpi(baseName, '(sub.*)$', 'tokens', 'once');
    if isempty(token) || isempty(strtrim(token{1}))
        error('Unable to extract participant ID from FC file: %s', fc_all(i).name);
    end
    fc_ids{i} = strtrim(token{1});
end

sc_ids_lower = lower(sc_ids);
fc_ids_lower = lower(fc_ids);
[u_sc, ~, idx_sc] = unique(sc_ids_lower);
sc_counts = accumarray(idx_sc, 1);
dup_sc = u_sc(sc_counts > 1);
[u_fc, ~, idx_fc] = unique(fc_ids_lower);
fc_counts = accumarray(idx_fc, 1);
dup_fc = u_fc(fc_counts > 1);
if ~isempty(dup_sc), error('Duplicated SC participant IDs detected: %s', strjoin(dup_sc, ', ')); end
if ~isempty(dup_fc), error('Duplicated FC participant IDs detected: %s', strjoin(dup_fc, ', ')); end

sc_only = setdiff(sc_ids_lower, fc_ids_lower);
fc_only = setdiff(fc_ids_lower, sc_ids_lower);
if numel(sc_all) ~= numel(fc_all) || ~isempty(sc_only) || ~isempty(fc_only)
    fprintf('\nSC/FC matching failed during initialization.\n');
    fprintf('SC MAT file count: %d\n', numel(sc_all));
    fprintf('FC MAT file count: %d\n', numel(fc_all));
    if ~isempty(sc_only)
        fprintf('SC-only participants, possible missing FC files:\n'); fprintf('  %s\n', sc_only{:});
    end
    if ~isempty(fc_only)
        fprintf('FC-only participants, possible missing SC files:\n'); fprintf('  %s\n', fc_only{:});
    end
    error('SC and FC files cannot be matched one-to-one. Please check the data folders.');
end

common_ids = expected_ids;
nsub = numel(common_ids);

sc_list = repmat(sc_all(1), nsub, 1);
fc_list = repmat(fc_all(1), nsub, 1);

sc_file_names_lower = lower({sc_all.name});
fc_file_names_lower = lower({fc_all.name});

for i = 1:nsub
    this_id = lower(strtrim(common_ids{i}));

    % First try exact ID matching from extracted IDs
    idxSC = find(strcmpi(sc_ids, common_ids{i}), 1, 'first');
    idxFC = find(strcmpi(fc_ids, common_ids{i}), 1, 'first');

    % Fallback: match by whether the full filename contains the participant ID
    if isempty(idxSC)
        idxSC = find(contains(sc_file_names_lower, this_id), 1, 'first');
    end

    if isempty(idxFC)
        idxFC = find(contains(fc_file_names_lower, this_id), 1, 'first');
    end

    if isempty(idxSC)
        fprintf('\nAvailable SC files:\n');
        fprintf('  %s\n', sc_all.name);
        error('SC file was not found for participant: %s', common_ids{i});
    end

    if isempty(idxFC)
        fprintf('\nAvailable FC files:\n');
        fprintf('  %s\n', fc_all.name);
        error('FC file was not found for participant: %s', common_ids{i});
    end

    sc_list(i) = sc_all(idxSC);
    fc_list(i) = fc_all(idxFC);
end

first_sc_matrix = load_first_matrix(load(fullfile(sc_dir, sc_list(1).name)));
if size(first_sc_matrix, 1) ~= size(first_sc_matrix, 2)
    error('The first SC file does not contain a valid square matrix: %s', sc_list(1).name);
end
nreg = size(first_sc_matrix, 1);
nedge = nreg * (nreg - 1) / 2;
sc_stack = zeros(nreg, nreg, nsub);
func_edgevec = zeros(nsub, nedge);

for i = 1:nsub
    sc_mat = load_first_matrix(load(fullfile(sc_dir, sc_list(i).name)));
    fc_mat = load_first_matrix(load(fullfile(fc_dir, fc_list(i).name)));
    if size(sc_mat, 1) ~= nreg || size(sc_mat, 2) ~= nreg
        error('SC matrix size mismatch in file: %s', sc_list(i).name);
    end
    if size(fc_mat, 1) ~= nreg || size(fc_mat, 2) ~= nreg
        error('FC matrix size mismatch in file: %s', fc_list(i).name);
    end
    sc_stack(:, :, i) = double(sc_mat);
    func_edgevec(i, :) = double(fc_mat(triu(true(nreg), 1)));
end

thresholded_sc_dir = fullfile(results_dir, 'Thresholded_SC');
if ~exist(thresholded_sc_dir, 'dir'), mkdir(thresholded_sc_dir); end
struct_edgevec = zeros(nsub, nedge);
thresholded_sc_file_paths = cell(nsub, 1);

switch thresh_mode
    case 'Consistency-based'
        [W_thr, ~] = GLB_threshold_consistency(sc_stack, p_preserve);
        mask = W_thr > 0;
        for i = 1:nsub
            temp_sc = sc_stack(:, :, i);
            temp_sc(~mask) = 0;
            struct_edgevec(i, :) = temp_sc(triu(true(nreg), 1));
            NetworkMatrix = temp_sc; %#ok<NASGU>
            out_name = fullfile(thresholded_sc_dir, sc_list(i).name);
            save(out_name, 'NetworkMatrix');
            thresholded_sc_file_paths{i} = out_name;
        end
    case 'Individual-proportional'
        if exist('threshold_proportional', 'file') ~= 2
            error('threshold_proportional.m was not found on the MATLAB path.');
        end
        for i = 1:nsub
            temp_sc = threshold_proportional(sc_stack(:, :, i), p_preserve);
            struct_edgevec(i, :) = temp_sc(triu(true(nreg), 1));
            NetworkMatrix = temp_sc; %#ok<NASGU>
            out_name = fullfile(thresholded_sc_dir, sc_list(i).name);
            save(out_name, 'NetworkMatrix');
            thresholded_sc_file_paths{i} = out_name;
        end
    case {'Pre-thresholded', 'Skip Thresholding'}
        for i = 1:nsub
            temp_sc = sc_stack(:, :, i);
            struct_edgevec(i, :) = temp_sc(triu(true(nreg), 1));
            NetworkMatrix = temp_sc; %#ok<NASGU>
            out_name = fullfile(thresholded_sc_dir, sc_list(i).name);
            save(out_name, 'NetworkMatrix');
            thresholded_sc_file_paths{i} = out_name;
        end
    otherwise
        error('Unknown SC thresholding mode: %s', thresh_mode);
end

time_str = datestr(now, 'yyyy-mm-dd_HHMMSS');
Initialization_Parameters = struct;
Initialization_Parameters.Timestamp = time_str;
Initialization_Parameters.WorkingDirectory = work_dir;
Initialization_Parameters.SCRawDir = sc_dir;
Initialization_Parameters.FCRawDir = fc_dir;
Initialization_Parameters.ResultsDir = results_dir;
Initialization_Parameters.ThresholdedSCDir = thresholded_sc_dir;
Initialization_Parameters.SCThresholding = thresh_mode;
Initialization_Parameters.PreservePercent = p_preserve * 100;
Initialization_Parameters.PreserveProportion = p_preserve;
Initialization_Parameters.ParticipantIDs = common_ids;
Initialization_Parameters.NodeCount = nreg;
Initialization_Parameters.EdgeCount = nedge;
Initialization_Parameters.SCFileNames = {sc_list.name}';
Initialization_Parameters.FCFileNames = {fc_list.name}';
Initialization_Parameters.ThresholdedSCFilePaths = thresholded_sc_file_paths;

initialization_save_file = fullfile(results_dir, sprintf('SFC_Initialization_Results_%s.mat', time_str));
save(initialization_save_file, 'struct_edgevec', 'func_edgevec', 'common_ids', 'Initialization_Parameters', '-v7.3');
Initialization_Parameters.SaveFile = initialization_save_file;

fprintf('\n==========================================================\n');
fprintf('               SFC INITIALIZATION COMPLETE\n');
fprintf('==========================================================\n');
fprintf('Matched Participants : %d\n', nsub);
fprintf('Nodes per Subject    : %d\n', nreg);
fprintf('Edges per Subject    : %d\n', nedge);
fprintf('SC Threshold Method  : %s\n', thresh_mode);
fprintf('Preserve Percent     : %.2f%%\n', p_preserve * 100);
fprintf('Thresholded SC folder: %s\n', thresholded_sc_dir);
fprintf('Initialization file  : %s\n', initialization_save_file);
fprintf('==========================================================\n\n');
end

function value = load_first_matrix(data_struct)
fn = fieldnames(data_struct);
for i = 1:numel(fn)
    v = data_struct.(fn{i});
    if isnumeric(v) && ndims(v) == 2 && ~isempty(v)
        value = v;
        return;
    end
end
error('No numeric matrix variable found in MAT file.');
end
