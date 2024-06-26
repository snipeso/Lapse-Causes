function ProbEvents = probability_of_event_by_outcome(TrialData, TrialsTable, ...
    MaxNaNProportion, MinTrials, onlyResponses)
% 
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

    % averaging trials, gives event probability for 1s and 0s, and average
    % globality otherwise
    ProbEvent = event_probability(TypeTrialData, MinTrials);

    % some timepoints may be missing enough trials, so they are interpolated
    ProbEvent = close_small_gaps(ProbEvent, numel(ProbEvent)*MaxGapProportion);

    if isempty(ProbEvent) || any(isnan(ProbEvent))
        ProbEvents(idxType, :) = nan(1, TimepointsCount);
    else
        ProbEvents(idxType, :) = ProbEvent;
    end
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions


function Prob = event_probability(TypeTrialData, MinTrials)

% number of trials for each timepoint, excluding NaNs
TrialCount = size(TypeTrialData, 1)-sum(isnan(TypeTrialData), 1);

% average trials for each timepoint
Prob = sum(TypeTrialData, 1, 'omitnan')./TrialCount;

% set to nan all timepoints that came from an average with too few trials
Prob(TrialCount<MinTrials) = nan;
end


function TypeTrialData = remove_trials_too_much_nan(TypeTrialData, MaxNaNProportion)
% remove trials that are missing too much data in time
%TypeTrialData is Trials x time

TrialsTime = size(TypeTrialData, 2);
NanProportion = sum(isnan(TypeTrialData), 2)./TrialsTime;
TypeTrialData(NanProportion>MaxNaNProportion, :) = [];
end

