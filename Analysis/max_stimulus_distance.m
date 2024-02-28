function [MaxStimulusDistance, TitleTag] = max_stimulus_distance(TrialsTable, ...
    OnlyClosestStimuli, MaxStimulusDistanceProportion, TitleTag)
% specify only close trials, or all trials
if OnlyClosestStimuli
    TitleTag = [ TitleTag, '_Close'];
    MaxStimulusDistance = quantile(TrialsTable.Radius, MaxStimulusDistanceProportion);
else
    MaxStimulusDistance = max(TrialsTable.Radius);
end
end