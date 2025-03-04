function Cfg = y_Organize_fmriprep(Cfg,WorkingDir,SubjectListFile,IsSlurmOrganizeSurf)
% function Cfg = y_Organize_fmriprep(Cfg,WorkingDir,SubjectListFile,IsSlurmOrganizeSurf)
% Organize results by fmriprep.
%   Input:
%   Cfg - the parameters for auto data processing. 
%   WorkingDir - Define the working directory to replace the one defined in Cfg
%   SubjectListFile - Define the subject list to replace the one defined in Cfg. Should be a text file
%   IsSlurmOrganizeSurf - Surf files have been organized by Slurm, thus no need to use parallel
%   Output:
%     see Results/Anat/Thickness, Area and Curv. See FunSurfW.
%___________________________________________________________________________
% Written by YAN Chao-Gan 181120.
% Key Laboratory of Behavioral Science and Magnetic Resonance Imaging Research Center, Institute of Psychology, Chinese Academy of Sciences, Beijing, China
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
SubjectIDString=[];
for i=1:Cfg.SubjectNum
    SubjectIDString = sprintf('%s %s',SubjectIDString,Cfg.SubjectID{i});
end

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


if IsNeedOrganizeSurfWithParallel
    fprintf('Organize thickness files...\n');
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsaverage','Thickness'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsaverage5','Thickness'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsaverage','Thickness'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsaverage5','Thickness'));

    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage --hemi lh --sval %s/freesurfer/{1}/surf/lh.thickness --tval %s/Results/AnatSurfLH/fsaverage/Thickness/{1}_space-fsaverage_hemi-L.thickness.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage --hemi rh --sval %s/freesurfer/{1}/surf/rh.thickness --tval %s/Results/AnatSurfRH/fsaverage/Thickness/{1}_space-fsaverage_hemi-R.thickness.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage5 --hemi lh --sval %s/freesurfer/{1}/surf/lh.thickness --tval %s/Results/AnatSurfLH/fsaverage5/Thickness/{1}_space-fsaverage5_hemi-L.thickness.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage5 --hemi rh --sval %s/freesurfer/{1}/surf/rh.thickness --tval %s/Results/AnatSurfRH/fsaverage5/Thickness/{1}_space-fsaverage5_hemi-R.thickness.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);

    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsnative','Thickness'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsnative','Thickness'));
    Command = sprintf('%s parallel -j %g mris_convert -c %s/freesurfer/{1}/surf/lh.thickness %s/freesurfer/{1}/surf/lh.white %s/Results/AnatSurfLH/fsnative/Thickness/{1}_space-fsnative_hemi-L.thickness.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mris_convert -c %s/freesurfer/{1}/surf/rh.thickness %s/freesurfer/{1}/surf/rh.white %s/Results/AnatSurfRH/fsnative/Thickness/{1}_space-fsnative_hemi-R.thickness.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);


    fprintf('Organize area files...\n');
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsaverage','Area'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsaverage5','Area'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsaverage','Area'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsaverage5','Area'));

    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage --hemi lh --sval %s/freesurfer/{1}/surf/lh.area --tval %s/Results/AnatSurfLH/fsaverage/Area/{1}_space-fsaverage_hemi-L.area.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage --hemi rh --sval %s/freesurfer/{1}/surf/rh.area --tval %s/Results/AnatSurfRH/fsaverage/Area/{1}_space-fsaverage_hemi-R.area.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage5 --hemi lh --sval %s/freesurfer/{1}/surf/lh.area --tval %s/Results/AnatSurfLH/fsaverage5/Area/{1}_space-fsaverage5_hemi-L.area.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage5 --hemi rh --sval %s/freesurfer/{1}/surf/rh.area --tval %s/Results/AnatSurfRH/fsaverage5/Area/{1}_space-fsaverage5_hemi-R.area.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);

    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsnative','Area'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsnative','Area'));
    Command = sprintf('%s parallel -j %g mris_convert -c %s/freesurfer/{1}/surf/lh.area %s/freesurfer/{1}/surf/lh.white %s/Results/AnatSurfLH/fsnative/Area/{1}_space-fsnative_hemi-L.area.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mris_convert -c %s/freesurfer/{1}/surf/rh.area %s/freesurfer/{1}/surf/rh.white %s/Results/AnatSurfRH/fsnative/Area/{1}_space-fsnative_hemi-R.area.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);



    fprintf('Organize curv files...\n');
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsaverage','Curv'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsaverage5','Curv'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsaverage','Curv'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsaverage5','Curv'));

    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage --hemi lh --sval %s/freesurfer/{1}/surf/lh.curv --tval %s/Results/AnatSurfLH/fsaverage/Curv/{1}_space-fsaverage_hemi-L.curv.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage --hemi rh --sval %s/freesurfer/{1}/surf/rh.curv --tval %s/Results/AnatSurfRH/fsaverage/Curv/{1}_space-fsaverage_hemi-R.curv.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage5 --hemi lh --sval %s/freesurfer/{1}/surf/lh.curv --tval %s/Results/AnatSurfLH/fsaverage5/Curv/{1}_space-fsaverage5_hemi-L.curv.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage5 --hemi rh --sval %s/freesurfer/{1}/surf/rh.curv --tval %s/Results/AnatSurfRH/fsaverage5/Curv/{1}_space-fsaverage5_hemi-R.curv.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);

    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsnative','Curv'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsnative','Curv'));
    Command = sprintf('%s parallel -j %g mris_convert -c %s/freesurfer/{1}/surf/lh.curv %s/freesurfer/{1}/surf/lh.white %s/Results/AnatSurfLH/fsnative/Curv/{1}_space-fsnative_hemi-L.curv.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mris_convert -c %s/freesurfer/{1}/surf/rh.curv %s/freesurfer/{1}/surf/rh.white %s/Results/AnatSurfRH/fsnative/Curv/{1}_space-fsnative_hemi-R.curv.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);



    fprintf('Organize sulc files...\n');
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsaverage','Sulc'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsaverage5','Sulc'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsaverage','Sulc'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsaverage5','Sulc'));

    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage --hemi lh --sval %s/freesurfer/{1}/surf/lh.sulc --tval %s/Results/AnatSurfLH/fsaverage/Sulc/{1}_space-fsaverage_hemi-L.sulc.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage --hemi rh --sval %s/freesurfer/{1}/surf/rh.sulc --tval %s/Results/AnatSurfRH/fsaverage/Sulc/{1}_space-fsaverage_hemi-R.sulc.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage5 --hemi lh --sval %s/freesurfer/{1}/surf/lh.sulc --tval %s/Results/AnatSurfLH/fsaverage5/Sulc/{1}_space-fsaverage5_hemi-L.sulc.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage5 --hemi rh --sval %s/freesurfer/{1}/surf/rh.sulc --tval %s/Results/AnatSurfRH/fsaverage5/Sulc/{1}_space-fsaverage5_hemi-R.sulc.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);

    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsnative','Sulc'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsnative','Sulc'));
    Command = sprintf('%s parallel -j %g mris_convert -c %s/freesurfer/{1}/surf/lh.sulc %s/freesurfer/{1}/surf/lh.white %s/Results/AnatSurfLH/fsnative/Sulc/{1}_space-fsnative_hemi-L.sulc.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mris_convert -c %s/freesurfer/{1}/surf/rh.sulc %s/freesurfer/{1}/surf/rh.white %s/Results/AnatSurfRH/fsnative/Sulc/{1}_space-fsnative_hemi-R.sulc.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);



    fprintf('Organize volume files...\n');
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsaverage','Volume'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsaverage5','Volume'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsaverage','Volume'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsaverage5','Volume'));

    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage --hemi lh --sval %s/freesurfer/{1}/surf/lh.volume --tval %s/Results/AnatSurfLH/fsaverage/Volume/{1}_space-fsaverage_hemi-L.volume.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage --hemi rh --sval %s/freesurfer/{1}/surf/rh.volume --tval %s/Results/AnatSurfRH/fsaverage/Volume/{1}_space-fsaverage_hemi-R.volume.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage5 --hemi lh --sval %s/freesurfer/{1}/surf/lh.volume --tval %s/Results/AnatSurfLH/fsaverage5/Volume/{1}_space-fsaverage5_hemi-L.volume.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mri_surf2surf --srcsubject {1} --trgsubject fsaverage5 --hemi rh --sval %s/freesurfer/{1}/surf/rh.volume --tval %s/Results/AnatSurfRH/fsaverage5/Volume/{1}_space-fsaverage5_hemi-R.volume.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);

    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfLH','fsnative','Volume'));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatSurfRH','fsnative','Volume'));
    Command = sprintf('%s parallel -j %g mris_convert -c %s/freesurfer/{1}/surf/lh.volume %s/freesurfer/{1}/surf/lh.white %s/Results/AnatSurfLH/fsnative/Volume/{1}_space-fsnative_hemi-L.volume.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mris_convert -c %s/freesurfer/{1}/surf/rh.volume %s/freesurfer/{1}/surf/rh.white %s/Results/AnatSurfRH/fsnative/Volume/{1}_space-fsnative_hemi-R.volume.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);

end



% Multiple Sessions Processing
FunSessionPrefixSet={''}; %The first session doesn't need a prefix. From the second session, need a prefix such as 'S2_';
for iFunSession=2:Cfg.FunctionalSessionNumber
    FunSessionPrefixSet=[FunSessionPrefixSet;{['S',num2str(iFunSession),'_']}];
end

%For fmriprepfuncSessionPrefixSet
if Cfg.FunctionalSessionNumber==1
    fmriprepfuncSessionPrefixSet={'func'}; %The first session doesn't need a prefix. From the second session, need a prefix such as 'S2_';
else
    for iFunSession=1:Cfg.FunctionalSessionNumber
        fmriprepfuncSessionPrefixSet{iFunSession}=['ses-',num2str(iFunSession),filesep,'func'];
    end
end


% The parpool might be shut down, restart it.
% if isempty(gcp('nocreate')) && Cfg.ParallelWorkersNumber~=0
%     parpool(Cfg.ParallelWorkersNumber);
% end
% YAN Chao-Gan, 190312. To be compatible with early matlab versions
PCTVer = ver('distcomp');
if ~isempty(PCTVer)
    FullMatlabVersion = sscanf(version,'%d.%d.%d.%d%s');
    if FullMatlabVersion(1)*1000+FullMatlabVersion(2)<8*1000+3    %YAN Chao-Gan, 151117. If it's lower than MATLAB 2014a.  %FullMatlabVersion(1)*1000+FullMatlabVersion(2)>=7*1000+8    %YAN Chao-Gan, 120903. If it's higher than MATLAB 2008.
        CurrentSize_MatlabPool = matlabpool('size');
        if (CurrentSize_MatlabPool==0) && (Cfg.ParallelWorkersNumber~=0)
            matlabpool(Cfg.ParallelWorkersNumber)
        end
    else
        if isempty(gcp('nocreate')) && Cfg.ParallelWorkersNumber~=0
            parpool(Cfg.ParallelWorkersNumber);
        end
    end
end


fprintf('Organize AnatVolu...\n');

for i=1:Cfg.SubjectNum
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatVolu','T1wSpace',Cfg.SubjectID{i}));
    mkdir(fullfile(Cfg.WorkingDir,'Results','AnatVolu','MNISpace',Cfg.SubjectID{i}));
    if exist(fullfile(Cfg.WorkingDir,'fmriprep')) %YAN Chao-Gan 221010. With fastsurfer, fmriprep may not exist
        if Cfg.FunctionalSessionNumber<=1
            %copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'anat','*_space-MNI152NLin2009cAsym_*'),fullfile(Cfg.WorkingDir,'Results','AnatVolu','MNISpace',Cfg.SubjectID{i}));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'anat','*.nii.gz'),fullfile(Cfg.WorkingDir,'Results','AnatVolu','T1wSpace',Cfg.SubjectID{i}));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'anat','*.json'),fullfile(Cfg.WorkingDir,'Results','AnatVolu','T1wSpace',Cfg.SubjectID{i}));
            movefile(fullfile(Cfg.WorkingDir,'Results','AnatVolu','T1wSpace',Cfg.SubjectID{i},'*_space-MNI152NLin2009cAsym_*'),fullfile(Cfg.WorkingDir,'Results','AnatVolu','MNISpace',Cfg.SubjectID{i}));
        else
            %copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'ses-1','anat','*_space-MNI152NLin2009cAsym_*'),fullfile(Cfg.WorkingDir,'Results','AnatVolu','MNISpace',Cfg.SubjectID{i}));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'ses-1','anat','*.nii.gz'),fullfile(Cfg.WorkingDir,'Results','AnatVolu','T1wSpace',Cfg.SubjectID{i}));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'ses-1','anat','*.json'),fullfile(Cfg.WorkingDir,'Results','AnatVolu','T1wSpace',Cfg.SubjectID{i}));
            movefile(fullfile(Cfg.WorkingDir,'Results','AnatVolu','T1wSpace',Cfg.SubjectID{i},'*_space-MNI152NLin2009cAsym_*'),fullfile(Cfg.WorkingDir,'Results','AnatVolu','MNISpace',Cfg.SubjectID{i}));
        end
    end
end


fprintf('Organize aparcaseg files...\n');
Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/aparc+aseg.mgz  %s/Results/AnatVolu/T1wSpace/{1}/{1}_space-T1w_desc-aparcaseg.nii.gz ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
system(Command);
fprintf('Organize aseg files...\n');
Command = sprintf('%s parallel -j %g mri_convert %s/freesurfer/{1}/mri/aseg.mgz  %s/Results/AnatVolu/T1wSpace/{1}/{1}_space-T1w_desc-aseg.nii.gz ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, SubjectIDString);
system(Command);



fprintf('Organize Anat Segment Volume...\n');
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/asegstats2table --subjects %s --meas volume --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_Segment_Volume.tsv');
system(Command);

fprintf('Organize freesurfer parcellation stats...\n');
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi lh --meas thickness --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_Aparc_Stats_Thickness_LH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi rh --meas thickness --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_Aparc_Stats_Thickness_RH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi lh --meas area --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_Aparc_Stats_Area_LH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi rh --meas area --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_Aparc_Stats_Area_RH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi lh --meas volume --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_Aparc_Stats_Volume_LH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi rh --meas volume --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_Aparc_Stats_Volume_RH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi lh --meas meancurv --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_Aparc_Stats_MeanCurv_LH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi rh --meas meancurv --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_Aparc_Stats_MeanCurv_RH.tsv');
system(Command);

Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi lh --parc aparc.a2009s --meas thickness --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_AparcA2009s_Stats_Thickness_LH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi rh --parc aparc.a2009s --meas thickness --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_AparcA2009s_Stats_Thickness_RH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi lh --parc aparc.a2009s --meas area --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_AparcA2009s_Stats_Area_LH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi rh --parc aparc.a2009s --meas area --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_AparcA2009s_Stats_Area_RH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi lh --parc aparc.a2009s --meas volume --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_AparcA2009s_Stats_Volume_LH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi rh --parc aparc.a2009s --meas volume --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_AparcA2009s_Stats_Volume_RH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi lh --parc aparc.a2009s --meas meancurv --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_AparcA2009s_Stats_MeanCurv_LH.tsv');
system(Command);
Command = sprintf('%s /opt/freesurfer/bin/fspython /opt/freesurfer/python/scripts/aparcstats2table --subjects %s --hemi rh --parc aparc.a2009s --meas meancurv --tablefile %s%s', CommandInit, SubjectIDString,WorkingDir,'/Results/AnatVolu/Anat_AparcA2009s_Stats_MeanCurv_RH.tsv');
system(Command);


if Cfg.FunctionalSessionNumber==0 %YAN Chao-Gan, 210414. If no anatomical images
    return
end


fprintf('Organize functional surface files...\n');
if Cfg.FunctionalSessionNumber==1
    mkdir(fullfile(Cfg.WorkingDir,'FunSurfW'));
    mkdir(fullfile(Cfg.WorkingDir,'FunSurf'));
    parfor i=1:Cfg.SubjectNum
        mkdir(fullfile(Cfg.WorkingDir,'FunSurfW',Cfg.SubjectID{i}));
        copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'func','*fsaverage5_*.func.gii'),fullfile(Cfg.WorkingDir,'FunSurfW',Cfg.SubjectID{i}));
        %copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'func','*_space-MNI152NLin2009cAsym_*desc-aparcaseg_dseg.nii.gz'),fullfile(Cfg.WorkingDir,'Results','AnatVolu',Cfg.SubjectID{i}));
        mkdir(fullfile(Cfg.WorkingDir,'FunSurf',Cfg.SubjectID{i}));
        copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'func','*fsnative_*.func.gii'),fullfile(Cfg.WorkingDir,'FunSurf',Cfg.SubjectID{i}));
    end
else
    for iFunSession=1:Cfg.FunctionalSessionNumber
        mkdir(fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunSurfW']));
        parfor i=1:Cfg.SubjectNum
            mkdir(fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunSurfW'],Cfg.SubjectID{i}));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},['ses-',num2str(iFunSession)],'func','*fsaverage5_*.func.gii'),fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunSurfW'],Cfg.SubjectID{i}));
            %copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},['ses-',num2str(iFunSession)],'func','*_space-MNI152NLin2009cAsym_*desc-aparcaseg_dseg.nii.gz'),fullfile(Cfg.WorkingDir,'Results','AnatVolu',Cfg.SubjectID{i}));
            mkdir(fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunSurf'],Cfg.SubjectID{i}));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},['ses-',num2str(iFunSession)],'func','*fsnative_*.func.gii'),fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunSurf'],Cfg.SubjectID{i}));
        end
    end
end


fprintf('Organize functional volume files...\n');
if Cfg.FunctionalSessionNumber==1
    mkdir(fullfile(Cfg.WorkingDir,'FunVoluW'));
    mkdir(fullfile(Cfg.WorkingDir,'FunVolu'));
    parfor i=1:Cfg.SubjectNum
        mkdir(fullfile(Cfg.WorkingDir,'FunVoluW',Cfg.SubjectID{i}));
        copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'func','*space-MNI152NLin2009cAsym_*desc-preproc_bold.nii.gz'),fullfile(Cfg.WorkingDir,'FunVoluW',Cfg.SubjectID{i}));
        mkdir(fullfile(Cfg.WorkingDir,'FunVolu',Cfg.SubjectID{i}));
        copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'func','*space-T1w_*desc-preproc_bold.nii.gz'),fullfile(Cfg.WorkingDir,'FunVolu',Cfg.SubjectID{i}));
    end
else
    for iFunSession=1:Cfg.FunctionalSessionNumber
        mkdir(fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunVoluW']));
        mkdir(fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunVolu']));
        parfor i=1:Cfg.SubjectNum
            mkdir(fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunVoluW'],Cfg.SubjectID{i}));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},['ses-',num2str(iFunSession)],'func','*space-MNI152NLin2009cAsym_*desc-preproc_bold.nii.gz'),fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunVoluW'],Cfg.SubjectID{i}));
            mkdir(fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunVolu'],Cfg.SubjectID{i}));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},['ses-',num2str(iFunSession)],'func','*space-T1w_*desc-preproc_bold.nii.gz'),fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunVolu'],Cfg.SubjectID{i}));
        end
    end
end


fprintf('Organize functional mask files...\n');
if Cfg.FunctionalSessionNumber==1
    mkdir(fullfile(Cfg.WorkingDir,'Masks','AutoMasks'));
    parfor i=1:Cfg.SubjectNum
        copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'func','*space-MNI152NLin2009cAsym_*desc-brain_mask.nii.gz'),fullfile(Cfg.WorkingDir,'Masks','AutoMasks'));
        copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'func','*space-T1w_*desc-brain_mask.nii.gz'),fullfile(Cfg.WorkingDir,'Masks','AutoMasks'));
    end
else
    for iFunSession=1:Cfg.FunctionalSessionNumber
        mkdir(fullfile(Cfg.WorkingDir,'Masks',[FunSessionPrefixSet{iFunSession},'AutoMasks']));
        parfor i=1:Cfg.SubjectNum
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},['ses-',num2str(iFunSession)],'func','*space-MNI152NLin2009cAsym_*desc-brain_mask.nii.gz'),fullfile(Cfg.WorkingDir,'Masks',[FunSessionPrefixSet{iFunSession},'AutoMasks']));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},['ses-',num2str(iFunSession)],'func','*space-T1w_*desc-brain_mask.nii.gz'),fullfile(Cfg.WorkingDir,'Masks',[FunSessionPrefixSet{iFunSession},'AutoMasks']));
        end
    end
end


%YAN Chao-Gan, 221205.
if IsNeedOrganizeSurfWithParallel
    fprintf('Organize fsnative mask files...\n');
    mkdir(fullfile(Cfg.WorkingDir,'Masks',filesep,'MasksForFun',filesep,'Masks_SurfSpace'));
    Command = sprintf('%s parallel -j %g mris_convert --label %s/freesurfer/{1}/label/lh.cortex.label 1 %s/freesurfer/{1}/surf/lh.white %s/Masks/MasksForFun/Masks_SurfSpace/{1}_lh_cortex_label.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
    Command = sprintf('%s parallel -j %g mris_convert --label %s/freesurfer/{1}/label/rh.cortex.label 1 %s/freesurfer/{1}/surf/rh.white %s/Masks/MasksForFun/Masks_SurfSpace/{1}_rh_cortex_label.gii ::: %s', CommandInit, Cfg.ParallelWorkersNumber, WorkingDir, WorkingDir, WorkingDir, SubjectIDString);
    system(Command);
end


fprintf('Organize ICA-AROMA Noise files...\n');
if Cfg.FunctionalSessionNumber==1
    DirList=dir(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{1},'func','*_AROMAnoiseICs.csv'));
    if ~isempty(DirList)
        mkdir(fullfile(Cfg.WorkingDir,'FunVoluWICAAROMANoise'));
        parfor i=1:Cfg.SubjectNum
            mkdir(fullfile(Cfg.WorkingDir,'FunVoluWICAAROMANoise',Cfg.SubjectID{i}));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'func','*_AROMAnoiseICs.csv'),fullfile(Cfg.WorkingDir,'FunVoluWICAAROMANoise',Cfg.SubjectID{i}));
            copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},'func','*-MELODIC_mixing.tsv'),fullfile(Cfg.WorkingDir,'FunVoluWICAAROMANoise',Cfg.SubjectID{i}));
        end
    end
else
    for iFunSession=1:Cfg.FunctionalSessionNumber
        DirList=dir(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{1},['ses-',num2str(iFunSession)],'func','*_AROMAnoiseICs.csv'));
        if ~isempty(DirList)
            mkdir(fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunVoluWICAAROMANoise']));
            parfor i=1:Cfg.SubjectNum
                copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},['ses-',num2str(iFunSession)],'func','*_AROMAnoiseICs.csv'),fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunVoluWICAAROMANoise'],Cfg.SubjectID{i}));
                copyfile(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},['ses-',num2str(iFunSession)],'func','*-MELODIC_mixing.tsv'),fullfile(Cfg.WorkingDir,[FunSessionPrefixSet{iFunSession},'FunVoluWICAAROMANoise'],Cfg.SubjectID{i}));
            end
        end
    end
end


fprintf('Organize realign parameters (MCFLIRT motion parameters, normalized to SPM format (X, Y, Z, Rx, Ry, Rz))...\n');
mkdir(fullfile(Cfg.WorkingDir,'RealignParameter'));
for iFunSession=1:Cfg.FunctionalSessionNumber
    HeadMotion = zeros(Cfg.SubjectNum,20);
    % max(abs(Tx)), max(abs(Ty)), max(abs(Tz)), max(abs(Rx)), max(abs(Ry)), max(abs(Rz)),
    % mean(abs(Tx)), mean(abs(Ty)), mean(abs(Tz)), mean(abs(Rx)), mean(abs(Ry)), mean(abs(Rz)),
    % mean RMS, mean relative RMS (mean FD_VanDijk),
    % mean FD_Power, Number of FD_Power>0.5, Percent of FD_Power>0.5, Number of FD_Power>0.2, Percent of FD_Power>0.2
    % mean FD_Jenkinson (FSL's relative RMS)
    for i=1:Cfg.SubjectNum
        mkdir(fullfile(Cfg.WorkingDir,'RealignParameter',Cfg.SubjectID{i}));
        cd(fullfile(Cfg.WorkingDir,'RealignParameter',Cfg.SubjectID{i}));
        
        DirFile=dir(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},fmriprepfuncSessionPrefixSet{iFunSession},'*confounds_*.tsv'));
        Table=tdfread(fullfile(Cfg.WorkingDir,'fmriprep',Cfg.SubjectID{i},fmriprepfuncSessionPrefixSet{iFunSession},DirFile(1).name));
        RP=[Table.trans_x,Table.trans_y,Table.trans_z,Table.rot_x,Table.rot_y,Table.rot_z];
        
        save(fullfile(Cfg.WorkingDir,'RealignParameter',Cfg.SubjectID{i},[FunSessionPrefixSet{iFunSession},'rp_',Cfg.SubjectID{i},'.txt']), 'RP', '-ASCII', '-DOUBLE','-TABS');
        
        MaxRP = max(abs(RP));
        MaxRP(4:6) = MaxRP(4:6)*180/pi;
        
        MeanRP = mean(abs(RP));
        MeanRP(4:6) = MeanRP(4:6)*180/pi;
        
        %Calculate FD Van Dijk (Van Dijk, K.R., Sabuncu, M.R., Buckner, R.L., 2012. The influence of head motion on intrinsic functional connectivity MRI. Neuroimage 59, 431-438.)
        RPRMS = sqrt(sum(RP(:,1:3).^2,2));
        MeanRMS = mean(RPRMS);
        
        FD_VanDijk = abs(diff(RPRMS));
        FD_VanDijk = [0;FD_VanDijk];
        save([FunSessionPrefixSet{iFunSession},'FD_VanDijk_',Cfg.SubjectID{i},'.txt'], 'FD_VanDijk', '-ASCII', '-DOUBLE','-TABS');
        MeanFD_VanDijk = mean(FD_VanDijk);
        
        %Calculate FD Power (Power, J.D., Barnes, K.A., Snyder, A.Z., Schlaggar, B.L., Petersen, S.E., 2012. Spurious but systematic correlations in functional connectivity MRI networks arise from subject motion. Neuroimage 59, 2142-2154.)
        RPDiff=diff(RP);
        RPDiff=[zeros(1,6);RPDiff];
        RPDiffSphere=RPDiff;
        RPDiffSphere(:,4:6)=RPDiffSphere(:,4:6)*50;
        FD_Power=sum(abs(RPDiffSphere),2);
        save([FunSessionPrefixSet{iFunSession},'FD_Power_',Cfg.SubjectID{i},'.txt'], 'FD_Power', '-ASCII', '-DOUBLE','-TABS');
        MeanFD_Power = mean(FD_Power);
        
        NumberFD_Power_05 = length(find(FD_Power>0.5));
        PercentFD_Power_05 = length(find(FD_Power>0.5)) / length(FD_Power);
        NumberFD_Power_02 = length(find(FD_Power>0.2));
        PercentFD_Power_02 = length(find(FD_Power>0.2)) / length(FD_Power);
        
        %Calculate FD Jenkinson (FSL's relative RMS) (Jenkinson, M., Bannister, P., Brady, M., Smith, S., 2002. Improved optimization for the robust and accurate linear registration and motion correction of brain images. Neuroimage 17, 825-841. Jenkinson, M. 1999. Measuring transformation error by RMS deviation. Internal Technical Report TR99MJ1, FMRIB Centre, University of Oxford. Available at www.fmrib.ox.ac.uk/analysis/techrep for downloading.)
        %The matrix in Header is needed, thus look for the functional image before realignment
        DirFile=dir([Cfg.WorkingDir,filesep,'BIDS',filesep,Cfg.SubjectID{i},filesep,fmriprepfuncSessionPrefixSet{iFunSession},filesep,'*.nii*']);
        RefFile=[Cfg.WorkingDir,filesep,'BIDS',filesep,Cfg.SubjectID{i},filesep,fmriprepfuncSessionPrefixSet{iFunSession},filesep,DirFile(1).name];
        FD_Jenkinson = y_FD_Jenkinson(fullfile(Cfg.WorkingDir,'RealignParameter',Cfg.SubjectID{i},[FunSessionPrefixSet{iFunSession},'rp_',Cfg.SubjectID{i},'.txt']),RefFile); %YAN Chao-Gan 220525. Fix for multiple sessions.
        %FD_Jenkinson = y_FD_Jenkinson(fullfile(Cfg.WorkingDir,'RealignParameter',Cfg.SubjectID{i},['rp_',Cfg.SubjectID{i},'.txt']),RefFile);
        save([FunSessionPrefixSet{iFunSession},'FD_Jenkinson_',Cfg.SubjectID{i},'.txt'], 'FD_Jenkinson', '-ASCII', '-DOUBLE','-TABS');
        MeanFD_Jenkinson = mean(FD_Jenkinson);
        
        HeadMotion(i,:) = [MaxRP,MeanRP,MeanRMS,MeanFD_VanDijk,MeanFD_Power,NumberFD_Power_05,PercentFD_Power_05,NumberFD_Power_02,PercentFD_Power_02,MeanFD_Jenkinson];
    end
    
    save([Cfg.WorkingDir,filesep,'RealignParameter',filesep,FunSessionPrefixSet{iFunSession},'HeadMotion.mat'],'HeadMotion');
    
    %Write the Head Motion as .tsv
    fid = fopen([Cfg.WorkingDir,filesep,'RealignParameter',filesep,FunSessionPrefixSet{iFunSession},'HeadMotion.tsv'],'w');
    fprintf(fid,'Subject ID\tmax(abs(Tx))\tmax(abs(Ty))\tmax(abs(Tz))\tmax(abs(Rx))\tmax(abs(Ry))\tmax(abs(Rz))\tmean(abs(Tx))\tmean(abs(Ty))\tmean(abs(Tz))\tmean(abs(Rx))\tmean(abs(Ry))\tmean(abs(Rz))\tmean RMS\tmean relative RMS (mean FD_VanDijk)\tmean FD_Power\tNumber of FD_Power>0.5\tPercent of FD_Power>0.5\tNumber of FD_Power>0.2\tPercent of FD_Power>0.2\tmean FD_Jenkinson\n');
    for i=1:Cfg.SubjectNum
        fprintf(fid,'%s\t',Cfg.SubjectID{i});
        fprintf(fid,'%e\t',HeadMotion(i,:));
        fprintf(fid,'\n');
    end
    fclose(fid);
    
    ExcludeSub_Text=[];
    for ExcludingCriteria=3:-0.5:0.5
        BigHeadMotion=find(HeadMotion(:,1:6)>ExcludingCriteria);
        if ~isempty(BigHeadMotion)
            [II JJ]=ind2sub([Cfg.SubjectNum,6],BigHeadMotion);
            ExcludeSub=unique(II);
            ExcludeSub_ID=Cfg.SubjectID(ExcludeSub);
            TempText='';
            for iExcludeSub=1:length(ExcludeSub_ID)
                TempText=sprintf('%s%s\n',TempText,ExcludeSub_ID{iExcludeSub});
            end
        else
            TempText='None';
        end
        ExcludeSub_Text=sprintf('%s\nExcluding Criteria: %2.1fmm and %2.1f degree in max head motion\n%s\n\n\n',ExcludeSub_Text,ExcludingCriteria,ExcludingCriteria,TempText);
    end
    fid = fopen([Cfg.WorkingDir,filesep,'RealignParameter',filesep,FunSessionPrefixSet{iFunSession},'ExcludeSubjectsAccordingToMaxHeadMotion.txt'],'at+');
    fprintf(fid,'%s',ExcludeSub_Text);
    fclose(fid);
    
end

%Generate QC HTML file based on results by fmriprep.
y_GenerateQCHTML(Cfg);

fprintf('Organize fmriprep files finished!\n');
