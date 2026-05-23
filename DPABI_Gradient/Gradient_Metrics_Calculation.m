function Metrics = Gradient_Metrics_Calculation(GradientResult, Options, OutDir)
% =========================================
% Gradient Metrics Calculation (Subject-wise)
% Compatible with Result struct from Gradient_Calculation
% =========================================
% Input:
%   GradientResult: struct with fields
%       - Gradient: 1xNsub cell, each cell NxM (gradients per subject)
%       - Lambda:   1xNsub cell, each cell 1xM (variance per gradient)
%   Options: struct with logical fields:
%       - ExplanationRatio
%       - GradientRange
%       - GradientVariance
%       - GradientDispersion
%   OutDir: folder to save per-subject metrics
%
% Output:
%   Metrics: struct with Metrics.All{subject}

% =========================================
% Basic checks
% =========================================
if nargin < 1 || isempty(GradientResult)
    error('No input data loaded.');
end
if nargin < 2 || isempty(Options)
    Options = struct();
end
if nargin < 3 || isempty(OutDir)
    OutDir = pwd;
end
if ~exist(OutDir,'dir')
    mkdir(OutDir);
end

% =========================================
% Extract Gradient and Lambda
% =========================================
Gradient = GradientResult.Gradient;
if isfield(GradientResult,'Lambda')
    Lambda = GradientResult.Lambda;
elseif isfield(GradientResult,'lambda')
    Lambda = GradientResult.lambda;
else
    Lambda = [];
end

% =========================================
% Ensure cell format
% =========================================
if ~iscell(Gradient)
    Gradient = {Gradient};
end
if ~iscell(Lambda) && ~isempty(Lambda)
    Lambda = {Lambda};
end

Nsub = numel(Gradient);
Metrics.All = cell(Nsub,1);

% =========================================
% Loop over subjects
% =========================================
for s = 1:Nsub
    G = Gradient{s};   % NxM
    if ~isempty(Lambda)
        L = Lambda{s}; % 1xM
    else
        L = [];
    end

    SubMetrics = struct;

    % -------------------------
    % Explanation Ratio
    % -------------------------
    if isfield(Options,'ExplanationRatio') && Options.ExplanationRatio
        if ~isempty(L)
            L(L<0) = 0; % 防止负值
            SubMetrics.ExplanationRatio = L;
        else
            SubMetrics.ExplanationRatio = [];
        end
    end

    % -------------------------
    % Gradient Range
    % -------------------------
    if isfield(Options,'GradientRange') && Options.GradientRange
        SubMetrics.GradientRange = max(G,[],1) - min(G,[],1);
    end

    % -------------------------
    % Gradient Variance
    % -------------------------
    if isfield(Options,'GradientVariance') && Options.GradientVariance
        SubMetrics.GradientVariance = var(G,0,1);
    end

    % -------------------------
    % Gradient Dispersion (Euclidean distance to centroid)
    % -------------------------
    if isfield(Options,'GradientDispersion') && Options.GradientDispersion
        % 取前两个梯度列
        if size(G,2) >= 2
            coords = G(:,1:2);               % N x 2
            centroid = mean(coords,1);       % 1 x 2
            dist = sqrt(sum((coords - centroid).^2,2)); % N x 1
            SubMetrics.GradientDispersion = sum(dist);   % 总和作为 dispersion
        else
            SubMetrics.GradientDispersion = NaN;
        end
    end

    % -------------------------
    % Save per subject
    % -------------------------
    SubID = sprintf('Sub%03d',s);
    SaveFile = fullfile(OutDir, [SubID '_Metrics.mat']);
    MetricsSubject = SubMetrics; %#ok<NASGU>
    save(SaveFile,'MetricsSubject');
end

% =========================================
% Console log
% =========================================
fprintf('\nSaved subject-wise metrics in:\n%s\n', OutDir);
fprintf('\n=================================\n');
fprintf('Finished Gradient Metrics Calculation\n');
fprintf('=================================\n');

end