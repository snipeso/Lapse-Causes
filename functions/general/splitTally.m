function [ProbType, ProbEvent] = splitTally(Trials, TrialIndexes1, TrialIndexes2, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants)
% ProbType is a P x TT x 2
% ProbEvent is a P x 2 matrix

CheckEyes = true;

% get number of trials by each type for the subset of trials that are closest
[Tally1, ~] = tabulateTable(Trials, TrialIndexes1, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
[Tally2, ~] = tabulateTable(Trials, TrialIndexes2, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

% make relative to total trials
Tots1 = sum(Tally1, 3, 'omitnan');
Prob1 = Tally1./Tots1;

Tots2 = sum(Tally2, 3, 'omitnan');
Prob2 = Tally2./Tots2;

% use only SD data
ProbType = cat(3, squeeze(Prob1), squeeze(Prob2)); % P x TT x D

% remove data that has too few trials
BadParticipants = Tots1 < MinTots | Tots2 < MinTots | BadParticipants;
ProbType(BadParticipants, :, :) = nan;


ProbEvent = [Tots1, Tots2]./(Tots1+Tots2);
ProbEvent(BadParticipants, :) = nan;

