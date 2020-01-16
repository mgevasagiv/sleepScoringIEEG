function sleepScoring_iEEG_wrapper(PtList, headerFileFolder,manualValidation)

if (~exist('manualValidation','var'))
    manualValidation = 0;
end

params.lowCut = .5;
params.highCut = 4;
params.ds_SR = 200;
sleepScore_obj = sleepScoring_iEEG;


pt = PtList.subj;
exp =  PtList.Nsessions;
a = dir(fullfile(headerFileFolder, sprintf('p%03d_EXP%d_dataset.mat',pt,exp)));
if isempty(a)
    disp(sprintf('file %s not found', sprintf('p%03d_EXP%d_dataset.mat',pt,exp)))
end
load(fullfile(headerFileFolder, sprintf('p%03d_EXP%d_dataset.mat',pt,exp)))

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
if ~isempty(pt_score_table(ptInd).ElectrodeForSleepScoring2)
    ElectrodeForSleepScoring(2) = pt_score_table(ptInd).ElectrodeForSleepScoring2;
end

cd(source_folder);

if ~manualValidation
    for ii = 1:length(ElectrodeForSleepScoring)
        mm = matfile(sprintf('CSC%d.mat',ElectrodeForSleepScoring(ii)));
        data = mm.data;
        LocalHeader = mm.LocalHeader;
        
        [sleep_score_vec] = evluateDelta(sleepScore_obj,data, LocalHeader, header);
    end
else
    for ii = 1:length(ElectrodeForSleepScoring)
        fileList = dir(fullfile(source_folder,'sleepScore_manualValidated*'));
        if ~isempty(fileList)
            continue
        end
        mm = matfile(sprintf('CSC%d.mat',ElectrodeForSleepScoring(ii)));
        data = mm.data;
        LocalHeader = mm.LocalHeader;
        
        manualValidationSleepScoring(data,mm.LocalHeader,header)
    end
end

end


