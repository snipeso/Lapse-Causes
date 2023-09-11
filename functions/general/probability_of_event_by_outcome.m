function ProbEvents = probability_of_event_by_outcome(TrialData, TrialsTable, MaxNaNProportion, MinTrials, onlyResponses)
% TrialData is a T x time matrix
% ProbEvents is a 3 x t matrix

MaxGapProportion = .2;

TimepointsCount = size(TrialData, 2);
ProbEvents = nan(3, TimepointsCount); % Lapses, Late, Fast

if onlyResponses
    TrialTypes = 2:3; % skip lapses
else
    TrialTypes = 1:3;
end

for idxType = TrialTypes
    
    % select subset of trials
    TrialIndexes = TrialsTable.Type==idxType;
    TypeTrialData = TrialData(TrialIndexes, :);

    TypeTrialData = remove_trials_too_much_nan(TypeTrialData, MaxNaNProportion);

    ProbEvent = event_probability(TypeTrialData, MinTrials);

    % event probability has NaNs when there weren't enough trials; if it's
    % just a small gap, then this is interpolated.
    ProbEvent = close_gaps(ProbEvent, numel(ProbEvent)*MaxGapProportion);

    if isempty(ProbEvent) || any(isnan(ProbEvent))
        ProbEvents(idxType, :) = nan(1, TimepointsCount);
    else
        ProbEvents(idxType, :) = ProbEvent;
    end
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function TypeTrialData = remove_trials_too_much_nan(TypeTrialData, MaxNaNProportion)
TrialsTime = size(TypeTrialData, 2);
NanProportion = sum(isnan(TypeTrialData), 2)./TrialsTime;
TypeTrialData(NanProportion>MaxNaNProportion, :) = [];
end


function Prob = event_probability(TypeTrialData, MinTrials)
TrialCount = size(TypeTrialData, 1)-sum(isnan(TypeTrialData), 1); % only normalize by valid timepoints
Prob = sum(TypeTrialData, 1, 'omitnan')./TrialCount;

% set to nan all timepoints that came from an average with too few trials
Prob(TrialCount<MinTrials) = nan;
end


function NewData = close_gaps(Data, MaxSize)
% in an array with nan's, provides interpolated values for smaller gaps

[Starts, Ends] = data2windows(isnan(Data));
if isempty(Starts) || all(isnan(Data))
    NewData = Data;
    return
end

Gaps = (Ends-Starts);

if any(Gaps>MaxSize)
    NewData = nan(size(Data));
    return
end

% if starts with a gap, fill the gap with just the first value
if Starts(1)==1
    Data(1:Ends(1)) = Data(Ends(1)+1);
end

% likewise for if it ends with a gap
if Ends(end) == numel(Data)
    Data(Starts(end):Ends(end)) = Data(Starts(end)-1);
end

% interpolate all missing data
NewData = fillmissing(Data, 'linear');
end
