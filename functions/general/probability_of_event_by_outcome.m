function ProbEvent = probability_of_event_by_outcome(TrialData, TrialsTable, MaxNaNProportion, MinTrials, onlyResponses)

Dims = size(TrialData);
ProbEvent = nan(3, Dims(2)); % Lapses, Late, Fast

if onlyResponses
    TrialTypes = 2:3; % skip lapses
else
    TrialTypes = 1:3;
end

for idxType = TrialTypes

    Trial_Indexes = TrialsTable.Type==idxType;
    TypeTrialData = TrialData(Trial_Indexes, :);

    ProbEvent(idxType, :) = probability_event(TypeTrialData, MaxNaNProportion, MinTrials);
end
end



function Prob = probability_event(TypeTrialData, MaxNaNProportion, MinTrials)
% gets the probability of an event.
% AllTrials is a Trials x time matrix of ones and zeros and nans
% MinTrials is the minimum number of trials to keep, otherwise Prob is just
% nans.
% minNanProportion is the minimum timepoints that can be nans before
% removing that trial from the batch

TrialsCount = size(TypeTrialData, 1);
Pnts = size(TypeTrialData);
MaxSize = Pnts*.2;

% make all trial nan if there's not much of it
NanProportion = sum(isnan(TypeTrialData), 2)/Pnts;
TypeTrialData(NanProportion>MaxNaNProportion, :) = nan;

% check if there's enough data
Nans = sum(isnan(TypeTrialData), 1);
if isempty(TypeTrialData) || TrialsCount < MinTrials || nnz(TrialsCount - Nans < MinTrials)/Pnts > MaxNaNProportion % makes sure every timepoint had at least 10 trials
    Prob = nan(1, Pnts);
    return
end

% average trials
nTrialsPoints = sum(TypeTrialData==1)+sum(TypeTrialData==0); % for each timepoint
Prob = sum(TypeTrialData, 1, 'omitnan')./nTrialsPoints;

% remove timepoints with not enough trials involved
Gaps = TrialsCount - Nans < MinTrials;
if any(Gaps)
    Prob(Gaps) = nan;

    Prob = close_gaps(Prob, MaxSize);
    if any(isnan(Prob))
        Prob = nan(size(Prob));
    end
end
end


function NewData = close_gaps(Data, MaxSize)
% in an array with nan's, provides interpolated values for smaller gaps

[Starts, Ends] = data2windows(isnan(Data));

Gaps = (Ends-Starts);



% fill edges with last result to avoid any edge artefacts
if Starts(1)==1
    Data(1:Ends(1)) = Data(Ends(1)+1);
end

if Ends(end) == numel(Data)
    Data(Starts(end):Ends(end)) = Data(Starts(end)-1);
end

    % keep list of only larger gaps
SmallGaps = Gaps<MaxSize;
    Starts(SmallGaps) = [];
Ends(SmallGaps) = [];

% interpolate all missing data
NewData = fillmissing(Data, 'linear');

% restore nans for the larger gaps
for Indx_G = 1:numel(Starts)
    NewData(Starts(Indx_G):Ends(Indx_G)) = nan;
end
end
