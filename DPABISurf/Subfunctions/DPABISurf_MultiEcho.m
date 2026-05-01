function Cfg = DPABISurf_MultiEcho(Cfg)
% DPABISurf_MultiEcho
% Select multi-echo data analysis method.
%
% Usage:
%   Cfg = DPABISurf_MultiEcho(Cfg);

    if nargin < 1 || isempty(Cfg)
        Cfg = struct;
    end

    CfgOriginal = Cfg;

    figWidth  = 320;
    figHeight = 240;

    fig = uifigure( ...
        'Name', 'Multi Echo Data Analysis Method', ...
        'WindowStyle', 'modal', ...
        'Position', [500 500 figWidth figHeight]);

    % Optional: center the window
    movegui(fig, 'center');

    comp = DPABISurf_MultiEcho_UI(fig);
    comp.Position = [1 1 figWidth figHeight];

    comp.Cfg = Cfg;
    comp.initializeFromCfg();

    fig.CloseRequestFcn = @(src, event) uiresume(src);

    uiwait(fig);

    if isvalid(comp) && comp.IsAccepted
        Cfg = comp.Cfg;
    else
        Cfg = CfgOriginal;
    end

    if isvalid(fig)
        delete(fig);
    end

end