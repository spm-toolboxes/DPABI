function varargout = ResultsViewSetting(varargin)
% RESULTSVIEWSETTING MATLAB code for ResultsViewSetting.fig
% This GUIDE dialog returns atlas settings for Results View.
%
% Usage:
%   settings = ResultsViewSetting(oldSettings)
%
% Returned fields:
%   Enabled
%   VolumeSpaceCortexAtlas
%   VolumeSpaceSubcorticalAtlas
%   SurfaceSpaceCortexAtlasLH
%   SurfaceSpaceCortexAtlasRH

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ResultsViewSetting_OpeningFcn, ...
                   'gui_OutputFcn',  @ResultsViewSetting_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

function ResultsViewSetting_OpeningFcn(hObject, eventdata, handles, varargin)
% hObject    handle to figure
% eventdata  reserved
% handles    structure with handles and user data
% varargin   optional: oldSettings

handles.output = [];

if nargin >= 4 && ~isempty(varargin)
    settings = varargin{1};
else
    settings = [];
end
if isempty(settings) || ~isstruct(settings)
    settings = local_default_results_view_settings();
else
    settings = local_complete_results_view_settings(settings);
end
handles.inputSettings = settings;

set(hObject, 'Name', 'Results View Setting', 'CloseRequestFcn', @local_cancel_callback);

% Restore previous paths.
if isfield(handles, 'editVolumeSpaceCortex') && ishandle(handles.editVolumeSpaceCortex)
    set(handles.editVolumeSpaceCortex, 'String', settings.VolumeSpaceCortexAtlas);
end
if isfield(handles, 'editVolumeSpaceSubcorticalTissue') && ishandle(handles.editVolumeSpaceSubcorticalTissue)
    set(handles.editVolumeSpaceSubcorticalTissue, 'String', settings.VolumeSpaceSubcorticalAtlas);
end
if isfield(handles, 'editSurfaceSpaceCortexLH') && ishandle(handles.editSurfaceSpaceCortexLH)
    set(handles.editSurfaceSpaceCortexLH, 'String', settings.SurfaceSpaceCortexAtlasLH);
end
if isfield(handles, 'editSurfaceSpaceCortexRH') && ishandle(handles.editSurfaceSpaceCortexRH)
    set(handles.editSurfaceSpaceCortexRH, 'String', settings.SurfaceSpaceCortexAtlasRH);
end

% Force-bind file selection callbacks because some GUIDE FIG files may keep
% empty Callback properties after controls are copied or renamed.
if isfield(handles, 'pushbuttonVolumeSpaceCortex') && ishandle(handles.pushbuttonVolumeSpaceCortex)
    set(handles.pushbuttonVolumeSpaceCortex, 'Callback', @(src,evt)pushbuttonVolumeSpaceCortex_Callback(src, evt, guidata(src)));
end
if isfield(handles, 'pushbuttonVolumeSpaceSubcorticalTissue') && ishandle(handles.pushbuttonVolumeSpaceSubcorticalTissue)
    set(handles.pushbuttonVolumeSpaceSubcorticalTissue, 'Callback', @(src,evt)pushbuttonVolumeSpaceSubcorticalTissue_Callback(src, evt, guidata(src)));
end
if isfield(handles, 'pushbuttonSurfaceSpaceCortexLH') && ishandle(handles.pushbuttonSurfaceSpaceCortexLH)
    set(handles.pushbuttonSurfaceSpaceCortexLH, 'Callback', @(src,evt)pushbuttonSurfaceSpaceCortexLH_Callback(src, evt, guidata(src)));
end
if isfield(handles, 'pushbuttonSurfaceSpaceCortexRH') && ishandle(handles.pushbuttonSurfaceSpaceCortexRH)
    set(handles.pushbuttonSurfaceSpaceCortexRH, 'Callback', @(src,evt)pushbuttonSurfaceSpaceCortexRH_Callback(src, evt, guidata(src)));
end

% Add centered OK and Cancel buttons without modifying the FIG file.
% GUIDE figures may use character units, so switch to pixels before computing positions.
set(hObject, 'Units', 'pixels');
figPos = get(hObject, 'Position');
btnW = 130;
btnH = 34;
gap = 40;
yPos = 14;
xStart = max((figPos(3) - 2 * btnW - gap) / 2, 10);
handles.pushbuttonOK = uicontrol(hObject, 'Style', 'pushbutton', 'String', 'OK', ...
    'Units', 'pixels', 'Position', [xStart, yPos, btnW, btnH], ...
    'Callback', @local_ok_callback);
handles.pushbuttonCancel = uicontrol(hObject, 'Style', 'pushbutton', 'String', 'Cancel', ...
    'Units', 'pixels', 'Position', [xStart + btnW + gap, yPos, btnW, btnH], ...
    'Callback', @local_cancel_callback);

guidata(hObject, handles);
uiwait(hObject);
end

function varargout = ResultsViewSetting_OutputFcn(hObject, eventdata, handles)
if isempty(handles) || ~isstruct(handles) || ~isfield(handles, 'output')
    varargout{1} = [];
else
    varargout{1} = handles.output;
end
if ~isempty(hObject) && ishandle(hObject)
    delete(hObject);
end
end

function pushbuttonVolumeSpaceCortex_Callback(hObject, eventdata, handles)
if isfield(handles, 'editVolumeSpaceCortex') && ishandle(handles.editVolumeSpaceCortex)
    local_select_atlas_file(handles.editVolumeSpaceCortex, 'Select Volume Space Cortex Atlas File');
end
end

function pushbuttonVolumeSpaceSubcorticalTissue_Callback(hObject, eventdata, handles)
if isfield(handles, 'editVolumeSpaceSubcorticalTissue') && ishandle(handles.editVolumeSpaceSubcorticalTissue)
    local_select_atlas_file(handles.editVolumeSpaceSubcorticalTissue, 'Select Volume Space Subcortical Tissue Atlas File');
end
end

function pushbuttonSurfaceSpaceCortexLH_Callback(hObject, eventdata, handles)
if isfield(handles, 'editSurfaceSpaceCortexLH') && ishandle(handles.editSurfaceSpaceCortexLH)
    local_select_atlas_file(handles.editSurfaceSpaceCortexLH, 'Select Surface Space Cortex Atlas File LH');
end
end

function pushbuttonSurfaceSpaceCortexRH_Callback(hObject, eventdata, handles)
if isfield(handles, 'editSurfaceSpaceCortexRH') && ishandle(handles.editSurfaceSpaceCortexRH)
    local_select_atlas_file(handles.editSurfaceSpaceCortexRH, 'Select Surface Space Cortex Atlas File RH');
end
end

function editVolumeSpaceCortex_Callback(hObject, eventdata, handles)
end

function editVolumeSpaceCortex_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function editVolumeSpaceSubcorticalTissue_Callback(hObject, eventdata, handles)
end

function editVolumeSpaceSubcorticalTissue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function editSurfaceSpaceCortexLH_Callback(hObject, eventdata, handles)
end

function editSurfaceSpaceCortexLH_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function editSurfaceSpaceCortexRH_Callback(hObject, eventdata, handles)
end

function editSurfaceSpaceCortexRH_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function local_ok_callback(hObject, eventdata)
fig = ancestor(hObject, 'figure');
handles = guidata(fig);
settings = local_default_results_view_settings();
settings.VolumeSpaceCortexAtlas = local_get_edit_string(handles, 'editVolumeSpaceCortex');
settings.VolumeSpaceSubcorticalAtlas = local_get_edit_string(handles, 'editVolumeSpaceSubcorticalTissue');
settings.SurfaceSpaceCortexAtlasLH = local_get_edit_string(handles, 'editSurfaceSpaceCortexLH');
settings.SurfaceSpaceCortexAtlasRH = local_get_edit_string(handles, 'editSurfaceSpaceCortexRH');
settings.Enabled = ~isempty(settings.VolumeSpaceCortexAtlas) || ...
                   ~isempty(settings.SurfaceSpaceCortexAtlasLH) || ...
                   ~isempty(settings.SurfaceSpaceCortexAtlasRH);
try
    local_validate_results_view_settings(settings);
catch ME
    errordlg({ME.message}, 'Invalid Results View Settings');
    return;
end
handles.output = settings;
guidata(fig, handles);
uiresume(fig);
end

function local_cancel_callback(hObject, eventdata)
fig = ancestor(hObject, 'figure');
if isempty(fig) || ~ishandle(fig)
    fig = hObject;
end
if ishandle(fig)
    handles = guidata(fig);
    if isstruct(handles)
        handles.output = [];
        guidata(fig, handles);
    end
    uiresume(fig);
end
end

function local_select_atlas_file(editHandle, dialogTitle)
currentPath = strtrim(get(editHandle, 'String'));
startDir = pwd;
if exist(currentPath, 'file') == 2
    startDir = fileparts(currentPath);
end
[fileName, filePath] = uigetfile( ...
    {'*.nii;*.nii.gz;*.gii;*.mat;*.img', 'Atlas files (*.nii, *.nii.gz, *.gii, *.mat, *.img)'; '*.*', 'All files'}, ...
    dialogTitle, startDir);
if isequal(fileName, 0)
    return;
end
set(editHandle, 'String', fullfile(filePath, fileName));
end

function txt = local_get_edit_string(handles, tagName)
txt = '';
if isfield(handles, tagName) && ishandle(handles.(tagName))
    txt = strtrim(get(handles.(tagName), 'String'));
end
end

function settings = local_default_results_view_settings()
settings = struct;
settings.Enabled = false;
settings.VolumeSpaceCortexAtlas = '';
settings.VolumeSpaceSubcorticalAtlas = '';
settings.SurfaceSpaceCortexAtlasLH = '';
settings.SurfaceSpaceCortexAtlasRH = '';
end

function settings = local_complete_results_view_settings(settings)
defaults = local_default_results_view_settings();
fields = fieldnames(defaults);
for iField = 1:numel(fields)
    f = fields{iField};
    if ~isfield(settings, f) || isempty(settings.(f))
        settings.(f) = defaults.(f);
    end
end
end

function local_validate_results_view_settings(settings)
if nargin < 1 || isempty(settings) || ~isfield(settings, 'Enabled') || ~settings.Enabled
    return;
end
volCortex = strtrim(settings.VolumeSpaceCortexAtlas);
volSub = strtrim(settings.VolumeSpaceSubcorticalAtlas);
surfLH = strtrim(settings.SurfaceSpaceCortexAtlasLH);
surfRH = strtrim(settings.SurfaceSpaceCortexAtlasRH);
if isempty(volCortex) && isempty(surfLH) && isempty(surfRH)
    error('Please select at least one cortical atlas for Results View.');
end
if xor(isempty(surfLH), isempty(surfRH))
    error('Surface space cortical visualization requires both LH and RH atlas files.');
end
paths = {volCortex, volSub, surfLH, surfRH};
for iPath = 1:numel(paths)
    thisPath = strtrim(paths{iPath});
    if ~isempty(thisPath) && exist(thisPath, 'file') ~= 2
        error('Atlas file does not exist: %s', thisPath);
    end
end
end
