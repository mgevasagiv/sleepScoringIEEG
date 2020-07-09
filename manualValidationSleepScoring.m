%% Manually edit sleep scored vector
function manualValidationSleepScoring(data, LocalHeader,header)

load(sprintf('sleepScore_%s_%d_%s',header.id,header.experimentNum,LocalHeader.origName))

figure_name_out = sprintf('sleepScore_%s_E%d_%s',header.id,header.experimentNum,LocalHeader.origName);
figure('Name', figure_name_out,'NumberTitle','off');
set(gcf,'PaperUnits','centimeters','PaperPosition',[0.2 0.2 21 30]); % this size is the maximal to fit on an A4 paper when printing to PDF
set(gcf,'PaperOrientation','portrait');
set(gcf,'Units','centimeters','Position', get(gcf,'paperPosition')+[1 1 0 0]);
colormap('jet');
set(gcf,'DefaultAxesFontSize',14);
axes('position',[0.1,0.65,0.8,0.3])
msz = 10; % marker size
ah1 = imagesc(T,F,P2',[-40,-5]);axis xy;
yticks = obj.flimits(1):5:obj.flimits(2);
colorbar
title_str = sprintf('%s, E%d, sleep scoring - NREM (red), Wake/REM (black)',header.id,header.experimentNum);
axis([get(gca,'xlim'),[0.5,30]])
set(gca,'ytick',[0.5,10,20,30])
YLIM = get(gca,'ylim');

hold on
plot(T(logical(pointsPassedSleepThresh)),20,'.r','markersize',msz)
plot(T(logical(pointsPassedREMThresh)),18,'.k','markersize',msz)


answer = input('add a new NREM session?(Y/N)','s');
while strcmpi(answer,'Y')
    [x,y] = ginput(2);
    line(x(1)*ones(1,2),YLIM,'color','r')
    line(x(2)*ones(1,2),YLIM,'color','g')
    
    answer = input('mark between lines as NREM ?(Y/N)','s');
    if strcmpi(answer,'Y')
        [~, ind1] = min( abs(T-x(1)));
        [~, ind2] = min( abs(T-x(2)));
        pointsPassedSleepThresh(ind1:ind2) = obj.NREM_CODE;
        pointsPassedREMThresh(ind1:ind2) = 0;
        sleep_score_vec(floor(x(1)*obj.samplingRate):floor(x(2)*obj.samplingRate)) = obj.NREM_CODE;
    end
    answer = input('add an additonal new NREM session?(Y/N)','s');
    
end


answer = input('erase an existing session?(Y/N)','s');
while strcmpi(answer,'Y')
    [x,y] = ginput(2);
    line(x(1)*ones(1,2),YLIM,'color','r')
    line(x(2)*ones(1,2),YLIM,'color','g')
    pause
    answer = input('remove scoring between lines ?(Y/N)','s');
    if strcmpi(answer,'Y')
         [~, ind1] = min( abs(T-x(1)));
         [~, ind2] = min( abs(T-x(2)));
        pointsPassedREMThresh(ind1:ind2) = 0;
        pointsPassedSleepThresh(ind1:ind2) = 0;
        sleep_score_vec(floor(x(1)*obj.samplingRate):floor(x(2)*obj.samplingRate)) = 0;
      
    end
    answer = input('remove additional scoring between lines ?(Y/N)','s');
    
end

save(sprintf('sleepScore_manualValidated_%s_%d_%s',header.id,header.experimentNum,LocalHeader.origName),...
    'header','sleep_score_vec','obj','P_delta')

% Plot final figures
[~, hostname]= system('hostname');
if strfind(hostname, 'cns-cdkngw2')
    figure_folder = 'E:\Data_p\ClosedLoopDataset\sleepScoring';
else
    error('host not identified')
end

figure_name_out = sprintf('manualVAlidatedSleepScore_%s_E%d_%s',header.id,header.experimentNum,LocalHeader.origName);
figure('Name', figure_name_out,'NumberTitle','off');
set(gcf,'PaperUnits','centimeters','PaperPosition',[0.2 0.2 21 30]); % this size is the maximal to fit on an A4 paper when printing to PDF
set(gcf,'PaperOrientation','portrait');
set(gcf,'Units','centimeters','Position', get(gcf,'paperPosition')+[1 1 0 0]);
colormap('jet');
set(gcf,'DefaultAxesFontSize',14);
axes('position',[0.1,0.65,0.8,0.3])
msz = 10; % marker size


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


xData = linspace(start_time,end_time,length(P2));

ah = imagesc(xData,F,P2',[-40,-5]);axis xy;

axis([get(gca,'xlim'),[0.5,20]])
set(gca,'ytick',[0.5,10,20])
datetick('x','HH:MM PM','keeplimits')

%                 xlimits = [0 T2(end)];
%                 xticks = 1:(60*60):T2(end);
%                 for ii = 1:length(xticks)
%                     xlabel_str{ii} = num2str(floor((xticks(ii)/(60*60))));
%                 end
%                 axis([xlimits obj.flimits'])
%                 set(gca,'xtick',xticks,'XTickLabel',xlabel_str)
%
yticks = obj.flimits(1):5:obj.flimits(2);
colorbar
title_str = sprintf('%s, E%d, sleep scoring - NREM (red), Wake/REM (black)',header.id,header.experimentNum);
axis([get(gca,'xlim'),[0.5,30]])
set(gca,'ytick',[0.5,10,20,30])
YLIM = get(gca,'ylim');


hold on
xData2 = linspace(start_time,end_time,length(T));
plot(xData2(logical(pointsPassedSleepThresh)),20,'.r','markersize',msz)
plot(xData2(logical(pointsPassedREMThresh)),18,'.k','markersize',msz)

xlabel('t (hh:mm)')
ylabel('f (Hz)')
title(title_str)

axes('position',[0.1,0.2,0.3,0.3])
sleepRange = zeros(1,length(sleep_score_vec));
startInd = find(sleep_score_vec == obj.NREM_CODE,1,'first');
endInd = find(sleep_score_vec == obj.NREM_CODE,1,'last');
sleepRange(startInd:endInd) = 1;

for ii_a = 1:3
    if ii_a == 1
        a_data =  data(sleep_score_vec == obj.NREM_CODE);
    elseif ii_a == 2
        a_data =  data(sleep_score_vec == obj.REM_CODE);
    elseif ii_a == 3
        a_data =  data(~sleepRange);
    end
    a_data(isnan(a_data)) = 0;
    a_data = a_data - nanmean(a_data);
    freq = 0:obj.samplingRate/2;
    WIN = min(500,length(a_data));
    NOVERLAP = min(400,WIN/2);
    [pxx1, f1] = pwelch(a_data,WIN,NOVERLAP,freq,obj.samplingRate);
    
    
    hold on
    if ii_a == 1
        plot(f1,10*log10(pxx1),'b')
        hold on
    elseif ii_a == 2
        plot(f1,10*log10(pxx1),'g')
    elseif ii_a == 3
        plot(f1,10*log10(pxx1),'color',[0.8 0.8 0.8])
    end
    
end

axis([0 25,0,inf])
xlabel('f(Hz)')
ylabel('dB')
legend('NREM','REM*','Wake*')
title('power spectrum (iEEG)')


axes('position',[0.5,0.2,0.3,0.3])
text(0,0.6,sprintf('sleep length = %2.2fh',(endInd-startInd)/(60000*60)))
text(0,0.5,sprintf('NREM = %2.2f%%',100*sum(sleep_score_vec == obj.NREM_CODE)/(endInd-startInd)))
text(0,0.4,sprintf('REM = ~%2.2f%%',100*sum(sleep_score_vec == obj.REM_CODE)/(endInd-startInd)))
axis off

PrintActiveFigs(figure_folder)

end