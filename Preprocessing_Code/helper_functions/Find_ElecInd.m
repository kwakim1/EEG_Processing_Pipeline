function [ElecInds] = Find_ElecInd(chanlocs,des_chan)
%2/23/22 - finds the index in chanlocs of specific electrodes

%Input
    %chanlocs = struct. from eeglab, gives the names and coordinates of
        %electrodes in whatever cap you are using
    %deselec = cell. cell array of strings containing electrodes whose
        %indices you want to find, e.g. {'Fz','Cz'} (or, if only one
        %electrode is desired, {'Fz'}

%Output
    %ElecInds=double. indices of electrodes specified in deselec, e.g.
         %[1,15]
labels={chanlocs.labels};
ElecInds=[];
for i=1:size(des_chan,2) %for all electrodes specified in deselec
    elec=find(ismember(labels,des_chan{i})==1);
    ElecInds=[ElecInds,elec];
end
assert(~isempty(elec),'desired electrodeis not in electrode montage (or montage employs a different labeling scheme, such as A1, A2 etc)--modify params.deschan in GetParams.m')