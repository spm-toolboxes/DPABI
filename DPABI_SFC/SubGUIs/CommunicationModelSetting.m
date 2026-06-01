function varargout = CommunicationModelSetting(varargin)
% COMMUNICATIONMODELSETTING MATLAB code for CommunicationModelSetting.fig
% This GUIDE dialog returns a communication-model setting structure.
%
% Usage:
%   newSettings = CommunicationModelSetting(oldSettings, dialogTitle)
%
% Returned structure fields:
%   PredictorList
%   GammaValues
%   MarkovTimeValues
%   CoordinateMatrix
%   SCType

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CommunicationModelSetting_OpeningFcn, ...
                   'gui_OutputFcn',  @CommunicationModelSetting_OutputFcn, ...
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


% --- Executes just before CommunicationModelSetting is made visible.
function CommunicationModelSetting_OpeningFcn(hObject, eventdata, handles, varargin)
% hObject    handle to figure
% eventdata  reserved
% handles    structure with handles and user data
% varargin   optional: oldSettings, dialogTitle

% Default output is empty when the user cancels or closes the window.
handles.output = [];

if nargin >= 4 && ~isempty(varargin)
    inputSettings = varargin{1};
else
    inputSettings = [];
end

if numel(varargin) >= 2 && ~isempty(varargin{2})
    dialogTitle = varargin{2};
else
    dialogTitle = 'Communication Model Setting';
end

if isempty(inputSettings) || ~isstruct(inputSettings)
    inputSettings = local_default_comm_settings();
else
    inputSettings = local_complete_comm_settings(inputSettings);
end

handles.inputSettings = inputSettings;

% Set title text and figure name.
set(hObject, 'Name', dialogTitle, 'CloseRequestFcn', @local_cancel_callback);
if isfield(handles, 'textCommSetting') && ishandle(handles.textCommSetting)
    set(handles.textCommSetting, 'String', dialogTitle);
end

% Restore previous settings to controls.
local_apply_settings_to_controls(handles, inputSettings);

% Force-bind coordinate-selection callback because some GUIDE FIG files may
% keep an empty Callback property after controls are renamed or copied.
if isfield(handles, 'pushbuttonSelectCoordinateMatrix') && ishandle(handles.pushbuttonSelectCoordinateMatrix)
    set(handles.pushbuttonSelectCoordinateMatrix, ...
        'Enable', 'on', ...
        'Callback', @(src, evt)pushbuttonSelectCoordinateMatrix_Callback(src, evt, guidata(src)));
end

if isfield(handles, 'editSelectCoordinateMatrix') && ishandle(handles.editSelectCoordinateMatrix)
    set(handles.editSelectCoordinateMatrix, 'Enable', 'on');
end

% Add centered OK and Cancel buttons programmatically so the original FIG does not need to be edited.
% GUIDE figures may use character units, so switch to pixels before computing positions.
set(hObject, 'Units', 'pixels');
figPos = get(hObject, 'Position');
btnW = 130;
btnH = 34;
gap = 40;
yPos = 2;
xStart = max((figPos(3) - 2 * btnW - gap) / 2, 10);

handles.pushbuttonOK = uicontrol(hObject, ...
    'Style', 'pushbutton', ...
    'String', 'OK', ...
    'Units', 'pixels', ...
    'Position', [xStart, yPos, btnW, btnH], ...
    'Callback', @local_ok_callback);

handles.pushbuttonCancel = uicontrol(hObject, ...
    'Style', 'pushbutton', ...
    'String', 'Cancel', ...
    'Units', 'pixels', ...
    'Position', [xStart + btnW + gap, yPos, btnW, btnH], ...
    'Callback', @local_cancel_callback);

% Update handles structure and wait for user response.
guidata(hObject, handles);
uiwait(hObject);


% --- Outputs from this function are returned to the command line.
function varargout = CommunicationModelSetting_OutputFcn(hObject, eventdata, handles)
% hObject    handle to figure
% eventdata  reserved
% handles    structure with handles and user data

if isempty(handles) || ~isstruct(handles) || ~isfield(handles, 'output')
    varargout{1} = [];
else
    varargout{1} = handles.output;
end

if ishandle(hObject)
    delete(hObject);
end


% --- Executes on button press in checkboxCommunicability.
function checkboxCommunicability_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkboxCommunicability


% --- Executes on button press in checkboxEuclideanDistance.
function checkboxEuclideanDistance_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkboxEuclideanDistance


% --- Executes on button press in checkboxNavigation.
function checkboxNavigation_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkboxNavigation


% --- Executes on button press in pushbuttonSelectCoordinateMatrix.
function pushbuttonSelectCoordinateMatrix_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSelectCoordinateMatrix

startDir = pwd;
if isfield(handles, 'editSelectCoordinateMatrix') && ishandle(handles.editSelectCoordinateMatrix)
    currentPath = strtrim(get(handles.editSelectCoordinateMatrix, 'String'));
    if exist(currentPath, 'file') == 2
        startDir = fileparts(currentPath);
    elseif exist(currentPath, 'dir') == 7
        startDir = currentPath;
    end
end

sourceChoice = questdlg( ...
    'Select coordinate source type:', ...
    'Coordinate Source', ...
    'Single MAT File', 'Folder', 'Cancel', 'Single MAT File');

if isempty(sourceChoice) || strcmp(sourceChoice, 'Cancel')
    return;
end

switch sourceChoice
    case 'Single MAT File'
        [fileName, filePath] = uigetfile('*.mat', ...
            'Select Coordinate Matrix MAT File', startDir);

        if isequal(fileName, 0)
            return;
        end

        set(handles.editSelectCoordinateMatrix, 'String', fullfile(filePath, fileName));

    case 'Folder'
        folderPath = uigetdir(startDir, 'Select Coordinate Matrix Folder');

        if isequal(folderPath, 0)
            return;
        end

        set(handles.editSelectCoordinateMatrix, 'String', folderPath);
end

guidata(hObject, handles);


function editSelectCoordinateMatrix_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of editSelectCoordinateMatrix as text


% --- Executes during object creation, after setting all properties.
function editSelectCoordinateMatrix_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxFlowGraphs.
function checkboxFlowGraphs_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkboxFlowGraphs


function editMarkovTime_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of editMarkovTime as text


% --- Executes during object creation, after setting all properties.
function editMarkovTime_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxPathLength.
function checkboxPathLength_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkboxPathLength


% --- Executes on button press in checkboxPathTransitivity.
function checkboxPathTransitivity_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkboxPathTransitivity


% --- Executes on button press in checkboxSearchInformation.
function checkboxSearchInformation_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkboxSearchInformation


function editGamma_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of editGamma as text


% --- Executes during object creation, after setting all properties.
function editGamma_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxMatchingIndex.
function checkboxMatchingIndex_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkboxMatchingIndex


% --- Executes on button press in checkboxCosineSimilarity.
function checkboxCosineSimilarity_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkboxCosineSimilarity


% --- Executes on button press in checkboxMeanFirstPassageTime.
function checkboxMeanFirstPassageTime_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of checkboxMeanFirstPassageTime


function settings = local_default_comm_settings()
settings = struct;
settings.PredictorList = {'Path Length', 'Path Transitivity', 'Search Information', ...
    'Flow Graphs', 'Euclidean Distance', 'Navigation', 'Communicability', ...
    'Matching Index', 'Cosine Similarity', 'Mean First Passage Time'};
settings.GammaValues = [0.25 0.5 1 2];
settings.MarkovTimeValues = [1 2.5 5 10];
settings.CoordinateMatrix = '';
settings.SCType = 'Both Binary+Weighted';

function settings = local_complete_comm_settings(settings)
def = local_default_comm_settings();
fn = fieldnames(def);
for i = 1:numel(fn)
    if ~isfield(settings, fn{i}) || isempty(settings.(fn{i}))
        settings.(fn{i}) = def.(fn{i});
    end
end
if isstring(settings.PredictorList)
    settings.PredictorList = cellstr(settings.PredictorList);
elseif ischar(settings.PredictorList)
    settings.PredictorList = cellstr(settings.PredictorList);
end
if isstring(settings.CoordinateMatrix)
    settings.CoordinateMatrix = char(settings.CoordinateMatrix);
end

function local_apply_settings_to_controls(handles, settings)
selectedModels = settings.PredictorList;

local_set_checkbox(handles, 'checkboxPathLength', ismember('Path Length', selectedModels));
local_set_checkbox(handles, 'checkboxPathTransitivity', ismember('Path Transitivity', selectedModels));
local_set_checkbox(handles, 'checkboxSearchInformation', ismember('Search Information', selectedModels));
local_set_checkbox(handles, 'checkboxFlowGraphs', ismember('Flow Graphs', selectedModels));
local_set_checkbox(handles, 'checkboxEuclideanDistance', ismember('Euclidean Distance', selectedModels));
local_set_checkbox(handles, 'checkboxNavigation', ismember('Navigation', selectedModels));
local_set_checkbox(handles, 'checkboxCommunicability', ismember('Communicability', selectedModels));
local_set_checkbox(handles, 'checkboxMatchingIndex', ismember('Matching Index', selectedModels));
local_set_checkbox(handles, 'checkboxCosineSimilarity', ismember('Cosine Similarity', selectedModels));
local_set_checkbox(handles, 'checkboxMeanFirstPassageTime', ismember('Mean First Passage Time', selectedModels));

if isfield(handles, 'editGamma') && ishandle(handles.editGamma)
    set(handles.editGamma, 'String', local_numeric_vector_to_string(settings.GammaValues));
end
if isfield(handles, 'editMarkovTime') && ishandle(handles.editMarkovTime)
    set(handles.editMarkovTime, 'String', local_numeric_vector_to_string(settings.MarkovTimeValues));
end
if isfield(handles, 'editSelectCoordinateMatrix') && ishandle(handles.editSelectCoordinateMatrix)
    set(handles.editSelectCoordinateMatrix, 'String', settings.CoordinateMatrix);
end

function local_set_checkbox(handles, tagName, value)
if isfield(handles, tagName) && ishandle(handles.(tagName))
    set(handles.(tagName), 'Value', double(value));
end

function txt = local_numeric_vector_to_string(v)
if isempty(v)
    txt = '';
else
    txt = strtrim(sprintf('%.6g ', v));
end

function local_ok_callback(hObject, eventdata)
fig = ancestor(hObject, 'figure');
handles = guidata(fig);

[settings, isValid, messageText, messageTitle] = local_read_settings_from_controls(handles);
if ~isValid
    errordlg(messageText, messageTitle);
    return;
end

handles.output = settings;
guidata(fig, handles);
uiresume(fig);

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

function [settings, isValid, messageText, messageTitle] = local_read_settings_from_controls(handles)
settings = local_default_comm_settings();
isValid = false;
messageText = '';
messageTitle = 'Invalid Communication Model Setting';

modelList = {};
if local_get_checkbox(handles, 'checkboxPathLength'), modelList{end+1} = 'Path Length'; end %#ok<AGROW>
if local_get_checkbox(handles, 'checkboxPathTransitivity'), modelList{end+1} = 'Path Transitivity'; end %#ok<AGROW>
if local_get_checkbox(handles, 'checkboxSearchInformation'), modelList{end+1} = 'Search Information'; end %#ok<AGROW>
if local_get_checkbox(handles, 'checkboxFlowGraphs'), modelList{end+1} = 'Flow Graphs'; end %#ok<AGROW>
if local_get_checkbox(handles, 'checkboxEuclideanDistance'), modelList{end+1} = 'Euclidean Distance'; end %#ok<AGROW>
if local_get_checkbox(handles, 'checkboxNavigation'), modelList{end+1} = 'Navigation'; end %#ok<AGROW>
if local_get_checkbox(handles, 'checkboxCommunicability'), modelList{end+1} = 'Communicability'; end %#ok<AGROW>
if local_get_checkbox(handles, 'checkboxMatchingIndex'), modelList{end+1} = 'Matching Index'; end %#ok<AGROW>
if local_get_checkbox(handles, 'checkboxCosineSimilarity'), modelList{end+1} = 'Cosine Similarity'; end %#ok<AGROW>
if local_get_checkbox(handles, 'checkboxMeanFirstPassageTime'), modelList{end+1} = 'Mean First Passage Time'; end %#ok<AGROW>

if isempty(modelList)
    messageText = {'Please select at least one communication model.'};
    messageTitle = 'No Model Selected';
    return;
end

gammaText = '';
if isfield(handles, 'editGamma') && ishandle(handles.editGamma)
    gammaText = strtrim(get(handles.editGamma, 'String'));
end
gammaVals = str2num(gammaText); %#ok<ST2NM>
if isempty(gammaVals) || any(~isfinite(gammaVals)) || any(gammaVals <= 0)
    messageText = {'Gamma must be a positive numeric vector.'; ...
                   'Example: 0.25 0.5 1 2'};
    messageTitle = 'Invalid Gamma';
    return;
end

markovText = '';
if isfield(handles, 'editMarkovTime') && ishandle(handles.editMarkovTime)
    markovText = strtrim(get(handles.editMarkovTime, 'String'));
end
markovVals = str2num(markovText); %#ok<ST2NM>
if isempty(markovVals) || any(~isfinite(markovVals)) || any(markovVals <= 0)
    messageText = {'Markov Time must be a positive numeric vector.'; ...
                   'Example: 1 2.5 5 10'};
    messageTitle = 'Invalid Markov Time';
    return;
end

coordSource = '';
if isfield(handles, 'editSelectCoordinateMatrix') && ishandle(handles.editSelectCoordinateMatrix)
    coordSource = strtrim(get(handles.editSelectCoordinateMatrix, 'String'));
end

needsCoord = any(ismember(modelList, {'Euclidean Distance', 'Navigation'}));
if needsCoord && (isempty(coordSource) || ~(exist(coordSource, 'file') == 2 || exist(coordSource, 'dir') == 7))
    messageText = {'Euclidean Distance and Navigation require a valid coordinate source.'; ...
                   'Please select either one coordinate MAT file or one coordinate folder.'};
    messageTitle = 'Coordinate Source Required';
    return;
end

settings.PredictorList = modelList;
settings.GammaValues = gammaVals;
settings.MarkovTimeValues = markovVals;
settings.CoordinateMatrix = coordSource;
settings.SCType = 'Both Binary+Weighted';
isValid = true;

function value = local_get_checkbox(handles, tagName)
value = false;
if isfield(handles, tagName) && ishandle(handles.(tagName))
    value = logical(get(handles.(tagName), 'Value'));
end
