function [] = Plot_IndivSub_ERP(ERPs,dirpath,params)

%KW - 11/5/21
%plot individual subject ERPs. Save .png output in each subject'sfolder

%input:
    %dirpath = struct. contains string of filepath including a field for
        %'ParentDir'
   %params = struct. contains fields for necessary parameters including
   %'deschan' and 'descond'
    %formatspec = string. If you want to plot data stored in a directory
         %whose naming structure does not follow the traditional [subnum]_erp,
        %include an extra things indicating which folder your data can be
        %found. For example, if the folder containing your data is titled
        %[subnum]_erp_NoICA_JointKurt, then formatspec should be
        %'_NoICA_JointKurt'
    %type = string. takes on the value of 'raw' or 'cleaned' depending on
        %which type of ERP you want to plot

%example call:
    %Plot_IndivSub_ERP(dirpath,params,'_NoICA_JointKurt','cleaned')


t=ERPs.times;
chanlocs=ERPs.chanlocs;
elec = Find_ElecInd(chanlocs,{params.deschan});
figure
hold on
plot(t,mean(squeeze(ERPs.data(elec,:,:)),2))
xline(0,'--');
title(sprintf('%s, Elec. %s, Cond %d',ERPs.subject,params.deschan,params.descond),'interpreter','none');
l=legend;
txt=annotation('textbox');
txt.String={sprintf('%s',ERPs.group),...
    sprintf('NumTrials = %d',size(ERPs.data,3))};
txt.Position=[l.Position(1),l.Position(2)*.3,l.Position(3),l.Position(4)];
txt.LineStyle='None';
l=legend('off');
saveas(gcf,fullfile(dirpath.SubDir_PlotDir,sprintf('%s_%s_cond%d.png',ERPs.subject,params.deschan,params.descond)));

end
