function Gradient_Visualization(Result, OutDir, opts)

% =========================================================
% OUTPUT DIR (GUI SAFE)
% =========================================================
if iscell(OutDir)
    OutDir = OutDir{1};
end
OutDir = char(string(OutDir));

if ~exist(OutDir,'dir')
    mkdir(OutDir);
end

fprintf('\nWriting Gradient Visualization...\n');

% =========================================================
% LOAD DATA
% =========================================================
AlignedGradient = Result.Gradient;     % cell: nSub × 1
MaskCell        = Result.ValidVertex;  % logical index per subject
nSub            = numel(AlignedGradient);

% =========================================================
% INIT
% =========================================================
if nargin < 3 || isempty(opts)
    opts = struct;
end

OutNameList = cell(0,1);

if isfield(opts,'ScatterPlot') && opts.ScatterPlot

    fprintf('\nScatter plot...\n');

    % =====================================================
    % STEP 1: subject-level mean (先对齐每个subject)
    % =====================================================
    nSub = numel(AlignedGradient);

    Gref = AlignedGradient{1};
    Gtmp = AlignedGradient;

    for i = 2:numel(Gtmp)
        G = Gtmp{i};
        for k = 1:size(G,2)
            if corr(G(:,k), Gref(:,k)) < 0
                G(:,k) = -G(:,k);
            end
        end
        Gtmp{i} = G;
    end

    Gmean = mean(cat(3, Gtmp{:}), 3);

    % =====================================================
    % STEP 3: scatter uses G1 vs G2
    % =====================================================
    mask = Result.GroupMask;
    g1 = Gmean(:,1);
    g2 = Gmean(:,2);

    % optional coloring (PC1-PC3)
    if size(Gmean,2) >= 3
        cdata = Gmean(:,1:3);
        cdata = (cdata - min(cdata)) ./ (max(cdata)-min(cdata) + eps);
    else
        cdata = [g1 g2 g2];
    end

    fig = figure('Visible','off','Color','w');

    scatter(g1, g2, 6, cdata, 'filled');

    xlabel('Gradient 1');
    ylabel('Gradient 2');
    title('Group Mean Gradient Space');

    axis square;
    box off;

    saveas(fig, fullfile(OutDir,'scatter.png'));
    savefig(fig, fullfile(OutDir,'scatter.fig'));
    close(fig);
end

% =========================================================
% 2. SCREE PLOT
% =========================================================
if isfield(opts,'ScreePlot') && opts.ScreePlot

    fprintf('\nScree plot...\n');

    if isfield(Result,'Lambda')

        lam = Result.Lambda;

        if iscell(lam)
            lam = lam{1};
        end

        lam = double(lam(:));

        fig = figure('Visible','off','Color','w');
        plot(lam,'-o','LineWidth',1.5);

        xlabel('Component');
        ylabel('Eigenvalue');
        title('Scree Plot');
        box off;

        saveas(fig, fullfile(OutDir,'scree.png'));
        savefig(fig, fullfile(OutDir,'scree.fig'));
        close(fig);
    end
end

% =========================================================
% 3. SUBJECT LOOP (OUTPUT)
% =========================================================
for iSub = 1:nSub
    
    fprintf('Writing subject %d/%d\n',iSub,nSub);
    
    data = AlignedGradient{iSub};   % vertex × comp
    nComp = size(data,2);
    mask = Result.ValidVertex{iSub};

    % -------------------------
    % output name (simple stable version)
    % -------------------------
    OutName = fullfile(OutDir, sprintf('Sub%04d', iSub));
    % =========================
    % ADD THIS BLOCK HERE
    % =========================
    if strcmp(Result.Meta.Type(iSub),"matrix")

        save([OutName '.mat'],'data','-v7.3');
        OutNameList{end+1,1} = OutName;
        continue
    end

    % =====================================================
    % VOLUME OUTPUT (4D NIfTI)
    % =====================================================
    if strcmp(Result.Meta.Type(iSub),"volume")

        Header = Result.Meta.Header{iSub};

        nVox = numel(mask);
        tmp = zeros(nVox, nComp);
        tmp(mask,:) = data;

        tmp = zeros(nVox, nComp);
        tmp(mask,:) = data;

        % assume volume dims stored in header
        dims = Header.dim(2:4);

        tmp = reshape(tmp, [dims nComp]);

        Header.dt = [16,0];
        Header.pinfo = [1;0;0];

        y_Write(tmp, Header, [OutName,'.nii']);

    % =====================================================
    % SURFACE OUTPUT (GIFTI)
    % =====================================================
    else

        fprintf('=== NEW SURFACE WRITER ===\n');
        
        LHN = Result.Meta.LHVertexNum{iSub};
        RHN = Result.Meta.RHVertexNum{iSub};

        nVert = LHN + RHN;

        tmp = zeros(nVert,nComp);

        if nnz(mask) ~= size(data,1)
            error('Mask and gradient size mismatch.');
        end

        tmp(mask,:) = data;

        LHdata = tmp(1:LHN,:);
        RHdata = tmp(LHN+1:LHN+RHN,:);
        figure;
        plot(LHdata(:,1));
        title('LH Gradient 1');

        fprintf('nComp = %d\n',nComp);

        for iGrad = 1:nComp

            fnameL = [OutName sprintf('_LH_G%d.gii',iGrad)];
            fnameR = [OutName sprintf('_RH_G%d.gii',iGrad)];

            fprintf('%s\n',fnameL);
            fprintf('%s\n',fnameR);

            gL = gifti(LHdata(:,iGrad));
            save(gL,fnameL);

            gR = gifti(RHdata(:,iGrad));
            save(gR,fnameR);

        end

    end

    OutNameList{end+1,1} = OutName;
    
end


% =========================================================
% 4. TABLE OUTPUT
% =========================================================
GradientData = AlignedGradient;

save(fullfile(OutDir,'GradientData.mat'), ...
     'GradientData','-v7.3');

if exist('writematrix','file') && ~isempty(GradientData)

    writematrix(GradientData{1}, ...
        fullfile(OutDir,'Gradient_Sub1.xlsx'));

end

fprintf('\nGradient visualization finished.\n');
%fprintf('LHN=%d RHN=%d nVert=%d\n',LHN,RHN,nVert);
%fprintf('sum(mask)=%d size(data,1)=%d\n',sum(mask),size(data,1));

end