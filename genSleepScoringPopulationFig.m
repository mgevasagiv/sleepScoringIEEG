% List of sleep-scoring files follwoing review
fileDir = 'E:\Data_p\SleepScore_v1\';
resultsFolder = 'E:\Data_p\ClosedLoopDataset\sleepScoring\results';

fileList = dir(fullfile(fileDir,'sleepScore_manualValidated*'));
NREM_CODE = 1;
REM_CODE = -1;
samplingRate = 1e3; % Hz

%% Basic statistics of sleep oscillations
% Whole sleep spectrogram - to see SWS\Spindles periods
% Choose best MACRO channel to score  (pre-defined)
dropboxLink
pt_score_table = importXLSClosedLoopPatientList(fullfile(dropbox_link,'Nir_Lab\Work\closedLoopPatients\closedLoopStats1.xlsx')...
    ,'sleepScoring',40);

% Go over all pts, and generate a population figure
for iPatient = 1:length(fileList)
    % load sleep scoring results
    load(fullfile(fileDir,fileList(iPatient).name))
    ptNum = str2num(fileList(iPatient).name(29:31));
    disp(ptNum)
    try
        MacroMontage = load(header.macroMontagePath,'MacroMontage'); MacroMontage = MacroMontage.MacroMontage;
    catch
        disp(ptNum)
        error('montage file not found')
    end
    
    
    ptInd = [];
    for ii = 1:length(pt_score_table)
        if pt_score_table(ii).subj == ptNum
            ptInd = ii;
        end
    end
    exp =  pt_score_table(ptInd).session;
    source_folder = header.processed_MACRO;
    cd(source_folder)
    ElectrodeForSleepScoring(1) = pt_score_table(ptInd).ElectrodeForSleepScoring;
    
    mm = matfile(sprintf('CSC%d.mat',ElectrodeForSleepScoring(1)));
    data = mm.data;
    areaLabel = MacroMontage(ElectrodeForSleepScoring(1)).Area;
    
    sleepRange = zeros(1,length(sleep_score_vec));
    startInd = find(sleep_score_vec == NREM_CODE,1,'first');
    endInd = find(sleep_score_vec == NREM_CODE,1,'last');
    sleepRange(startInd:endInd) = 1;
    
    for ii_a = 1:3
        if ii_a == 1
            a_data =  data(sleep_score_vec == NREM_CODE);
        elseif ii_a == 2
            a_data =  data(sleep_score_vec == REM_CODE);
        elseif ii_a == 3
            a_data =  data(~sleepRange);
        end
        a_data(isnan(a_data)) = 0;
        a_data = a_data - nanmean(a_data);
        freq = 0:samplingRate/2;
        WIN = min(500,length(a_data));
        NOVERLAP = min(400,WIN/2);
        [pxx1, f1] = pwelch(a_data,WIN,NOVERLAP,freq,samplingRate);
        
        sleep_cell{ii_a}.pxx1(iPatient,:) = pxx1;
        sleep_cell{ii_a}.f(iPatient,:) = f1;
        
    end
    
    sleep_cell_stats{iPatient}.sleep_score_vec = int8(sleep_score_vec);
    sleep_cell_stats{iPatient}.ElectrodeForSleepScoring = ElectrodeForSleepScoring(1);
    sleep_cell_stats{iPatient}.areaLabel = areaLabel;
    sleep_cell_stats{iPatient}.ptNum = ptNum;
    
end

save(fullfile(resultsFolder,'sleep_population_power'),'sleep_cell_stats','sleep_cell')

%% Printing Extended Data Fig. 1c

load(fullfile(resultsFolder,'sleep_population_power'),'sleep_cell_stats','sleep_cell')
f1 = sleep_cell{1}.f(1,:);

figure_name_out = sprintf('SUP_FIG3_sleepScoring_powerSpectrum_all');
f0 = figure('Name', figure_name_out,'NumberTitle','off');
set(gcf,'PaperUnits','centimeters','PaperPosition',[0.2 0.2 12 8]); % this size is the maximal to fit on an A4 paper when printing to PDF
set(gcf,'PaperOrientation','portrait');
set(gcf,'Units','centimeters','Position', get(gcf,'paperPosition')+[1 1 0 0]);
colormap('jet');
set(gcf,'DefaultAxesFontSize',8);

aa(1,:) = [0.1,0.15,0.1,0.2];
aa(2,:) = [0.3,0.15,0.1,0.2];
aa(3,:) = [0.5,0.15,0.1,0.2];
aa(4,:) = [0.7,0.15,0.1,0.2];

for ii_a = 1:3
    if ii_a == 1
        col = 'r';
    elseif ii_a == 2
        col = 'g';
    elseif ii_a == 3
        col = [0.6 0.6 0.6];
    end
    axes('position',aa(ii_a,:));
    plot(f1,10*log10(mean(sleep_cell{ii_a}.pxx1)),'color',col,'linewidth',5)
    hold on 
    plot(f1,10*log10(sleep_cell{ii_a}.pxx1),'--k')
    axis([0 25,0,40])
    set(gca,'xtick',[0 25])

    if SAVE_TABLE
        outputFolderSrc = 'C:\Users\mgeva\Documents\GitHub\closedLoop-pub\figureGen';
        varnames = {'average_power_dB','frequency'};
        b = f1;
        a = 10*log10(mean(sleep_cell{ii_a}.pxx1));
        jointTable = table(a(:),b(:),'VariableNames',varnames);
        for iiP = 1:size( sleep_cell{ii_a}.pxx1,1)
            varName = {sprintf('pt%d',iiP)};
            a = 10*log10(sleep_cell{ii_a}.pxx1(iiP,:));
            data_table1 = table(a(:),'VariableNames',varName);
            jointTable = [jointTable, data_table1];
        end
        filename = fullfile(outputFolderSrc,sprintf('ExtendedDataFig1c%d_table',ii_a+1));
        save(filename,'jointTable');
    end

end

axes('position',aa(4,:));
hold on
for ii_a = 1:3
    if ii_a == 1
        col = 'r';
        hold on
    elseif ii_a == 2
        col = 'g';
    elseif ii_a == 3
        col = [0.6 0.6 0.6];
    end
    plot(f1,10*log10(mean(sleep_cell{ii_a}.pxx1)),'color',col,'linewidth',2)
    axis([0 25,0,40])
    set(gca,'xtick',[0 25])

    data(ii_a,:) = 10*log10(mean(sleep_cell{ii_a}.pxx1));  
end

if SAVE_TABLE
    outputFolderSrc = 'C:\Users\mgeva\Documents\GitHub\closedLoop-pub\figureGen';
    varnames = {'nrem_power_dB','desynch_power_dB','wake_power_dB','frequency'};
    b = f1;
    data_table = table(data(1,:)',data(2,:)',data(3,:)',b(:),'VariableNames',varnames);
    filename = fullfile(outputFolderSrc,sprintf('ExtendedDataFig1c1_table'));
    save(filename,'data_table');
end


outputFigureFolder = 'E:\Dropbox\Nir_Lab\closedLoopRevision\Figures\links_sup_fig1';
res =  600;
a = gcf;
eval(['print ', [outputFigureFolder,'\',a.Name], ' -f', num2str(a.Number),sprintf(' -dtiff  -r%d',res), '-cmyk' ]); % adding r600 slows down this process significantly!
