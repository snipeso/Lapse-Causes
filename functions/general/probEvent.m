function Prob = probEvent(AllTrials, minNanProportion, minTrials)
% gets the probability of an event.
% AllTrials is a Trials x time matrix of ones and zeros and nans
% MinTrials is the minimum number of trials to keep, otherwise Prob is just
% nans.
% minNanProportion is the minimum timepoints that can be nans before
% removing that trial from the batch

Dims = size(AllTrials);
nTrials = Dims(1);
Pnts = Dims(2);
MaxSize = Pnts*.2;

% make all trial nan if there's not much of it
NanProportion = sum(isnan(AllTrials), 2)/Pnts;
AllTrials(NanProportion>minNanProportion, :) = nan;

% check if there's enough data
Nans = sum(isnan(AllTrials), 1);
if isempty(AllTrials) || nTrials < minTrials || nnz(nTrials - Nans < minTrials)/Pnts > minNanProportion % makes sure every timepoint had at least 10 trials
    Prob = nan(1, Pnts);
    return
end

% average trials
nTrialsPoints = sum(AllTrials==1)+sum(AllTrials==0); % for each timepoint
Prob = sum(AllTrials, 1, 'omitnan')./nTrialsPoints;

% remove timepoints with not enough trials involved
Gaps = nTrials - Nans < minTrials;
if any (Gaps)
    Prob(Gaps) = nan;

    Prob = closeGaps(Prob, MaxSize);
    if any(isnan(Prob))
        Prob = nan(size(Prob));
    end
end
