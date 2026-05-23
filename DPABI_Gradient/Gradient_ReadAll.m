function [Data, VoxelSize, FileList, Header] = Gradient_ReadAll(InputName)
% Gradient_ReadAll
% Read .nii/.nii.gz/.gii/.mat/.xlsx/.csv/.tsv/.txt files.

VoxelSize = [];
Header = struct();

if iscell(InputName)
    if size(InputName,1) == 1
        InputName = InputName';
    end
    FileList = InputName;

elseif exist(InputName, 'dir') == 7
    DirImg = dir(fullfile(InputName, '*.img'));
    if isempty(DirImg), DirImg = dir(fullfile(InputName, '*.nii.gz')); end
    if isempty(DirImg), DirImg = dir(fullfile(InputName, '*.nii')); end
    if isempty(DirImg), DirImg = dir(fullfile(InputName, '*.gii')); end
    if isempty(DirImg), DirImg = dir(fullfile(InputName, '*.mat')); end
    if isempty(DirImg), DirImg = dir(fullfile(InputName, '*.csv')); end
    if isempty(DirImg), DirImg = dir(fullfile(InputName, '*.xlsx')); end
    if isempty(DirImg), DirImg = dir(fullfile(InputName, '*.txt')); end
    if isempty(DirImg), DirImg = dir(fullfile(InputName, '*.tsv')); end

    FileList = cell(numel(DirImg), 1);
    for j = 1:numel(DirImg)
        FileList{j,1} = fullfile(InputName, DirImg(j).name);
    end

elseif exist(InputName, 'file') == 2
    FileList = {InputName};

else
    error('The input name is not supported: %s', InputName);
end

if isempty(FileList)
    error('No supported file is found.');
end

fprintf('\nReading data from "%s" etc.\n', FileList{1});

if numel(FileList) == 1
    [~, ~, Ext] = local_fileparts_gz(FileList{1});

    if strcmpi(Ext, '.gii')
        Header = gifti(FileList{1});
        Data = Header.cdata;

    elseif strcmpi(Ext, '.mat')
        S = load(FileList{1});
        VarNames = fieldnames(S);
        Data = [];
        for i = 1:numel(VarNames)
            if isnumeric(S.(VarNames{i}))
                Data = S.(VarNames{i});
                Header.SelectedVariable = VarNames{i};
                break;
            end
        end
        if isempty(Data)
            error('No numeric variable found in MAT file.');
        end

    elseif strcmpi(Ext, '.nii')
        if exist('y_ReadRPI', 'file') == 2
            [Data, VoxelSize, Header] = y_ReadRPI(FileList{1});
        elseif exist('niftiread', 'file') == 2
            Data = niftiread(FileList{1});
            Header = niftiinfo(FileList{1});
            VoxelSize = Header.PixelDimensions;
        else
            error('No NIfTI reader found.');
        end

    else
        T = readtable(FileList{1}, 'ReadVariableNames', 'auto');
        Header.name = T.Properties.VariableNames;
        Header.tablesize = size(T);
        Data = table2array(T);
        Data = Data(:);
    end

else
    [~, ~, Ext] = local_fileparts_gz(FileList{1});

    if strcmpi(Ext, '.gii')
        G = gifti(FileList{1});
        Data = zeros(size(G.cdata,1), numel(FileList));
        Data(:,1) = G.cdata(:);
        Header = G;

        for j = 2:numel(FileList)
            Gtemp = gifti(FileList{j});
            Data(:,j) = Gtemp.cdata(:);
        end

    elseif strcmpi(Ext, '.mat')
        S = load(FileList{1});
        VarNames = fieldnames(S);
        Data0 = [];
        for i = 1:numel(VarNames)
            if isnumeric(S.(VarNames{i}))
                Data0 = S.(VarNames{i});
                Header.SelectedVariable = VarNames{i};
                break;
            end
        end
        if isempty(Data0)
            error('No numeric variable found in MAT file.');
        end

        Data = zeros(numel(Data0), numel(FileList));
        Data(:,1) = Data0(:);

        for j = 2:numel(FileList)
            S = load(FileList{j});
            VarNames = fieldnames(S);
            DataTemp = [];
            for i = 1:numel(VarNames)
                if isnumeric(S.(VarNames{i}))
                    DataTemp = S.(VarNames{i});
                    break;
                end
            end
            if isempty(DataTemp)
                error('No numeric variable found in MAT file: %s', FileList{j});
            end
            Data(:,j) = DataTemp(:);
        end

    elseif strcmpi(Ext, '.nii')
        if exist('y_ReadRPI', 'file') == 2
            [Data0, VoxelSize, Header] = y_ReadRPI(FileList{1});
        elseif exist('niftiread', 'file') == 2
            Data0 = niftiread(FileList{1});
            Header = niftiinfo(FileList{1});
            VoxelSize = Header.PixelDimensions;
        else
            error('No NIfTI reader found.');
        end

        Data = zeros([size(Data0), numel(FileList)], class(Data0));
        Data(:,:,:,1) = Data0;

        for j = 2:numel(FileList)
            if exist('y_ReadRPI', 'file') == 2
                DataTemp = y_ReadRPI(FileList{j});
            else
                DataTemp = niftiread(FileList{j});
            end
            Data(:,:,:,j) = DataTemp;
        end

    else
        Data = cell(1, numel(FileList));
        Header = struct('name', {}, 'tablesize', {});

        for j = 1:numel(FileList)
            T = readtable(FileList{j}, 'ReadVariableNames', 'auto');
            Header(j).name = T.Properties.VariableNames;
            Header(j).tablesize = size(T);
            Data{j} = table2array(T);
            Data{j} = Data{j}(:);
        end

        Data = cell2mat(Data);
    end
end


function [Path, Name, Ext] = local_fileparts_gz(FileName)
[Path, Name, Ext] = fileparts(FileName);
if strcmpi(Ext, '.gz')
    [Path2, Name2, Ext2] = fileparts(fullfile(Path, Name));
    Path = Path2;
    Name = Name2;
    Ext = Ext2;
end
