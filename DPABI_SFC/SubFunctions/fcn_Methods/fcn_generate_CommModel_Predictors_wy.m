function [predictor_maps, predictor_labels] = fcn_generate_CommModel_Predictors_wy(sc_matrix, coords, opts)
% FCN_GENERATE_COMMMODEL_PREDICTORS_WY Build selected communication-model predictor maps.
%
% This version accepts GUI-selected predictors and generates only the selected
% communication-model maps. The output labels are valid model labels used by
% the saving function as MAT variable names.

if nargin < 3 || isempty(opts)
    opts = struct();
end
if nargin < 2
    coords = [];
end

predictor_list = get_opt_value(opts, 'predictor_list', { ...
    'Path Length', 'Path Transitivity', 'Search Information', ...
    'Flow Graphs', 'Euclidean Distance', 'Navigation', 'Communicability', ...
    'Matching Index', 'Cosine Similarity', 'Mean First Passage Time'});
sc_type = lower(strtrim(get_opt_value(opts, 'sc_type', 'Both Binary+Weighted')));
gamma_vals = get_opt_value(opts, 'gamma_vals', [0.25, 0.5, 1, 2]);
t_vals = get_opt_value(opts, 't_vals', [1, 2.5, 5, 10]);

if isstring(predictor_list)
    predictor_list = cellstr(predictor_list);
elseif ischar(predictor_list)
    predictor_list = cellstr(predictor_list);
end

n = size(sc_matrix, 1);
sc_weighted = double(sc_matrix);
sc_weighted(~isfinite(sc_weighted)) = 0;
sc_weighted(1:n+1:end) = 0;
sc_binary = double(sc_weighted > 0);

use_binary = any(strcmp(sc_type, {'both binary+weighted', 'both', 'binary only', 'binary'}));
use_weighted = any(strcmp(sc_type, {'both binary+weighted', 'both', 'weighted only', 'weighted'}));

canonical_order = { ...
    'Path Length', 'Path Transitivity', 'Search Information', ...
    'Flow Graphs', 'Euclidean Distance', 'Navigation', 'Communicability', ...
    'Matching Index', 'Cosine Similarity', 'Mean First Passage Time'};

selected_map = containers.Map('KeyType', 'char', 'ValueType', 'logical');
for i = 1:numel(canonical_order)
    selected_map(normalize_model_key(canonical_order{i})) = false;
end
for i = 1:numel(predictor_list)
    key = normalize_model_key(predictor_list{i});
    if isKey(selected_map, key)
        selected_map(key) = true;
    end
end

if selected_map('euclideandistance') || selected_map('navigation')
    if isempty(coords) || ~isnumeric(coords) || size(coords, 1) ~= n || size(coords, 2) < 3
        error('Euclidean Distance and Navigation require coordinates with size [nreg x 3].');
    end
    coords = coords(:, 1:3);
end

predictor_cells = {};
predictor_labels = {};

for p = 1:numel(canonical_order)
    model_name = canonical_order{p};
    if ~selected_map(normalize_model_key(model_name))
        continue;
    end

    switch model_name
        case 'Path Length'
            if use_binary
                predictor_cells{end+1} = distance_bin(sc_binary); %#ok<AGROW>
                predictor_labels{end+1} = 'PathLength_bin'; %#ok<AGROW>
            end
            if use_weighted
                for g = gamma_vals(:)'
                    mat_cost = sc_weighted .^ (-g);
                    mat_cost(~isfinite(mat_cost)) = 0;
                    predictor_cells{end+1} = distance_wei_floyd(mat_cost); %#ok<AGROW>
                    predictor_labels{end+1} = ['PathLength_wei_gamma' number_to_label(g)]; %#ok<AGROW>
                end
            end

        case 'Path Transitivity'
            if use_binary
                predictor_cells{end+1} = path_transitivity(sc_binary, 'inv'); %#ok<AGROW>
                predictor_labels{end+1} = 'PathTransitivity_bin'; %#ok<AGROW>
            end
            if use_weighted
                for g = gamma_vals(:)'
                    mat_cost = sc_weighted .^ (-g);
                    mat_cost(~isfinite(mat_cost)) = 0;
                    predictor_cells{end+1} = path_transitivity(mat_cost, []); %#ok<AGROW>
                    predictor_labels{end+1} = ['PathTransitivity_wei_gamma' number_to_label(g)]; %#ok<AGROW>
                end
            end

        case 'Search Information'
            if use_binary
                predictor_cells{end+1} = search_information_SFC(sc_binary, 'inv', false); %#ok<AGROW>
                predictor_labels{end+1} = 'SearchInformation_bin'; %#ok<AGROW>
            end
            if use_weighted
                for g = gamma_vals(:)'
                    mat_cost = sc_weighted .^ (-g);
                    mat_cost(~isfinite(mat_cost)) = 0;
                    predictor_cells{end+1} = search_information_SFC(mat_cost, [], false); %#ok<AGROW>
                    predictor_labels{end+1} = ['SearchInformation_wei_gamma' number_to_label(g)]; %#ok<AGROW>
                end
            end

        case 'Flow Graphs'
            if use_binary
                for t = t_vals(:)'
                    predictor_cells{end+1} = fcn_flow_graph(sc_binary, ones(n, 1), t); %#ok<AGROW>
                    predictor_labels{end+1} = ['FlowGraph_bin_t' number_to_label(t)]; %#ok<AGROW>
                end
            end
            if use_weighted
                for t = t_vals(:)'
                    predictor_cells{end+1} = fcn_flow_graph(sc_weighted, ones(n, 1), t); %#ok<AGROW>
                    predictor_labels{end+1} = ['FlowGraph_wei_t' number_to_label(t)]; %#ok<AGROW>
                end
            end

        case 'Euclidean Distance'
            predictor_cells{end+1} = squareform(pdist(coords)); %#ok<AGROW>
            predictor_labels{end+1} = 'EuclideanDistance'; %#ok<AGROW>

        case 'Navigation'
            nav_struct = navigate(sc_weighted, squareform(pdist(coords)));
            failed = nav_struct.failed_paths;
            nav_struct.num_hops(failed == 1) = inf;
            nav_struct.pl_MS(failed == 1) = inf;
            predictor_cells{end+1} = nav_struct.num_hops; %#ok<AGROW>
            predictor_labels{end+1} = 'Navigation_NumHops'; %#ok<AGROW>
            predictor_cells{end+1} = nav_struct.pl_MS; %#ok<AGROW>
            predictor_labels{end+1} = 'Navigation_MS'; %#ok<AGROW>

        case 'Communicability'
            if use_binary
                predictor_cells{end+1} = expm(sc_binary); %#ok<AGROW>
                predictor_labels{end+1} = 'Communicability_bin'; %#ok<AGROW>
            end
            if use_weighted
                predictor_cells{end+1} = communicability_wei(sc_weighted); %#ok<AGROW>
                predictor_labels{end+1} = 'Communicability_wei'; %#ok<AGROW>
            end

        case 'Matching Index'
            if use_binary
                predictor_cells{end+1} = matching_ind_und(sc_binary); %#ok<AGROW>
                predictor_labels{end+1} = 'MatchingIndex_bin'; %#ok<AGROW>
            end
            if use_weighted
                predictor_cells{end+1} = matching_ind_und(sc_weighted); %#ok<AGROW>
                predictor_labels{end+1} = 'MatchingIndex_wei'; %#ok<AGROW>
            end

        case 'Cosine Similarity'
            if use_binary
                predictor_cells{end+1} = safe_cosine_similarity(sc_binary); %#ok<AGROW>
                predictor_labels{end+1} = 'CosineSimilarity_bin'; %#ok<AGROW>
            end
            if use_weighted
                predictor_cells{end+1} = safe_cosine_similarity(sc_weighted); %#ok<AGROW>
                predictor_labels{end+1} = 'CosineSimilarity_wei'; %#ok<AGROW>
            end

        case 'Mean First Passage Time'
            if use_binary
                predictor_cells{end+1} = zscore(mean_first_passage_time(sc_binary)); %#ok<AGROW>
                predictor_labels{end+1} = 'MFPT_bin'; %#ok<AGROW>
            end
            if use_weighted
                predictor_cells{end+1} = zscore(mean_first_passage_time(sc_weighted)); %#ok<AGROW>
                predictor_labels{end+1} = 'MFPT_wei'; %#ok<AGROW>
            end
    end
end

if isempty(predictor_cells)
    error('No communication-model predictors were generated. Check predictor selection and SC type.');
end

for k = 1:numel(predictor_cells)
    predictor_cells{k}(~isfinite(predictor_cells{k})) = 0;
    predictor_cells{k}(1:n+1:end) = 0;
end

predictor_maps = cat(3, predictor_cells{:});
end

function key = normalize_model_key(name)
    if isstring(name)
        name = char(name);
    end
    key = lower(strtrim(name));
    key = strrep(key, ' ', '');
    key = strrep(key, '_', '');
    key = strrep(key, '-', '');
    if strcmp(key, 'flowgraph')
        key = 'flowgraphs';
    elseif strcmp(key, 'cosinedistance')
        key = 'cosinesimilarity';
    elseif strcmp(key, 'meanfirstpassagetime') || strcmp(key, 'mfpt')
        key = 'meanfirstpassagetime';
    end
end

function label = number_to_label(x)
    label = sprintf('%.4g', x);
    label = strrep(label, '.', 'p');
    label = strrep(label, '-', 'm');
end

function s = safe_cosine_similarity(x)
    try
        s = 1 - squareform(pdist(x, 'cosine'));
    catch
        s = zeros(size(x, 1));
    end
    s(~isfinite(s)) = 0;
end

function value = get_opt_value(opts, field_name, default_value)
    if isfield(opts, field_name)
        value = opts.(field_name);
    else
        value = default_value;
    end
end
