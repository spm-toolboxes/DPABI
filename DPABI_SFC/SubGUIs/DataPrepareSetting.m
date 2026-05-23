function varargout = DataPrepareSetting(varargin)
% DATAPREPARESETTING Prepare FC, ROISignals, and coordinate files for SFC Toolbox.
% Usage:
%   result = DataPrepareSetting(previousSettings)
% The GUIDE figure is used for the layout. This file binds callbacks and runs
% the data preparation after the user presses OK.

% Begin initialization code - DO NOT EDIT
 gui_Singleton = 1;
 gui_State = struct('gui_Name',       mfilename, ...
                    'gui_Singleton',  gui_Singleton, ...
                    'gui_OpeningFcn', @DataPrepareSetting_OpeningFcn, ...
                    'gui_OutputFcn',  @DataPrepareSetting_OutputFcn, ...
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

function DataPrepareSetting_OpeningFcn(hObject, eventdata, handles, varargin)
% hObject    handle to figure
% handles    structure with handles and user data

handles.output = [];
handles.SFC_PreviousSettings = struct();

if nargin >= 4 && ~isempty(varargin)
    if isstruct(varargin{1})
        handles.SFC_PreviousSettings = varargin{1};
    end
end

% Fill previous settings if available
if isfield(handles.SFC_PreviousSettings, 'OutputDirectory') && isfield(handles, 'editSelectOutputDirectory')
    set(handles.editSelectOutputDirectory, 'String', handles.SFC_PreviousSettings.OutputDirectory);
end
if isfield(handles.SFC_PreviousSettings, 'FCRelatedDataDirectory') && isfield(handles, 'editSelectFCRelatedDataDirectory')
    set(handles.editSelectFCRelatedDataDirectory, 'String', handles.SFC_PreviousSettings.FCRelatedDataDirectory);
end
if isfield(handles.SFC_PreviousSettings, 'ROIIndicesText') && isfield(handles, 'editEnterROIIndices')
    set(handles.editEnterROIIndices, 'String', handles.SFC_PreviousSettings.ROIIndicesText);
end
if isfield(handles.SFC_PreviousSettings, 'CoordinatesRelatedDataDirectory') && isfield(handles, 'editSelectCoordinatesRelatedDataDirectory')
    set(handles.editSelectCoordinatesRelatedDataDirectory, 'String', handles.SFC_PreviousSettings.CoordinatesRelatedDataDirectory);
end

% Force callback bindings, even when the FIG callback fields are empty.
if isfield(handles, 'pushbuttonSelectOutputDirectory') && ishandle(handles.pushbuttonSelectOutputDirectory)
    set(handles.pushbuttonSelectOutputDirectory, 'Callback', @pushbuttonSelectOutputDirectory_Callback);
end
if isfield(handles, 'pushbuttonSelectFCRelatedDataDirectory') && ishandle(handles.pushbuttonSelectFCRelatedDataDirectory)
    set(handles.pushbuttonSelectFCRelatedDataDirectory, 'Callback', @pushbuttonSelectFCRelatedDataDirectory_Callback);
end
if isfield(handles, 'pushbuttonSelectCoordinatesRelatedDataDirectory') && ishandle(handles.pushbuttonSelectCoordinatesRelatedDataDirectory)
    set(handles.pushbuttonSelectCoordinatesRelatedDataDirectory, 'Callback', @pushbuttonSelectCoordinatesRelatedDataDirectory_Callback);
end

% Add OK and Cancel buttons programmatically because the current GUIDE layout
% only contains input fields.
figUnits = get(hObject, 'Units');
set(hObject, 'Units', 'pixels');
figPos = get(hObject, 'Position');
btnW = 100;
btnH = 32;
gap = 25;
y = 18;
x1 = (figPos(3) - 2*btnW - gap) / 2;
x2 = x1 + btnW + gap;
handles.pushbuttonOK = uicontrol(hObject, 'Style', 'pushbutton', 'String', 'OK', ...
    'Units', 'pixels', 'Position', [x1 y btnW btnH], 'Callback', @pushbuttonOK_Callback);
handles.pushbuttonCancel = uicontrol(hObject, 'Style', 'pushbutton', 'String', 'Cancel', ...
    'Units', 'pixels', 'Position', [x2 y btnW btnH], 'Callback', @pushbuttonCancel_Callback);
set(hObject, 'Units', figUnits);

% Store handles
 guidata(hObject, handles);
 uiwait(hObject);
end

function varargout = DataPrepareSetting_OutputFcn(hObject, eventdata, handles)
if isempty(handles)
    varargout{1} = [];
    return;
end
varargout{1} = handles.output;
if isfield(handles, 'figure1') && ishandle(handles.figure1)
    delete(handles.figure1);
end
end

function pushbuttonSelectOutputDirectory_Callback(hObject, eventdata, handles)
if nargin < 3 || isempty(handles)
    handles = guidata(hObject);
end
startDir = pwd;
if isfield(handles, 'editSelectOutputDirectory') && ishandle(handles.editSelectOutputDirectory)
    oldPath = strtrim(get(handles.editSelectOutputDirectory, 'String'));
    if exist(oldPath, 'dir') == 7
        startDir = oldPath;
    end
end
outDir = uigetdir(startDir, 'Select Output Directory');
if isequal(outDir, 0)
    return;
end
set(handles.editSelectOutputDirectory, 'String', outDir);
guidata(hObject, handles);
end

function editSelectOutputDirectory_Callback(hObject, eventdata, handles) %#ok<INUSD>
end

function editSelectOutputDirectory_CreateFcn(hObject, eventdata, handles) %#ok<INUSD>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function pushbuttonSelectFCRelatedDataDirectory_Callback(hObject, eventdata, handles)
if nargin < 3 || isempty(handles)
    handles = guidata(hObject);
end
startDir = pwd;
if isfield(handles, 'editSelectFCRelatedDataDirectory') && ishandle(handles.editSelectFCRelatedDataDirectory)
    oldPath = strtrim(get(handles.editSelectFCRelatedDataDirectory, 'String'));
    if exist(oldPath, 'dir') == 7
        startDir = oldPath;
    end
end
fcDir = uigetdir(startDir, 'Select FC Related Data Directory');
if isequal(fcDir, 0)
    return;
end
set(handles.editSelectFCRelatedDataDirectory, 'String', fcDir);
guidata(hObject, handles);
end

function editSelectFCRelatedDataDirectory_Callback(hObject, eventdata, handles) %#ok<INUSD>
end

function editSelectFCRelatedDataDirectory_CreateFcn(hObject, eventdata, handles) %#ok<INUSD>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function editEnterROIIndices_Callback(hObject, eventdata, handles) %#ok<INUSD>
end

function editEnterROIIndices_CreateFcn(hObject, eventdata, handles) %#ok<INUSD>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function pushbuttonSelectCoordinatesRelatedDataDirectory_Callback(hObject, eventdata, handles)
if nargin < 3 || isempty(handles)
    handles = guidata(hObject);
end
startDir = pwd;
if isfield(handles, 'editSelectCoordinatesRelatedDataDirectory') && ishandle(handles.editSelectCoordinatesRelatedDataDirectory)
    oldPath = strtrim(get(handles.editSelectCoordinatesRelatedDataDirectory, 'String'));
    if exist(oldPath, 'dir') == 7
        startDir = oldPath;
    end
end
coordDir = uigetdir(startDir, 'Select Coordinates Related Data Directory');
if isequal(coordDir, 0)
    return;
end
set(handles.editSelectCoordinatesRelatedDataDirectory, 'String', coordDir);
guidata(hObject, handles);
end

function editSelectCoordinatesRelatedDataDirectory_Callback(hObject, eventdata, handles) %#ok<INUSD>
end

function editSelectCoordinatesRelatedDataDirectory_CreateFcn(hObject, eventdata, handles) %#ok<INUSD>
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function pushbuttonOK_Callback(hObject, eventdata, handles) %#ok<INUSL>
if nargin < 3 || isempty(handles)
    handles = guidata(hObject);
end
try
    outDir = strtrim(get(handles.editSelectOutputDirectory, 'String'));
    fcRelatedDir = strtrim(get(handles.editSelectFCRelatedDataDirectory, 'String'));
    roiText = strtrim(get(handles.editEnterROIIndices, 'String'));
    coordRelatedDir = strtrim(get(handles.editSelectCoordinatesRelatedDataDirectory, 'String'));

    if isempty(outDir)
        error('Please select an output directory.');
    end
    if exist(outDir, 'dir') ~= 7
        mkdir(outDir);
    end
    if ~isempty(fcRelatedDir) && exist(fcRelatedDir, 'dir') ~= 7
        error('FC related data directory does not exist: %s', fcRelatedDir);
    end
    if isempty(fcRelatedDir) && isempty(coordRelatedDir)
        error('Please select at least an FC related data directory or a coordinates related data directory.');
    end
    roiIndices = SFC_parseROIIndices(roiText);

    fprintf('\n============================================================\n');
    fprintf('[SFC Toolbox] Data preparation started\n');
    fprintf('Output directory: %s\n', outDir);
    if isempty(fcRelatedDir)
        fprintf('FC related directory: Not selected\n');
    else
        fprintf('FC related directory: %s\n', fcRelatedDir);
    end
    if isempty(coordRelatedDir)
        fprintf('Coordinates related directory: Not selected\n');
    else
        fprintf('Coordinates related directory: %s\n', coordRelatedDir);
    end
    if isempty(roiIndices)
        fprintf('ROI indices: All available ROIs will be preserved.\n');
    else
        fprintf('ROI index count: %d\n', numel(roiIndices));
    end
    fprintf('============================================================\n');

    report = SFC_prepareData(outDir, fcRelatedDir, roiIndices, coordRelatedDir);

    result = struct;
    result.OutputDirectory = outDir;
    result.FCRelatedDataDirectory = fcRelatedDir;
    result.ROIIndicesText = roiText;
    result.ROIIndices = roiIndices;
    result.CoordinatesRelatedDataDirectory = coordRelatedDir;
    result.Report = report;

    handles.output = result;
    guidata(hObject, handles);
    msgbox({'Data preparation completed successfully.'; ...
            ['Output directory: ', outDir]}, 'Data Prepare Complete');
    uiresume(handles.figure1);
catch ME
    fprintf('\n==================== DATA PREPARE ERROR ====================\n');
    fprintf('%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    fprintf('============================================================\n\n');
    errordlg({ME.message; 'Please check the Command Window for details.'}, 'Data Prepare Failed');
end
end

function pushbuttonCancel_Callback(hObject, eventdata, handles) %#ok<INUSD>
if nargin < 3 || isempty(handles)
    handles = guidata(hObject);
end
handles.output = [];
guidata(hObject, handles);
uiresume(handles.figure1);
end

function roiIndices = SFC_parseROIIndices(txt)
% Empty ROI Indices means keeping all available ROIs.
if isempty(strtrim(txt))
    roiIndices = [];
    return;
end
roiIndices = str2num(txt); %#ok<ST2NM>
if isempty(roiIndices) || ~isnumeric(roiIndices)
    error('Unable to parse ROI Indices. Please enter a numeric vector, for example: 1:454 or [1 5 9].');
end
roiIndices = roiIndices(:)';
if any(~isfinite(roiIndices)) || any(roiIndices < 1) || any(mod(roiIndices, 1) ~= 0)
    error('ROI Indices must be positive integer values.');
end
roiIndices = unique(roiIndices, 'stable');
end

function report = SFC_prepareData(outDir, fcRelatedDir, roiIndices, coordRelatedDir)
fcOutDir = fullfile(outDir, 'FC');
roiOutDir = fullfile(outDir, 'ROISignals');
coordOutDir = fullfile(outDir, 'Coordinates');
perSubCoordOutDir = fullfile(coordOutDir, 'PerSubjects');

hasFCRelated = ~isempty(strtrim(fcRelatedDir));
hasCoordRelated = ~isempty(strtrim(coordRelatedDir));

if ~hasFCRelated && ~hasCoordRelated
    error('Please select at least an FC related data directory or a coordinates related data directory.');
end

if hasFCRelated && exist(fcRelatedDir, 'dir') ~= 7
    error('FC related data directory does not exist: %s', fcRelatedDir);
end

if hasCoordRelated && exist(coordRelatedDir, 'dir') ~= 7
    error('Coordinates related data directory does not exist: %s', coordRelatedDir);
end

report = struct;
report.FCFilesWritten = {};
report.ROISignalsFilesWritten = {};
report.CommonCoordinateFile = '';
report.PerSubjectCoordinateFilesWritten = {};
report.ROIIndices = roiIndices;
report.KeepAllROIs = isempty(roiIndices);

if isempty(roiIndices)
    fprintf('ROI Indices: empty input. All available ROIs will be preserved.\n');
else
    fprintf('ROI Indices: %d selected ROIs.\n', numel(roiIndices));
end

%% FC matrices and optional ROISignals/common coordinates
if hasFCRelated
    if ~exist(fcOutDir, 'dir')
        mkdir(fcOutDir);
    end

    % FC matrices are required when an FC related data directory is provided.
    fcFiles = SFC_findROICorrelationFiles(fcRelatedDir);
    if isempty(fcFiles)
        error('No ROICorrelation*.mat or ROICorrelation_FisherZ*.mat files were found. FC related data are required when an FC related data directory is selected.');
    end

    for iFile = 1:numel(fcFiles)
        inFile = fcFiles{iFile};
        mat = SFC_loadFirstNumericMatrix(inFile);
        fcMat = SFC_extractSquareMatrixByROI(mat, roiIndices, inFile);
        fcMat = (fcMat + fcMat') ./ 2;

        [~, baseName, ~] = fileparts(inFile);
        outFile = fullfile(fcOutDir, [baseName, '.mat']);
        NetworkMatrix = fcMat; %#ok<NASGU>
        FCMatrix = fcMat; %#ok<NASGU>
        save(outFile, 'NetworkMatrix', 'FCMatrix');
        report.FCFilesWritten{end+1,1} = outFile; %#ok<AGROW>
        fprintf('FC saved: %s\n', outFile);
    end

    % ROISignals are optional.
    roiSignalFiles = dir(fullfile(fcRelatedDir, 'ROISignals*.mat'));
    roiSignalFiles = roiSignalFiles(~[roiSignalFiles.isdir]);
    if ~isempty(roiSignalFiles)
        if ~exist(roiOutDir, 'dir'), mkdir(roiOutDir); end
        for iFile = 1:numel(roiSignalFiles)
            inFile = fullfile(fcRelatedDir, roiSignalFiles(iFile).name);
            ts = SFC_loadFirstNumericMatrix(inFile);
            roi_ts = SFC_extractROISignalsByROI(ts, roiIndices, inFile);
            [~, baseName, ~] = fileparts(inFile);
            outFile = fullfile(roiOutDir, [baseName, '.mat']);
            ROISignals = roi_ts; %#ok<NASGU>
            save(outFile, 'ROISignals');
            report.ROISignalsFilesWritten{end+1,1} = outFile; %#ok<AGROW>
            fprintf('ROISignals saved: %s\n', outFile);
        end
    else
        fprintf('ROISignals*.mat not found. Skipped ROISignals preparation.\n');
    end

    % Common coordinate file is optional.
    commonCoordFile = fullfile(fcRelatedDir, 'ROI_CenterOfMass.mat');
    if exist(commonCoordFile, 'file') == 2
        if ~exist(coordOutDir, 'dir')
            mkdir(coordOutDir);
        end

        coordMatAll = SFC_loadFirstNumericMatrix(commonCoordFile);
        CoordinateMatrix = SFC_extractCoordinateMatrixByROI(coordMatAll, roiIndices, commonCoordFile); %#ok<NASGU>
        outFile = fullfile(coordOutDir, 'ROI_CenterOfMass.mat');
        save(outFile, 'CoordinateMatrix');
        report.CommonCoordinateFile = outFile;
        fprintf('Common coordinates saved: %s\n', outFile);
    else
        fprintf('ROI_CenterOfMass.mat not found. Skipped common coordinate preparation.\n');
    end
else
    fprintf('FC related data directory was not selected. FC, ROISignals, and common coordinates were skipped.\n');
end

%% Per-subject coordinates from subject-specific coordinate matrices or atlas files
if hasCoordRelated
    coordFiles = SFC_findCoordinateAtlasFiles(coordRelatedDir);
    if isempty(coordFiles)
        fprintf('No coordinate-related files were found. Skipped per-subject coordinates.\n');
    else
        if ~exist(coordOutDir, 'dir')
            mkdir(coordOutDir);
        end
        if ~exist(perSubCoordOutDir, 'dir')
            mkdir(perSubCoordOutDir);
        end

        for iFile = 1:numel(coordFiles)
            inFile = coordFiles{iFile};
            [~, baseName, ext] = fileparts(inFile);
            subjectID = SFC_extractSubjectID(baseName);
            if isempty(subjectID)
                subjectID = baseName;
            end
            outFile = fullfile(perSubCoordOutDir, [subjectID, '_center.mat']);

            try
                if strcmpi(ext, '.mat')
                    coordMatAll = SFC_loadFirstNumericMatrix(inFile);
                    CoordinateMatrix = SFC_extractCoordinateMatrixByROI(coordMatAll, roiIndices, inFile); %#ok<NASGU>
                    save(outFile, 'CoordinateMatrix');
                else
                    if exist('y_ExtractROICenterOfMass', 'file') ~= 2
                        warning('y_ExtractROICenterOfMass was not found on the MATLAB path. Skipped atlas coordinate file: %s', inFile);
                        continue;
                    end
                    [MaskROI, ~, ~, Header] = y_ReadAll(inFile);
                    if ndims(MaskROI) == 4
                        MaskROI = MaskROI(:,:,:,1);
                    end
                    ROIDef = {MaskROI};
                    roiSelectedIndex = SFC_getAtlasROISelectedIndex(MaskROI, roiIndices);
                    [~, XYZCenter, ~] = y_ExtractROICenterOfMass( ...
                        ROIDef, outFile, 1, {roiSelectedIndex}, MaskROI, Header);
                    if size(XYZCenter, 2) < 3
                        error('The extracted coordinate matrix has fewer than 3 columns.');
                    end
                    CoordinateMatrix = XYZCenter(:, 1:3); %#ok<NASGU>
                    save(outFile, 'CoordinateMatrix');
                end
                report.PerSubjectCoordinateFilesWritten{end+1,1} = outFile; %#ok<AGROW>
                fprintf('Per-subject coordinates saved: %s\n', outFile);
            catch ME
                warning('Failed to extract per-subject coordinates from %s: %s', inFile, ME.message);
            end
        end
    end
end

fprintf('============================================================\n');
fprintf('[SFC Toolbox] Data preparation completed\n');
fprintf('FC files written: %d\n', numel(report.FCFilesWritten));
fprintf('ROISignals files written: %d\n', numel(report.ROISignalsFilesWritten));
fprintf('Per-subject coordinate files written: %d\n', numel(report.PerSubjectCoordinateFilesWritten));
fprintf('============================================================\n\n');
end

function fcMat = SFC_extractSquareMatrixByROI(mat, roiIndices, fileName)
if ndims(mat) ~= 2 || size(mat, 1) ~= size(mat, 2)
    error('FC matrix must be a square numeric matrix: %s', fileName);
end
if isempty(roiIndices)
    fcMat = mat;
else
    maxROI = max(roiIndices);
    if size(mat, 1) < maxROI || size(mat, 2) < maxROI
        error('ROI index exceeds matrix dimensions in file: %s', fileName);
    end
    fcMat = mat(roiIndices, roiIndices);
end
end

function roi_ts = SFC_extractROISignalsByROI(ts, roiIndices, fileName)
if isempty(roiIndices)
    roi_ts = ts;
    return;
end
maxROI = max(roiIndices);
if size(ts, 2) >= maxROI
    roi_ts = ts(:, roiIndices);
elseif size(ts, 1) >= maxROI
    roi_ts = ts(roiIndices, :)';
else
    error('ROI index exceeds ROISignals dimensions in file: %s', fileName);
end
end

function CoordinateMatrix = SFC_extractCoordinateMatrixByROI(coordMatAll, roiIndices, fileName)
if size(coordMatAll, 2) < 3
    error('Coordinate matrix must contain at least 3 columns: %s', fileName);
end
if isempty(roiIndices)
    CoordinateMatrix = coordMatAll(:, 1:3);
else
    maxROI = max(roiIndices);
    if size(coordMatAll, 1) < maxROI
        error('ROI index exceeds coordinate matrix rows in file: %s', fileName);
    end
    CoordinateMatrix = coordMatAll(roiIndices, 1:3);
end
end

function roiSelectedIndex = SFC_getAtlasROISelectedIndex(MaskROI, roiIndices)
if isempty(roiIndices)
    labels = unique(double(MaskROI(:)));
    labels = labels(isfinite(labels) & labels > 0);
    roiSelectedIndex = labels(:)';
else
    roiSelectedIndex = 1:numel(roiIndices);
end
if isempty(roiSelectedIndex)
    error('No nonzero ROI label was found in the coordinate atlas file.');
end
end

function fcFiles = SFC_findROICorrelationFiles(inputDir)
fz = dir(fullfile(inputDir, 'ROICorrelation_FisherZ*.mat'));
fz = fz(~[fz.isdir]);
raw = dir(fullfile(inputDir, 'ROICorrelation*.mat'));
raw = raw(~[raw.isdir]);
raw = raw(~contains({raw.name}, 'FisherZ', 'IgnoreCase', true));

fileMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
% Add raw first, then FisherZ overwrites the same subject key.
for i = 1:numel(raw)
    f = fullfile(inputDir, raw(i).name);
    key = SFC_extractSubjectID(raw(i).name);
    if isempty(key), key = raw(i).name; end
    fileMap(lower(key)) = f;
end
for i = 1:numel(fz)
    f = fullfile(inputDir, fz(i).name);
    key = SFC_extractSubjectID(fz(i).name);
    if isempty(key), key = fz(i).name; end
    fileMap(lower(key)) = f;
end
keysList = sort(fileMap.keys);
fcFiles = cell(numel(keysList), 1);
for i = 1:numel(keysList)
    fcFiles{i} = fileMap(keysList{i});
end
end

function id = SFC_extractSubjectID(fileName)
[~, baseName, ~] = fileparts(fileName);
token = regexp(baseName, '(sub|Sub|SUB)[^_\.]*', 'match', 'once');
if isempty(token)
    token = regexp(baseName, '(sub|Sub|SUB).+$', 'match', 'once');
end
id = token;
end

function mat = SFC_loadFirstNumericMatrix(filePath)
data = load(filePath);
fields = fieldnames(data);
mat = [];
for i = 1:numel(fields)
    value = data.(fields{i});
    if isnumeric(value) && ismatrix(value)
        mat = value;
        return;
    end
end
error('No numeric matrix variable was found in file: %s', filePath);
end

function files = SFC_findCoordinateAtlasFiles(inputDir)
patterns = {'*.nii', '*.nii.gz', '*.img', '*.gii', '*.mat'};
files = {};
for p = 1:numel(patterns)
    thisList = dir(fullfile(inputDir, patterns{p}));
    thisList = thisList(~[thisList.isdir]);
    for i = 1:numel(thisList)
        name = thisList(i).name;
        if contains(name, 'ROI_CenterOfMass', 'IgnoreCase', true)
            continue;
        end
        if contains(name, 'ROICorrelation', 'IgnoreCase', true) || contains(name, 'ROISignals', 'IgnoreCase', true)
            continue;
        end
        files{end+1,1} = fullfile(inputDir, name); %#ok<AGROW>
    end
end
end
