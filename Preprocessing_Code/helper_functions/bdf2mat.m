function bdf2mat(dirpath,FolderEnding)
%merges multiple BDF files belonging to the same subject in one .mat
%structure
%9/19/22 - added eeg_checkset to verify output structure
%12/15/22 - KW updating documentation for github

datadir=dirpath.ParentDir;
folders = dir(datadir);
subjects = {folders([folders(:).isdir]).name};
subjects(ismember(subjects,{'.','..'})) = [];
[~,ind]=ismember({'Group_Analysis','Group_Plots','..','.','.DS_Store','LogFiles'},subjects);
ind(find(ind==0))=[];
subjects(ind) = [];
disp('Converting files to .mat format...');



for i = 1:length(subjects)
    if ~isfolder(fullfile(datadir,subjects{i},sprintf('%s_mat',subjects{i})))
        mkdir(fullfile(datadir,subjects{i},sprintf('%s_mat',subjects{i})))
    end
    bdffiles_path=fullfile(datadir,subjects{i},[subjects{i},'_bdf']);
    bdffiles_dir=dir(fullfile(bdffiles_path,'*bdf'));
    bdffiles={bdffiles_dir.name};
    if ~isfolder(fullfile(datadir,subjects{i},sprintf('%s_mat%s',subjects{i},FolderEnding)))
        mkdir(fullfile(datadir,subjects{i},sprintf('%s_mat%s',subjects{i},FolderEnding)));
        mkdir(fullfile(datadir,subjects{i},sprintf('%s_mat',subjects{i})));
    end
    if ~isempty(bdffiles)
        if ~any(size(dir([datadir,filesep,subjects{i},filesep,[subjects{i} '_mat' FolderEnding] '/*.set' ]),1)) %if the data hasn't already been converted to .set
            fprintf('Sub %s (%d of %d): Converting and merging...\n',subjects{i},i,length(subjects))
            for j = 1:size(bdffiles,2) %for every BDF file
                fprintf('Sub %s (%d of %d): BDF file %d of %d\n',subjects{i},i,length(subjects),j,size(bdffiles,1))
                temp_dat = pop_biosig(fullfile(bdffiles_path,sprintf('%s',bdffiles{j})));
                if j == 1
                    EEG = temp_dat;
                else
                    EEG = pop_mergeset(EEG,temp_dat);
                end
                clear temp_dat;
            end
            if length(EEG.chanlocs)<73
                fprintf('Sub %s (%d of %d): Loading channel locations file...',subjects{i},i,length(subjects),j)
                EEG=pop_chanedit(EEG, 'lookup',fullfile(dirpath.EEGlabDir,'plugins','dipfit','standard_BESA','standard-10-5-cap385.elp'));
            end
            EEG.subject=subjects{i};
            EEG.setname=subjects{i};
            EEG=eeg_checkset(EEG); %added 9/19/22
            save(fullfile(datadir,subjects{i},sprintf('%s_mat%s',subjects{i},FolderEnding),sprintf('%s.mat',subjects{i})),'EEG','-mat');
            save(fullfile(datadir,subjects{i},sprintf('%s_mat',subjects{i}),sprintf('%s.mat',subjects{i})),'EEG','-mat');
            EEG = pop_saveset( EEG, 'filename',sprintf('%s.set',subjects{i}),'filepath',fullfile(datadir,subjects{i},sprintf('%s_mat%s',subjects{i},FolderEnding))); %added 9/19/22
            EEG = pop_saveset( EEG, 'filename',sprintf('%s.set',subjects{i}),'filepath',fullfile(datadir,subjects{i},sprintf('%s_mat',subjects{i}))); %added 9/19/22
            clear bdffiles EEG 
        else
            disp(['Sub ' subjects{i} ' already converted!']);
        end
    else
        disp(['Folder for ' subjects{i} ' contained no .bdf files to convert! (or the folder structure is incorrect!)']);
    end
end
disp('Finished file merging and conversions! On to preprocessing...');