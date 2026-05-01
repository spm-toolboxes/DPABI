function Cfg = y_Organize_SegmentSubregions(Cfg,WorkingDir,SubjectListFile,IsSlurmOrganizeSurf)
% function Cfg = y_Organize_SegmentSubregions(Cfg,WorkingDir,SubjectListFile,IsSlurmOrganizeSurf)
% Organize results by Segment Subregions.
%   Input:
%   Cfg - the parameters for auto data processing. 
%   WorkingDir - Define the working directory to replace the one defined in Cfg
%   SubjectListFile - Define the subject list to replace the one defined in Cfg. Should be a text file
%   IsSlurmOrganizeSurf - Surf files have been organized by Slurm, thus no need to use parallel
%   Output:
%     see Results/AnatVolu/Anat_Segment_Subregions_Volume.csv and related files.
%___________________________________________________________________________
% Written by YAN Chao-Gan 230214.
% The R-fMRI Lab, Institute of Psychology, Chinese Academy of Sciences, Beijing, China
% International Big-Data Center for Depression Research, Institute of Psychology, Chinese Academy of Sciences, Beijing, China
% ycg.yan@gmail.com


if ischar(Cfg)  %If inputed a .mat file name. (Cfg inside)
    load(Cfg);
end

if exist('WorkingDir','var') && ~isempty(WorkingDir)
    Cfg.WorkingDir=WorkingDir;
end

if exist('SubjectListFile','var') && ~isempty(SubjectListFile)
    fid = fopen(SubjectListFile);
    IDCell = textscan(fid,'%s\n'); %YAN Chao-Gan. For compatiblity of MALLAB 2014b. IDCell = textscan(fid,'%s','\n');
    fclose(fid);
    Cfg.SubjectID=IDCell{1};
end

IsNeedOrganizeSurfWithParallel = 1;
if exist('IsSlurmOrganizeSurf','var') && (~isempty(IsSlurmOrganizeSurf)) && (IsSlurmOrganizeSurf ~= 0)
    IsNeedOrganizeSurfWithParallel=0;
end

[DPABIPath, fileN, extn] = fileparts(which('DPABI.m'));

Cfg.SubjectNum=length(Cfg.SubjectID);
FreeSurferSubjectID = local_get_freesurfer_subject_ids(Cfg);
Cfg.FreeSurferSubjectID = FreeSurferSubjectID;
SubjectIDString=[];
FreeSurferSubjectIDString=[];
for i=1:Cfg.SubjectNum
    SubjectIDString = sprintf('%s %s',SubjectIDString,Cfg.SubjectID{i});
    FreeSurferSubjectIDString = sprintf('%s %s',FreeSurferSubjectIDString,FreeSurferSubjectID{i});
end
LinkedFreeSurferAndSubjectIDString = sprintf('::: %s :::+ %s', FreeSurferSubjectIDString, SubjectIDString);

if ispc
    CommandInit=sprintf('docker run -i --rm -v %s:/opt/freesurfer/license.txt -v %s:/data -e SUBJECTS_DIR=/data/freesurfer cgyan/dpabi', fullfile(DPABIPath, 'DPABISurf', 'FreeSurferLicense', 'license.txt'), Cfg.WorkingDir); %YAN Chao-Gan, 181214. Remove -t because there is a tty issue in windows
else
    CommandInit=sprintf('docker run -ti --rm -v %s:/opt/freesurfer/license.txt -v %s:/data -e SUBJECTS_DIR=/data/freesurfer cgyan/dpabi', fullfile(DPABIPath, 'DPABISurf', 'FreeSurferLicense', 'license.txt'), Cfg.WorkingDir); 
end
if isdeployed && (isunix && (~ismac)) % If running within docker with compiled version
    CommandInit=sprintf('export SUBJECTS_DIR=%s/freesurfer && ', Cfg.WorkingDir);
    WorkingDir=Cfg.WorkingDir;
else
    WorkingDir='/data';
end



%Write table
SegTable=[];
for i=1:Cfg.SubjectNum

    SubjectID={Cfg.SubjectID{i}};
    OneSub=table(SubjectID);

    SegVolume=readtable(fullfile(Cfg.WorkingDir,'freesurfer',FreeSurferSubjectID{i},'mri','lh.hippoSfVolumes.txt'),'ReadRowNames',true);
    SegVolume=rows2vars(SegVolume);
    SegVolume=removevars(SegVolume,'OriginalVariableNames');
    VarName=SegVolume.Properties.VariableNames;
    VarName = append('Left-',VarName);
    SegVolume=renamevars(SegVolume,1:width(SegVolume),VarName);
    SegVolume.SubjectID={Cfg.SubjectID{i}};
    OneSub=join(OneSub,SegVolume);

    SegVolume=readtable(fullfile(Cfg.WorkingDir,'freesurfer',FreeSurferSubjectID{i},'mri','rh.hippoSfVolumes.txt'),'ReadRowNames',true);
    SegVolume=rows2vars(SegVolume);
    SegVolume=removevars(SegVolume,'OriginalVariableNames');
    VarName=SegVolume.Properties.VariableNames;
    VarName = append('Right-',VarName);
    SegVolume=renamevars(SegVolume,1:width(SegVolume),VarName);
    SegVolume.SubjectID={Cfg.SubjectID{i}};
    OneSub=join(OneSub,SegVolume);

    SegVolume=readtable(fullfile(Cfg.WorkingDir,'freesurfer',FreeSurferSubjectID{i},'mri','lh.amygNucVolumes.txt'),'ReadRowNames',true);
    SegVolume=rows2vars(SegVolume);
    SegVolume=removevars(SegVolume,'OriginalVariableNames');
    VarName=SegVolume.Properties.VariableNames;
    VarName = append('Left-',VarName);
    SegVolume=renamevars(SegVolume,1:width(SegVolume),VarName);
    SegVolume.SubjectID={Cfg.SubjectID{i}};
    OneSub=join(OneSub,SegVolume);

    SegVolume=readtable(fullfile(Cfg.WorkingDir,'freesurfer',FreeSurferSubjectID{i},'mri','rh.amygNucVolumes.txt'),'ReadRowNames',true);
    SegVolume=rows2vars(SegVolume);
    SegVolume=removevars(SegVolume,'OriginalVariableNames');
    VarName=SegVolume.Properties.VariableNames;
    VarName = append('Right-',VarName);
    SegVolume=renamevars(SegVolume,1:width(SegVolume),VarName);
    SegVolume.SubjectID={Cfg.SubjectID{i}};
    OneSub=join(OneSub,SegVolume);

    SegVolume=readtable(fullfile(Cfg.WorkingDir,'freesurfer',FreeSurferSubjectID{i},'mri','ThalamicNuclei.volumes.txt'),'ReadRowNames',true);
    SegVolume=rows2vars(SegVolume);
    SegVolume=removevars(SegVolume,'OriginalVariableNames');
    SegVolume.SubjectID={Cfg.SubjectID{i}};
    OneSub=join(OneSub,SegVolume);

    SegVolume=readtable(fullfile(Cfg.WorkingDir,'freesurfer',FreeSurferSubjectID{i},'mri','brainstemSsLabels.volumes.txt'),'ReadRowNames',true);
    SegVolume=rows2vars(SegVolume);
    SegVolume=removevars(SegVolume,'OriginalVariableNames');
    SegVolume.SubjectID={Cfg.SubjectID{i}};
    OneSub=join(OneSub,SegVolume);

    SegTable=[SegTable;OneSub];
end

writetable(SegTable,fullfile(Cfg.WorkingDir,'Results','AnatVolu','Anat_Segment_Subregions_Volume.csv'),'Delimiter','\t');


if IsNeedOrganizeSurfWithParallel
    %Convert to .nii
    Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/lh.hippoAmygLabels.CA.FSvoxelSpace.mgz %s/Results/AnatVolu/T1wSpace/{2}/{2}_Subregions_lh.hippoAmygLabels.CA.FSvoxelSpace.nii.gz %s', ...
        CommandInit, Cfg.ParallelWorkersNumber, WorkingDir,WorkingDir,LinkedFreeSurferAndSubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/lh.hippoAmygLabels.FS60.FSvoxelSpace.mgz %s/Results/AnatVolu/T1wSpace/{2}/{2}_Subregions_lh.hippoAmygLabels.FS60.FSvoxelSpace.nii.gz %s', ...
        CommandInit, Cfg.ParallelWorkersNumber, WorkingDir,WorkingDir,LinkedFreeSurferAndSubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/lh.hippoAmygLabels.HBT.FSvoxelSpace.mgz %s/Results/AnatVolu/T1wSpace/{2}/{2}_Subregions_lh.hippoAmygLabels.HBT.FSvoxelSpace.nii.gz %s', ...
        CommandInit, Cfg.ParallelWorkersNumber, WorkingDir,WorkingDir,LinkedFreeSurferAndSubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/lh.hippoAmygLabels.FSvoxelSpace.mgz %s/Results/AnatVolu/T1wSpace/{2}/{2}_Subregions_lh.hippoAmygLabels.FSvoxelSpace.nii.gz %s', ...
        CommandInit, Cfg.ParallelWorkersNumber, WorkingDir,WorkingDir,LinkedFreeSurferAndSubjectIDString);
    system(Command);

    Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/rh.hippoAmygLabels.CA.FSvoxelSpace.mgz %s/Results/AnatVolu/T1wSpace/{2}/{2}_Subregions_rh.hippoAmygLabels.CA.FSvoxelSpace.nii.gz %s', ...
        CommandInit, Cfg.ParallelWorkersNumber, WorkingDir,WorkingDir,LinkedFreeSurferAndSubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/rh.hippoAmygLabels.FS60.FSvoxelSpace.mgz %s/Results/AnatVolu/T1wSpace/{2}/{2}_Subregions_rh.hippoAmygLabels.FS60.FSvoxelSpace.nii.gz %s', ...
        CommandInit, Cfg.ParallelWorkersNumber, WorkingDir,WorkingDir,LinkedFreeSurferAndSubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/rh.hippoAmygLabels.HBT.FSvoxelSpace.mgz %s/Results/AnatVolu/T1wSpace/{2}/{2}_Subregions_rh.hippoAmygLabels.HBT.FSvoxelSpace.nii.gz %s', ...
        CommandInit, Cfg.ParallelWorkersNumber, WorkingDir,WorkingDir,LinkedFreeSurferAndSubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/rh.hippoAmygLabels.FSvoxelSpace.mgz %s/Results/AnatVolu/T1wSpace/{2}/{2}_Subregions_rh.hippoAmygLabels.FSvoxelSpace.nii.gz %s', ...
        CommandInit, Cfg.ParallelWorkersNumber, WorkingDir,WorkingDir,LinkedFreeSurferAndSubjectIDString);
    system(Command);

    Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/ThalamicNuclei.FSvoxelSpace.mgz %s/Results/AnatVolu/T1wSpace/{2}/{2}_Subregions_ThalamicNuclei.FSvoxelSpace.nii.gz %s', ...
        CommandInit, Cfg.ParallelWorkersNumber, WorkingDir,WorkingDir,LinkedFreeSurferAndSubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/brainstemSsLabels.FSvoxelSpace.mgz %s/Results/AnatVolu/T1wSpace/{2}/{2}_Subregions_brainstemSsLabels.FSvoxelSpace.nii.gz %s', ...
        CommandInit, Cfg.ParallelWorkersNumber, WorkingDir,WorkingDir,LinkedFreeSurferAndSubjectIDString);
    system(Command);
end


fprintf('Organize results by Segment Subregions finished!\n');

end


function FreeSurferSubjectID = local_get_freesurfer_subject_ids(Cfg)

FreeSurferSubjectID = {};
if isfield(Cfg,'FreeSurferSubjectID') && length(Cfg.FreeSurferSubjectID)==Cfg.SubjectNum
    FreeSurferSubjectID = Cfg.FreeSurferSubjectID;
    return;
end

FreeSurferSubjectID = cell(Cfg.SubjectNum,1);
for i=1:Cfg.SubjectNum
    FreeSurferSubjectID{i} = local_resolve_freesurfer_subject_id(Cfg, Cfg.SubjectID{i});
end

end


function FreeSurferSubjectID = local_resolve_freesurfer_subject_id(Cfg, SubjectID)

FreeSurferSubjectID = SubjectID;
FreeSurferDir = fullfile(Cfg.WorkingDir,'freesurfer');
if ~exist(FreeSurferDir,'dir')
    return;
end

DirList = dir(fullfile(FreeSurferDir, [SubjectID '*']));
DirList = DirList([DirList.isdir]);
if isempty(DirList)
    return;
end

CandidateNameSet = sort({DirList.name});

if any(strcmp(CandidateNameSet, SubjectID))
    FreeSurferSubjectID = SubjectID;
    return;
end

Session1Candidate = [SubjectID '_ses-1'];
if any(strcmp(CandidateNameSet, Session1Candidate))
    FreeSurferSubjectID = Session1Candidate;
    return;
end

SessionCandidateSet = CandidateNameSet(~cellfun('isempty', regexp(CandidateNameSet, ['^' regexptranslate('escape', SubjectID) '_ses-[0-9]+$'], 'once')));
if numel(SessionCandidateSet) == 1
    FreeSurferSubjectID = SessionCandidateSet{1};
    return;
end

FreeSurferSubjectID = CandidateNameSet{1};

end
