# sleepScoringIEEG
sleep scoring based on intracranial recordings

GENERAL DESCRIPTION - 
In XX sessions (X nights / X naps), no PSG was recorded (or recorded signals were noisy) making conventional scalp EEG-based sleep staging impossible. Instead, we performed sleep scoring by using depth EEG and video recordings (REFs). We calculated spectrograms with a 30 sec window (no overlap) from 0 to 40Hz and averaged the power in the delta band (0-4Hz). Epochs with delta power higher than the percentile 55 were scored as NREM sleep and those with delta power lower than the percentile 20 were scored as wakefulness/REM sleep and were further separated as below. 

Separating REM sleep from wakeful epochs - epochs that showed on video that the patient was awake (eyes open, moving, sitting…) were scored as wakefulness. Long periods (at least 10min? continuously) occurring during the second part of the night that showed on video that the patient was apparently asleep (closed eyes, no movements) were scored as REM sleep.

FINER DETAILS - 
Start with generating a hypnogram for all available channels - using plotHypnogram_perChannel()
(create_sleepHypnogram_per_pt() is my wrapper function for that purpose).

Then - select the best channels to perform sleep-scoring with. The best candidates would be frontal, cingulate, parietal (*not* MTL) as medial as possible. Look for a contact with prominent spindle power.

sleepScoring_iEEG_wrapper uses evluateDelta() to perform sleep scoring on the selected channels and produces figures that can be used to judge how well it performed. 
Next - use manualValidationSleepScoring() to fine tune the scoring - that is, if the automatic scoring missed epochs with prominent spindle power because the percentile allowed for NREM sleep is too low, add them in.
Finally - this code will generate a figure with the power statistics of NREM/REM sleep based on this channel.
