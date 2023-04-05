function [ProbStim, ProbResp] = removeBlankParticipants(ProbStim, ProbResp)
% ProbStim is a P x TT x t matrix, and if any of the TT are nans (so no
% trials for a given type), it removes all data for that participant

for Indx_P = 1:size(ProbStim, 1)
    if any(isnan(ProbStim(Indx_P, :, :)), 'all')
        ProbStim(Indx_P, :, :) = nan;
    end

    if any(isnan(ProbResp(Indx_P, 2:3, :)), 'all') % first is lapses, which of course is blank
        ProbResp(Indx_P, :, :) = nan;
    end
end