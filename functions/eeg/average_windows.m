function WindowedStim = average_windows(ProbTrialStim, TrialTime, Windows)
% average timepoints into windows. PropTrialStim is a P x TT x Ch x t
% matrix. TrialTime is a vector of the trial timepoints in seconds. Windows is a W x 2
% array in seconds

WindowsCount = size(Windows, 1);
ParticipantCount = size(ProbTrialStim, 1);
ChannelCount = size(ProbTrialStim, 3);

WindowedStim = nan(ParticipantCount, 3, ChannelCount, 2, WindowsCount);

for idxWindow = 1:WindowsCount
    Edges = dsearchn(TrialTime', Windows(idxWindow, :)');
    WindowedStim(:, :, :, :, idxWindow) = mean(ProbTrialStim(:, :, :, :, Edges(1):Edges(2)), ...
        5, 'omitnan');
end
