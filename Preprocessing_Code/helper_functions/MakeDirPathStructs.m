function [dirpath,dirstruct] = MakeDirPathStructs(dirpath,dirstruct,SubNum,formatspec)

%11/19/21 - KW
%captures important paths and creates subject-level structs
% necessary for processing. Also creates a subject-level
% directory called [subnum]_plots and [subnum]_erp[formatspec]
% if they do not already exist

%input:
    %dirpath = struct containing the field 'ParentDir,' containing a string
        %of the file path where subject-level directories are stored
    %dirstruct = struct. Can be empty
    %SubNum = string of a subject number, e.g. '1161'
    %formatspec = string. If you want to plot data stored in a directory
         %whose naming structure does not follow the traditional [subnum]_erp,
        %include an extra things indicating which folder your data can be
        %found. For example, if the folder containing your data is titled
        %[subnum]_erp_NoICA_JointKurt, then formatspec should be
        %'_NoICA_JointKurt'

%output:
    %dirpath = dirpath updated with the new fields dirpath.SubDir,
        %dirpath.SubDir_MatDir, etc.
    %dirstruct = dirstruct updated with similar fields, e.g.
        %dirstruct.SubDir

%example call:
    %MakeDirPathStructs(dirpath,dirstruct,'1161','_ICA_Chanrej')

dirpath.SubDir = fullfile(dirpath.ParentDir,SubNum);
dirstruct.SubDir=dir(dirpath.SubDir);
dirpath.SubDir_MatDir= fullfile(dirpath.ParentDir,SubNum,sprintf('%s_mat%s',SubNum,formatspec));
dirpath.SubDir_BDFdir= fullfile(dirpath.ParentDir,SubNum,sprintf('%s_bdf',SubNum));
if ~isdir(fullfile(dirpath.SubDir,sprintf('%s_erp%s',SubNum,formatspec)))
    mkdir(fullfile(dirpath.SubDir,sprintf('%s_erp%s',SubNum,formatspec)))
end
if ~isdir(fullfile(dirpath.SubDir,sprintf('%s_plots',SubNum)))
    mkdir(fullfile(dirpath.SubDir,sprintf('%s_plots',SubNum)))
end
dirpath.SubDir_PlotDir=fullfile(dirpath.SubDir,sprintf('%s_plots',SubNum));
dirpath.SubDir_ERPdir=fullfile(dirpath.ParentDir,SubNum,sprintf('%s_erp%s',SubNum,formatspec));
dirstruct.SubDir_ERPdir=dir(fullfile(dirpath.SubDir,sprintf('%s_erp%s',SubNum,formatspec)));


end