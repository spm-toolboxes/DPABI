function Result = Gradient_Calculation( ...
    InputData, InputFiles, InputType, ...
    OutDir, AlignmentType, ReferenceUI, ...
    nIterations, SparsityThreshold,nComp)

% =========================================================
% DPABI_Gradient
% =========================================================
% Functional connectivity gradient computation toolbox
% based on diffusion embedding and BrainSpace framework.
%
% This function computes low-dimensional gradients of brain
% functional organization from connectivity matrices or imaging
% data, and optionally performs alignment across subjects.
%
% =========================================================
% Written in 2026. Latest Modified by Zhengjiayi-Hu 260613. 
% Key Laboratory of Behavioral Science and Magnetic Resonance Imaging Research Center, Institute of Psychology, Chinese Academy of Sciences, Beijing, China
% Tsinghua University, Beijing 100084, China Research Center for Culture and Psychology
% huzhengjiayi22@mails.ucas.ac.cn

fprintf('\n=================================\n');
fprintf('Gradient Calculation Started\n');
fprintf('=================================\n');

% =========================
% defaults
% =========================
if nargin < 3 || isempty(InputType)
    InputType = 'auto';
end

if nargin < 7 || isempty(nIterations)
    nIterations = 10;
end

if nargin < 8 || isempty(SparsityThreshold)
    SparsityThreshold = 10;   % BrainSpace-style (keep top 10%)
end

if ~iscell(InputData)
    InputData = {InputData};
end

nSub = numel(InputData);

Result = struct;
Result.Meta = struct;
Result.Meta.Header = cell(nSub,1);
Result.Meta.Type   = strings(nSub,1);
Result.Meta.LHVertexNum = cell(nSub,1);
Result.Meta.RHVertexNum = cell(nSub,1);


RawGradient = cell(nSub,1);
FCdata      = cell(nSub,1);
ValidLambda = cell(nSub,1);
validIdx_all = cell(nSub,1);
ValidIndex = true(nSub,1);

AlignmentType = lower(strtrim(char(AlignmentType)));
ReferenceUI   = lower(strtrim(char(ReferenceUI)));

% =====================================================
% PHASE 1: LOAD + FC + RAW GRADIENT
% =====================================================
for iSub = 1:nSub

    fprintf('\nSubject %d/%d\n', iSub, nSub);

    try
        x = InputData{iSub};

        % -------------------------
        % LOAD INPUT (.nii / .gii / matrix)
        % -------------------------
        if iscell(x) && numel(x) == 2
            LH = y_ReadAll(x{1});
            RH = y_ReadAll(x{2});
            Data = [LH; RH];
            Result.Meta.Type(iSub) = "surface";
            Result.Meta.Header{iSub} = [];
            Result.Meta.LHVertexNum{iSub} = size(LH,1);
            Result.Meta.RHVertexNum{iSub} = size(RH,1);

        elseif isnumeric(x)
            Data = double(x);
            Result.Meta.Type(iSub) = "matrix";
            Result.Meta.Header{iSub} = [];
            Result.Meta.LHVertexNum{iSub} = [];
            Result.Meta.RHVertexNum{iSub} = [];

        else
            [~,~,ext] = fileparts(char(x));

            if contains(lower(ext), '.nii')
                [Data,~,~,Header] = y_ReadAll(x);
                Result.Meta.Type(iSub) = "volume";
                Result.Meta.Header{iSub} = Header;
                Result.Meta.LHVertexNum{iSub} = [];
                Result.Meta.RHVertexNum{iSub} = [];

            elseif contains(lower(ext), '.gii')
                error('Surface data must be provided as {LH.gii,RH.gii}');

            else
                error('Unsupported input format');
            end
        end
        
        % reshape
        if ndims(Data) > 2
            Data = reshape(Data, [], size(Data, ndims(Data)));
        end

        Data = double(Data);
        Data(~isfinite(Data)) = 0;

        % =========================================================
        % MASK INDEX (FINAL CORRECT VERSION)
        % =========================================================
        MaskIndex = var(Data,0,2) > 0;

        if ~any(MaskIndex)
            error('MaskIndex is empty. Check input data variance.');
        end

        MaskIndex = var(Data,0,2) > 0;

        validIdx_all{iSub} = find(MaskIndex);

        Data = Data(MaskIndex,:);
        
        % =========================
        % FC / timeseries handling
        % =========================
        switch lower(InputType)

            case 'fc'
                % already connectivity matrix
                FC = double(Data);

            case 'timeseries'
                % compute connectivity from time series
                FC = corr(Data');

            otherwise
                % fallback
                FC = corr(Data');
        end

        FCdata{iSub} = FC;
        

        % =========================
        % RAW Gradient (individual level)
        % =========================
        nComp = min([nComp, size(FC,1)-1, rank(FC)-1]);

        gm = GradientMaps( ...
            'kernel','na', ...
            'approach','dm', ...
            'n_components', nComp);

        gm = gm.fit(FC, 'sparsity', SparsityThreshold);

        RawGradient{iSub} = gm.gradients{1}(:,1:nComp);

        if iscell(gm.lambda)
            lam = gm.lambda{1};
        else
            lam = gm.lambda;
        end

        ValidLambda{iSub} = lam(1:nComp);

    catch ME
        ValidIndex(iSub) = false;
        fprintf('SKIP: %s\n', ME.message);
    end
end

if ~any(ValidIndex)
    error('No valid subjects.');
end

fprintf('\nValid subjects: %d\n', sum(ValidIndex));

% =====================================================
% PHASE 2: ALIGNMENT (BrainSpace CORRECT)
% =====================================================
fprintf('\nAlignment type: %s\n', AlignmentType);

refUI = lower(strtrim(ReferenceUI));

% -------------------------
% ensure consistent dim
% -------------------------
validGrad = RawGradient(ValidIndex);

nComp = min(cellfun(@(x) size(x,2), validGrad));

for i = 1:nSub
    RawGradient{i} = RawGradient{i}(:,1:nComp);
end

AlignedGradient = RawGradient;

switch AlignmentType

% =====================================================
% NONE
% =====================================================
case {'none','na'}
    AlignedGradient = RawGradient;
    
% =====================================================
% PROCRUSTES (PA)
% =====================================================
case {'procrustes','pa','procrustes alignment'}

    fprintf('Running Procrustes alignment...\n');

    % -------------------------
    % build FC ordering (CRITICAL PART)
    % -------------------------
    FCdata2 = FCdata;

    switch refUI
        case {'first subject','first','the first gradient','first_subject'}
            G = GradientMaps( ...
                    'kernel','na', ...
                    'approach','dm', ...
                    'alignment','pa', ...
                    'n_components', nComp);

            G = G.fit(FCdata2,'reference',RawGradient{1},'sparsity', SparsityThreshold);

            AlignedGradient = G.aligned;
            

        case {'mean','group mean','group_mean'}
            
            ref = RawGradient{1};
            
            AlignedForMean = RawGradient;
            for i = 1:nSub
                G = RawGradient{i};
                for k = 1:size(G,2)
                    r = corr(G(:,k), ref(:,k));
                    if r < 0
                        G(:,k) = -G(:,k);
                    end
                end
                AlignedForMean{i} = G;
            end
            meanGradient = mean(cat(3, AlignedForMean{:}), 3);
            G = GradientMaps( ...
                'kernel','na', ...
                'approach','dm', ...
                'alignment','pa', ...
                'n_components', nComp);
            
            G = G.fit(FCdata2,'reference',meanGradient,'sparsity', SparsityThreshold);
            
            AlignedGradient = G.aligned;
    
    end


% =====================================================
% JOINT ALIGNMENT
% =====================================================
case {'joint','ja','joint alignment'}

    fprintf('Running Joint alignment...\n');

    G = GradientMaps( ...
        'kernel','na', ...
        'approach','dm', ...
        'alignment','ja', ...
        'n_components', nComp);

    G = G.fit(FCdata,'sparsity', SparsityThreshold);

    AlignedGradient = G.aligned;

otherwise
    error('Unknown AlignmentType: %s', AlignmentType);

end

% =====================================================
% OUTPUT
% =====================================================

Result.Gradient       = AlignedGradient;
Result.RawGradient    = RawGradient;
Result.Lambda         = ValidLambda;

Result.ValidIndex     = ValidIndex;
Result.ValidVertex    = validIdx_all;

Result.InputType      = InputType;
Result.InputFiles     = InputFiles;
Result.Alignment      = AlignmentType;
Result.ReferenceUI    = ReferenceUI;

Result.SubjectNumber  = numel(RawGradient);
idx = find(ValidIndex,1);
if isempty(idx)
    error('No valid subjects for gradient dimension.');
end

Result.GradientNumber = size(AlignedGradient{idx},2);

Result.Mask = validIdx_all;
Result.GroupMask = all(cat(2, validIdx_all{:}),2);


% =====================================================
% SAVE
% =====================================================
if ~exist(OutDir,'dir')
    mkdir(OutDir);
end

save(fullfile(OutDir,'Gradient_Result.mat'), 'Result','-v7.3');

fprintf('\nSaved: %s\n', fullfile(OutDir,'Gradient_Result.mat'));

fprintf('\n=================================\n');
fprintf('Finished\n');
fprintf('=================================\n');

end