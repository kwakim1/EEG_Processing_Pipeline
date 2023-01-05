function [params] = GetParams()
%1/28/22 - Script to load up params and specs for EEG processing
%12/15/22 - KW updating documentation for github
%1/5/23 - KW edited

%Input
    %None

%Output
    %params = struct. contains all the fields specified below. params will
    %be fed as input to many scripts in RUNME.mat to preprocess data

%Example usage
 %[params] = GetParams()

% -----------------------------------------------------

params.expname='My_Science_Experiment'; %name your experiment!
params.trig_names={'Trig1','Trig2','Trig3','Trig4'}; %change to strings that are meaningful to your task

%----------------
%filtering params
%----------------
params.desFs = []; %sampling rate in Hz, e.g. 512
params.hPass = []; %high pass filter in Hz, e.g. 1
params.lPass = []; %low pass filter in Hz, e.g. 45
params.hPass_ica = []; %high pass filter to be applied to data before ICA in Hz, e.g. 2


%-------------------
%epoching parameters
%-------------------
params.tmin=[]; %time in ms to start epoch, e.g. -100ms
params.tmax=[]; %time in ms for upper bound of epoch, e.g. 1000 ms
params.blmin=[]; %time in ms for the beginning of the baseline, e.g. -100 ms
params.blmax=[]; %time in ms for upper bound of baseline period, e.g. 0 ms
params.trigs={{' ',' ',' '},' ',' ',' ' }; %triggers to be epoched as they appear in your data. can accept any number of triggers as input. When two conditions are combined in curly brackets, this groups them together like an "and" statement
params.ResponseCond=[]; %trigger corresponding to button press response, e.g. 1
params.Analysis='stimulus_locked'; %must be set to 'stimulus_locked' or 'response_locked' depending on the desired analysis
params.additional_erp_str='';

assert(abs(params.blmin) > abs(params.tmin),'Must baseline within epoch--make sure that abs(params.timin) > abs(params.blmin)')
assert(params.tmin < params.tmax,'Invalid epoch because params.timin is not less than params.tmax')
assert(isequal(length(params.trig_names),length(params.trigs)),'Verify that the length of params.trigs is equal to params.trig_names (there needs to be a name for every trigger)')


%------------------------------------
%channel / trial rejection parameters
%------------------------------------
params.thr1=[]; %voltage threshold for trial rejection in microvolts, e.g. 150 uV
params.ChanRejThresh=[]; %channel rejection threshold in standard deviations for pop_chanrej function, e.g. 5
params.BadChanThresh=[]; %percentage of allowable bad channel rejection, e.g. .15 (15% of channels)
params.NumTrialsRemaining_thresh=[] ;%flag if participant has fewer than X trials total,e.g. 150


%-----
%other
%-----
params.RunICA=' '; %set to 'y' or 'n' depending on whether you want to run ICA
params.deschan=' '; %desired channel for QC plotting
params.descond=[]; %desired condition for QC plotting
end