function PooledTrials = poolTrials(Trials)
% Trials is a Tr x Ch x t boolean, returns a Tr x t boolean, with nans

PooledTrials = double(squeeze(any(Trials==1, 2)));
Nans = squeeze(isnan(Trials(:, 1, :)));

PooledTrials(Nans) = nan;