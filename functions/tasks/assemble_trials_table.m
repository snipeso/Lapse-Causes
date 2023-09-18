function TrialsTable = assemble_trials_table(Task, Participants, Sessions, ...
   Paths, SampleRate, ...
    TrialWindows, WindowLabels, MinEventProportion, ...
    PupilDataQualityTable, Triggers)


CacheDir = fullfile(Paths.Cache, 'TrialsTables');
MicrosleepPath = fullfile(Paths.AnalyzedData,  ['Pupils_', num2str(SampleRate)], Task);



%%% get trial information
TrialsTable = load_task_output(Participants, Sessions, Task, Paths, false);

% TODO
% get time of stim and response trigger
% TrialsTable = trial_latencies(TrialsTable, BurstPath, Triggers);
% get eyes-closed info
% TrialsTable = getECtrials(TrialsTable, MicrosleepPath, DataQuality_Table, ...
%     SampleRate, TrialWindows, MinEventProportion, WindowLabels);

% save to cache for future
save(CachePath, 'TrialsTable')