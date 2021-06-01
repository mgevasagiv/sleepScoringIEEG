cd('E:\Dropbox\April25_2021')
earlyNight = 360;


% 398 , 402 - funky
% Example 2

ptID_vec = [396, 399, 404];
channelsForScoring = [15 17 16];
for ii = 1:length(ptID_vec)
    clear stages30secSegments_NREM stages30secSegments
    ptId = ptID_vec(ii);
    disp(['working on pt ', num2str(ptId)])
    
    stages30secSegments = load(sprintf('P%d_stages.mat',ptId),'stages30secSegments');
    stages30secSegments = stages30secSegments.stages30secSegments;
    [hdr, record] = edfread(sprintf('P%d_staging_PSG_and_intracranial_Mref_correct.txt.edf',ptId));
    
    channel_id = channelsForScoring(ii);
    disp(['loading ch ',hdr.label{channel_id}])
    data = record(channel_id,:);
    LocalHeader = [];
    header = [];
    ss_obj = sleepScoring_iEEG;
    ss_obj.samplingRate = 128;
    ss_obj.useClustering_for_scoring = 1;
    
    header.id = sprintf('%d',ptId);
    header.experimentNum = 1;
    LocalHeader.origName = 'fullNight';
    LocalHeader.channel_id = channel_id;
    [sleep_score_vec] = ss_obj.evluateDelta(data, LocalHeader, header);
    pointsPassedSleepThresh = load(sprintf('sleepScore_%d_1_fullNight.mat',ptId), 'pointsPassedSleepThresh');
    pointsPassedSleepThresh = pointsPassedSleepThresh.pointsPassedSleepThresh;
    
    stages30secSegments_NREM = zeros(1,length(stages30secSegments));
    stages30secSegments_NREM(~ismember(stages30secSegments,[Wake, REM, stage1]))=1;
    DIFF = sum(stages30secSegments_NREM(1:earlyNight)) - sum(pointsPassedSleepThresh(1:earlyNight));
    Perc_diff(ii) = DIFF/length(stages30secSegments_NREM);
    
end
