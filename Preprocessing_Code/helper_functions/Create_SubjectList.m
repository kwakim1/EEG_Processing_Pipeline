function FolderNames = Create_SubjectList(FolderNames,~,BadSubs)
%2/9/22 - creates a subject list by removing (1) extraneous items, (2) bad
%subjects (if desired), (3) analysis subfolders

%Input
    %FolderNames = cell. cell array of strings of size [nfolders,1], each
         % row containing a folder name
    %flag = string. takes on the value 'All_Subs' or 'Bad_Subs_Removed'
        %depending whether excluding bad subjects for the filelist is desired
    %BadSubs = cell. cell array of strings containing sub IDs of bad
         %subjects. If none, leave empty i.e. {}

%Output
    %FolderNames = cell. list of folder names of subject IDs / folder names

%Example call
    %FolderNames =
    %Create_SubjectList({'.','..','1001','1002'},'Bad_Subs_Removed',{'1001'})

%NOTE: the argument "flag" is not actually needed but has been kept for
%backwards compatibility


[~,ind]=ismember({'Group_Analysis','Group_Plots','..','.','LogFiles','.DS_Store'},FolderNames);
ind(find(ind==0))=[]; 
FolderNames(ind) = [];%remove extraneous folders
if ~isempty(BadSubs)
    FolderNames(ismember(FolderNames,BadSubs))=[]; %remove bad subs
end

end