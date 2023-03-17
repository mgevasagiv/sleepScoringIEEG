function create_sleepHypnogram_per_pt(PtList, headerFileFolder, reRun)

if ~exist('reRun','var')
    reRun = 0;
end

pt = PtList.subj;
exp =  PtList.Nsessions;
a = dir(fullfile(headerFileFolder, sprintf('p%03d_EXP%d_dataset.mat',pt,exp)));
if isempty(a)
    disp(sprintf('file %s not found', sprintf('p%03d_EXP%d_dataset.mat',pt,exp)))
    return
end
load(fullfile(headerFileFolder, sprintf('p%03d_EXP%d_dataset.mat',pt,exp)))
pt_header = header;

a = dir(fullfile(pt_header.processed_MACRO, 'CSC*.mat')); % path to extracted iEEG channels
if ~isempty(a) % MACRO channels
    useNLX_MACRO = 1;
    source_folder = pt_header.processed_MACRO;
    MacroMontage = load(pt_header.macroMontagePath,'MacroMontage'); MacroMontage = MacroMontage.MacroMontage;
end

%% Basic statistics of sleep oscillations
% Whole sleep spectrogram - to see SWS\Spindles periods

% Generating spectrograms for *all* channels
channels = getFullChannelListMacros_EEG_iEEG(MacroMontage);
  
for ii = 1:length(channels)
    if useNLX_MACRO
        areaLabel = MacroMontage(channels(ii)).Area;
    else
        for jj = 1:length(pt_header.MontageCell)
            if pt_header.MontageCell{jj,1} == channels(ii)
                areaLabel = pt_header.MontageCell{jj,2};
                break
            end
        end
    end
    plotHypnogram_perChannel(PtList, headerFileFolder, source_folder, ...
                                                channels(ii), areaLabel)
    PrintActiveFigs(fullfile(pt_header.figuresDataPath,'hypnogram'));
end

