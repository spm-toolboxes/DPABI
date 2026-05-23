classdef dpabi_Gradient_AddImage_Template < matlab.apps.AppBase
    % This file is a paste-ready template for the Add image logic in App Designer.
    % Copy the relevant properties and methods into dpabi_Gradient.mlapp.

    properties (Access = public)
        UIFigure matlab.ui.Figure
        AddimageButton matlab.ui.control.Button
    end

    properties (Access = private)
        FileList cell = {}
        Data
        VoxelSize = []
        Header
    end

    methods (Access = private)
        function AddimageButtonPushed(app, event)
            choice = uiconfirm(app.UIFigure, ...
                sprintf(['Choose how to import data:\n\n' ...
                'Single/Multiple Files: pick one or more files.\n' ...
                'Folder: import all supported files from a directory.']), ...
                'Add Image', ...
                'Options', {'Files', 'Folder', 'Cancel'}, ...
                'DefaultOption', 1, ...
                'CancelOption', 3);

            switch choice
                case 'Files'
                    [fileName, filePath] = uigetfile( ...
                        {'*.img;*.nii;*.nii.gz;*.gii;*.mat;*.xlsx;*.csv;*.tsv;*.txt', ...
                        'Supported files (*.img;*.nii;*.nii.gz;*.gii;*.mat;*.xlsx;*.csv;*.tsv;*.txt)'; ...
                        '*.*', 'All Files (*.*)'}, ...
                        'Select input file(s)', pwd, 'MultiSelect', 'on');
                    if isnumeric(fileName)
                        return;
                    end

                    if iscell(fileName)
                        InputName = fullfile(filePath, fileName);
                        if ischar(InputName)
                            InputName = cellstr(InputName);
                        end
                    else
                        InputName = fullfile(filePath, fileName);
                    end

                case 'Folder'
                    folderPath = uigetdir(pwd, 'Select input folder');
                    if isnumeric(folderPath)
                        return;
                    end
                    InputName = folderPath;

                otherwise
                    return;
            end

            try
                [Data, VoxelSize, FileList, Header] = yw_ReadAll(InputName);

                app.Data = Data;
                app.VoxelSize = VoxelSize;
                app.FileList = FileList;
                app.Header = Header;

                msg = sprintf('Loaded %d file(s).', numel(FileList));
                if ~isempty(VoxelSize)
                    msg = sprintf('%s VoxelSize = [%s].', msg, num2str(VoxelSize));
                end
                uialert(app.UIFigure, msg, 'Import Succeeded', 'Icon', 'success');

                % If you later add a ListBox/TextArea, update it here.
                % Example:
                % app.FileListBox.Items = FileList;

            catch ME
                uialert(app.UIFigure, ME.message, 'Import Failed', 'Icon', 'error');
            end
        end
    end
end
