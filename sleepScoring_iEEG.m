classdef sleepScoring_iEEG < handle
    
    %The class compares power of channel selected for sleep-scoring
    
    properties
        
        deltaRangeMin = .5;
        deltaRangeMax = 4;
        spRangeMin = 9;
        spRangeMax = 15;
        
        flimits = [0 30]';
        samplingRate = 1000;
        sub_sampleRate = 200;
        
        REMprctile = 20;
        NREMprctile = 55;
        minDistBetweenEvents = 60; % sec
        
        PLOT_FIG = 1;
        scaling_factor_delta_log = 2*10^-4 ; % Additive Factor to be used when computing the Spectrogram on a log scale
        
        scoringEpochDuration = 30; % sec
        NREM_CODE = 1;
        REM_CODE = -1;
        
    end
    
    methods
        
        function [sleep_score_vec] = evluateDelta(obj,data, LocalHeader, header)
            
            data(isnan(data)) = 0;

            window = obj.scoringEpochDuration*obj.samplingRate;
            [S,F,T,P]  = spectrogram(data,window,0,[0.5:0.2:obj.flimits(2)],obj.samplingRate,'yaxis');
            diffSamples = obj.minDistBetweenEvents/diff(T(1:2)); %samples
            
            relevantIndices = find(F > obj.deltaRangeMin & F < obj.deltaRangeMax);
            P_delta = movsum(sum(P(relevantIndices,:)),7);
            
            thSleepInclusion = prctile(P_delta,obj.NREMprctile);
            thREMInclusion = prctile(P_delta,obj.REMprctile);
            
            %find points which pass the peak threshold 
            
            meanSleep = mean(P_delta);
            stdSleep = std(P_delta);
            detectionThresholdSD = 1.5;
            
            pointsPassedThresh = ((P_delta-meanSleep)/stdSleep > detectionThresholdSD);
            pointsBelowThresh = ((P_delta-meanSleep)/stdSleep < detectionThresholdSD);
            
            pointsPassedSleepThresh = P_delta > thSleepInclusion;
            pointsPassedREMThresh = P_delta < thREMInclusion;
            
            relevantSpIndices = find(F > obj.spRangeMin & F < obj.spRangeMax);
            P_sp = movsum(sum(P(relevantSpIndices,:)),5);
            
            
            figure_name_out = sprintf('sleepScore_process_%s_E%d_%s',header.id,header.experimentNum,LocalHeader.origName);
            figure('Name', figure_name_out,'NumberTitle','off');
            set(gcf,'PaperUnits','centimeters','PaperPosition',[0.2 0.2 25 35]); % this size is the maximal to fit on an A4 paper when printing to PDF
            set(gcf,'PaperOrientation','portrait');
            set(gcf,'Units','centimeters','Position', get(gcf,'paperPosition')+[1 1 0 0]);
            colormap('jet');
            set(gcf,'DefaultAxesFontSize',14);
            axes('position',[0.1,0.5,0.8,0.3])
            
            P2 = P/max(max(P));
            P2 = (10*log10(abs(P2+obj.scaling_factor_delta_log)))';
            P2 = [P2(:,2) P2 P2(:,end)];
            ah1 = imagesc(T,F,P2',[-40,-5]);axis xy;
            hold on
            fitToWin1 = 30/max(P_delta);
            fitToWin2 = 30/max(P_sp);
            plot(T,P_delta*fitToWin1,'k-','linewidth',1)
            plot(T,P_sp*fitToWin2-min(P_sp)*fitToWin2,'-','linewidth',1,'color',[0.8,0.8,0.8])
            line(get(gca,'xlim'),thSleepInclusion*fitToWin1*ones(1,2),'color','k','linewidth',3)
            line(get(gca,'xlim'),thREMInclusion*fitToWin1*ones(1,2),'color','k','linewidth',3)
            legend('P delta','P spindle','TH1','TH2')
            
            xlabel('ms')
            ylabel('F(Hz)')
            XLIM = get(gca,'xlim');
            YLIM = get(gca,'xlim');
            text(XLIM(2)+diff(XLIM)/35,thSleepInclusion*fitToWin1,'NREM TH')
            text(XLIM(2)+diff(XLIM)/35,thREMInclusion*fitToWin1,'REM TH')
            
            
            
            
            for ii_a = 1:2
                if ii_a == 1
                    data_merge = pointsPassedSleepThresh;
                elseif ii_a == 2
                    data_merge = pointsPassedREMThresh;
                end
                diffStartEnd = diff(data_merge);
                %events are defined by sequences which have a peak above
                %detectionThresholdSD and a duration within the limits of
                %required duration. The duration is considered to be from the
                %first point above pointsPassedThreshStartEnd until the last
                %point above it
                nextInd = find(data_merge,1);
                EventsMinLimit = []; currDuration = [];
                EventsMaxLimit = []; eventTimes = [];
                while ~isempty(nextInd)
                    %last pass above the start threshold before current event
                    startCurrEvent = find(diffStartEnd(1:nextInd)==1, 1, 'last')+1;
                    if nextInd == 1
                        startCurrEvent = 1;
                    end
                    %last pass above the end threshold after current event
                    endCurrEvent = find(diffStartEnd(nextInd:end)==-1,1,'first')+nextInd-1;
                    if ~isempty(startCurrEvent) && ~isempty(endCurrEvent)
                        %calcualte the duration
                        currDuration = [currDuration (endCurrEvent-startCurrEvent)/obj.samplingRate];
                    else
                        currDuration = [currDuration nan];
                    end
                    
                    %if the duration is within required limits, add to event
                    %list
                    EventsMinLimit = [EventsMinLimit; startCurrEvent];
                    
                    if isempty(endCurrEvent)
                        EventsMaxLimit = [EventsMaxLimit; endCurrEvent];
                        
                    else
                        EventsMaxLimit = [EventsMaxLimit; endCurrEvent];
                    end
                    nextInd = find(data_merge(endCurrEvent+1:end),1,'first')+endCurrEvent;
                    if (nextInd>=length(diffStartEnd)); nextInd = []; end
                end
                if ~sum(data_merge(EventsMinLimit(end):end) == 0)
                    EventsMaxLimit = [EventsMaxLimit; length(data_merge)];
                end

                % if there's <minute between REM/NREM points - merge them (this is
                % inline with AASM guidlines)
                %merge events which are too close apart, and set the event
                %timing to be the middle of the event
                eventDiffs = EventsMinLimit(2:end)-EventsMaxLimit(1:end-1);
                %find only events for which enough far apart
                short_intervals = find(eventDiffs'<=(diffSamples));
                
                if ~isempty(short_intervals)
                    for iii = 1:length(short_intervals)
                        index = short_intervals(iii);
                        data_merge(EventsMaxLimit(index):EventsMinLimit(index+1)) = 1;
                    end
                end
                
                
                
                % Remove standalone detections which were not merged before
                diffStartEnd = diff(data_merge);
                %events are defined by sequences which have a peak above
                %detectionThresholdSD and a duration within the limits of
                %required duration. The duration is considered to be from the
                %first point above pointsPassedThreshStartEnd until the last
                %point above it
                nextInd = find(data_merge,1);
                EventsMinLimit = [];
                EventsMaxLimit = [];
                while ~isempty(nextInd)
                    %last pass above the start threshold before current spindle
                    startCurrEvent = find(diffStartEnd(1:nextInd)==1, 1, 'last')+1;
                    %last pass above the end threshold after current spindle
                    endCurrEvent = find(diffStartEnd(nextInd:end)==-1,1,'first')+nextInd-1;
                    
                    % remove single points
                    if endCurrEvent-startCurrEvent < 3
                        disp(sprintf('removing ind %d',nextInd))
                        data_merge(nextInd:nextInd+2) = 0;
                    end
                    nextInd = find(pointsPassedSleepThresh(endCurrEvent+1:end),1,'first')+endCurrEvent;
                    
                    % deal with last indice:
                    if nextInd > length(diffStartEnd)
                        disp(sprintf('removing ind %d',nextInd))
                        data_merge(nextInd) = 0;
                        nextInd = [];
                    end
                    
                end
                
                if ii_a == 1
                    pointsPassedSleepThresh = data_merge;
                elseif ii_a == 2
                    pointsPassedREMThresh = data_merge;
                end
                
            end
            
  
            sleep_score_vec = zeros(1,length(data));
            
            sleep_score_vec(1:T(1)*obj.samplingRate) = pointsPassedSleepThresh(1);
            
            for iEpoch = 2:length(T)
                if(pointsPassedSleepThresh(iEpoch))
                    sleep_score_vec(T(iEpoch-1)*obj.samplingRate+1:T(iEpoch)*obj.samplingRate) = obj.NREM_CODE;
                elseif pointsPassedREMThresh(iEpoch)
                    sleep_score_vec(T(iEpoch-1)*obj.samplingRate+1:T(iEpoch)*obj.samplingRate) = obj.REM_CODE;
                end
            end
            
            save(sprintf('sleepScore_%s_%d_%s',header.id,header.experimentNum,LocalHeader.origName),...
                'T','F','P2','header','sleep_score_vec','obj','P_delta','pointsPassedSleepThresh','pointsPassedREMThresh')
            
            if obj.PLOT_FIG
                
                [~, hostname]= system('hostname');
                if strfind(hostname, 'cns-cdkngw2')
                    figure_folder = 'E:\Data_p\ClosedLoopDataset\sleepScoring';
                else
                    error('host not identified')
                end
                
                figure_name_out = sprintf('sleepScore_%s_E%d_%s',header.id,header.experimentNum,LocalHeader.origName);
                figure('Name', figure_name_out,'NumberTitle','off');
                set(gcf,'PaperUnits','centimeters','PaperPosition',[0.2 0.2 21 30]); % this size is the maximal to fit on an A4 paper when printing to PDF
                set(gcf,'PaperOrientation','portrait');
                set(gcf,'Units','centimeters','Position', get(gcf,'paperPosition')+[1 1 0 0]);
                colormap('jet');
                set(gcf,'DefaultAxesFontSize',14);
                axes('position',[0.1,0.65,0.8,0.3])
                msz = 10; % marker size
                [S2,F2,T2,P2]  = spectrogram(data,window,0.8*window,[0.5:0.2:obj.flimits(2)],obj.samplingRate,'yaxis');
                
                P2 = P2/max(max(P2));
                P1 = (10*log10(abs(P2+obj.scaling_factor_delta_log)))';
                P1 = [P1(:,1) P1 P1(:,end)];
                T2 = [0 T2 T2(end)+1];
                Pplot = imgaussfilt(P1',3);
                
                start_time = datenum(LocalHeader.NLXfilesStartTime{1});
                if length(LocalHeader.NLXfilesStartTime) > 1
                    if datenum(LocalHeader.NLXfilesStartTime{2}) < datenum(LocalHeader.NLXfilesStartTime{1})
                        % Many times NLX numbering is reversed
                        start_time = datenum(LocalHeader.NLXfilesStartTime{2});
                    end
                end
                end_time = datenum(LocalHeader.NLXfilesEndTime{end});
                xData = linspace(start_time,end_time,length(P1));
                
                
                ah = imagesc(xData,F2,P1',[-40,-5]);axis xy;
                
                % ah = imagesc(xData,F,Pplot,[-40,-5]);axis xy;
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
                    
                    a_data = a_data - mean(a_data);
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
            
        end
        
        
        %% help functions
        function [f,psdx] = getPS(obj,segment)
            %an help method to calcualte the power spectrum of a segment
            
            segLength = length(segment);
            xdft = fft(segment);
            xdft = xdft(1:segLength/2+1);
            psdx = (1/(obj.samplingRate*segLength)) * abs(xdft).^2;
            psdx(2:end-1) = 2*psdx(2:end-1);
            psdx = 10*log10(psdx);
            
        end
        
        function [f, pow] = hereFFT (obj, signal)
            % Calculate the fft of the signal, with the given sampling rate, make
            % normalization(AUC=1). Return frequencis and respective powers.
            
            % Matlab sorce code of FFT
            Y = fft(signal);
            power_spec = Y.* conj(Y) / length(signal);
            
            % keep only half of the power spectrum array (second half is irrelevant)
            amp = power_spec(1:ceil(length(power_spec)/2)) ;
            
            % Define the frequencies relevant for the left powers, and cut for same
            % number of values (for each frequency - a power value)
            f = obj.samplingRate*(1:length(amp))/(length(amp)*2);
            pow = amp(1:length(f));
            
            %----- End of Regular fft -----
            
            pow = pow / sum (pow);   % normalize AUC
            
        end
        
        function BP = bandpass(obj, timecourse, SamplingRate, low_cut, high_cut, filterOrder)
            
            %bandpass code - from Maya
            
            if (nargin < 6)
                filterOrder = obj.defaultFilterOrder;
            end
            
            % Maya GS - handle NAN values
            indices = find(isnan(timecourse));
            if length(indices) > obj.nanWarning*length(timecourse)
                warning('many NaN values in filtered signal')
            end
            timecourse(indices) = 0;
            %
            
            [b, a] = butter(filterOrder, [(low_cut/SamplingRate)*2 (high_cut/SamplingRate)*2]);
            BP = filtfilt(b, a, timecourse );
            BP(indices) = NaN;
        end
        
        
    end % methods
    
    
end % classdef