function [StepCompleted,rootname] = CheckIfStepCompleted(dirpath,FileEnding,dirtype,varargin)
%12/1/21 - Checks if EEG processing step has been completed by looking to
%see whether the output file from that step is present

%5/5/22 - updated. removed SubNum as an argument, added functionality:
%FileEnding now can be a partial string, does not need to represent the
%entirity of the filename that comes after the subject number

%---------------

%input
    %dirpath = struct. fields contain path names for key paths. see
        %function MakeDirPathStructs.m
    %SubNum = string. subject ID, e.g. '1061'
    %FileEnding = string. Ouput file should contain this string. NOTE:
        %script asserts that this must be the only file in the subdirectory
        %that contains this string
    %dirtype = string. 'MatDir' or 'ERPdir' depending on where the output
        %file should be located
    %varargin = str. exclusionary strings. if you want the file name to NOT
        %contain this string, e.g. 'ERPs'

%Output
    %StepCompleted = logical. 1 if the output file exists, 0 if it does not
        %exist

%Example Call
    %StepCompleted=CheckIfStepCompleted(dirpath,'1061','_resample','MatDir');

%---------------------------------------------

%check for optional arguments (exclusionary strings)
if nargin>3
    NumExclusionaryStrings=length(varargin);
else
    NumExclusionaryStrings=0;
end

%check input dir type
switch dirtype
    case 'MatDir'
        KeyDir=dirpath.SubDir_MatDir;
    case 'ERPdir'
        KeyDir=dirpath.SubDir_ERPdir;
end

%create dir struct
dirstruct=dir(KeyDir);
fnames={dirstruct.name}';

%check for desired strings
fnames=fnames(find(contains(fnames,FileEnding)));
%check for exclusionary strings
for i=1:NumExclusionaryStrings
    fnames=fnames(find(~contains(fnames,varargin{i})));
end

%check assumptions
assert(length(fnames)<=1,'More than one file found in subject folder with this file ending--double check this');

%check whether step has been completed
if isempty(fnames)
    StepCompleted=0;
    rootname={};
else
    StepCompleted=isfile(fullfile(KeyDir,fnames{1}));
    [~,rootname,~]=fileparts(fullfile(KeyDir,fnames{1}));
end
