function varargout = DPABI_SFC(varargin)
% DPABI_SFC MATLAB code for DPABI_SFC.fig
%      DPABI_SFC, by itself, creates a new DPABI_SFC or raises the existing
%      singleton*.
%
%      H = DPABI_SFC returns the handle to a new DPABI_SFC or the handle to
%      the existing singleton*.
%
%      DPABI_SFC('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DPABI_SFC.M with the given input arguments.
%
%      DPABI_SFC('Property','Value',...) creates a new DPABI_SFC or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before DPABI_SFC_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to DPABI_SFC_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DPABI_SFC

% Last Modified by GUIDE v2.5 21-May-2026 13:21:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DPABI_SFC_OpeningFcn, ...
                   'gui_OutputFcn',  @DPABI_SFC_OutputFcn, ...
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


% --- Executes just before DPABI_SFC is made visible.

end

function DPABI_SFC_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to DPABI_SFC (see VARARGIN)
fprintf(['\nThe DPABI SFC Toolbox provides an integrated framework for quantifying structure-function coupling from structural and functional connectivity data using statistical correlation, communication models, dynamic analysis, and graph signal processing approaches. \n\n', ...
'References: \n\n', ...
'Zamani Esfahlani, F., Faskowitz, J., Slack, J., Misic, B., & Betzel, R. F. (2022). Local structure-function relationships in human brain networks across the lifespan. Nat Commun, 13(1), 2053. https://doi.org/10.1038/s41467-022-29770-y \n\n', ...
'Xia, C. H., Moore, T. M., Ruparel, K., Oathes, D. J., Alexander-Bloch, A. F., Shinohara, R. T., Raznahan, A., Gur, R. E., Gur, R. C., Bassett, D. S., & Satterthwaite, T. D. (2020). Development of structure-function coupling in human brain networks during youth. Proc Natl Acad Sci U S A, 117(1), 771-778. https://doi.org/10.1073/pnas.1912034117 \n\n', ...
'Xu, M., Li, X., Teng, T., Huang, Y., Liu, M., Long, Y., Lv, F., Zhi, D., Li, X., Feng, A., Yu, S., Calhoun, V., Zhou, X., & Sui, J. (2024). Reconfiguration of Structural and Functional Connectivity Coupling in Patient Subgroups With Adolescent Depression. JAMA Netw Open, 7(3), e241933. https://doi.org/10.1001/jamanetworkopen.2024.1933 \n\n', ...
'Liu, Z. Q., Vazquez-Rodriguez, B., Spreng, R. N., Bernhardt, B. C., Betzel, R. F., & Misic, B. (2022). Time-resolved structure-function coupling in brain networks. Commun Biol, 5(1), 532. https://doi.org/10.1038/s42003-022-03466-x \n\n', ...
'Preti, M. G., & Van De Ville, D. (2019). Decoupling of brain function from structure reveals regional behavioral specialization in humans. Nat Commun, 10(1), 4747. https://doi.org/10.1038/s41467-019-12765-7 \n\n']);

% Choose default command line output for DPABI_SFC
handles.output = hObject;

% MATLAB R2025a changed GUIDE rendering/scaling behavior.
% Keep legacy manual scaling for older MATLAB only.
SFC_applyGuideDisplayCompatibility(handles, hObject);

% Initialize data set-up status
handles.SFC_hasWorkDir = false;
handles.SFC_hasROISignals = false;
handles.SFC_WorkDir = '';
handles.SFC_SCDir = '';
handles.SFC_FCDir = '';
handles.SFC_ROISignalsDir = '';
handles.SFC_Participants = {};

% Default communication-model settings used by the main communication model method.
handles.SFC_CommModelSettings = SFC_defaultCommModelSettings();

% Default communication-model settings used by Dynamic Analysis when Communication Model is selected.
handles.SFC_DynamicCommModelSettings = SFC_defaultCommModelSettings();

% Default results-view settings.
handles.SFC_ResultsViewSettings = SFC_defaultResultsViewSettings();

% Normalize Average SC Source popup options for GSP.
if isfield(handles, 'popupAverageSCSource') && ishandle(handles.popupAverageSCSource)
    set(handles.popupAverageSCSource, 'String', {'Compute from the Thresholded SC Folder'; 'Select Average SC Source'}, 'Value', 1);
end

% Define method checkbox controls
handles.SFC_MethodCheckboxTags = { ...
    'checkboxStatistical', ...
    'checkboxCommunication', ...
    'checkboxDynamic', ...
    'checkboxGSP'};

% Define parameter controls for each method
handles.SFC_StatisticalParamTags = { ...
    'editMinSCDegree', ...
    'popupCorrType'};

handles.SFC_CommunicationParamTags = { ...
    'popupCommMethod', ...
    'editPCAVariance', ...
    'pushCommSetting'};

handles.SFC_DynamicParamTags = { ...
    'popupDynamicMethod', ...
    'pushDynamicCommSetting'};

handles.SFC_GSPParamTags = { ...
    'popupAverageSCSource', ...
    'pushGSPSCSource', ...
    'editGSPSCSource', ...
    'editAUCCutoff'};

handles.SFC_AllMethodParamTags = [ ...
    handles.SFC_StatisticalParamTags, ...
    handles.SFC_CommunicationParamTags, ...
    handles.SFC_DynamicParamTags, ...
    handles.SFC_GSPParamTags];

% Clear participant list
if isfield(handles, 'listParticipants') && ishandle(handles.listParticipants)
    set(handles.listParticipants, 'String', {}, 'Value', 1);
end

% Disable all method checkboxes before data set-up
for iTag = 1:numel(handles.SFC_MethodCheckboxTags)
    thisTag = handles.SFC_MethodCheckboxTags{iTag};

    if isfield(handles, thisTag) && ishandle(handles.(thisTag))
        set(handles.(thisTag), 'Value', 0, 'Enable', 'inactive');
    end
end

% Disable all method parameter controls before data set-up
for iTag = 1:numel(handles.SFC_AllMethodParamTags)
    thisTag = handles.SFC_AllMethodParamTags{iTag};

    if isfield(handles, thisTag) && ishandle(handles.(thisTag))
        set(handles.(thisTag), 'Enable', 'off');
    end
end

% Initialize thresholding and GSP source display states.
SFC_updateThresholdingState(handles);
SFC_updateGSPAverageSCSourceState(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DPABI_SFC wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.

end

function varargout = DPABI_SFC_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




end

function editWorkDir_Callback(hObject, eventdata, handles)
% hObject    handle to editWorkDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editWorkDir as text
%        str2double(get(hObject,'String')) returns contents of editWorkDir as a double


% --- Executes during object creation, after setting all properties.

end

function editWorkDir_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editWorkDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushBrowseWorkDir.

end

function pushBrowseWorkDir_Callback(hObject, eventdata, handles)
% hObject    handle to pushBrowseWorkDir (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Select working directory
startDir = pwd;

if isfield(handles, 'editWorkDir') && ishandle(handles.editWorkDir)
    oldDir = strtrim(get(handles.editWorkDir, 'String'));

    if exist(oldDir, 'dir') == 7
        startDir = oldDir;
    end
end

workDir = uigetdir(startDir, 'Select Working Directory');

if isequal(workDir, 0)
    return;
end

if isfield(handles, 'editWorkDir') && ishandle(handles.editWorkDir)
    set(handles.editWorkDir, 'String', workDir);
end

% Reset current data set-up status
handles.SFC_hasWorkDir = false;
handles.SFC_hasROISignals = false;
handles.SFC_WorkDir = '';
handles.SFC_SCDir = '';
handles.SFC_FCDir = '';
handles.SFC_ROISignalsDir = '';
handles.SFC_Participants = {};

% Clear participant list
if isfield(handles, 'listParticipants') && ishandle(handles.listParticipants)
    set(handles.listParticipants, 'String', {}, 'Value', 1);
end

% Reset all method selections when a new working directory is selected
for iTag = 1:numel(handles.SFC_MethodCheckboxTags)
    thisTag = handles.SFC_MethodCheckboxTags{iTag};

    if isfield(handles, thisTag) && ishandle(handles.(thisTag))
        set(handles.(thisTag), 'Value', 0, 'Enable', 'inactive');
    end
end

% Disable all method parameter controls
for iTag = 1:numel(handles.SFC_AllMethodParamTags)
    thisTag = handles.SFC_AllMethodParamTags{iTag};

    if isfield(handles, thisTag) && ishandle(handles.(thisTag))
        set(handles.(thisTag), 'Enable', 'off');
    end
end

guidata(hObject, handles);

% Define required folders
scDir = fullfile(workDir, 'SC');
fcDir = fullfile(workDir, 'FC');
roiDir = fullfile(workDir, 'ROISignals');

fprintf('\n============================================================\n');
fprintf('[SFC Toolbox] Data set-up check\n');
fprintf('Working directory: %s\n', workDir);
fprintf('SC folder: %s\n', scDir);
fprintf('FC folder: %s\n', fcDir);
fprintf('ROISignals folder: %s\n', roiDir);
fprintf('============================================================\n');

% Check SC and FC folders
if exist(scDir, 'dir') ~= 7 || exist(fcDir, 'dir') ~= 7
    fprintf('ERROR: The working directory must contain both SC and FC folders.\n');

    if exist(scDir, 'dir') ~= 7
        fprintf('Missing folder: SC\n');
    end

    if exist(fcDir, 'dir') ~= 7
        fprintf('Missing folder: FC\n');
    end

    errordlg({'The selected working directory must contain both SC and FC folders.'; ...
              'Please check your working directory.'}, ...
              'Missing Required Folders');
    return;
end

% Read .mat files
scFiles = dir(fullfile(scDir, '*.mat'));
fcFiles = dir(fullfile(fcDir, '*.mat'));

fprintf('SC .mat file count: %d\n', numel(scFiles));
fprintf('FC .mat file count: %d\n', numel(fcFiles));

if isempty(scFiles) || isempty(fcFiles)
    fprintf('ERROR: SC and FC folders must both contain .mat files.\n');

    errordlg({'SC and FC folders must both contain .mat files.'; ...
              'Currently only .mat files are supported.'}, ...
              'Missing Matrix Files');
    return;
end

scFileNames = {scFiles.name}';
fcFileNames = {fcFiles.name}';

% Extract participant IDs from SC filenames
scKeys = cell(numel(scFileNames), 1);
scDisplay = cell(numel(scFileNames), 1);
scHasSub = false(numel(scFileNames), 1);

for iFile = 1:numel(scFileNames)
    [~, baseName] = fileparts(scFileNames{iFile});
    token = regexpi(baseName, '(sub.*)$', 'tokens', 'once');

    if ~isempty(token)
        subjectID = strtrim(token{1});

        if ~isempty(subjectID)
            scKeys{iFile} = lower(subjectID);
            scDisplay{iFile} = subjectID;
            scHasSub(iFile) = true;
        end
    end
end

% Extract participant IDs from FC filenames
fcKeys = cell(numel(fcFileNames), 1);
fcDisplay = cell(numel(fcFileNames), 1);
fcHasSub = false(numel(fcFileNames), 1);

for iFile = 1:numel(fcFileNames)
    [~, baseName] = fileparts(fcFileNames{iFile});
    token = regexpi(baseName, '(sub.*)$', 'tokens', 'once');

    if ~isempty(token)
        subjectID = strtrim(token{1});

        if ~isempty(subjectID)
            fcKeys{iFile} = lower(subjectID);
            fcDisplay{iFile} = subjectID;
            fcHasSub(iFile) = true;
        end
    end
end

% Check files without sub/Sub/SUB
invalidSCFiles = scFileNames(~scHasSub);
invalidFCFiles = fcFileNames(~fcHasSub);

if ~isempty(invalidSCFiles) || ~isempty(invalidFCFiles)
    fprintf('\nERROR: Some .mat files do not contain sub/Sub/SUB in the filename.\n');

    if ~isempty(invalidSCFiles)
        fprintf('SC files without sub/Sub/SUB:\n');
        fprintf('  %s\n', invalidSCFiles{:});
    end

    if ~isempty(invalidFCFiles)
        fprintf('FC files without sub/Sub/SUB:\n');
        fprintf('  %s\n', invalidFCFiles{:});
    end

    errordlg({'Some .mat files do not contain sub/Sub/SUB in the filename.'; ...
              'Please check the Command Window for details.'}, ...
              'Invalid Participant Filename');
    return;
end

% Check duplicated participant IDs
[uSCKeys, ~, scIndex] = unique(scKeys);
scCounts = accumarray(scIndex, 1);
dupSCKeys = uSCKeys(scCounts > 1);

[uFCKeys, ~, fcIndex] = unique(fcKeys);
fcCounts = accumarray(fcIndex, 1);
dupFCKeys = uFCKeys(fcCounts > 1);

if ~isempty(dupSCKeys) || ~isempty(dupFCKeys)
    fprintf('\nERROR: Duplicated participant IDs were detected.\n');

    if ~isempty(dupSCKeys)
        fprintf('Duplicated SC participant IDs:\n');
        fprintf('  %s\n', dupSCKeys{:});
    end

    if ~isempty(dupFCKeys)
        fprintf('Duplicated FC participant IDs:\n');
        fprintf('  %s\n', dupFCKeys{:});
    end

    errordlg({'Duplicated participant IDs were detected in SC or FC folder.'; ...
              'Please check the Command Window for details.'}, ...
              'Duplicated Participant IDs');
    return;
end

% Match participants
matchedKeys = intersect(scKeys, fcKeys);
scOnlyKeys = setdiff(scKeys, fcKeys);
fcOnlyKeys = setdiff(fcKeys, scKeys);

matchedDisplay = matchedKeys;
scOnlyDisplay = scOnlyKeys;
fcOnlyDisplay = fcOnlyKeys;

fprintf('\nParticipant matching report:\n');
fprintf('Matched participants: %d\n', numel(matchedDisplay));

if isempty(matchedDisplay)
    fprintf('  None\n');
else
    fprintf('Matched participant IDs:\n');
    fprintf('  %s\n', matchedDisplay{:});
end

if isempty(scOnlyDisplay)
    fprintf('SC-only participants: None\n');
else
    fprintf('SC-only participants, possible missing FC files:\n');
    fprintf('  %s\n', scOnlyDisplay{:});
end

if isempty(fcOnlyDisplay)
    fprintf('FC-only participants: None\n');
else
    fprintf('FC-only participants, possible missing SC files:\n');
    fprintf('  %s\n', fcOnlyDisplay{:});
end

% Check file count mismatch
if numel(scFiles) ~= numel(fcFiles)
    fprintf('\nERROR: SC and FC file counts do not match.\n');
    fprintf('SC .mat file count: %d\n', numel(scFiles));
    fprintf('FC .mat file count: %d\n', numel(fcFiles));

    errordlg({'The number of SC and FC .mat files does not match.'; ...
              'Please check whether some SC or FC files are missing.'; ...
              'See the Command Window for the matching report.'}, ...
              'SC/FC File Count Mismatch');
    return;
end

% Check one-to-one participant mismatch
if ~isempty(scOnlyKeys) || ~isempty(fcOnlyKeys)
    fprintf('\nERROR: SC and FC file counts are equal, but participant IDs cannot be matched one-to-one.\n');

    errordlg({'SC and FC file counts are equal, but participant IDs cannot be matched one-to-one.'; ...
              'Please check the filenames in SC and FC folders.'; ...
              'See the Command Window for the matching report.'}, ...
              'SC/FC Participant Mismatch');
    return;
end

% Save valid data set-up information
participants = sort(matchedDisplay);

handles.SFC_hasWorkDir = true;
handles.SFC_WorkDir = workDir;
handles.SFC_SCDir = scDir;
handles.SFC_FCDir = fcDir;
handles.SFC_ROISignalsDir = roiDir;
handles.SFC_Participants = participants;

% Reset GSP average SC source to the default thresholded-SC folder for each new working directory.
if isfield(handles, 'popupAverageSCSource') && ishandle(handles.popupAverageSCSource)
    set(handles.popupAverageSCSource, 'Value', 1);
end
SFC_updateGSPAverageSCSourceState(handles);

if isfield(handles, 'listParticipants') && ishandle(handles.listParticipants)
    set(handles.listParticipants, 'String', participants, 'Value', 1);
end

% Enable SC/FC-based method checkboxes only
set(handles.checkboxStatistical, 'Enable', 'on');
set(handles.checkboxCommunication, 'Enable', 'on');

% Keep all method parameter controls disabled until the corresponding method is selected
for iTag = 1:numel(handles.SFC_AllMethodParamTags)
    thisTag = handles.SFC_AllMethodParamTags{iTag};

    if isfield(handles, thisTag) && ishandle(handles.(thisTag))
        set(handles.(thisTag), 'Enable', 'off');
    end
end

% Check ROISignals
roiMatFiles = [];

if exist(roiDir, 'dir') == 7
    roiMatFiles = dir(fullfile(roiDir, '*.mat'));
end

handles.SFC_hasROISignals = exist(roiDir, 'dir') == 7 && ~isempty(roiMatFiles);

if handles.SFC_hasROISignals
    fprintf('\nROISignals status: Found\n');
    fprintf('ROISignals .mat file count: %d\n', numel(roiMatFiles));

    % Enable ROI-dependent method checkboxes only
    set(handles.checkboxDynamic, 'Enable', 'on');
    set(handles.checkboxGSP, 'Enable', 'on');

else
    fprintf('\nROISignals status: Not found or no .mat files found\n');
    fprintf('Dynamic Analysis Method and Graph Signal Processing Method require ROISignals results.\n');

    % Keep ROI-dependent method checkboxes clickable for warning dialogs
    set(handles.checkboxDynamic, ...
        'Enable', 'on', ...
        'Value', 0, ...
        'TooltipString', 'ROISignals results are required for this method.');

    set(handles.checkboxGSP, ...
        'Enable', 'on', ...
        'Value', 0, ...
        'TooltipString', 'ROISignals results are required for this method.');

    % Keep ROI-dependent parameter controls disabled
    for iTag = 1:numel(handles.SFC_DynamicParamTags)
        thisTag = handles.SFC_DynamicParamTags{iTag};

        if isfield(handles, thisTag) && ishandle(handles.(thisTag))
            set(handles.(thisTag), 'Enable', 'off');
        end
    end

    for iTag = 1:numel(handles.SFC_GSPParamTags)
        thisTag = handles.SFC_GSPParamTags{iTag};

        if isfield(handles, thisTag) && ishandle(handles.(thisTag))
            set(handles.(thisTag), 'Enable', 'off');
        end
    end
end

fprintf('\nData set-up completed successfully.\n');
fprintf('Loaded participants: %d\n', numel(participants));
fprintf('============================================================\n\n');

guidata(hObject, handles);


% --- Executes on selection change in listParticipants.

end

function listParticipants_Callback(hObject, eventdata, handles)
% hObject    handle to listParticipants (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listParticipants contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listParticipants


% --- Executes during object creation, after setting all properties.

end

function listParticipants_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listParticipants (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when figure1 is resized.

end

function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




end

function editPreservePercent_Callback(hObject, eventdata, handles)
% hObject    handle to editPreservePercent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPreservePercent as text
%        str2double(get(hObject,'String')) returns contents of editPreservePercent as a double


% --- Executes during object creation, after setting all properties.

end

function editPreservePercent_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPreservePercent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenuSCThresholding.

end

function popupmenuSCThresholding_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenuSCThresholding (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SFC_updateThresholdingState(handles);
guidata(hObject, handles);

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenuSCThresholding contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenuSCThresholding


% --- Executes during object creation, after setting all properties.

end

function popupmenuSCThresholding_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenuSCThresholding (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Hint: get(hObject,'Value') returns toggle state of checkboxStatistical
% --- Executes on button press in checkboxStatistical.

end

function checkboxStatistical_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxStatistical (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'SFC_hasWorkDir') || ~handles.SFC_hasWorkDir
    set(hObject, 'Value', 0);

    warndlg({'Please select a valid working directory first.'}, ...
            'Data Set-up Required');
    return;
end

if get(hObject, 'Value')
    for iTag = 1:numel(handles.SFC_StatisticalParamTags)
        thisTag = handles.SFC_StatisticalParamTags{iTag};

        if isfield(handles, thisTag) && ishandle(handles.(thisTag))
            set(handles.(thisTag), 'Enable', 'on');
        end
    end
else
    for iTag = 1:numel(handles.SFC_StatisticalParamTags)
        thisTag = handles.SFC_StatisticalParamTags{iTag};

        if isfield(handles, thisTag) && ishandle(handles.(thisTag))
            set(handles.(thisTag), 'Enable', 'off');
        end
    end
end



end

function editMinSCDegree_Callback(hObject, eventdata, handles)
% hObject    handle to editMinSCDegree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editMinSCDegree as text
%        str2double(get(hObject,'String')) returns contents of editMinSCDegree as a double


% --- Executes during object creation, after setting all properties.

end

function editMinSCDegree_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editMinSCDegree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.

end

function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.

end

function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% Hint: get(hObject,'Value') returns toggle state of checkboxDynamic
% --- Executes on button press in checkboxDynamic.

end

function checkboxDynamic_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxDynamic (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'SFC_hasWorkDir') || ~handles.SFC_hasWorkDir
    set(hObject, 'Value', 0);
    warndlg({'Please select a valid working directory first.'}, 'Data Set-up Required');
    return;
end
if ~isfield(handles, 'SFC_hasROISignals') || ~handles.SFC_hasROISignals
    set(hObject, 'Value', 0);
    for iTag = 1:numel(handles.SFC_DynamicParamTags)
        thisTag = handles.SFC_DynamicParamTags{iTag};
        if isfield(handles, thisTag) && ishandle(handles.(thisTag))
            set(handles.(thisTag), 'Enable', 'off');
        end
    end
    warndlg({'Dynamic Analysis Method requires ROISignals results.'; ...
             'Please add a ROISignals folder with .mat files under the working directory.'; ...
             'Then select the working directory again.'}, 'ROISignals Required');
    return;
end
SFC_setControlsEnable(handles, handles.SFC_DynamicParamTags, get(hObject, 'Value'));
SFC_setDynamicCommButtonState(handles);


end

function popupDynamicMethod_Callback(hObject, eventdata, handles)
% hObject    handle to popupDynamicMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

SFC_setDynamicCommButtonState(handles);


end

function popupDynamicMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textDynamicMethodLabel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% Hint: get(hObject,'Value') returns toggle state of checkboxCommunication
% --- Executes on button press in checkboxCommunication.

end

function checkboxCommunication_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxCommunication (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'SFC_hasWorkDir') || ~handles.SFC_hasWorkDir
    set(hObject, 'Value', 0);

    warndlg({'Please select a valid working directory first.'}, ...
            'Data Set-up Required');
    return;
end

if get(hObject, 'Value')
    for iTag = 1:numel(handles.SFC_CommunicationParamTags)
        thisTag = handles.SFC_CommunicationParamTags{iTag};

        if isfield(handles, thisTag) && ishandle(handles.(thisTag))
            set(handles.(thisTag), 'Enable', 'on');
        end
    end
else
    for iTag = 1:numel(handles.SFC_CommunicationParamTags)
        thisTag = handles.SFC_CommunicationParamTags{iTag};

        if isfield(handles, thisTag) && ishandle(handles.(thisTag))
            set(handles.(thisTag), 'Enable', 'off');
        end
    end
end

% --- Executes on selection change in popupCommMethod.

end

function popupCommMethod_Callback(hObject, eventdata, handles)
% hObject    handle to popupCommMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupCommMethod contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupCommMethod


% --- Executes during object creation, after setting all properties.

end

function popupCommMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupCommMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




end

function editPCAVariance_Callback(hObject, eventdata, handles)
% hObject    handle to editPCAVariance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPCAVariance as text
%        str2double(get(hObject,'String')) returns contents of editPCAVariance as a double


% --- Executes during object creation, after setting all properties.

end

function editPCAVariance_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPCAVariance (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushCommSetting.

end

function pushCommSetting_Callback(hObject, eventdata, handles)
% hObject    handle to pushCommSetting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'SFC_hasWorkDir') || ~handles.SFC_hasWorkDir
    warndlg({'Please select a valid working directory first.'}, 'Data Set-up Required');
    return;
end
if ~get(handles.checkboxCommunication, 'Value')
    warndlg({'Please select Communication Model Method first.'; ...
             'The method parameters can be edited only after its checkbox is selected.'}, ...
             'Method Not Selected');
    return;
end
if ~isfield(handles, 'SFC_CommModelSettings') || isempty(handles.SFC_CommModelSettings)
    handles.SFC_CommModelSettings = SFC_defaultCommModelSettings();
end
newSettings = CommunicationModelSetting(handles.SFC_CommModelSettings, ...
    'Communication Model Setting');
if ~isempty(newSettings)
    handles.SFC_CommModelSettings = newSettings;
    guidata(hObject, handles);
end


end

function popupCorrType_Callback(hObject, eventdata, handles)
% hObject    handle to popupCorrType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupCorrType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupCorrType


% --- Executes during object creation, after setting all properties.

end

function popupCorrType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupCorrType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




end

function editParallelWorkers_Callback(hObject, eventdata, handles)
% hObject    handle to editParallelWorkers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editParallelWorkers as text
%        str2double(get(hObject,'String')) returns contents of editParallelWorkers as a double


% --- Executes during object creation, after setting all properties.

end

function editParallelWorkers_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editParallelWorkers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in panelResultSetting.

end


function panelResultSetting_Callback(hObject, eventdata, handles)
% hObject    handle to panelResultSetting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'SFC_ResultsViewSettings') || isempty(handles.SFC_ResultsViewSettings)
    handles.SFC_ResultsViewSettings = SFC_defaultResultsViewSettings();
end

newSettings = ResultsViewSetting(handles.SFC_ResultsViewSettings);
if ~isempty(newSettings)
    handles.SFC_ResultsViewSettings = newSettings;
    guidata(hObject, handles);
end

end

function pushbuttonSave_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonSave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'SFC_hasWorkDir') || ~handles.SFC_hasWorkDir
    errordlg({'Please select a valid working directory before saving settings.'}, 'Data Set-up Required');
    return;
end
try
    SFC_Settings = SFC_collectSettingsFromGUI(handles, false);
catch ME
    errordlg({ME.message}, 'Invalid Settings');
    return;
end
SFC_Settings.SaveTime = datestr(now, 'yyyy-mm-dd HH:MM:SS');
defaultName = ['SFC_Toolbox_Settings_', datestr(now, 'yyyy-mm-dd_HHMMSS'), '.mat'];
[saveName, savePath] = uiputfile('*.mat', 'Save SFC Toolbox Settings', fullfile(handles.SFC_WorkDir, defaultName));
if isequal(saveName, 0)
    return;
end
save(fullfile(savePath, saveName), 'SFC_Settings');
fprintf('\nSFC toolbox settings saved:\n%s\n\n', fullfile(savePath, saveName));
msgbox({'SFC toolbox settings saved successfully.'}, 'Save Complete');


end

function pushbuttonRun_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonRun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'SFC_hasWorkDir') || ~handles.SFC_hasWorkDir
    errordlg({'Please select a valid working directory first.'}, 'Data Set-up Required');
    return;
end
try
    SFC_Settings = SFC_collectSettingsFromGUI(handles, true);
catch ME
    errordlg({ME.message}, 'Invalid Settings');
    return;
end
set(handles.pushbuttonRun, 'Enable', 'off');
drawnow;
try
    SFC_Results = MainScript_SFC(SFC_Settings);
    handles.SFC_LastRunSettings = SFC_Settings;
    handles.SFC_LastRunResults = SFC_Results;
    guidata(hObject, handles);
    msgbox({'SFC analysis completed successfully.'; ['Results folder: ', SFC_Results.ResultsDir]}, 'Run Complete');
catch ME
    fprintf('\n==================== ERROR REPORT ====================\n');
    fprintf('%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    fprintf('======================================================\n\n');
    errordlg({'SFC analysis failed.'; 'Please check the Command Window for details.'}, 'Run Failed');
end
set(handles.pushbuttonRun, 'Enable', 'on');


end

function pushbuttonLoad_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonLoad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[loadName, loadPath] = uigetfile('*.mat', 'Load SFC Toolbox Settings');
if isequal(loadName, 0)
    return;
end
loadedData = load(fullfile(loadPath, loadName));
if ~isfield(loadedData, 'SFC_Settings')
    errordlg({'The selected MAT file does not contain SFC_Settings.'}, 'Invalid Settings File');
    return;
end
SFC_Settings = loadedData.SFC_Settings;
if ~isfield(SFC_Settings, 'WorkDir') || exist(SFC_Settings.WorkDir, 'dir') ~= 7
    errordlg({'The working directory stored in this settings file does not exist.'; ...
              'Please check the saved path or select the working directory again.'}, 'Invalid Working Directory');
    return;
end
scDir = fullfile(SFC_Settings.WorkDir, 'SC');
fcDir = fullfile(SFC_Settings.WorkDir, 'FC');
roiDir = fullfile(SFC_Settings.WorkDir, 'ROISignals');
if exist(scDir, 'dir') ~= 7 || exist(fcDir, 'dir') ~= 7
    errordlg({'The working directory stored in this settings file does not contain both SC and FC folders.'; ...
              'Please check the saved path.'}, 'Missing Required Folders');
    return;
end
participants = SFC_Settings.Participants;
if isstring(participants)
    participants = cellstr(participants);
elseif ischar(participants)
    participants = cellstr(participants);
end
participants = participants(:);
handles.SFC_hasWorkDir = true;
handles.SFC_WorkDir = SFC_Settings.WorkDir;
handles.SFC_SCDir = scDir;
handles.SFC_FCDir = fcDir;
handles.SFC_ROISignalsDir = roiDir;
handles.SFC_Participants = participants;
roiMatFiles = [];
if exist(roiDir, 'dir') == 7
    roiMatFiles = dir(fullfile(roiDir, '*.mat'));
end
handles.SFC_hasROISignals = exist(roiDir, 'dir') == 7 && ~isempty(roiMatFiles);
if isfield(SFC_Settings, 'CommunicationModel') && isfield(SFC_Settings.CommunicationModel, 'Settings')
    handles.SFC_CommModelSettings = SFC_Settings.CommunicationModel.Settings;
else
    handles.SFC_CommModelSettings = SFC_defaultCommModelSettings();
end
if isfield(SFC_Settings, 'DynamicAnalysis') && isfield(SFC_Settings.DynamicAnalysis, 'CommunicationModel') && isfield(SFC_Settings.DynamicAnalysis.CommunicationModel, 'Settings')
    handles.SFC_DynamicCommModelSettings = SFC_Settings.DynamicAnalysis.CommunicationModel.Settings;
else
    handles.SFC_DynamicCommModelSettings = SFC_defaultCommModelSettings();
end
if isfield(SFC_Settings, 'ResultsView')
    handles.SFC_ResultsViewSettings = SFC_Settings.ResultsView;
else
    handles.SFC_ResultsViewSettings = SFC_defaultResultsViewSettings();
end
set(handles.editWorkDir, 'String', handles.SFC_WorkDir);
set(handles.listParticipants, 'String', participants, 'Value', 1);
if isfield(SFC_Settings, 'Initialization')
    SFC_setPopupByString(handles.popupmenuSCThresholding, SFC_Settings.Initialization.SCThresholding);
    if isfield(SFC_Settings.Initialization, 'PreservePercent')
        set(handles.editPreservePercent, 'String', num2str(SFC_Settings.Initialization.PreservePercent));
    end
end
if isfield(SFC_Settings, 'StatCorr')
    if isfield(SFC_Settings.StatCorr, 'MinSCDegree')
        set(handles.editMinSCDegree, 'String', num2str(SFC_Settings.StatCorr.MinSCDegree));
    end
    if isfield(SFC_Settings.StatCorr, 'CorrelationType')
        SFC_setPopupByString(handles.popupCorrType, SFC_Settings.StatCorr.CorrelationType);
    end
end
if isfield(SFC_Settings, 'CommunicationModel')
    if isfield(SFC_Settings.CommunicationModel, 'MethodSelection')
        SFC_setPopupByString(handles.popupCommMethod, SFC_Settings.CommunicationModel.MethodSelection);
    end
    if isfield(SFC_Settings.CommunicationModel, 'PCACumulativeVariance')
        set(handles.editPCAVariance, 'String', num2str(SFC_Settings.CommunicationModel.PCACumulativeVariance));
    end
end
if isfield(SFC_Settings, 'DynamicAnalysis') && isfield(SFC_Settings.DynamicAnalysis, 'MethodSelection')
    SFC_setPopupByString(handles.popupDynamicMethod, SFC_Settings.DynamicAnalysis.MethodSelection);
end
if isfield(SFC_Settings, 'GSP')
    if isfield(SFC_Settings.GSP, 'AverageSCSource')
        SFC_setPopupByString(handles.popupAverageSCSource, SFC_Settings.GSP.AverageSCSource);
    end
    if isfield(SFC_Settings.GSP, 'GSPSCSource')
        set(handles.editGSPSCSource, 'String', SFC_Settings.GSP.GSPSCSource);
    end
    if isfield(SFC_Settings.GSP, 'AUCCutoff')
        set(handles.editAUCCutoff, 'String', num2str(SFC_Settings.GSP.AUCCutoff));
    end
end
if isfield(SFC_Settings, 'ParallelWorkers')
    set(handles.editParallelWorkers, 'String', num2str(SFC_Settings.ParallelWorkers));
end
set(handles.checkboxStatistical, 'Value', false);
set(handles.checkboxCommunication, 'Value', false);
set(handles.checkboxDynamic, 'Value', false);
set(handles.checkboxGSP, 'Value', false);
if isfield(SFC_Settings, 'Methods')
    if isfield(SFC_Settings.Methods, 'StatisticalCorrelation')
        set(handles.checkboxStatistical, 'Value', logical(SFC_Settings.Methods.StatisticalCorrelation));
    end
    if isfield(SFC_Settings.Methods, 'CommunicationModel')
        set(handles.checkboxCommunication, 'Value', logical(SFC_Settings.Methods.CommunicationModel));
    end
    if isfield(SFC_Settings.Methods, 'DynamicAnalysis') && handles.SFC_hasROISignals
        set(handles.checkboxDynamic, 'Value', logical(SFC_Settings.Methods.DynamicAnalysis));
    end
    if isfield(SFC_Settings.Methods, 'GraphSignalProcessing') && handles.SFC_hasROISignals
        set(handles.checkboxGSP, 'Value', logical(SFC_Settings.Methods.GraphSignalProcessing));
    end
end
SFC_updateThresholdingState(handles);
SFC_updateGSPAverageSCSourceState(handles);
SFC_applyMethodParameterState(handles);
guidata(hObject, handles);
fprintf('\nSFC toolbox settings loaded:\n%s\n\n', fullfile(loadPath, loadName));
msgbox({'SFC toolbox settings loaded successfully.'}, 'Load Complete');


end

function pushbuttonQuit_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonQuit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles, 'figure1') && ishandle(handles.figure1)
    delete(handles.figure1);
else
    delete(gcbf);
end


end

function checkboxGSP_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxGSP (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'SFC_hasWorkDir') || ~handles.SFC_hasWorkDir
    set(hObject, 'Value', 0);

    warndlg({'Please select a valid working directory first.'}, ...
            'Data Set-up Required');
    return;
end

if ~isfield(handles, 'SFC_hasROISignals') || ~handles.SFC_hasROISignals
    set(hObject, 'Value', 0);

    for iTag = 1:numel(handles.SFC_GSPParamTags)
        thisTag = handles.SFC_GSPParamTags{iTag};

        if isfield(handles, thisTag) && ishandle(handles.(thisTag))
            set(handles.(thisTag), 'Enable', 'off');
        end
    end

    warndlg({'Graph Signal Processing Method requires ROISignals results.'; ...
             'Please add a ROISignals folder with .mat files under the working directory.'; ...
             'Then select the working directory again.'}, ...
             'ROISignals Required');
    return;
end

if get(hObject, 'Value')
    for iTag = 1:numel(handles.SFC_GSPParamTags)
        thisTag = handles.SFC_GSPParamTags{iTag};

        if isfield(handles, thisTag) && ishandle(handles.(thisTag))
            set(handles.(thisTag), 'Enable', 'on');
        end
    end
else
    for iTag = 1:numel(handles.SFC_GSPParamTags)
        thisTag = handles.SFC_GSPParamTags{iTag};

        if isfield(handles, thisTag) && ishandle(handles.(thisTag))
            set(handles.(thisTag), 'Enable', 'off');
        end
    end
end

SFC_updateGSPAverageSCSourceState(handles);
guidata(hObject, handles);

% --- Executes on button press in pushGSPSCSource.

end


function pushGSPSCSource_Callback(hObject, eventdata, handles)
% hObject    handle to pushGSPSCSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'SFC_hasWorkDir') || ~handles.SFC_hasWorkDir
    warndlg({'Please select a valid working directory first.'}, 'Data Set-up Required');
    return;
end
if ~get(handles.checkboxGSP, 'Value')
    warndlg({'Please select Graph Signal Processing Method first.'; ...
             'The SC source can be selected only after its checkbox is selected.'}, 'Method Not Selected');
    return;
end

avgSource = SFC_getPopupString(handles.popupAverageSCSource);
if contains(lower(avgSource), 'threshold')
    % The source is fixed to the thresholded SC folder in this mode.
    SFC_updateGSPAverageSCSourceState(handles);
    return;
end

startDir = handles.SFC_WorkDir;
oldPath = strtrim(get(handles.editGSPSCSource, 'String'));
if exist(oldPath, 'file') == 2
    startDir = fileparts(oldPath);
elseif exist(oldPath, 'dir') == 7
    startDir = oldPath;
end

sourceChoice = questdlg('Select average SC source type:', 'Average SC Source', ...
    'Single MAT File', 'Folder', 'Cancel', 'Single MAT File');
if isempty(sourceChoice) || strcmp(sourceChoice, 'Cancel')
    return;
end

switch sourceChoice
    case 'Single MAT File'
        [fileName, filePath] = uigetfile('*.mat', 'Select Average SC MAT File', startDir);
        if isequal(fileName, 0)
            return;
        end
        selectedPath = fullfile(filePath, fileName);
        set(handles.editGSPSCSource, 'String', selectedPath, 'TooltipString', selectedPath);
    case 'Folder'
        folderPath = uigetdir(startDir, 'Select Average SC Source Folder');
        if isequal(folderPath, 0)
            return;
        end
        set(handles.editGSPSCSource, 'String', folderPath, 'TooltipString', folderPath);
end

guidata(hObject, handles);

end

function popupAverageSCSource_Callback(hObject, eventdata, handles)
% hObject    handle to popupAverageSCSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    avgSource = SFC_getPopupString(handles.popupAverageSCSource);
    if ~contains(lower(avgSource), 'threshold')
        set(handles.editGSPSCSource, 'String', '');
    end
catch
end
SFC_updateGSPAverageSCSourceState(handles);
guidata(hObject, handles);

% Hints: contents = cellstr(get(hObject,'String')) returns popupAverageSCSource contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupAverageSCSource


% --- Executes during object creation, after setting all properties.

end

function popupAverageSCSource_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupAverageSCSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




end

function editGSPSCSource_Callback(hObject, eventdata, handles)
% hObject    handle to editGSPSCSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editGSPSCSource as text
%        str2double(get(hObject,'String')) returns contents of editGSPSCSource as a double


% --- Executes during object creation, after setting all properties.

end

function editGSPSCSource_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editGSPSCSource (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




end

function editAUCCutoff_Callback(hObject, eventdata, handles)
% hObject    handle to editAUCCutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAUCCutoff as text
%        str2double(get(hObject,'String')) returns contents of editAUCCutoff as a double


% --- Executes during object creation, after setting all properties.

end

function editAUCCutoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAUCCutoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushDynamicCommSetting.

end

function pushDynamicCommSetting_Callback(hObject, eventdata, handles)
% hObject    handle to pushDynamicCommSetting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isfield(handles, 'SFC_hasWorkDir') || ~handles.SFC_hasWorkDir
    warndlg({'Please select a valid working directory first.'}, 'Data Set-up Required');
    return;
end
if ~isfield(handles, 'SFC_hasROISignals') || ~handles.SFC_hasROISignals
    warndlg({'Dynamic Analysis Method requires ROISignals results.'; ...
             'Please add a ROISignals folder with .mat files under the working directory.'; ...
             'Then select the working directory again.'}, 'ROISignals Required');
    return;
end
if ~get(handles.checkboxDynamic, 'Value')
    warndlg({'Please select Dynamic Analysis Method first.'}, 'Method Not Selected');
    return;
end
dynamicMethod = SFC_getPopupString(handles.popupDynamicMethod);
if ~contains(lower(dynamicMethod), 'communication')
    warndlg({'Communication Model Setting is only used when Dynamic Analysis Method is set to Communication Model.'}, 'Communication Model Not Selected');
    return;
end
if ~isfield(handles, 'SFC_DynamicCommModelSettings') || isempty(handles.SFC_DynamicCommModelSettings)
    handles.SFC_DynamicCommModelSettings = SFC_defaultCommModelSettings();
end
newSettings = CommunicationModelSetting(handles.SFC_DynamicCommModelSettings, ...
    'Dynamic Analysis Communication Model Setting');
if ~isempty(newSettings)
    handles.SFC_DynamicCommModelSettings = newSettings;
    guidata(hObject, handles);
end

end

function settings = SFC_defaultCommModelSettings()
settings = struct;
settings.PredictorList = {'Path Length', 'Path Transitivity', 'Search Information', ...
    'Flow Graphs', 'Euclidean Distance', 'Navigation', 'Communicability', ...
    'Matching Index', 'Cosine Similarity', 'Mean First Passage Time'};
settings.GammaValues = [0.25 0.5 1 2];
settings.MarkovTimeValues = [1 2.5 5 10];
settings.CoordinateMatrix = '';
settings.SCType = 'Both Binary+Weighted';
end

function settings = SFC_openCommunicationModelSettingDialog(settings, dialogTitle)
if nargin < 1 || isempty(settings)
    settings = SFC_defaultCommModelSettings();
end
if nargin < 2 || isempty(dialogTitle)
    dialogTitle = 'Communication Model Setting';
end

allModels = {'Path Length', 'Path Transitivity', 'Search Information', ...
    'Flow Graphs', 'Euclidean Distance', 'Navigation', 'Communicability', ...
    'Matching Index', 'Cosine Similarity', 'Mean First Passage Time'};
selectedModels = settings.PredictorList;
if isstring(selectedModels)
    selectedModels = cellstr(selectedModels);
elseif ischar(selectedModels)
    selectedModels = cellstr(selectedModels);
end

fig = dialog('Name', dialogTitle, 'Units', 'pixels', 'Position', [300 180 620 620], ...
    'WindowStyle', 'modal');

uicontrol(fig, 'Style', 'text', 'String', dialogTitle, ...
    'Units', 'pixels', 'Position', [110 570 400 30], ...
    'FontSize', 14, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

uicontrol(fig, 'Style', 'text', 'String', 'Model Selection', ...
    'Units', 'pixels', 'Position', [65 520 180 25], ...
    'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'left');
uicontrol(fig, 'Style', 'text', 'String', 'Parameter Setting', ...
    'Units', 'pixels', 'Position', [355 520 200 25], ...
    'FontSize', 11, 'FontWeight', 'bold', 'HorizontalAlignment', 'left');

panel1 = uipanel(fig, 'Units', 'pixels', 'Position', [30 390 560 120]);
panel2 = uipanel(fig, 'Units', 'pixels', 'Position', [30 315 560 60]);
panel3 = uipanel(fig, 'Units', 'pixels', 'Position', [30 210 560 90]);
panel4 = uipanel(fig, 'Units', 'pixels', 'Position', [30 70 560 125]);

cb.PathLength = uicontrol(panel1, 'Style', 'checkbox', 'String', 'Path Length', ...
    'Units', 'pixels', 'Position', [35 80 170 25], 'Value', ismember('Path Length', selectedModels));
cb.PathTransitivity = uicontrol(panel1, 'Style', 'checkbox', 'String', 'Path Transitivity', ...
    'Units', 'pixels', 'Position', [35 50 170 25], 'Value', ismember('Path Transitivity', selectedModels));
cb.SearchInformation = uicontrol(panel1, 'Style', 'checkbox', 'String', 'Search Information', ...
    'Units', 'pixels', 'Position', [35 20 180 25], 'Value', ismember('Search Information', selectedModels));
uicontrol(panel1, 'Style', 'text', 'String', 'Gamma :', 'Units', 'pixels', ...
    'Position', [310 50 75 25], 'HorizontalAlignment', 'right');
editGamma = uicontrol(panel1, 'Style', 'edit', 'String', SFC_numericVectorToString(settings.GammaValues), ...
    'Units', 'pixels', 'Position', [395 53 120 25], 'BackgroundColor', 'white');

cb.FlowGraphs = uicontrol(panel2, 'Style', 'checkbox', 'String', 'Flow Graphs', ...
    'Units', 'pixels', 'Position', [35 20 170 25], 'Value', ismember('Flow Graphs', selectedModels));
uicontrol(panel2, 'Style', 'text', 'String', 'Markov Time :', 'Units', 'pixels', ...
    'Position', [275 20 110 25], 'HorizontalAlignment', 'right');
editMarkov = uicontrol(panel2, 'Style', 'edit', 'String', SFC_numericVectorToString(settings.MarkovTimeValues), ...
    'Units', 'pixels', 'Position', [395 23 120 25], 'BackgroundColor', 'white');

cb.EuclideanDistance = uicontrol(panel3, 'Style', 'checkbox', 'String', 'Euclidean Distance', ...
    'Units', 'pixels', 'Position', [35 55 190 25], 'Value', ismember('Euclidean Distance', selectedModels));
cb.Navigation = uicontrol(panel3, 'Style', 'checkbox', 'String', 'Navigation', ...
    'Units', 'pixels', 'Position', [35 25 170 25], 'Value', ismember('Navigation', selectedModels));
uicontrol(panel3, 'Style', 'text', 'String', 'Select Coordinate Matrix :', ...
    'Units', 'pixels', 'Position', [235 55 180 25], 'HorizontalAlignment', 'right');
editCoord = uicontrol(panel3, 'Style', 'edit', 'String', settings.CoordinateMatrix, ...
    'Units', 'pixels', 'Position', [315 20 225 25], 'BackgroundColor', 'white', ...
    'HorizontalAlignment', 'left');
uicontrol(panel3, 'Style', 'pushbutton', 'String', '...', ...
    'Units', 'pixels', 'Position', [235 20 65 28], 'Callback', @selectCoordCallback);

cb.Communicability = uicontrol(panel4, 'Style', 'checkbox', 'String', 'Communicability', ...
    'Units', 'pixels', 'Position', [35 90 190 25], 'Value', ismember('Communicability', selectedModels));
cb.MatchingIndex = uicontrol(panel4, 'Style', 'checkbox', 'String', 'Matching Index', ...
    'Units', 'pixels', 'Position', [35 65 190 25], 'Value', ismember('Matching Index', selectedModels));
cb.CosineSimilarity = uicontrol(panel4, 'Style', 'checkbox', 'String', 'Cosine Similarity', ...
    'Units', 'pixels', 'Position', [35 40 190 25], 'Value', ismember('Cosine Similarity', selectedModels));
cb.MFPT = uicontrol(panel4, 'Style', 'checkbox', 'String', 'Mean First Passage Time', ...
    'Units', 'pixels', 'Position', [35 15 220 25], 'Value', ismember('Mean First Passage Time', selectedModels));

uicontrol(fig, 'Style', 'pushbutton', 'String', 'OK', ...
    'Units', 'pixels', 'Position', [385 25 85 30], 'Callback', @okCallback);
uicontrol(fig, 'Style', 'pushbutton', 'String', 'Cancel', ...
    'Units', 'pixels', 'Position', [490 25 85 30], 'Callback', @cancelCallback);

result = [];
uiwait(fig);
if ishandle(fig)
    delete(fig);
end
settings = result;

    function selectCoordCallback(~, ~)
        startDir = pwd;
        currentPath = strtrim(get(editCoord, 'String'));

        if exist(currentPath, 'file') == 2
            startDir = fileparts(currentPath);
        elseif exist(currentPath, 'dir') == 7
            startDir = currentPath;
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

                set(editCoord, 'String', fullfile(filePath, fileName));

            case 'Folder'
                folderPath = uigetdir(startDir, 'Select Coordinate Matrix Folder');

                if isequal(folderPath, 0)
                    return;
                end

                set(editCoord, 'String', folderPath);
        end
    end

    function okCallback(~, ~)
        modelList = {};
        if get(cb.PathLength, 'Value'), modelList{end+1} = 'Path Length'; end %#ok<AGROW>
        if get(cb.PathTransitivity, 'Value'), modelList{end+1} = 'Path Transitivity'; end %#ok<AGROW>
        if get(cb.SearchInformation, 'Value'), modelList{end+1} = 'Search Information'; end %#ok<AGROW>
        if get(cb.FlowGraphs, 'Value'), modelList{end+1} = 'Flow Graphs'; end %#ok<AGROW>
        if get(cb.EuclideanDistance, 'Value'), modelList{end+1} = 'Euclidean Distance'; end %#ok<AGROW>
        if get(cb.Navigation, 'Value'), modelList{end+1} = 'Navigation'; end %#ok<AGROW>
        if get(cb.Communicability, 'Value'), modelList{end+1} = 'Communicability'; end %#ok<AGROW>
        if get(cb.MatchingIndex, 'Value'), modelList{end+1} = 'Matching Index'; end %#ok<AGROW>
        if get(cb.CosineSimilarity, 'Value'), modelList{end+1} = 'Cosine Similarity'; end %#ok<AGROW>
        if get(cb.MFPT, 'Value'), modelList{end+1} = 'Mean First Passage Time'; end %#ok<AGROW>
        if isempty(modelList)
            errordlg({'Please select at least one communication model.'}, 'No Model Selected');
            return;
        end
        gammaVals = str2num(strtrim(get(editGamma, 'String'))); %#ok<ST2NM>
        markovVals = str2num(strtrim(get(editMarkov, 'String'))); %#ok<ST2NM>
        if isempty(gammaVals) || any(~isfinite(gammaVals)) || any(gammaVals <= 0)
            errordlg({'Gamma must be a positive numeric vector, for example: 0.25 0.5 1 2.'}, 'Invalid Gamma');
            return;
        end
        if isempty(markovVals) || any(~isfinite(markovVals)) || any(markovVals <= 0)
            errordlg({'Markov Time must be a positive numeric vector, for example: 1 2.5 5 10.'}, 'Invalid Markov Time');
            return;
        end
        coordPath = strtrim(get(editCoord, 'String'));
        needsCoord = any(ismember(modelList, {'Euclidean Distance', 'Navigation'}));
        if needsCoord && ~(exist(coordPath, 'file') == 2 || exist(coordPath, 'dir') == 7)
            errordlg({'Euclidean Distance and Navigation require a valid coordinate source.'; ...
                      'Please select either a single coordinate MAT file or a coordinate folder.'}, ...
                'Coordinate Source Required');
            return;
        end
        result = settings;
        result.PredictorList = modelList;
        result.GammaValues = gammaVals;
        result.MarkovTimeValues = markovVals;
        result.CoordinateMatrix = coordPath;
        result.SCType = 'Both Binary+Weighted';
        uiresume(fig);
    end

    function cancelCallback(~, ~)
        result = [];
        uiresume(fig);
    end
end

function txt = SFC_numericVectorToString(v)
if isempty(v)
    txt = '';
else
    txt = strtrim(sprintf('%.6g ', v));
end
end

function SFC_Settings = SFC_collectSettingsFromGUI(handles, validateForRun)
if nargin < 2
    validateForRun = false;
end

thresholdOptions = cellstr(get(handles.popupmenuSCThresholding, 'String'));
scThresholding = strtrim(thresholdOptions{get(handles.popupmenuSCThresholding, 'Value')});
preserveText = strtrim(get(handles.editPreservePercent, 'String'));
if isempty(preserveText)
    preservePercent = NaN;
else
    preservePercent = str2double(preserveText);
end

corrOptions = cellstr(get(handles.popupCorrType, 'String'));
corrType = strtrim(corrOptions{get(handles.popupCorrType, 'Value')});
minSCDegree = str2double(strtrim(get(handles.editMinSCDegree, 'String')));

parallelText = strtrim(get(handles.editParallelWorkers, 'String'));
if isempty(parallelText)
    parallelWorkers = 1;
    set(handles.editParallelWorkers, 'String', '1');
else
    parallelWorkers = str2double(parallelText);
end

if contains(lower(scThresholding), 'skip')
    preservePercent = 100;
elseif isnan(preservePercent) || preservePercent <= 0 || preservePercent > 100
    error('Preserve Percent must be a numeric value between 0 and 100.');
end
if isnan(minSCDegree) || minSCDegree < 1 || mod(minSCDegree, 1) ~= 0
    error('Min SC Degree must be a positive integer.');
end
if isnan(parallelWorkers) || parallelWorkers < 1 || mod(parallelWorkers, 1) ~= 0
    error('Parallel Workers must be a positive integer.');
end

SFC_Settings.Version = 'SFC_Toolbox_Settings_v2';
SFC_Settings.WorkDir = handles.SFC_WorkDir;
SFC_Settings.SCDir = handles.SFC_SCDir;
SFC_Settings.FCDir = handles.SFC_FCDir;
SFC_Settings.ROISignalsDir = handles.SFC_ROISignalsDir;
SFC_Settings.HasROISignals = handles.SFC_hasROISignals;
SFC_Settings.Participants = handles.SFC_Participants(:);

SFC_Settings.Initialization.SCThresholding = scThresholding;
SFC_Settings.Initialization.PreservePercent = preservePercent;
SFC_Settings.StatCorr.MinSCDegree = minSCDegree;
SFC_Settings.StatCorr.CorrelationType = corrType;

commOptions = cellstr(get(handles.popupCommMethod, 'String'));
SFC_Settings.CommunicationModel.MethodSelection = strtrim(commOptions{get(handles.popupCommMethod, 'Value')});
SFC_Settings.CommunicationModel.PCACumulativeVariance = str2double(strtrim(get(handles.editPCAVariance, 'String')));
if ~isfield(handles, 'SFC_CommModelSettings') || isempty(handles.SFC_CommModelSettings)
    SFC_Settings.CommunicationModel.Settings = SFC_defaultCommModelSettings();
else
    SFC_Settings.CommunicationModel.Settings = handles.SFC_CommModelSettings;
end
SFC_Settings.CommunicationModel.CoordinateMatrix = SFC_Settings.CommunicationModel.Settings.CoordinateMatrix;

dynamicOptions = cellstr(get(handles.popupDynamicMethod, 'String'));
SFC_Settings.DynamicAnalysis.MethodSelection = strtrim(dynamicOptions{get(handles.popupDynamicMethod, 'Value')});
if ~isfield(handles, 'SFC_DynamicCommModelSettings') || isempty(handles.SFC_DynamicCommModelSettings)
    SFC_Settings.DynamicAnalysis.CommunicationModel.Settings = SFC_defaultCommModelSettings();
else
    SFC_Settings.DynamicAnalysis.CommunicationModel.Settings = handles.SFC_DynamicCommModelSettings;
end
SFC_Settings.DynamicAnalysis.CommunicationModel.CoordinateMatrix = ...
    SFC_Settings.DynamicAnalysis.CommunicationModel.Settings.CoordinateMatrix;

averageSCOptions = cellstr(get(handles.popupAverageSCSource, 'String'));
SFC_Settings.GSP.AverageSCSource = strtrim(averageSCOptions{get(handles.popupAverageSCSource, 'Value')});
SFC_Settings.GSP.GSPSCSource = strtrim(get(handles.editGSPSCSource, 'String'));
if contains(lower(SFC_Settings.GSP.AverageSCSource), 'threshold')
    SFC_Settings.GSP.GSPSCSource = SFC_getDefaultThresholdedSCFolder(handles);
end
SFC_Settings.GSP.AUCCutoff = str2double(strtrim(get(handles.editAUCCutoff, 'String')));

SFC_Settings.Methods.StatisticalCorrelation = logical(get(handles.checkboxStatistical, 'Value'));
SFC_Settings.Methods.CommunicationModel = logical(get(handles.checkboxCommunication, 'Value'));
SFC_Settings.Methods.DynamicAnalysis = logical(get(handles.checkboxDynamic, 'Value'));
SFC_Settings.Methods.GraphSignalProcessing = logical(get(handles.checkboxGSP, 'Value'));
if isfield(handles, 'SFC_ResultsViewSettings') && ~isempty(handles.SFC_ResultsViewSettings)
    SFC_Settings.ResultsView = handles.SFC_ResultsViewSettings;
else
    SFC_Settings.ResultsView = SFC_defaultResultsViewSettings();
end
SFC_Settings.ParallelWorkers = parallelWorkers;
SFC_Settings.RunTime = datestr(now, 'yyyy-mm-dd HH:MM:SS');

if validateForRun
    if ~SFC_Settings.Methods.StatisticalCorrelation && ~SFC_Settings.Methods.CommunicationModel && ...
            ~SFC_Settings.Methods.DynamicAnalysis && ~SFC_Settings.Methods.GraphSignalProcessing
        error('Please select at least one SFC method before running.');
    end
    if SFC_Settings.Methods.CommunicationModel
        if isnan(SFC_Settings.CommunicationModel.PCACumulativeVariance) || ...
                SFC_Settings.CommunicationModel.PCACumulativeVariance <= 0 || ...
                SFC_Settings.CommunicationModel.PCACumulativeVariance > 100
            error('PCA Cumulative Variance must be within (0, 100].');
        end
        SFC_validateCommModelCoordinate(SFC_Settings.CommunicationModel.Settings, ...
            'Communication Model Method');
    end
    if SFC_Settings.Methods.DynamicAnalysis
        if ~SFC_Settings.HasROISignals
            error('Dynamic Analysis Method requires ROISignals results.');
        end
        if contains(lower(SFC_Settings.DynamicAnalysis.MethodSelection), 'communication')
            SFC_validateCommModelCoordinate(SFC_Settings.DynamicAnalysis.CommunicationModel.Settings, ...
                'Dynamic Analysis Communication Model');
        end
    end
    if SFC_Settings.Methods.GraphSignalProcessing
        if ~SFC_Settings.HasROISignals
            error('Graph Signal Processing Method requires ROISignals results.');
        end
        if isnan(SFC_Settings.GSP.AUCCutoff) || SFC_Settings.GSP.AUCCutoff <= 0 || SFC_Settings.GSP.AUCCutoff >= 100
            error('GSP AUC Cutoff must be within (0, 100).');
        end
        gspSourceIsThresholded = contains(lower(SFC_Settings.GSP.AverageSCSource), 'threshold');
        if ~gspSourceIsThresholded
            if isempty(SFC_Settings.GSP.GSPSCSource) || ...
                    ~(exist(SFC_Settings.GSP.GSPSCSource, 'dir') == 7 || exist(SFC_Settings.GSP.GSPSCSource, 'file') == 2)
                error('GSP SC source must be a valid MAT file or folder when Select Average SC Source is selected.');
            end
        end
    end
    if isfield(SFC_Settings, 'ResultsView')
        SFC_validateResultsViewSettings(SFC_Settings.ResultsView);
    end
end
end

function SFC_validateCommModelCoordinate(commSettings, methodName)
needsCoord = any(ismember(commSettings.PredictorList, {'Euclidean Distance', 'Navigation'}));
coordSource = strtrim(commSettings.CoordinateMatrix);

if needsCoord && (isempty(coordSource) || ~(exist(coordSource, 'file') == 2 || exist(coordSource, 'dir') == 7))
    error(['%s requires a valid coordinate source when Euclidean Distance or Navigation is selected. ' ...
           'Please select either one coordinate MAT file or a coordinate folder.'], methodName);
end
end

function SFC_applyMethodParameterState(handles)
% Enable method checkboxes after data set-up.
if isfield(handles, 'SFC_hasWorkDir') && handles.SFC_hasWorkDir
    set(handles.checkboxStatistical, 'Enable', 'on');
    set(handles.checkboxCommunication, 'Enable', 'on');
    set(handles.checkboxDynamic, 'Enable', 'on');
    set(handles.checkboxGSP, 'Enable', 'on');
else
    set(handles.checkboxStatistical, 'Enable', 'inactive');
    set(handles.checkboxCommunication, 'Enable', 'inactive');
    set(handles.checkboxDynamic, 'Enable', 'inactive');
    set(handles.checkboxGSP, 'Enable', 'inactive');
end

SFC_setControlsEnable(handles, handles.SFC_StatisticalParamTags, get(handles.checkboxStatistical, 'Value'));
SFC_setControlsEnable(handles, handles.SFC_CommunicationParamTags, get(handles.checkboxCommunication, 'Value'));
SFC_setControlsEnable(handles, handles.SFC_DynamicParamTags, get(handles.checkboxDynamic, 'Value') && handles.SFC_hasROISignals);
SFC_setControlsEnable(handles, handles.SFC_GSPParamTags, get(handles.checkboxGSP, 'Value') && handles.SFC_hasROISignals);
SFC_setDynamicCommButtonState(handles);
SFC_updateGSPAverageSCSourceState(handles);
end

function SFC_setControlsEnable(handles, tagList, enabled)
if enabled
    state = 'on';
else
    state = 'off';
end
for iTag = 1:numel(tagList)
    thisTag = tagList{iTag};
    if isfield(handles, thisTag) && ishandle(handles.(thisTag))
        set(handles.(thisTag), 'Enable', state);
    end
end
end

function SFC_setDynamicCommButtonState(handles)
if ~isfield(handles, 'pushDynamicCommSetting') || ~ishandle(handles.pushDynamicCommSetting)
    return;
end
try
    dynamicMethod = SFC_getPopupString(handles.popupDynamicMethod);
    if get(handles.checkboxDynamic, 'Value') && handles.SFC_hasROISignals && contains(lower(dynamicMethod), 'communication')
        set(handles.pushDynamicCommSetting, 'Enable', 'on');
    else
        set(handles.pushDynamicCommSetting, 'Enable', 'off');
    end
catch
    set(handles.pushDynamicCommSetting, 'Enable', 'off');
end
end

function value = SFC_getPopupString(hPopup)
options = cellstr(get(hPopup, 'String'));
value = strtrim(options{get(hPopup, 'Value')});
end

function SFC_setPopupByString(hPopup, targetString)
if isempty(targetString)
    return;
end
options = cellstr(get(hPopup, 'String'));
idx = find(strcmpi(strtrim(options), strtrim(targetString)), 1, 'first');
if ~isempty(idx)
    set(hPopup, 'Value', idx);
end
end



function SFC_updateThresholdingState(handles)
if ~isfield(handles, 'popupmenuSCThresholding') || ~ishandle(handles.popupmenuSCThresholding) || ...
        ~isfield(handles, 'editPreservePercent') || ~ishandle(handles.editPreservePercent)
    return;
end
try
    thresholdMode = SFC_getPopupString(handles.popupmenuSCThresholding);
catch
    return;
end
if contains(lower(thresholdMode), 'skip')
    set(handles.editPreservePercent, 'String', '', 'Enable', 'off');
else
    if isempty(strtrim(get(handles.editPreservePercent, 'String')))
        set(handles.editPreservePercent, 'String', '80');
    end
    set(handles.editPreservePercent, 'Enable', 'on');
end
end

function defaultFolder = SFC_getDefaultThresholdedSCFolder(handles)
defaultFolder = '';
if isfield(handles, 'SFC_WorkDir') && ~isempty(handles.SFC_WorkDir)
    [parentDir, ~] = fileparts(handles.SFC_WorkDir);
    defaultFolder = fullfile(parentDir, 'SFC_Results', 'Thresholded_SC');
end
end

function SFC_updateGSPAverageSCSourceState(handles)
if ~isfield(handles, 'popupAverageSCSource') || ~ishandle(handles.popupAverageSCSource) || ...
        ~isfield(handles, 'editGSPSCSource') || ~ishandle(handles.editGSPSCSource)
    return;
end
try
    avgSource = SFC_getPopupString(handles.popupAverageSCSource);
catch
    return;
end
if contains(lower(avgSource), 'threshold')
    defaultFolder = SFC_getDefaultThresholdedSCFolder(handles);
    set(handles.editGSPSCSource, 'String', defaultFolder, ...
        'Enable', 'on', ...
        'TooltipString', defaultFolder, ...
        'HorizontalAlignment', 'left');
    if isfield(handles, 'pushGSPSCSource') && ishandle(handles.pushGSPSCSource)
        set(handles.pushGSPSCSource, 'Enable', 'off');
    end
else
    set(handles.editGSPSCSource, 'Enable', 'on');
    if isfield(handles, 'pushGSPSCSource') && ishandle(handles.pushGSPSCSource)
        if isfield(handles, 'checkboxGSP') && ishandle(handles.checkboxGSP) && get(handles.checkboxGSP, 'Value')
            set(handles.pushGSPSCSource, 'Enable', 'on');
        else
            set(handles.pushGSPSCSource, 'Enable', 'off');
        end
    end
end
end

function settings = SFC_defaultResultsViewSettings()
settings = struct;
settings.Enabled = false;
settings.VolumeSpaceCortexAtlas = '';
settings.VolumeSpaceSubcorticalAtlas = '';
settings.SurfaceSpaceCortexAtlasLH = '';
settings.SurfaceSpaceCortexAtlasRH = '';
end

function settings = SFC_openResultsViewSettingDialog(settings, currentMethods)
if nargin < 1 || isempty(settings)
    settings = SFC_defaultResultsViewSettings();
end
if nargin < 2 || isempty(currentMethods)
    currentMethods = struct;
end

fig = dialog('Name', 'Results View Setting', 'Units', 'pixels', ...
    'Position', [360 220 720 520], 'WindowStyle', 'modal');

uicontrol(fig, 'Style', 'text', 'String', 'Results View Setting', ...
    'Units', 'pixels', 'Position', [180 465 360 32], ...
    'FontSize', 14, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

panel = uipanel(fig, 'Units', 'pixels', 'Position', [35 80 650 370]);

methodText = SFC_resultsViewMethodText(currentMethods);
uicontrol(panel, 'Style', 'text', 'String', ['Selected methods: ', methodText], ...
    'Units', 'pixels', 'Position', [40 325 560 25], ...
    'HorizontalAlignment', 'left');

cbEnable = uicontrol(panel, 'Style', 'checkbox', 'String', 'Generate view files after Run', ...
    'Units', 'pixels', 'Position', [40 295 280 25], 'Value', logical(settings.Enabled));

uicontrol(panel, 'Style', 'text', 'String', 'Select Volume Space Cortex Atlas File :', ...
    'Units', 'pixels', 'Position', [90 245 360 25], 'HorizontalAlignment', 'left', 'FontSize', 10);
editVolCortex = uicontrol(panel, 'Style', 'edit', 'String', settings.VolumeSpaceCortexAtlas, ...
    'Units', 'pixels', 'Position', [170 215 405 28], 'HorizontalAlignment', 'left', 'BackgroundColor', 'white');
uicontrol(panel, 'Style', 'pushbutton', 'String', '...', ...
    'Units', 'pixels', 'Position', [90 214 60 30], 'Callback', @(~,~)selectFile(editVolCortex, 'Select Volume Space Cortex Atlas File'));

uicontrol(panel, 'Style', 'text', 'String', 'Select Volume Space Subcortical Tissue Atlas File :', ...
    'Units', 'pixels', 'Position', [90 175 420 25], 'HorizontalAlignment', 'left', 'FontSize', 10);
editVolSub = uicontrol(panel, 'Style', 'edit', 'String', settings.VolumeSpaceSubcorticalAtlas, ...
    'Units', 'pixels', 'Position', [170 145 405 28], 'HorizontalAlignment', 'left', 'BackgroundColor', 'white');
uicontrol(panel, 'Style', 'pushbutton', 'String', '...', ...
    'Units', 'pixels', 'Position', [90 144 60 30], 'Callback', @(~,~)selectFile(editVolSub, 'Select Volume Space Subcortical Tissue Atlas File'));

uicontrol(panel, 'Style', 'text', 'String', 'Select Surface Space Cortex Atlas File (LH) :', ...
    'Units', 'pixels', 'Position', [90 105 390 25], 'HorizontalAlignment', 'left', 'FontSize', 10);
editSurfLH = uicontrol(panel, 'Style', 'edit', 'String', settings.SurfaceSpaceCortexAtlasLH, ...
    'Units', 'pixels', 'Position', [170 75 405 28], 'HorizontalAlignment', 'left', 'BackgroundColor', 'white');
uicontrol(panel, 'Style', 'pushbutton', 'String', '...', ...
    'Units', 'pixels', 'Position', [90 74 60 30], 'Callback', @(~,~)selectFile(editSurfLH, 'Select Surface Space Cortex Atlas File LH'));

uicontrol(panel, 'Style', 'text', 'String', 'Select Surface Space Cortex Atlas File (RH) :', ...
    'Units', 'pixels', 'Position', [90 35 390 25], 'HorizontalAlignment', 'left', 'FontSize', 10);
editSurfRH = uicontrol(panel, 'Style', 'edit', 'String', settings.SurfaceSpaceCortexAtlasRH, ...
    'Units', 'pixels', 'Position', [170 5 405 28], 'HorizontalAlignment', 'left', 'BackgroundColor', 'white');
uicontrol(panel, 'Style', 'pushbutton', 'String', '...', ...
    'Units', 'pixels', 'Position', [90 4 60 30], 'Callback', @(~,~)selectFile(editSurfRH, 'Select Surface Space Cortex Atlas File RH'));

uicontrol(fig, 'Style', 'pushbutton', 'String', 'OK', ...
    'Units', 'pixels', 'Position', [235 30 95 32], 'Callback', @okCallback);
uicontrol(fig, 'Style', 'pushbutton', 'String', 'Cancel', ...
    'Units', 'pixels', 'Position', [390 30 95 32], 'Callback', @cancelCallback);

uiwait(fig);

    function selectFile(editHandle, dialogTitle)
        currentPath = strtrim(get(editHandle, 'String'));
        startDir = pwd;
        if exist(currentPath, 'file') == 2
            startDir = fileparts(currentPath);
        end
        [fileName, filePath] = uigetfile({'*.nii;*.nii.gz;*.gii;*.mat;*.img', 'Atlas files (*.nii, *.nii.gz, *.gii, *.mat, *.img)'; '*.*', 'All files'}, dialogTitle, startDir);
        if isequal(fileName, 0)
            return;
        end
        set(editHandle, 'String', fullfile(filePath, fileName));
    end

    function okCallback(~, ~)
        newSettings = struct;
        newSettings.Enabled = logical(get(cbEnable, 'Value'));
        newSettings.VolumeSpaceCortexAtlas = strtrim(get(editVolCortex, 'String'));
        newSettings.VolumeSpaceSubcorticalAtlas = strtrim(get(editVolSub, 'String'));
        newSettings.SurfaceSpaceCortexAtlasLH = strtrim(get(editSurfLH, 'String'));
        newSettings.SurfaceSpaceCortexAtlasRH = strtrim(get(editSurfRH, 'String'));
        try
            SFC_validateResultsViewSettings(newSettings);
        catch ME
            errordlg({ME.message}, 'Invalid Results View Settings');
            return;
        end
        settings = newSettings;
        uiresume(fig);
        delete(fig);
    end

    function cancelCallback(~, ~)
        settings = [];
        uiresume(fig);
        delete(fig);
    end
end

function txt = SFC_resultsViewMethodText(currentMethods)
items = {};
if isfield(currentMethods, 'StatisticalCorrelation') && currentMethods.StatisticalCorrelation
    items{end+1} = 'Statistical Correlation'; %#ok<AGROW>
end
if isfield(currentMethods, 'CommunicationModel') && currentMethods.CommunicationModel
    items{end+1} = 'Communication Model'; %#ok<AGROW>
end
if isfield(currentMethods, 'DynamicAnalysis') && currentMethods.DynamicAnalysis
    items{end+1} = 'Dynamic Analysis'; %#ok<AGROW>
end
if isfield(currentMethods, 'GraphSignalProcessing') && currentMethods.GraphSignalProcessing
    items{end+1} = 'Graph Signal Processing'; %#ok<AGROW>
end
if isempty(items)
    txt = 'None selected yet';
else
    txt = strjoin(items, ', ');
end
end

function SFC_validateResultsViewSettings(settings)
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


function pushbuttonDataPrepareSetting_Callback(hObject, eventdata, handles)
% hObject    handle to pushbuttonDataPrepareSetting (see GCBO)
% eventdata  reserved
% handles    structure with handles and user data

if ~isfield(handles, 'SFC_DataPrepareSettings') || isempty(handles.SFC_DataPrepareSettings)
    handles.SFC_DataPrepareSettings = struct();
end

try
    result = DataPrepareSetting(handles.SFC_DataPrepareSettings);
catch ME
    fprintf('\n==================== DATA PREPARE SETTING ERROR ====================\n');
    fprintf('%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    fprintf('===================================================================\n\n');
    errordlg({'Unable to open or run Data Prepare Setting.'; ...
              'Please check whether DataPrepareSetting.m and DataPrepareSetting.fig are on the MATLAB path.'}, ...
              'Data Prepare Setting Error');
    return;
end

if isempty(result)
    return;
end

handles.SFC_DataPrepareSettings = rmfield_if_exists(result, 'Report');
workDir = result.OutputDirectory;
set(handles.editWorkDir, 'String', workDir);

try
    handles = SFC_loadPreparedWorkDirIntoGUI(handles, workDir);
    guidata(hObject, handles);
catch ME
    fprintf('\n==================== DATA SET-UP ERROR ====================\n');
    fprintf('%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    fprintf('==========================================================\n\n');
    errordlg({'Data were prepared, but the generated working directory failed the standard Data Set-up check.'; ...
              'Please check whether the output directory contains matched SC and FC folders.'; ...
              'See the Command Window for details.'}, ...
              'Data Set-up Failed');
end
end

function s = rmfield_if_exists(s, fieldName)
if isstruct(s) && isfield(s, fieldName)
    s = rmfield(s, fieldName);
end
end

function handles = SFC_loadPreparedWorkDirIntoGUI(handles, workDir)
% Apply the same work-directory validation logic after Data Prepare Setting.

scDir = fullfile(workDir, 'SC');
fcDir = fullfile(workDir, 'FC');
roiDir = fullfile(workDir, 'ROISignals');

fprintf('\n============================================================\n');
fprintf('[SFC Toolbox] Data set-up check after Data Prepare Setting\n');
fprintf('Working directory: %s\n', workDir);
fprintf('SC folder: %s\n', scDir);
fprintf('FC folder: %s\n', fcDir);
fprintf('ROISignals folder: %s\n', roiDir);
fprintf('============================================================\n');

if exist(scDir, 'dir') ~= 7 || exist(fcDir, 'dir') ~= 7
    if exist(scDir, 'dir') ~= 7
        fprintf('Missing folder: SC\n');
    end
    if exist(fcDir, 'dir') ~= 7
        fprintf('Missing folder: FC\n');
    end
    error('The working directory must contain both SC and FC folders.');
end

scFiles = dir(fullfile(scDir, '*.mat'));
fcFiles = dir(fullfile(fcDir, '*.mat'));
fprintf('SC .mat file count: %d\n', numel(scFiles));
fprintf('FC .mat file count: %d\n', numel(fcFiles));
if isempty(scFiles) || isempty(fcFiles)
    error('SC and FC folders must both contain .mat files.');
end

[scKeys, scValid, scNames] = SFC_extractKeysFromFileList(scFiles);
[fcKeys, fcValid, fcNames] = SFC_extractKeysFromFileList(fcFiles);
if any(~scValid) || any(~fcValid)
    fprintf('Files without valid sub/Sub/SUB IDs were detected.\n');
    if any(~scValid)
        fprintf('Invalid SC files:\n');
        fprintf('  %s\n', scNames{~scValid});
    end
    if any(~fcValid)
        fprintf('Invalid FC files:\n');
        fprintf('  %s\n', fcNames{~fcValid});
    end
    error('Some .mat files do not contain valid sub/Sub/SUB participant IDs.');
end

matchedKeys = intersect(scKeys, fcKeys);
scOnlyKeys = setdiff(scKeys, fcKeys);
fcOnlyKeys = setdiff(fcKeys, scKeys);
matchedDisplay = matchedKeys;
scOnlyDisplay = scOnlyKeys;
fcOnlyDisplay = fcOnlyKeys;

fprintf('\nParticipant matching report:\n');
fprintf('Matched participants: %d\n', numel(matchedDisplay));
if ~isempty(matchedDisplay)
    fprintf('Matched participant IDs:\n');
    fprintf('  %s\n', matchedDisplay{:});
end
if ~isempty(scOnlyDisplay)
    fprintf('SC-only participants, possible missing FC files:\n');
    fprintf('  %s\n', scOnlyDisplay{:});
end
if ~isempty(fcOnlyDisplay)
    fprintf('FC-only participants, possible missing SC files:\n');
    fprintf('  %s\n', fcOnlyDisplay{:});
end

if numel(scFiles) ~= numel(fcFiles)
    error('SC and FC file counts do not match.');
end
if ~isempty(scOnlyKeys) || ~isempty(fcOnlyKeys)
    error('SC and FC participant IDs cannot be matched one-to-one.');
end

participants = sort(matchedDisplay);
handles.SFC_hasWorkDir = true;
handles.SFC_WorkDir = workDir;
handles.SFC_SCDir = scDir;
handles.SFC_FCDir = fcDir;
handles.SFC_ROISignalsDir = roiDir;
handles.SFC_Participants = participants;

if isfield(handles, 'editWorkDir') && ishandle(handles.editWorkDir)
    set(handles.editWorkDir, 'String', workDir);
end
if isfield(handles, 'listParticipants') && ishandle(handles.listParticipants)
    set(handles.listParticipants, 'String', participants, 'Value', 1);
end

% Reset method selections and parameter states.
for iTag = 1:numel(handles.SFC_MethodCheckboxTags)
    thisTag = handles.SFC_MethodCheckboxTags{iTag};
    if isfield(handles, thisTag) && ishandle(handles.(thisTag))
        set(handles.(thisTag), 'Value', 0, 'Enable', 'inactive');
    end
end
for iTag = 1:numel(handles.SFC_AllMethodParamTags)
    thisTag = handles.SFC_AllMethodParamTags{iTag};
    if isfield(handles, thisTag) && ishandle(handles.(thisTag))
        set(handles.(thisTag), 'Enable', 'off');
    end
end

set(handles.checkboxStatistical, 'Enable', 'on');
set(handles.checkboxCommunication, 'Enable', 'on');

roiMatFiles = [];
if exist(roiDir, 'dir') == 7
    roiMatFiles = dir(fullfile(roiDir, '*.mat'));
end
handles.SFC_hasROISignals = exist(roiDir, 'dir') == 7 && ~isempty(roiMatFiles);
if handles.SFC_hasROISignals
    fprintf('ROISignals status: Found (%d .mat files)\n', numel(roiMatFiles));
    set(handles.checkboxDynamic, 'Enable', 'on');
    set(handles.checkboxGSP, 'Enable', 'on');
else
    fprintf('ROISignals status: Not found or no .mat files found\n');
    set(handles.checkboxDynamic, 'Enable', 'on', 'Value', 0, ...
        'TooltipString', 'ROISignals results are required for this method.');
    set(handles.checkboxGSP, 'Enable', 'on', 'Value', 0, ...
        'TooltipString', 'ROISignals results are required for this method.');
end

if isfield(handles, 'popupAverageSCSource') && ishandle(handles.popupAverageSCSource)
    set(handles.popupAverageSCSource, 'Value', 1);
end
SFC_updateGSPAverageSCSourceState(handles);
SFC_updateThresholdingState(handles);

fprintf('\nData set-up completed successfully.\n');
fprintf('Loaded participants: %d\n', numel(participants));
fprintf('============================================================\n\n');
end

function [keys, valid, names] = SFC_extractKeysFromFileList(fileList)
names = {fileList.name}';
keys = cell(numel(names), 1);
valid = false(numel(names), 1);
for iFile = 1:numel(names)
    [~, baseName] = fileparts(names{iFile});
    token = regexpi(baseName, '(sub.*)$', 'tokens', 'once');
    if ~isempty(token)
        subjectID = strtrim(token{1});
        if ~isempty(subjectID)
            keys{iFile} = lower(subjectID);
            valid(iFile) = true;
        end
    end
end
keys = keys(valid);
end

function SFC_applyGuideDisplayCompatibility(handles, FigureHandle)
if nargin < 2 || isempty(FigureHandle) || ~ishandle(FigureHandle)
    if isfield(handles, 'figure1') && ishandle(handles.figure1)
        FigureHandle = handles.figure1;
    else
        return;
    end
end

if SFC_isR2025OrLater()
    SFC_applyGuideCompatR2025(FigureHandle);
else
    SFC_applyLegacyScale(handles, FigureHandle);
end

SFC_expandFigureToFitContents(FigureHandle);

try
    movegui(FigureHandle, 'center');
catch
end
end

function IsR2025OrLater = SFC_isR2025OrLater()
ReleaseText = version('-release');
ReleaseYearText = regexp(ReleaseText, '^\d{4}', 'match', 'once');
ReleaseYear = str2double(ReleaseYearText);
IsR2025OrLater = (~isnan(ReleaseYear)) && (ReleaseYear >= 2025);
end

function SFC_applyGuideCompatR2025(FigureHandle)
% R2025+ already performs UI scaling for classic figures. Avoid double scaling.
try
    set(FigureHandle, 'WindowStyle', 'normal');
catch
end

ObjectHandles = findall(FigureHandle);
for iHandle = 1:length(ObjectHandles)
    CurrentHandle = ObjectHandles(iHandle);

    if isprop(CurrentHandle, 'FontUnits')
        try
            set(CurrentHandle, 'FontUnits', 'points');
        catch
        end
    end

    if isprop(CurrentHandle, 'Units')
        try
            CurrentUnits = get(CurrentHandle, 'Units');
            if strcmpi(CurrentUnits, 'characters')
                set(CurrentHandle, 'Units', 'pixels');
            end
        catch
        end
    end
end
end

function SFC_applyLegacyScale(handles, FigureHandle)
% Legacy GUIDE scaling path used by MATLAB R2024 and earlier.
if ismac
    ZoonMatrix = [1 1 1.2 1.2];  %For mac
elseif ispc
    ZoonMatrix = [1 1 1.3 1.3];  %For pc
else
    ZoonMatrix = [1 1 1.3 1.3];  %For Linux
end
UISize = get(FigureHandle, 'Position');
UISize = UISize.*ZoonMatrix;
set(FigureHandle, 'Position', UISize);

% Make Display correct in Mac and linux
if ~ispc
    if ismac
        ZoomFactor = 1.5;  %For Mac
    else
        ZoomFactor = 1;  %For Linux
    end
    ObjectNames = fieldnames(handles);
    for iObject = 1:length(ObjectNames)
        try
            IsFontSizeProp = isprop(handles.(ObjectNames{iObject}), 'FontSize');
        catch
            IsFontSizeProp = 0;
        end
        if IsFontSizeProp
            PCFontSize = get(handles.(ObjectNames{iObject}), 'FontSize');
            FontSize = PCFontSize*ZoomFactor;
            set(handles.(ObjectNames{iObject}), 'FontSize', FontSize);
        end
    end
end
end

function SFC_expandFigureToFitContents(FigureHandle)
try
    OriginalUnits = get(FigureHandle, 'Units');
    set(FigureHandle, 'Units', 'pixels');
    FigurePosition = get(FigureHandle, 'Position');
catch
    return;
end

Padding = 12;
RequiredWidth = FigurePosition(3);
RequiredHeight = FigurePosition(4);
ObjectHandles = findall(FigureHandle);

for iHandle = 1:length(ObjectHandles)
    CurrentHandle = ObjectHandles(iHandle);
    if isequal(CurrentHandle, FigureHandle) || ~isprop(CurrentHandle, 'Position')
        continue;
    end

    try
        ObjectPosition = getpixelposition(CurrentHandle, true);
    catch
        continue;
    end

    RequiredWidth = max(RequiredWidth, ObjectPosition(1) + ObjectPosition(3) + Padding);
    RequiredHeight = max(RequiredHeight, ObjectPosition(2) + ObjectPosition(4) + Padding);
end

FigurePosition(3) = ceil(RequiredWidth);
FigurePosition(4) = ceil(RequiredHeight);

try
    set(FigureHandle, 'Position', FigurePosition);
    set(FigureHandle, 'Units', OriginalUnits);
catch
end
end
