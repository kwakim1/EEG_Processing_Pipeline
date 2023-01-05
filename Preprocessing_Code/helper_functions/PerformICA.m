function [EEG_ica,bad_components] = PerformICA(EEG_ica)
%11/15/21 - KW, Performs ICA and identifies bad components
%(kamywakim@gmail.com)
%9/19/22 - added eeg_checkset to verify output structure


%Input:
    %EEG_ica - structure containing 1hz HPF single-subject EEG data
%Output:
    %EEG - updated structure containing the results of ICA
    %bad_components - array of doubles containing indices of bad ICA
        %components, e.g. [1,3,4,5] indicating that components 1,3,4 and 5
        %represent eye components

%5/4/22 - verified by KW
pca = EEG_ica.nbchan-1; %the PCA part of the ICA needs stops the rank-deficiency 
EEG_ica = pop_runica(EEG_ica, 'extended',1,'interupt','on','pca',pca); %using runica function, with the PCA part
EEG_ica = iclabel(EEG_ica); %does ICLable function
ICA_components = EEG_ica.etc.ic_classification.ICLabel.classifications ; %creates a new matrix with ICA components
ICA_components(:,8) = ICA_components(:,3); %row 1 = Brain row 2 = muscle row 3= eye row 4 = Heart Row 5 = Line Noise row 6 = channel noise row 7 = other, combining this makes sure that the component also gets deleted if its a combination of all.
bad_components = find(ICA_components(:,8)>0.80 & ICA_components(:,1)<0.05); %if the new row is over 80% of the component and the component has less the 5% brain
EEG_ica=eeg_checkset(EEG_ica); %added 9/19/22
end