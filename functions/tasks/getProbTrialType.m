function [ProbStim, ProbResp] = getProbTrialType(TrialsStim, TrialsResp, Trials, minNanProportion, minTrials)
% function to split trials by trial type, and identify the probability of
% an event (encoded in TrialsStim and TrialsResp) for every timepoint.
% Outputs a TT x t array for both stim locked and responsed locked
% matrices.

Dims = size(TrialsStim);

nTrialTypes = 3; % Lapse, Late, Correct
ProbStim = nan(nTrialTypes, Dims(2));
ProbResp = ProbStim; % even if only late and correct, keeps black to make it easier to loop

for Indx_TT = 1:nTrialTypes

    % choose trials
    Trial_Indexes = Trials.Type==Indx_TT;
    TypeTrials_Stim = TrialsStim(Trial_Indexes, :);

    ProbStim(Indx_TT, :) = probEvent(TypeTrials_Stim, minNanProportion, minTrials);


    % response trials
    if Indx_TT > 1 % not lapses
        TypeTrials_Resp = TrialsResp(Trial_Indexes, :);
        ProbResp(Indx_TT, :) = ...
            probEvent(TypeTrials_Resp, minNanProportion, minTrials);
    end
end