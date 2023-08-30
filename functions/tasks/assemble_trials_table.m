function TrialsTable = assemble_trials_table(Task, Participants, Sessions, ...
   Paths, ...
    TrialWindows, WindowLabels, MinEventProportion, ...
    PupilDataQualityTable)


CacheDir
Trial

%%% cache
% location of cache
CacheString = strjoin({Task, 'TrialTable.mat'}, '_');
CachePath = fullfile(CacheDir, CacheString);

% load from cache
if exist(CachePath, 'file') && ~Refresh
    load(CachePath, 'TrialsTable')
    return
end

if ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end

%%% get trial information
Trials = load_task_output(Participants, Sessions, Task, Paths, false);