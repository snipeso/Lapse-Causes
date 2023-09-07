function TrialData = chop_trials(Data, SampleRate, TriggerLatencies, Window)
% Data is a ch x t matrix

TriggerLatencies(isnan(TriggerLatencies)) = [];

ChannelCount = size(Data, 1);

Starts = round(TriggerLatencies+Window(1)*SampleRate);
Ends = round(TriggerLatencies+Window(2)*SampleRate)-1;

if isempty(Starts) || numel(Starts)<1
    TrialData = [];
    return
end

TrialData = nan(numel(Starts), ChannelCount, Ends(1)-Starts(1)+1);
for idxTrials = 1:numel(Starts)
    TrialData(idxTrials, :, :) = Data(:, Starts(idxTrials):Ends(idxTrials));

end

% if only 1 channel, remove extra dimention
TrialData = squeeze(TrialData);