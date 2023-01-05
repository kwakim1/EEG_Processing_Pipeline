function [] = OrganizeDir_bdf2mat(ParentDir)
%KW - 11/1/21 - Organize subdirectires as expected for the script bdf2mat
%12/15/21 - updated KW bug fixes

%input:
    %ParentDir = string of filepath for directory containing subject-level
        %directories

%example call:
    %OrganizeDir_bdf2mat('C:\Users\kwakimtaka\Desktop\AVSRT_TD')

dirstruct.ParentDir=dir(ParentDir);
FolderNames={dirstruct.ParentDir.name}';
[~,ind]=ismember({'Group_Analysis','Group_Plots','LogFiles','..','.','.DS_Store','LogFiles'},FolderNames);
ind(find(ind==0))=[];
FolderNames(ind) = [];

for i=1:length(FolderNames)
    if ~isdir(fullfile(ParentDir,FolderNames{i},sprintf('%s_bdf',FolderNames{i})))
        fprintf('Sub %s (%d of %d): Making directory structure for bdf2mat script...\n',FolderNames{i},i,length(FolderNames));
        mkdir(fullfile(ParentDir,FolderNames{i},sprintf('%s_bdf',FolderNames{i})));
        movefile(fullfile(ParentDir,FolderNames{i},'*.bdf'),fullfile(ParentDir,FolderNames{i},sprintf('%s_bdf',FolderNames{i})));
        if ~isempty(dir(fullfile(ParentDir,FolderNames{i},'*.txt')))
            mkdir(fullfile(ParentDir,FolderNames{i},sprintf('%s_log',FolderNames{i})));
            movefile(fullfile(ParentDir,FolderNames{i},'*.txt'),fullfile(ParentDir,FolderNames{i},sprintf('%s_log',FolderNames{i})));
        end
        if ~isempty(dir(fullfile(ParentDir,FolderNames{i},'*.log')))
            mkdir(fullfile(ParentDir,FolderNames{i},sprintf('%s_log',FolderNames{i})));
            movefile(fullfile(ParentDir,FolderNames{i},'*.log'),fullfile(ParentDir,FolderNames{i},sprintf('%s_log',FolderNames{i})));
        end
    else
        fprintf('Sub %s (%d of %d): Already formatted for bdf2mat script--skipping...\n',FolderNames{i},i,length(FolderNames))
    end
end
end