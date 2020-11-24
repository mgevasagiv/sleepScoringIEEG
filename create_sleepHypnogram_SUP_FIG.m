function create_sleepHypnogram_SUP_FIG(PtList, headerFileFolder)
outputFigureFolder = 'E:\Dropbox\ILLUSTRATOR\SUP_fig3\links';

pt = PtList.subj;
exp =  PtList.Nsessions;
a = dir(fullfile(headerFileFolder, sprintf('p%03d_EXP%d_dataset.mat',pt,exp)));
if isempty(a)
    disp(sprintf('file %s not found', sprintf('p%03d_EXP%d_dataset.mat',pt,exp)))
    return
end
load(fullfile(headerFileFolder, sprintf('p%03d_EXP%d_dataset.mat',pt,exp)))
pt_header = header;

a = dir(fullfile(pt_header.processed_MACRO, 'CSC*.mat'));
if ~isempty(a) % MACRO channels
    useNLX_MACRO = 1;
    source_folder = pt_header.processed_MACRO;
    MacroMontage = load(pt_header.macroMontagePath,'MacroMontage'); MacroMontage = MacroMontage.MacroMontage;
else % MICRO channels
    useNLX_MACRO = 0;
    source_folder = pt_header.processed_MICRO;
    montage = load(pt_header.montagePath,'Montage'); montage = montage.Montage;
end

%% Basic statistics of sleep oscillations
% Whole sleep spectrogram - to see SWS\Spindles periods
% Choose best MACRO channel to score  (pre-defined)
dropboxLink
pt_score_table = importXLSClosedLoopPatientList(fullfile(dropbox_link,'Nir_Lab\Work\closedLoopPatients\closedLoopStats1.xlsx')...
    ,'sleepScoring',35);
ptInd = [];
for ii = 1:length(pt_score_table)
    if pt_score_table(ii).subj == pt
        ptInd = ii;
    end
end
exp =  pt_score_table(ptInd).session;
source_folder = header.processed_MACRO;
ElectrodeForSleepScoring(1) = pt_score_table(ptInd).ElectrodeForSleepScoring;

mm = matfile(fullfile(source_folder,sprintf('CSC%d.mat',ElectrodeForSleepScoring(1))));
data = mm.data;
LocalHeader = mm.LocalHeader;
      
% load sleep scoring results
load(fullfile(source_folder,sprintf('sleepScore_manualValidated_%s_%d_%s',header.id,header.experimentNum,LocalHeader.origName)));

areaLabel = MacroMontage(ElectrodeForSleepScoring(1)).Area;

% based pn plotHypnogram_perChannel()
params.ds_SR = 200;
scaling_factor_delta_log = 2*10^-4 ; % Additive Factor to be used when computing the Spectrogram on a log scale

pt = PtList.subj;
exp =  PtList.Nsessions;
a = dir(fullfile(headerFileFolder, sprintf('p%03d_EXP%d_dataset.mat',pt,exp)));
load(fullfile(headerFileFolder, sprintf('p%03d_EXP%d_dataset.mat',pt,exp)))


flimits = [0 30];
data_ds = accurateResampling(data(1:end), 1000, params.ds_SR);
window = 30*params.ds_SR;
[S,F,T,P]  = spectrogram(data_ds,window,0,[0.5:0.2:flimits(2)],params.ds_SR,'yaxis');
P = P/max(max(P));
P1 = (10*log10(abs(P+scaling_factor_delta_log)))';
P1 = [P1(:,1) P1 P1(:,end)];
T = [0 T T(end)+1];
Pplot = imgaussfilt(P1',3);

figure_name_out = sprintf('SUP_FIG3_sleepScoring_wholeRecSpectrogram_%s_E%d_ch%d_%s',header.id,header.experimentNum, ElectrodeForSleepScoring(1), areaLabel);
f0 = figure('Name', figure_name_out,'NumberTitle','off');
set(gcf,'PaperUnits','centimeters','PaperPosition',[0.2 0.2 12 8]); % this size is the maximal to fit on an A4 paper when printing to PDF
set(gcf,'PaperOrientation','portrait');
set(gcf,'Units','centimeters','Position', get(gcf,'paperPosition')+[1 1 0 0]);
colormap('jet');
set(gcf,'DefaultAxesFontSize',8);

axes('position',[0.1,0.6,0.8,0.35])
imagesc(T,F,Pplot,[-40,-15]);axis xy;

hold on
xlimits = [0 T(end)];
xticks = 0:(60*60):T(end);

set(gca,'xtick','')
XLIM = get(gca,'xlim');
axis([get(gca,'xlim'),[0.5,30]])
set(gca,'xtick',xticks(2:2:end),'xticklabels',{'11:00pm','03:00am','05:00am','07:00am'})
set(gca,'ytick',[0.5,10,20])
YLIM = get(gca,'ylim');
ylabel('f (Hz)')
xlabel('')
title('')

NREM_vec = zeros(1,length(T));
for iEpoch = 2:length(T)
    if sum( sleep_score_vec(T(iEpoch-1)*obj.samplingRate+1:T(iEpoch)*obj.samplingRate) == obj.NREM_CODE)
        NREM_vec(iEpoch) = obj.NREM_CODE;
    end
end
hold all
plot(T(logical(NREM_vec)),22,'r.')

box off
cc = colorbar;
cc.TickDirection = 'out';
cc.Ticks = [-40,-30,-20];

plot(get(gca,'xlim'),[4 4],'k')
plot(get(gca,'xlim'),[9 9],'k')
plot(get(gca,'xlim'),[16 16],'k')

ss_obj  = sleepScoring_iEEG;
relevantIndices = find(F > ss_obj.deltaRangeMin & F < ss_obj.deltaRangeMax);
P_delta = movsum(sum(P(relevantIndices,:)),2);
relevantSpIndices = find(F > ss_obj.spRangeMin & F < ss_obj.spRangeMax);
P_sp = movsum(sum(P(relevantSpIndices,:)),2);

axes('position',[0.1,0.15,0.2,0.2])
sleepRange = zeros(1,length(sleep_score_vec));
startInd = find(sleep_score_vec == ss_obj.NREM_CODE,1,'first');
endInd = find(sleep_score_vec == ss_obj.NREM_CODE,1,'last');
sleepRange(startInd:endInd) = 1;

for ii_a = 1:3
    if ii_a == 1
        a_data =  data(sleep_score_vec == ss_obj.NREM_CODE);
    elseif ii_a == 2
        a_data =  data(sleep_score_vec == ss_obj.REM_CODE);
    elseif ii_a == 3
        a_data =  data(~sleepRange);
    end
    a_data(isnan(a_data)) = 0;
    a_data = a_data - nanmean(a_data);
    freq = 0:ss_obj.samplingRate/2;
    WIN = min(500,length(a_data));
    NOVERLAP = min(400,WIN/2);
    [pxx1, f1] = pwelch(a_data,WIN,NOVERLAP,freq,ss_obj.samplingRate);
    
    
    hold on
    if ii_a == 1
        plot(f1,10*log10(pxx1),'r')
        hold on
    elseif ii_a == 2
        plot(f1,10*log10(pxx1),'g')
    elseif ii_a == 3
        plot(f1,10*log10(pxx1),'color',[0.6 0.6 0.6])
    end
    
end

 axis([0 25,0,inf])
% xlabel('f(Hz)')
% ylabel('dB')
% legend('NREM','REM*','Wake*')
% title('power spectrum (iEEG)')

axes('position',[0.6,0.2,0.2,0.2])
text(0,0.6,sprintf('sleep length = %2.2fh',(endInd-startInd)/(60000*60)))
text(0,0.4,sprintf('NREM = %2.2f%%',100*sum(sleep_score_vec == ss_obj.NREM_CODE)/(endInd-startInd)))
text(0,0.2,sprintf('REM = ~%2.2f%%',100*sum(sleep_score_vec == ss_obj.REM_CODE)/(endInd-startInd)))
axis off

figure_name_out = sprintf('SUP_FIG3_sleepScoring_scatterhist_%s_E%d_ch%d_%s',header.id,header.experimentNum, ElectrodeForSleepScoring(1), areaLabel);
f1 = figure('Name', figure_name_out,'NumberTitle','off');
set(gcf,'PaperUnits','centimeters','PaperPosition',[0.2 0.2 4 4]); % this size is the maximal to fit on an A4 paper when printing to PDF
set(gcf,'PaperOrientation','portrait');
set(gcf,'Units','centimeters','Position', get(gcf,'paperPosition')+[1 1 0 0]);
colormap('jet');
set(gcf,'DefaultAxesFontSize',8);

hold all
for ii = 1:length(P_delta)
    if pointsPassedSleepThresh(ii)
        group{ii,1} = 'NREM';
    else
        group{ii,1} = 'OTHER';
    end
end
P_delta_dB = 10*log10(P_delta);
P_sp_dB = 10*log10(P_sp);
as = scatterhist(P_delta_dB',P_sp_dB','Group',group,'Parent',f1,'Color','gr','Marker','..');
xlabel('');
ylabel('');
legend('off')


outputFigureFolder2 = 'E:\Data_p\ClosedLoopDataset\sleepScoring\figures';

res =  600;
figure(f0);
a = gcf;
eval(['print ', [outputFigureFolder,'\',a.Name], ' -f', num2str(a.Number),sprintf(' -dtiff  -r%d',res), '-cmyk' ]); % adding r600 slows down this process significantly!
copyfile([outputFigureFolder,'\',a.Name], outputFigureFolder2);

figure(f1);
a = gcf;
eval(['print ', [outputFigureFolder,'\',a.Name], ' -f', num2str(a.Number),sprintf(' -dtiff  -r%d',res), '-cmyk' ]); % adding r600 slows down this process significantly!
copyfile([outputFigureFolder,'\',a.Name], outputFigureFolder2);
            
           
end

