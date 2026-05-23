function Gradient_Visualization(Result, OutDir, opts)

% =========================================================
% FULL SURFACE GRADIENT VISUALIZATION (FINAL CLEAN VERSION)
% =========================================================

fprintf('\n=================================\n');
fprintf('Gradient Visualization Started\n');
fprintf('=================================\n');

% =========================================================
% OPTIONS
% =========================================================
if nargin < 3 || isempty(opts)
    opts = struct;
end

if ~isfield(opts,'ScatterPlot'); opts.ScatterPlot = true; end
if ~isfield(opts,'ScreePlot'); opts.ScreePlot = true; end
if ~isfield(opts,'GradientMaps'); opts.GradientMaps = true; end
if ~isfield(opts,'MeanGii'); opts.MeanGii = true; end

% =========================================================
% OUTPUT DIR
% =========================================================
if iscell(OutDir)
    OutDir = OutDir{1};
end

OutDir = char(string(OutDir));

if ~exist(OutDir,'dir')
    mkdir(OutDir);
end

% =========================================================
% LOAD DATA
% =========================================================
G = Result.Gradient;

if iscell(G)
    G = cat(3, G{:});
end

validMask = Result.ValidVertex;

if iscell(validMask)
    validMask = validMask{1};
end

validMask = logical(validMask);

nV = length(validMask);
nHalf = nV / 2;

nSub = size(G,3);
nComp = size(G,2);

% =========================================================
% SAFE SAVE FUNCTION
% =========================================================
save_gii = @(x,f) local_save_gii(x,f);

% =========================================================
% 1. SCATTER PLOT
% =========================================================
if opts.ScatterPlot

    fprintf('\nScatter plot...\n');

    Gmean = mean(G,3);

    if size(Gmean,2) >= 3

        g1 = Gmean(:,1);
        g2 = Gmean(:,2);
        g3 = Gmean(:,3);

        cdata = [g1 g2 g3];
        cdata = (cdata - min(cdata,[],1)) ./ ...
                (max(cdata,[],1) - min(cdata,[],1) + eps);

        fig = figure('Visible','off','Color','w');

        scatter(g1, g2, 10, cdata, 'filled');

        xlabel('Gradient 1');
        ylabel('Gradient 2');
        title('Gradient Scatter (Mean)');

        axis square;
        box off;

        saveas(fig, fullfile(OutDir,'scatter.png'));
        savefig(fig, fullfile(OutDir,'scatter.fig'));

        close(fig);
    end
end

% =========================================================
% 2. SCREE PLOT
% =========================================================
if opts.ScreePlot

    fprintf('\nScree plot...\n');

    if isfield(Result,'Lambda')

        lam = Result.Lambda;

        if iscell(lam)
            lam = lam{1};
        end

        lam = double(lam(:));

        fig = figure('Visible','off','Color','w');
        plot(lam,'-o','LineWidth',2);

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
% 3. SUBJECT GII MAPS
% =========================================================
if opts.GradientMaps

    fprintf('\nSubject GII maps...\n');

    outDir = fullfile(OutDir,'GII');
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end

    for s = 1:nSub

        Gs = G(:,:,s);

        for c = 1:nComp

            fullVec = zeros(nV,1);
            fullVec(validMask) = Gs(:,c);

            lh = fullVec(1:nHalf);
            rh = fullVec(nHalf+1:end);

            % -----------------------------
            % CLEAN NAMING (FIXED)
            % -----------------------------
            save_gii(lh, fullfile(outDir, ...
                sprintf('sub%d_L_grad%d.gii',s,c)));

            save_gii(rh, fullfile(outDir, ...
                sprintf('sub%d_R_grad%d.gii',s,c)));

        end
    end
end

% =========================================================
% 4. MEAN GII MAPS
% =========================================================
if opts.MeanGii

    fprintf('\nMean GII maps...\n');

    meanG = mean(G,3);

    outMean = fullfile(OutDir,'mean_GII');
    if ~exist(outMean,'dir')
        mkdir(outMean);
    end

    for c = 1:nComp

        fullVec = zeros(nV,1);
        fullVec(validMask) = meanG(:,c);

        lh = fullVec(1:nHalf);
        rh = fullVec(nHalf+1:end);

        % -----------------------------
        % CLEAN NAMING (FIXED)
        % -----------------------------
        save_gii(lh, fullfile(outMean, ...
            sprintf('mean_L_grad%d.gii',c)));

        save_gii(rh, fullfile(outMean, ...
            sprintf('mean_R_grad%d.gii',c)));

    end
end

fprintf('\n=================================\n');
fprintf('Visualization Finished\n');
fprintf('=================================\n');

end

% =========================================================
function local_save_gii(data, fname)

g = gifti;
g.cdata = single(data(:));
save(g, fname);

end