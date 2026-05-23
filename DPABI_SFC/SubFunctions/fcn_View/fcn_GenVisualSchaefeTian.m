function fcn_GenVisualSchaefeTian(Data, OutDir, Prefix, Mode)
% fcn_GenVisualSchaefeTian: Visualization mapping for Schaefer-Tian parcellations.
% -------------------------------------------------------------------------------------------
% Used to demonstrate the usage of the function fcn_GenVisualSchaeferTian.
% This function maps nodal value vectors onto brain templates (Surface/Volume).
%
% INPUTS:
%    Data    - [N X 1] Numeric vector. 
%              Required length: 454 for combined modes, 400 for cortical, 54 for subcortical.
%    OutDir  - String. Target directory for saving output image files.
%    Prefix  - String. Custom prefix for output filenames (e.g., 'view_DataName').
%    Mode    - Integer (1-5). Visualization mode:
%              1: Volume 400 (Cortex) + Volume 54 (Subcortex)
%              2: Surface 400 (Cortex) + Volume 54 (Subcortex)
%              3: Surface 400 Only (Cortex)
%              4: Volume 54 Only (Subcortex)
%              5: Volume 400 Only (Cortex)
%
% OUTPUTS:
%    Saves brain maps with full descriptive suffixes:
%    - Surface: _SurfLh.gii, _SurfRh.gii
%    - Volume:  _Volume.nii (Cortex), _Subcortical.nii (Subcortex)
% -------------------------------------------------------------------------------------------

    % --- Data Dimension Validation ---
    dataLen = length(Data);
    if (ismember(Mode, [1, 2, 3, 5]) && dataLen < 400)
        error('Input Error: Data length (%d) is insufficient for Cortical mapping (min 400).', dataLen);
    elseif (ismember(Mode, [1, 2]) && dataLen < 454)
        error('Input Error: Data length (%d) is insufficient for Combined mapping (min 454).', dataLen);
    elseif (Mode == 4 && dataLen < 54)
        error('Input Error: Data length (%d) is insufficient for Subcortical mapping (min 54).', dataLen);
    end

    % --- Locate Templates via DPABI Path ---
    dpabiPath = which('dpabi.m'); %
    if isempty(dpabiPath), error('DPABI not found.'); end
    [dpabiRoot, ~, ~] = fileparts(dpabiPath);
    surfDir = fullfile(dpabiRoot, 'DPABISurf', 'SurfTemplates');
    volDir = fullfile(dpabiRoot, 'Templates');

    % --- 1 & 2. Surface Mapping (Schaefer 400) ---
    if Mode == 2 || Mode == 3
        [TempL, ~, ~, ~] = y_ReadAll(fullfile(surfDir, 'fsaverage5_lh_Schaefer2018_400Parcels_7Networks_order.label.gii'));
        [TempR, ~, ~, ~] = y_ReadAll(fullfile(surfDir, 'fsaverage5_rh_Schaefer2018_400Parcels_7Networks_order.label.gii'));
        DataL = zeros(length(TempL),1); DataR = zeros(length(TempR),1);
        idxL = find(TempL ~= 0); DataL(idxL) = Data(TempL(idxL));
        idxR = find(TempR ~= 0); DataR(idxR) = Data(TempR(idxR)+200);
        y_Write(DataL, gifti(DataL), fullfile(OutDir, [Prefix, '_SurfLh.gii']));
        y_Write(DataR, gifti(DataR), fullfile(OutDir, [Prefix, '_SurfRh.gii']));
    end

    % --- 3. Volume Subcortex Mapping (Tian 54) ---
    if ismember(Mode, [1, 2, 4])
        [TempT, ~, ~, HeaderT] = y_ReadAll(fullfile(volDir, 'Tian2020_Subcortex_Atlas', 'Tian_Subcortex_S4_3T_1mm.nii'));
        DataT = zeros(size(TempT));
        idxT = find(TempT ~= 0);
        if Mode == 4 && dataLen < 400, DataT(idxT) = Data(TempT(idxT));
        else, DataT(idxT) = Data(TempT(idxT)+400); end
        y_Write(DataT, HeaderT, fullfile(OutDir, [Prefix, '_Subcortical.nii']));
    end

    % --- 4. Volume Cortex Mapping (Schaefer 400) ---
    if Mode == 1 || Mode == 5
        [TempS, ~, ~, HeaderS] = y_ReadAll(fullfile(volDir, 'Schaefer2018_400Parcels_7Networks_order_FSLMNI152_1mm.nii'));
        DataS = zeros(size(TempS));
        idxS = find(TempS ~= 0); DataS(idxS) = Data(TempS(idxS));
        y_Write(DataS, HeaderS, fullfile(OutDir, [Prefix, '_Cortical.nii']));
    end
end