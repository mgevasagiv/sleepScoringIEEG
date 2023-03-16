function plotHypnogram_perChannel(PtList, headerFileFolder, source_folder, channel, chArea, restrictedT)

params.lowCut = .5;
params.highCut = 30;
params.ds_SR = 200;

pt = PtList.subj;
exp =  PtList.Nsessions;
a = dir(fullfile(headerFileFolder, sprintf('p%03d_EXP%d_dataset.mat',pt,exp)));
if isempty(a)
    disp(sprintf('file %s not found', sprintf('p%03d_EXP%d_dataset.mat',pt,exp)))
end
load(fullfile(headerFileFolder, sprintf('p%03d_EXP%d_dataset.mat',pt,exp)))

cd(source_folder);
a = dir((sprintf('CSC%d.mat',channel)));
if isempty(a)
    disp(sprintf('data for hypnogram not found: p%03d EXP%d ch%d',pt,exp,channel))
    return
end
load(sprintf('CSC%d.mat',channel))

%% plot spectrogram for selected electrodes
scaling_factor_delta_log = 2*10^-4 ; % Additive Factor to be used when computing the Spectrogram on a log scale

figure_name_out = sprintf('wholeRecSpectrogram_%s_E%d_ch%d_%s',header.id,header.experimentNum, channel, chArea);
figure('Name', figure_name_out,'NumberTitle','off');
set(gcf,'PaperUnits','centimeters','PaperPosition',[0.2 0.2 21 30]); % this size is the maximal to fit on an A4 paper when printing to PDF
set(gcf,'PaperOrientation','portrait');
set(gcf,'Units','centimeters','Position', get(gcf,'paperPosition')+[1 1 0 0]);
colormap('jet');
set(gcf,'DefaultAxesFontSize',20);
axes('position',[0.1,0.5,0.8,0.4])

flimits = [0 30];
data(isnan(data)) = 0;
data_ds = accurateResampling(data(1:end), 1000, params.ds_SR);
%[b,a]=ellip(2,0.1,40,[params.lowCut params.highCut]*2/params.ds_SR);
%filteredBlock=filtfilt(b,a,data_ds);
window = 30*params.ds_SR;
[S,F,T,P]  = spectrogram(data_ds,window,0.8*window,[0.5:0.2:flimits(2)],params.ds_SR,'yaxis');
P = P/max(max(P));
P1 = (10*log10(abs(P+scaling_factor_delta_log)))';
P1 = [P1(:,1) P1 P1(:,end)];
T = [0 T T(end)+1];
Pplot = imgaussfilt(P1',3);

imagesc(T,F,Pplot,[-40,-5]);axis xy;
xlimits = [0 T(end)];
xticks = 1:(60*60):T(end);
for ii = 1:length(xticks)
    xlabel_str{ii} = num2str(floor((xticks(ii)/(60*60))));
end

yticks = 0:5:30;
axis([xlimits flimits])
set(gca,'xtick',xticks,'XTickLabel',xlabel_str)
colorbar
title_str = sprintf('%s, E%d, channel %d (%s)',header.id,header.experimentNum, channel, chArea);
axis([get(gca,'xlim'),[0.5,30]])
set(gca,'ytick',[0.5,10,20,30])
YLIM = get(gca,'ylim');

hold all;
if isfield(EXP_DATA,'stimTiming')
    if ~isempty(strfind(pwd,'MACRO'))
        plot(EXP_DATA.stimTiming.validatedTTL_NLX/(1000)',YLIM(2)*0.9,'r.')
    else
        plot(EXP_DATA.stimTiming.validatedTTL_BR_msec/(1000)',YLIM(2)*0.9,'r.')
    end
end
xlabel('t (hr)')
ylabel('f (Hz)')
title(title_str)

axes('position',[0.1,0.1,0.8,0.2])
try
    start_time = datenum(LocalHeader.NLXfilesStartTime{1});
    if length(LocalHeader.NLXfilesStartTime) > 1
        if datenum(LocalHeader.NLXfilesStartTime{2}) < datenum(LocalHeader.NLXfilesStartTime{1})
            % Many times NLX numbering is reversed
            start_time = datenum(LocalHeader.NLXfilesStartTime{2});
        end
    end
    end_time = datenum(LocalHeader.NLXfilesEndTime{end});
catch
    start_time = datenum('2017/10/21 00:00:00');
    hh = round(diff([T(1), T(end)])/(60*60));
    if hh >= 1
        mm = round(diff([T(1), T(end)])/60 - hh*60);
    else
        hh = 0;
        mm = round(diff([T(1), T(end)])/60)
    end
    end_time = datenum(sprintf('2017/10/21 %02d:%02d:00',hh,mm));
end

xData = linspace(start_time,end_time,length(T));
ah = imagesc(xData,F,Pplot,[-40,-5]);axis xy;
axis([get(gca,'xlim'),[0.5,20]])
set(gca,'ytick',[0.5,10,20])
datetick('x','HH:MM PM','keeplimits')
% set(gca,'xtick',linspace(start_time,end_time,4))
colorbar

PPT_FIG = 0;
if PPT_FIG
    newA4figure(figure_name_out)
    set(gcf,'DefaultAxesFontSize',28);
    axes('position',[0.1,0.4,0.8,0.3])
    imagesc(T,F,Pplot,[-40,-5]);axis xy;
    hold on
    xlimits = [0 T(end)];
    xticks = 0:(60*60):T(end);
    
    set(gca,'xtick','')
    set(gca,'fontsize',28)
    XLIM = get(gca,'xlim');
    axis([get(gca,'xlim'),[0.5,30]])
    set(gca,'xtick',xticks(2:2:end),'xticklabels',{'11:00pm','03:00am','05:00am','07:00am'})
    set(gca,'ytick',[0.5,10,20])
    YLIM = get(gca,'ylim');
    ylabel('f (Hz)')
    xlabel('')
    title('')
    box off
    colorbar
    if isfield(EXP_DATA,'stimTiming')
    plot(EXP_DATA.stimTiming.validatedTTL_NLX/(1000)',YLIM(2)*0.9,'w.','markersize',10)
    end
    
    axes('position',[0.1,0.2,0.8,0.03])
    set(gca,'fontsize',28)
    if isfield(EXP_DATA,'stimTiming')
    plot(EXP_DATA.stimTiming.validatedTTL_NLX/(1000)',1,'r.','markersize',24)
    end
    
    set(gca,'xlim',XLIM)
    set(gca,'xtick',xticks(2:2:end),'xticklabels',{'11:00pm','03:00am','05:00am','07:00am'})
    set(gca,'ytick','')
    
    PrintActiveFigs('C:\Maya\Dropbox\Conferences - Posters\2018\SFN 2018\poster\dataSets_for_Figures');
    
end

