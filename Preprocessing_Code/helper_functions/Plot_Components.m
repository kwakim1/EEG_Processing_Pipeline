function [] = Plot_Components(EEG,bad_components,formatspec,dirpath)
%11/30/21 KW - Plot components
%5/9/22 - documentation updated

%Input
    %EEG - struct. output from EEGlab after run_ica.
    %bad_components - double. number of components to reject based on iclabel
    %formatspec - string. appended to the end of subfolders within
        %subject-level folders
    %dirpath - struct. has fields containing path to key directories

%Output
    %(1) PNG of rejected components
    %([SubNum]_bad_ICs_topos_[formatspec].png)
    %(2) PNG of all components ([SubNum]_all_ICs_topos_[formatspec])

%Example Call
    %Plot_Components(EEG,5,'_stimonset',dirpath)

%-----------------

if length(bad_components) >= 1
    pop_topoplot(EEG, 0, [bad_components bad_components],EEG.subject ,0,'electrodes','on');
    saveas(gcf,fullfile(dirpath.SubDir_PlotDir,sprintf('%s_bad_ICs_topos%s.png',EEG.subject,formatspec))); 
end
fprintf('Sub %s: Plotting all components...\n',EEG.subject)
pop_topoplot(EEG, 0, 1:size(EEG.icaweights,1) ,EEG.subject,[ceil(sqrt(size(EEG.icaweights,1))) ceil(sqrt(size(EEG.icaweights,1)))] ,0,'electrodes','on','iclabel','on');
saveas(gcf,fullfile(dirpath.SubDir_PlotDir,sprintf('%s_all_ICs_topos%s.png',EEG.subject,formatspec)))

end