function [ResponseIndex] = CalculateResponseIndex(EEG,TargetEvent)
%12/7/21 - KW
% Calculates the percentage of the occurance of a target event relative to
%all other events in an EEG structure

%Input:
    %EEG = struct. Continuous EEG data processed in EEGlab
    %TargetEvent = double. The identity of the target event you want to
        %calculate the occurance of, e.g. 1

%Output
    %ResponseIndex = double. (Number of target event occurances) / (Number
    %Non-target event occurances)
    
%Example Call
    %ResponseIndex=CalculateResponseIndex(EEG,1)

events=[EEG.urevent(:).edftype]';
NumTargetEvent=sum(events(:)==TargetEvent);
NumNonTargetEvent=length(events)-NumTargetEvent;
ResponseIndex=NumTargetEvent/NumNonTargetEvent;

end