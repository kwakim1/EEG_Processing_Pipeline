function [HasData] = CheckIfChanHasData(EEG,deschan)
%1/28/22 - checks if a channel is empty or if contains data. Returns 0 if
%the channel is empty, 1 if the channel has data

%NOTE: channels that don't have data have different profiles... some have
%random spikes at 1000 samples, others have a constant near-zero value the
%whole time.

%Input
    %EEG = struct. EEG lab structure containing continuous data
    %deschan = double. channel you want to check, e.g. 65

%Output
    %HasData = double. 0 if channel does not have real EEG data, 1 if it
    %does have real EEG data

%Example call: HasData = CheckIfChannelHasData(EEG,65)

%check if data are 0 over a long period of time
Check1=abs(mean(EEG.data(deschan,1:900)))<10e-13;
%check if data have a constant value
Check2=isequal(max(EEG.data(deschan,:)),min(EEG.data(deschan,:)));
if isequal(Check1,1)||isequal(Check2,1);
    HasData=0;
else
    HasData=1;
end



end