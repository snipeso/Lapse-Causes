function [EyesOpenTrialIndexes, EyetrackingQualityTable, TitleTag] = ...
    only_eyes_open_trials(TrialsTable, CheckEyes, Paths, Task)
TitleTag = '';
if CheckEyes
    TitleTag = [TitleTag, '_EO'];
    EyesOpenTrialIndexes = TrialsTable.EyesClosed == 0;
    EyetrackingQualityTable = readtable(fullfile(Paths.QualityCheck, 'EyeTracking', ...
        ['DataQuality_', Task, '_Pupils.csv']));
else
    EyesOpenTrialIndexes = true(size(TrialsTable, 1), 1);
    EyetrackingQualityTable = [];
end
end
