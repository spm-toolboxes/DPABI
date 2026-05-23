function Result = Gradient_Calculation( ...
    InputData, InputFiles, InputType, ...
    OutDir, AlignmentType, ReferenceUI, nIterations)

fprintf('\n=================================\n');
fprintf('Gradient Calculation Started\n');
fprintf('=================================\n');

% =========================
% defaults
% =========================
if nargin < 7 || isempty(nIterations)
    nIterations = 5;
end

if ~iscell(InputData)
    InputData = {InputData};
end

nSub = length(InputData);

ValidGradient = {};
ValidLambda = {};
ValidIndex = true(nSub,1);
validIdx_all = {};

% =========================
% ALIGNMENT CLEAN INPUT
% =========================
AlignmentType = lower(strtrim(char(AlignmentType)));
ReferenceUI = lower(strtrim(char(ReferenceUI)));

% =========================
% LOOP SUBJECTS
% =========================
for iSub = 1:nSub

    fprintf('\nSubject %d/%d\n', iSub, nSub);

    try
        x = InputData{iSub};
        Data = [];

        % -------------------------
        % load
        % -------------------------
        if iscell(x) && numel(x) == 2
            LH = y_ReadAll(x{1});
            RH = y_ReadAll(x{2});
            Data = [LH; RH];

        elseif isnumeric(x)
            Data = double(x);

        else
            [~,~,ext] = fileparts(char(x));
            if ismember(lower(ext), {'.nii','.gz'})
                Data = y_ReadAll(x);
            else
                error('Unsupported input');
            end
        end

        % =========================
        % reshape safe
        % =========================
        if ndims(Data) > 2
            Data = reshape(Data, [], size(Data, ndims(Data)));
        end

        Data = double(Data);
        Data(~isfinite(Data)) = 0;

        % =========================
        % ONLY remove zero vertices (IMPORTANT FIX)
        % =========================
        validIdx = any(Data ~= 0, 2);
        Data = Data(validIdx,:);

        validIdx_all{iSub} = validIdx;

        fprintf('Vertices: %d\n', size(Data,1));

        % =========================
        % FC
        % =========================
        FC = corr(Data');

        % =========================
        % gradient
        % =========================
        nComp = min(10, size(FC,1)-1);

        gm = GradientMaps( ...
            'kernel','na', ...
            'approach','dm', ...
            'n_components', nComp);

        gm = gm.fit(FC);

        ValidGradient{end+1} = gm.gradients{1}(:,1:nComp);

        if iscell(gm.lambda)
            lam = gm.lambda{1};
        else
            lam = gm.lambda;
        end

        ValidLambda{end+1} = lam(1:nComp);

        fprintf('OK comps=%d\n', nComp);

    catch ME
        ValidIndex(iSub) = false;
        fprintf('SKIP: %s\n', ME.message);
    end
end

if isempty(ValidGradient)
    error('No valid gradients');
end

fprintf('\nValid subjects: %d\n', length(ValidGradient));

% =========================
% ALIGNMENT
% =========================
fprintf('\nAlignment type: %s\n', AlignmentType);

switch AlignmentType

% =====================================================
% NONE
% =====================================================
case {'none','na'}

    AlignedGradient = ValidGradient;

% =====================================================
% PROCRUSTES (SAFE SURFACE VERSION)
% =====================================================
case {'procrustes','pa','procrustes alignment'}

    fprintf('Running BrainSpace-style alignment...\n');

    % reference
    ref = ValidGradient{1}(:,1);

    for it = 1:nIterations

        fprintf('Iter %d\n', it);

        G1 = zeros(length(ref), length(ValidGradient));

        for s = 1:length(ValidGradient)

            g = ValidGradient{s};

            if size(g,1) ~= length(ref)
                continue;
            end

            % sign flip
            if corr(g(:,1), ref) < 0
                g = -g;
            end

            ValidGradient{s} = g;
            G1(:,s) = g(:,1);

        end

        ref = mean(G1,2);
    end

    % final output (NO heavy procrustes -> avoids surface crash)
    AlignedGradient = ValidGradient;

% =====================================================
% JOINT
% =====================================================
case {'joint','ja','joint alignment'}

    gm = GradientMaps( ...
        'kernel','na', ...
        'approach','dm', ...
        'alignment','ja', ...
        'n_components', nComp);

    gm = gm.fit(ValidGradient);

    AlignedGradient = gm.aligned;

otherwise
    error('Unknown AlignmentType: %s', AlignmentType);

end

% =========================
% OUTPUT
% =========================
Result = struct;
Result.Gradient = AlignedGradient;
Result.RawGradient = ValidGradient;
Result.Lambda = ValidLambda;
Result.ValidIndex = ValidIndex;
Result.ValidVertex = validIdx_all;
Result.InputType = InputType;
Result.InputFiles = InputFiles;
Result.Alignment = AlignmentType;

% =========================
% SAVE
% =========================
if ~exist(OutDir,'dir')
    mkdir(OutDir);
end

save(fullfile(OutDir,'Gradient_Result.mat'),'Result','-v7.3');

fprintf('\nSaved.\n');
fprintf('=================================\nFinished\n=================================\n');

end