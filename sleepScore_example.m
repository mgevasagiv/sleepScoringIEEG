dropboxLink()

poolobj = gcp('nocreate'); % If no pool, do not create new one.
if isempty(poolobj)
    parpool('local',2)
else
    poolsize = poolobj.NumWorkers;
end

PtList = importXLSClosedLoopPatientList(fullfile(dropbox_link,'experimentaslInfo.xlsx')...
                ,'SubjectCharacteristics',40);
            
            % PtList.subj - subj name, PtList.Nsessions - session id,
            % function assumes a header file exists with name -
            % sprintf('p%03d_EXP%d_dataset.mat',pt,exp) that holds the following
            % info -
            % pt_header.macroMontagePath - pointer to file matching contact numbers
            %                              to their location in the brain
            % pt_header.processed_MACRO - pointer to file with extracted iEEG files
            % (CSC*.mat)
            
            
    
% Step 1 - create hypnograms for all channels
ID_list = 1:length(PtList); % Entry ID in PtList XLS
parfor ii_s = 1:length(ID_list) 
    
    ptEntry = PtList(ID_list(ii_s));
    disp(sprintf('sleep scoring pt %d',ptEntry.subj))
    
    % Sleep scoring
    create_sleepHypnogram_per_pt(ptEntry, headerFileFolder)
       
end

% Step 2 - review hypnograms, choose one channel for sleep scoring and
% update the XLS 'sleepScoring' pt/session table

% Step 3 - run automated sleep scoring on the selected channels
for ii_s = 1:length(ID_list) 
    
    ptEntry = PtList(ID_list(ii_s));
    disp(sprintf('sleep scoring pt %d',ptEntry.subj))
    
    manualValidation = 0;
    sleepScoring_iEEG_wrapper(ptEntry, headerFileFolder,manualValidation); 
end

% step 4
for ii_s = 1:length(ID_list) 
    
    %% inter-ictal activity, SWS, spindle - per channel
    ptEntry = PtList(ID_list(ii_s));
    disp(sprintf('sleep scoring pt %d',ptEntry.subj))
    
    % Sleep scoring
    % create_sleepHypnogram_per_pt(ptEntry, headerFileFolder)
    manualValidation = 1;
    sleepScoring_iEEG_wrapper(ptEntry, headerFileFolder,manualValidation); % TBD - evaluating sleep
     
end

% step 5 
% publication worthy hypnogram 
% this folder contains all sleep scored vectors
fileFolder = 'E:\Data_p\SleepScore_v1';

% Collecting data from all patients
genSleepScoringPopulationFig()

ptEntry = PtList(36);
disp(sprintf('sleep scoring pt %d',ptEntry.subj))
create_sleepHypnogram_SUP_FIG(ptEntry, headerFileFolder)

ptEntry = PtList(29);
disp(sprintf('sleep scoring pt %d',ptEntry.subj))
