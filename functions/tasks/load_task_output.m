function Trials = load_task_output(Participants, Sessions, Task, Paths, Refresh)
% single function to load main outcomes for PVT and LAT.
% LAT types are Lapses, Late, and Correct Responses.
% PVT types are Lapses (<.5), Correct Responses and Bugs.
% From Lapses-Causes.

TaskDataDir = fullfile(Paths.AnalyzedData, 'Behavior');

if ~exist(TaskDataDir, 'dir')
    mkdir(TaskDataDir)
end

Filename = [Task, '_AllAnswers.mat'];

% get behavior data from RAW data structure if table doesn't already exist
if ~exist(fullfile(TaskDataDir, Filename), 'file') || Refresh
    AllTrials = import_task_logs(Paths.Datasets, Task, TaskDataDir);
else
    load(fullfile(TaskDataDir, Filename), 'AllAnswers')
    AllTrials = AllAnswers;
end

% make it in a nice table
switch Task
    case 'LAT'
        AllTrials = cleanup_LAT(AllTrials);
    case 'PVT'
        AllTrials = cleanup_PVT(AllTrials);
    otherwise
        error('unknown task')
end

% include only data in selected participants & sessions
Trials = AllTrials(ismember(AllTrials.Participant, Participants) & ...
    ismember(AllTrials.Session, Sessions), :);


