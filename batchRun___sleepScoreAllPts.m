dropboxLink()

poolobj = gcp('nocreate'); % If no pool, do not create new one.
if isempty(poolobj)
    parpool('local',2)
else
    poolsize = poolobj.NumWorkers;
end

PtList = importXLSClosedLoopPatientList(fullfile(dropbox_link,'Nir_Lab\Work\closedLoopPatients\closedLoopStats1.xlsx')...
    ,'SubjectCharacteristics',40);

ID_list = [15,18:19,21:23,25:31]; % Entry ID in PtList XLS
parfor ii_s = 1:length(ID_list) 
    
    %% inter-ictal activity, SWS, spindle - per channel
    ptEntry = PtList(ID_list(ii_s));
    disp(sprintf('sleep scoring pt %d',ptEntry.subj))
    
    % Sleep scoring
    create_sleepHypnogram_per_pt(ptEntry, headerFileFolder)
    manualValidation = 1;
    sleepScoring_iEEG_wrapper(ptEntry, headerFileFolder,manualValidation); % TBD - evaluating sleep
     
end

for ii_s = 1:length(ID_list) 
    
    %% inter-ictal activity, SWS, spindle - per channel
    ptEntry = PtList(ID_list(ii_s));
    disp(sprintf('sleep scoring pt %d',ptEntry.subj))
    
    % Sleep scoring
    % create_sleepHypnogram_per_pt(ptEntry, headerFileFolder)
    manualValidation = 1;
    sleepScoring_iEEG_wrapper(ptEntry, headerFileFolder,manualValidation); % TBD - evaluating sleep
     
end