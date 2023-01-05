%Basic preprocessing pipeline for AVSRT - 11/3/21
%KW
%12/15/22 - KW updating documentation for github
%1/5/23 - KW edited

%STEP ORDER - 11/9/22
%1. Initalize / load data
%2. Resample (if desired)
%3. remove external channels,verify channel data, and get channel locations
%4. filter, including line noise removal at 60 Hz
%5. channel rejection and interpolation
%6. rereference to average
%7. ICA
%8. epoch, baseline, trial rej
%9. Make single-subject plots for QC
%10. Finalize / save data and log file


%% initialize

addpath(genpath('PATH/TO/CODE/DIRECTORY')) % replace with the path to the code directory. e.g. 'C:\Users\me\Desktop\Preprocessing_ForGithub'
dirpath.ParentDir='PATH/TO/DATA/DIR'; %replace with path to parent directory containing subject-level folders, e.g. 'C:\Users\me\Desktop\my_experiment'
FolderEnding='_OPTIONAL_DESCRIPTION_OF_ANALYSIS'; %e.g. '_stimulus_locked_data. Can also be left blank
dirpath.EEGLabDir='PATH/TO/EEGLAB'; %e.g. 'C:\Users\me\Documents\MATLAB\eeglab2021.1'


eeglab nogui

if ~isdir(fullfile(dirpath.ParentDir,'LogFiles'))
    mkdir(fullfile(dirpath.ParentDir,'LogFiles'));
end
dirpath.ProcessingLogDir=fullfile(dirpath.ParentDir,'LogFiles');
dirpath.ManualOverride=''; %not used, kept for backward compatibility
dirstruct.ParentDir=dir(dirpath.ParentDir);
FolderNames={dirstruct.ParentDir.name}';
FolderNames=Create_SubjectList(FolderNames,{},{});
ManualOverride=[];
if ~isempty(dirpath.ManualOverride) %if there are electrodes to manually reject
    ManualOverride=xlsread(dirpath.ManualOverride);
end

%load params
params=GetParams();

%initalize diarly log file
diary(fullfile(dirpath.ProcessingLogDir,sprintf('%s_ProcessingLog_%s_%dsubs%s.txt',datestr(now,'mmddyy'),params.expname,length(FolderNames),FolderEnding)));     

%           1          2                3               4                      5                       6             
names={'SubNum','NumElectrodes','NumBadElectrodes','IndBadElec','PercentTrialRej_EEGquality','ResponseIndex',...
    'NumTotalTrials','Flag?'};
%     7                8
LogFile=cell(length(FolderNames),length(names));
LogFile(:,1)=FolderNames;

% %% convert BDF files to matlab data structure
OrganizeDir_bdf2mat(dirpath.ParentDir)
bdf2mat(dirpath,FolderEnding)


for i=1:length(FolderNames)
    fprintf('Sub %s (%d of %d): Beginning %s analysis at %s\n',FolderNames{i},i,length(FolderNames),params.Analysis,datestr(now,'HH:MM:SS'))
    %------------
    %% 1. initalize
    %------------
    SubNum=FolderNames{i};
    [dirpath,dirstruct] = MakeDirPathStructs(dirpath,dirstruct,SubNum,FolderEnding);
    %---------------------------------
    %% 2. Load data and resample if needed
    %---------------------------------
    %% load data
    StepCompleted=CheckIfStepCompleted(dirpath,'_resample','MatDir','filter');
    switch StepCompleted
        case 1 %if the step has already been completed, skip it and load the output
            fprintf('Sub %s (%d of %d): Resampling step compoleted--loading data...\n',SubNum,i,length(FolderNames))
            load(fullfile(dirpath.SubDir_MatDir,sprintf('%s_resample.mat',FolderNames{i})));
        case 0 %if you haven't already done the step... then do the step!
            assert(~isempty(params.desFs),'Field for desired sampling rate in in GetParams.m is empty. Make sure to set all parameters in GetParams.m!')
            load(fullfile(dirpath.SubDir_MatDir,sprintf('%s.mat',FolderNames{i})));
            if EEG.srate~=params.desFs
                fprintf('Sub %s (%d of %d): WARNING: Sampling rate ~= %d--resampling...\n',SubNum,i,length(FolderNames),params.desFs)
                EEG = pop_resample(EEG,params.desFs); %resample to desired sampling rate
                save(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample','.mat']),'EEG','-mat','-v7.3');
            else
                fprintf('Sub %s (%d of %d): Data sampling rate is already %d (the desired Fs)--skipping...\n',SubNum,i,length(FolderNames),params.desFs)
            end
            EEG.info=sprintf('processed on %s',datestr(now,2));
    end
    [~,changes]=eeg_checkset(EEG);
    %-----------------------------------------
    %% 3. remove external channels,verify channel data, and get chanlocs
    %-----------------------------------------

    CephalicChans=find(strcmp({EEG.chanlocs.labels}','EXG1'))-1; %identify index of the first external (non-cephalic) chanenl
    if isempty(CephalicChans) %if data does not have external channels
        CephalicChans=length(EEG.chanlocs);
    end
    fprintf('Sub %s (%d of %d): Verifying data on %d cephalic chans..\n',SubNum,i,length(FolderNames),CephalicChans)
    ChanData=[];
    for j=1:CephalicChans
        ChanData(j)=CheckIfChanHasData(EEG,j);
    end
    if ~all(ChanData==1) %if not all channels have data
        CephalicChans=find(ChanData,1,'last'); %find the last channel that has data
        fprintf('WARNING: Sub %s (%d of %d): Some channels do not contain real data...\n',SubNum,i,length(FolderNames))
        fprintf('WARNING: Sub %s (%d of %d): Chan %d identified is the last channel containing real data...\n',SubNum,i,length(FolderNames),CephalicChans) 
    end
    EEG.data=EEG.data(1:CephalicChans,:); %set the EEG struct equal to data from cephalic electrodes only 
    chanlocs=GetChanlocs(CephalicChans);
    fprintf('Sub %s (%d of %d): %d cephalic channels identified--loading ChanLocs file...\n',SubNum,i,length(FolderNames),length(chanlocs))
    EEG.chanlocs=chanlocs;
    EEG.nbchan=CephalicChans;
    EEG.params=params;
    LogFile{i,2}=length(EEG.chanlocs);
    [~,changes]=eeg_checkset(EEG);
    %------------
    %% 4. filter
    %------------
    %NEW: remove line noise 11/9/22
    switch params.RunICA
        case {'Y','y','Yes','yes'}
            StepCompleted=CheckIfStepCompleted(dirpath,'_resample_filter4ica','MatDir','chanrej');
            switch StepCompleted
                case 1
                    fprintf('Sub %s (%d of %d): Filtering for ICA already completed--loading data...\n',SubNum,i,length(FolderNames));
                    load(fullfile(dirpath.SubDir_MatDir,sprintf('%s_resample_filter4ica.mat',SubNum)));
                    load(fullfile(dirpath.SubDir_MatDir,sprintf('%s_resample_filter.mat',SubNum)));
                case 0
                    fprintf('Sub %s (%d of %d): Cleaning line noise...\n',SubNum,i,length(FolderNames))
                    EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',[1:CephalicChans] ,...
                        'computepower',1,'linefreqs',60,'newversion',0,'normSpectrum',0,...
                        'p',0.01,'pad',2,'plotfigures',0,'scanforlines',0,'sigtype',...
                        'Channels','taperbandwidth',2,'tau',100,'verb',1,'winsize',4,'winstep',1);
                    EEG = pop_eegfiltnew(EEG,'hicutoff',params.lPass,'plotfreqz',1); %low pass filter - 12/12/22
                    saveas(gcf,fullfile(dirpath.SubDir_PlotDir,[SubNum,'_lpf.fig']));
                    EEG_ica=EEG; %low pass filtered already
                    EEG = pop_eegfiltnew(EEG,'locutoff', params.hPass,'plotfreqz',1); %high pass filter for EEG - 12/12/22
                    saveas(gcf,fullfile(dirpath.SubDir_PlotDir,[SubNum,'_hpf_eeg.fig']));
                    fprintf('Sub %s (%d of %d): High pass filtering for ICA...\n',SubNum,i,length(FolderNames)) %11/18/22 - changed to length(FolderNames)
                    EEG_ica = pop_eegfiltnew(EEG_ica, 'locutoff',params.hPass_ica,'plotfreqz',1); %high pass filter it for ICA - 12/12/22
                    saveas(gcf,fullfile(dirpath.SubDir_PlotDir,[SubNum,'_hpf_ica.fig']));
                    save(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter4ica','.mat']),'EEG_ica','-mat','-v7.3');
                    save(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter','.mat']),'EEG','-mat','-v7.3');
            end
        case {'N','n','No','no'}
            StepCompleted=CheckIfStepCompleted(dirpath,'_resample_filter','MatDir','chanrej','ica');
            switch StepCompleted
                case 1
                    fprintf('Sub %s (%d of %d): Data already filtered--loading data...\n',SubNum,i,length(FolderNames));
                    load(fullfile(dirpath.SubDir_MatDir,sprintf('%s_resample_filter.mat',SubNum)));
                case 0
                    fprintf('Sub %s (%d of %d): Filtering data...\n',SubNum,i,length(FolderNames))
                    EEG = pop_eegfiltnew(EEG,'hicutoff',params.lPass,'plotfreqz',1); %low pass filter - 12/12/22
                    EEG = pop_eegfiltnew(EEG,'locutoff', params.hPass,'plotfreqz',1); %high pass filter for EEG - 12/12/22
                    save(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter','.mat']),'EEG','-mat','-v7.3');
            end
    end
    [EEG,changes]=eeg_checkset(EEG);
    %-----------------
    %% 5. channel rejection
    %-----------------
    StepCompleted=CheckIfStepCompleted(dirpath,'_resample_filter_chanrej','MatDir','reref');
    switch StepCompleted
        case 1 %step completed - load output
            fprintf('Sub %s (%d of %d): Channel rejection already completed--loading data...\n',SubNum,i,length(FolderNames))
            load(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter_chanrej','.mat']))
        case 0 %step not completed
            load(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter','.mat']));
            fprintf('Sub %s (%d of %d): Computing channels for rejection based on kurtosis and joint probability...\n',SubNum,i,length(FolderNames))
            [EEG,badChans]=ChannelRejection(EEG,ManualOverride,params); %identify channels for rejection
            switch params.RunICA
                case {'Y','y','Yes','yes'}
                    load(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter4ica','.mat']));
                    EEG_ica.reject.indelec=badChans;
                    EEG_ica=pop_select(EEG_ica,'nochannel',badChans);
                    EEG_ica=pop_interp(EEG_ica,chanlocs,'spherical'); %added 11/10/22
                    save(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter4ica_chanrej','.mat']),'EEG_ica','-mat','-v7.3');
                    fprintf('Sub %s (%d of %d): Saving data structure with bad channels interpolated for ICA..\n',SubNum,i,length(FolderNames))
            end
            EEG.reject.indelec=badChans;
            EEG=pop_select(EEG,'nochannel',badChans);
            EEG = pop_interp(EEG,chanlocs,'spherical');
            fprintf('Sub %s (%d of %d): Saving data structure with bad channels interpolated...\n',SubNum,i,length(FolderNames))
            EEG.reject.indelec=badChans;
            save(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter_chanrej','.mat']),'EEG','-mat','-v7.3');
    end
    ChanRej_Flag=length(EEG.reject.indelec)>length(EEG.chanlocs)*.15;
    switch ChanRej_Flag
        case 1
            fprintf('Sub %s (%d of %d): Flagging data for excessive channel rejection...\n',SubNum,i,length(FolderNames))
            LogFile{i,8}='Y';
    end
    LogFile{i,3} = length(EEG.reject.indelec);
    LogFile{i,4} = {chanlocs(EEG.reject.indelec).labels};
    [EEG,changes]=eeg_checkset(EEG);
    %-----------------------------
    %% 6. rereference
    %-----------------------------
    switch params.RunICA
        case {'y','Y','Yes','yes'}
            StepCompleted=CheckIfStepCompleted(dirpath,'_resample_filter4ica_chanrej_reref','MatDir','ICA');
            switch StepCompleted
                case 1
                    fprintf('Sub %s (%d of %d): Rereferencing already completed--loading data...\n',SubNum,i,length(FolderNames))
                    load(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter4ica_chanrej_reref','.mat']));
                    load(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter_chanrej_reref','.mat']));
                case 0
                    fprintf('Sub %s (%d of %d): Rereferencing to the common average...\n',SubNum,i,length(FolderNames))
                    EEG = pop_reref(EEG,[]);
                    fprintf('Sub %s (%d of %d): Rereferencing to the common average for ICA...\n',SubNum,i,length(FolderNames))
                    EEG_ica = pop_reref(EEG_ica,[]);
                    save(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter4ica_chanrej_reref','.mat']),'EEG_ica','-mat','-v7.3');
                    save(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter_chanrej_reref','.mat']),'EEG','-mat','-v7.3');
            end
        case {'n','N','no','No'}
            StepCompleted=CheckIfStepCompleted(dirpath,'_resample_filter_chanrej_reref','MatDir');
            switch StepCompleted
                case 1
                    fprintf('Sub %s (%d of %d): Rereferencing already completed--loading data...\n',SubNum,i,length(FolderNames))
                    load(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter_chanrej_reref','.mat']))
                case 0
                    fprintf('Sub %s (%d of %d): Rereferencing to the common average...\n',SubNum,i,length(FolderNames))
                    EEG = pop_reref(EEG,[]);
                    save(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter_chanrej_reref','.mat']),'EEG','-mat','-v7.3');
            end
    end
    [EEG,changes]=eeg_checkset(EEG);
    %-----------------
    %% 7. ICA
    %-----------------
    StepCompleted=CheckIfStepCompleted(dirpath,'_resample_filter_chanrej_reref_ICAweightTransfer_BadCompRej','MatDir','.set'); %11/18/22 - added '.set' as an exclusionary string
    switch StepCompleted
        case 1
            switch params.RunICA
                case 'y'
                    fprintf('Sub %s (%d of %d): ICA already completed--loading data...\n',SubNum,i,length(FolderNames))
                    load(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter_chanrej_reref_ICAweightTransfer_BadCompRej','.mat']));
            end
        case 0
            switch params.RunICA
                case {'Y','y','Yes','yes'}
                    fprintf('Sub %s (%d of %d): Performing ICA. This may take up to 1 hour...\n',SubNum,i,length(FolderNames))
                    load(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter4ica_chanrej_reref','.mat']))                   
                    [EEG_ica,bad_components] = PerformICA(EEG_ica);
                    save(fullfile(dirpath.SubDir_MatDir,[FolderNames{i},'_resample_filter4ica_chanrej_reref_ICA','.mat']),'EEG_ica','-mat','-v7.3');
                    fprintf('Sub %s (%d of %d): Transfering ICA weights from EEG_ica struct to EEG struct...\n',SubNum,i,length(FolderNames))
                    EEG = ICAtransferWeights(EEG_ica,EEG);
                    EEG = eeg_checkset(EEG);
                    fprintf('Sub %s (%d of %d): Saving results of ICA...\n',SubNum,i,length(FolderNames))
                    save(fullfile(dirpath.SubDir_MatDir,[FolderNames{i},'_resample_filter_chanrej_reref_ICAweightTransfer','.mat']),'EEG','-mat','-v7.3');
                    fprintf('Sub %s (%d of %d): Plotting bad components...\n',FolderNames{i},i,length(FolderNames))
                    Plot_Components(EEG,bad_components,FolderEnding,dirpath)
                    fprintf('Sub %s (%d of %d): Removing %d bad components...\n',FolderNames{i},i,length(FolderNames),length(bad_components))
                    EEG = pop_subcomp( EEG, [bad_components], 0); %excluding the bad component; 11/18/22 - KW noticed that this removes ICA activation matrix
                    EEG.info=sprintf('processed on %s by Kamy Wakim-Takaki: %s',datestr(now,2),FolderEnding);
                    EEG = eeg_checkset(EEG); %11/18/22 - added
                    save(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter_chanrej_reref_ICAweightTransfer_BadCompRej','.mat']),'EEG','-mat','-v7.3');
                    EEG=pop_saveset(EEG,'filename',[FolderNames{i},'_resample_filter_chanrej_reref_ICAweightTransfer_BadCompRej','.set'],'filepath',dirpath.SubDir_MatDir);
                case {'N','n','No','no'}
                    fprintf('Sub %s (%d of %d): User selected not to run ICA--skipping this step...\n',SubNum,i,length(FolderNames))
            end
    end
    [EEG,changes] = eeg_checkset(EEG);
    close all
    %-----------------------
    %% 8. epoch, baseline, trial rej
    %------------------------
    StepCompleted=CheckIfStepCompleted(dirpath,sprintf('_raw%s',params.additional_erp_str),'ERPdir');
    switch StepCompleted
       case 1
           fprintf('Sub %s (%d of %d): Data already epoched--loading data...\n',SubNum,i,length(FolderNames))
           load(fullfile(dirpath.SubDir_ERPdir,[SubNum,sprintf('_raw%s',params.additional_erp_str),'.mat']));
       case 0
           switch params.RunICA
               case {'Y','y','yes','Yes'}
                   load(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter_chanrej_reref_ICAweightTransfer_BadCompRej','.mat']));
               case {'N','n','no','No'}
                   load(fullfile(dirpath.SubDir_MatDir,[SubNum,'_resample_filter_chanrej_reref','.mat']));
           end
            TrialRej={};
            ERPs=cell(1,length(params.trigs));
            for j=1:length(params.trigs)
                [ERPs,TrialRej_cond]=EpochBaselineTrialRej(EEG,ERPs,j,params);
                ERPs{j}.TrialRej_EEG = TrialRej_cond;
                ERPs{j}.condition=params.trig_names{j};
            end
            ERPs{1,1}.ResponseIndex=CalculateResponseIndex(EEG,1);
            EEG.info=sprintf('processed on %s',datestr(now,2));
            save(fullfile(dirpath.SubDir_ERPdir,sprintf('%s_epoched%s.mat',SubNum,params.additional_erp_str)),'ERPs','-mat','-v7.3');
    end
    %--------------------------------
    %% 9. Plots for QC
    %--------------------------------
    fprintf('Sub %s (%d of %d): Plotting individual subject data for QC...\n',SubNum,i,length(FolderNames))
    Plot_IndivSub_Topo(ERPs{1},dirpath,params);
    Plot_IndivSub_ERP(ERPs{1},dirpath,params);
    %--------------------------------
    %% 10. Finalize
    %--------------------------------
    LogFile{i,6} = ERPs{1,1}.ResponseIndex;
    ResponseIndex_Flag=ERPs{1,1}.ResponseIndex>2||ERPs{1,1}.ResponseIndex<.3;
    switch ResponseIndex_Flag
        case 1
            fprintf('Sub %s (%d of %d): Flagging data for excesssive button pressing...\n',SubNum,i,length(FolderNames))
            LogFile{i,8}='Y';
    end
    TrialRej_all=cell(1,length(ERPs));
    for j=1:length(ERPs)
        TrialRej_all{j}=ERPs{j}.TrialRej_EEG;
    end
    NumTrials_all=cell(1,length(ERPs));
        for j=1:length(ERPs)
            NumTrials_all{j}=size(ERPs{j}.data,3);
        end
    LogFile{i,5}={TrialRej_all};
    LogFile{i,7}={NumTrials_all};
    TrialRej_Flag=ERPs{1,1}.TrialRej_EEG > 50;
    switch TrialRej_Flag
        case 1
            fprintf('Sub %s (%d of %d): Flagging data for excessive trial rejection...\n',SubNum,i,length(FolderNames))
            LogFile{i,8}='Y';
    end
end
diary off
fprintf('Saving composite log file for all %d subjects...\n',length(FolderNames))
LogFile=cell2table(LogFile,'VariableNames',names);
save(fullfile(dirpath.ProcessingLogDir,sprintf('Log_%dsubs%s_%s.mat',length(FolderNames),FolderEnding,datestr(now,'mmddyy'))),'LogFile','-mat','-v7.3')
disp('Done!')
