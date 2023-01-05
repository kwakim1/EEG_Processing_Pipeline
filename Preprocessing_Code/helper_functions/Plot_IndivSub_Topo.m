function [] = Plot_IndivSub_Topo(ERPs,dirpath,params)
%9/25/22 - edited to take single-sub data as input argument


%plot indivsub topo - 11/8/21, KW (kamywakim@gmail.com)
%plots topo in 50ms bins from begining of epoch to end of epoch

%input:
    %ParentDir = string. filepath for directory containing subject-level
        %directories
    %formatspec = string. If you want to plot data stored in a directory
         %whose naming structure does not follow the traditional [subnum]_erp,
        %include an extra things indicating which folder your data can be
        %found. For example, if the folder containing your data is titled
        %[subnum]_erp_NoICA_JointKurt, then formatspec should be
        %'_NoICA_JointKurt'
    %descond = struct. contains fields of user specification. see script
        %GetParams.m. relevant fields for this script is descond
    %data_type = string, taking on the value of 'raw' or 'cleaned' depending on
        %which ERPs the user wants to plot

%example call:
    %Plot_IndivSub_Topo(dirpath,params,'_NoICA_JointKurt','cleaned')


t=ERPs.times;
fs=ERPs.srate;
binlength=0.05;
numrows=4;
maplimits=[-8,8];
chanlocs=ERPs.chanlocs;
binsamples=floor(fs*binlength); %bin length in samples
numtopos2plot=floor(length(t)/binsamples); %num topos to be plotted for each sub
numcols=ceil(numtopos2plot/numrows); %num columns to plot
topodata=squeeze(mean(ERPs.data,3)); %mean across trials
figure
for j=1:numtopos2plot
    hold on
    f=subplot(numrows,numcols,j);
    if j==1
        topoplot(mean(topodata(:,1:binsamples),2),chanlocs,'electrodes','on','maplimits',maplimits);
        title(sprintf('t = [%d,%dms]',round(t(1)),round(t(binsamples))))
         cbar('vert',0,maplimits);
    else
        topoplot(mean(topodata(:,(j-1)*binsamples:j*binsamples),2),chanlocs,'electrodes','on','maplimits',maplimits);
        title(sprintf('t = [%d,%dms]',round(t(binsamples*(j-1))),round(t(binsamples*j))))
        cbar('vert',0,maplimits);
    end
end
title(sprintf('%s cond %s',ERPs.subject,params.descond))
subtitle(sprintf('n=%d',size(ERPs.data,3)))
saveas(gcf,fullfile(dirpath.SubDir_PlotDir,sprintf('%s_IndivSubTopo.png',ERPs.subject)));
