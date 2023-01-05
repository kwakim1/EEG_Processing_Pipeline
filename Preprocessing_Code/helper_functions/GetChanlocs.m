function [chanlocs] = GetChanlocs(CephalicChans)
%11/11/21 - KW
%reads in EEG data, detects number of celphalic channels, and loads
%approrpiate chanlocs file

switch CephalicChans %number of cephalic channels
    case 64
        load('chanlocs64.mat');
    case 128
        load('chanlocs128.mat');
    case 160
        load('chanlocs160.mat')
    otherwise
        error('Subject has a weird number of electrodes--check raw data or modify this script')
end
end