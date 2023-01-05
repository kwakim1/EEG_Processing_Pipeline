function [ERPs,TrialRej] = EpochBaselineTrialRej(EEG,ERPs,cond,params)
%11/19/21 - Epochs data, removes baseline, and rejects epochs based on
%absolute voltage and standard deviation from other trials

%5/4/22 - edited by KW
%9/19/22 - added eeg_checkset to verify output structure

%Input:
    %EEG = struct of single-subject EEG data from EEGlab
    %SubNum = string. Subject ID number e.g. '1161'
    %cond = double. task condition you want to epoch, e.g. condition 1
    %params = structure containing fields indicating rejection thresholds,
        %epoch time limits, etc. this

%Output:
    %ERPs = struct with data epoched for each condition
    %TrialRej = double. number of rejected trials per
        %conditon


if isequal(class(params.trigs{cond}),'cell')
    ERPs{cond} = pop_epoch(EEG,[params.trigs{cond}],[params.tmin/1e3,params.tmax/1e3]);
else
    ERPs{cond} = pop_epoch(EEG,[params.trigs(cond)],[params.tmin/1e3,params.tmax/1e3]);
end
NumTrialsBeforeRej=size(ERPs{cond}.data,3);
ERPs{cond} = pop_rmbase(ERPs{cond},[params.blmin,params.blmax]);
ERPs{cond} = pop_eegthresh(ERPs{cond},1,1:size(ERPs{1}.data,1),-params.thr1,params.thr1,params.tmin/1e3,params.tmax/1e3,0,1); %ERPs{1}.data = num channels
maxVals = squeeze(max(max(abs(ERPs{cond}.data(1:size(ERPs{1}.data,1),:,:)))));
thr2 = median(maxVals) + 3*median(abs(maxVals-median(maxVals)));
ERPs{cond} = pop_eegthresh(ERPs{cond},1,1:size(ERPs{1}.data,1),-thr2,thr2,params.tmin/1e3,params.tmax/1e3,0,1);
TrialRej=(NumTrialsBeforeRej-size(ERPs{cond}.data,3))/NumTrialsBeforeRej*100;
ERPs{cond}=eeg_checkset(ERPs{cond}); %9/19/22 - added eeg_checkset
end