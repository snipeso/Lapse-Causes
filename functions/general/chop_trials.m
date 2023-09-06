function TrialData = chop_trials(Data, SampleRate, Events, Trigger, Window)

Latencies = [Events.latency];
Types = {Events.type};
ChannelCount = size(Data, 1);

StimLatencyIndexes = strcmp(Types, Trigger);
StimLatencies = Latencies(StimLatencyIndexes);

Starts = round(StimLatencies-Window(1)*SampleRate);
Ends = round(StimLatencies+Window(2)*SampleRate);

TrialData = nan(numel(Starts),ChannelCount, Ends(1)-Starts(1)+1);
for idxTrials = 1:numel(Starts)
    TrialData(idxTrials, :, :) = Data(:, Starts(idxTrials):Ends(idxTrials));

end

% if only 1 channel, remove extra dimention
TrialData = squeeze(TrialData);