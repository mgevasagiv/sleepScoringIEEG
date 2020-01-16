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
pts = [484, 485, 486, 487, 488, 489, 490, 496, 497, 498, 499, 510];
hypnogram_ch_macro = [{[99,101,102]},{[8,52,44,59,66]} , {[20,24,38, 46, 53]},...    
{[16, 24, 26, 45]}, {[31,55,78]}, {[1, 10, 15, 58]}, {[15 ,8,10]},...
{[1,46,54]},{[8,24,16,49,56]},{[16,47,32, 55, 24]},{[15,23,65]},{[26,36,66,74 ]}];

idx_pt = find(pt ==  pts);
% channels = hypnogram_ch_macro{idx_pt};
% Get deep contacts - 
% channels = unique([channels,getDeepMacros(MacroMontage)]);
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

