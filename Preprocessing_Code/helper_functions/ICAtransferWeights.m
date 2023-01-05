function [EEG] = ICAtransferWeights(EEG_ica,EEG)
%11/15/21 - KW, Transfer ICA weights
%9/19/22 - added eeg_checkset to verify output structure


%input
    %EEG_ica - a struct of EEG data which has undergone ICA
    %EEG - a struct of the same original EEG data which has not undergone
    %ICA
%output
    %EEG - original EEG data now with fields containing ICA weights

    EEG.icaweights = EEG_ica.icaweights; 
    EEG.icasphere = EEG_ica.icasphere; 
    EEG=eeg_checkset(EEG); %added 9/19/22 - should recompute ICA activations
end