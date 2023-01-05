function [EEG,badChans] = ChannelRejection(EEG,ManualOverride,params)
%11/19/21 - KW
%identfies channels for rejection based on joint probability, kurtosis, and
%manual inspection
%12/15/22 - KW updating documentation for github

%Input
    %EEG = struct from EEG lab containg single-subject continuous data
    %ManualOverride = string. Path to a spreadsheet containing subject
        %numbers (column 1) and the indices of electrodes that the experimenter
        %wants to manually reject (all other columns)
    %params = a struct that contains the following fields: 
        %ChanRejThresh = double. This is a threshold set by the experimenter
            %(e.g. 5 standard deviations)
        %BadChanThres = double. percentage thresholds set by experimenter, e.g.
            %.15 of the maximum percentage of electrodes that can be rejected

%output
    %EEG = updated subject-level EEG struct
    %badChans = double. list of bad channels to be rejected, e.g. [1 17 32]

%5/4/22 - edited to remove SubNum as an input argument
%9/19/22 - added eeg_checkset to verify output structure

[~,idx1] = pop_rejchan(EEG,'elec',1:EEG.nbchan,'threshold',params.ChanRejThresh,...
        'norm','on','measure','prob');
[~,idx2] = pop_rejchan(EEG,'elec',1:EEG.nbchan,'threshold',params.ChanRejThresh,...
    'norm','on','measure','kurt');
badChans = unique([idx1,idx2]);
EEG.chanRejThresh=sprintf('%d STD',params.ChanRejThresh);
if ~isempty(ManualOverride)
    id_row=find(ManualOverride==str2num(EEG.subject));
    if ~isempty(id_row) %if a subject has electrodes slated for manual rejection.
        badChans=[badChans,ManualOverride(id_row,2:end)];
        badChans=badChans(~isnan(badChans));
        badChans=unique(badChans);
        fprintf('Sub %s: Manually rejecting bad channels...\n',EEG.subject);
        EEG.reject.manualreject=ManualOverride(id_row,2:end);
    else
        fprintf('Sub %s: No bad channel to manually reject...\n',EEG.subject);
    end
end
fprintf('Sub %s: %d bad channels (%d of total)...\n',EEG.subject,numel(badChans),round((length(badChans)/length(EEG.chanlocs)*100)))
if numel(badChans)>length(EEG.chanlocs)*params.BadChanThresh
     fprintf('WARNING!!! Subject %s has more than %d bad channels!\n',EEG.subject,params.BadChanThresh); %check if subject has more than 20% (nChans*.2) bad channels 
end
fprintf('Sub %s: Flagging bad channels for removal...\n',EEG.subject)
EEG=eeg_checkset(EEG); %added 9/19/22
end