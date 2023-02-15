# sleepScoringIEEG
sleep scoring based on intracranial recordings (in collaboration with Yuval Nir and Hanna Hayat)

GENERAL DESCRIPTION - 
In sleep sessions on which no PSG was recorded (or recorded signals were noisy), conventional scalp EEG-based sleep staging was made impossible. Instead, this toolbox allows sleep scoring by using depth EEG. We calculated spectrograms with a 30 sec window (no overlap) from 0 to 40Hz and averaged the power in the delta band (0-4Hz). 

FINER DETAILS - 
Start with generating a hypnogram for all available channels - using plotHypnogram_perChannel()
(create_sleepHypnogram_per_pt() is my wrapper function for that purpose).

Then - select the best channels to perform sleep-scoring with. The best candidates would be frontal, cingulate, parietal (*not* MTL) as medial as possible. Look for a contact with prominent spindle power.

sleepScoring_iEEG_wrapper uses evluateDelta() to perform sleep scoring on the selected channels and produces figures that can be used to judge how well it performed. 
Next - use manualValidationSleepScoring() to fine tune the scoring - that is, if the automatic scoring missed epochs with prominent spindle power because the percentile allowed for NREM sleep is too low, add them in.
Finally - this code will generate a figure with the power statistics of NREM/REM sleep based on this channel.
