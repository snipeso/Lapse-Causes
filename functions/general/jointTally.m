function ProbType = jointTally(Trials, TrialSubset, TrialIndexes1, TrialIndexes2, Participants, ...
    Sessions, SessionGroups)
% ProbType is a P x TT x 2
% ProbEvent is a P x 2 matrix

if isempty(TrialSubset)
    TrialSubset = ones(size(Trials, 1), 1);
end


% flexible if providing session groups or just list of sessions
if exist('SessionGroups', 'var') && ~isempty(SessionGroups)
    nSessions = numel(SessionGroups);
else
    nSessions = numel(Sessions);
    SessionGroups = num2cell(1:nSessions);
end


ProbType = nan(numel(Participants), numel(SessionGroups), 3);


for Indx_P = 1:numel(Participants)
    for Indx_S = 1:nSessions

        % get all trials for that session+participant
        CurrentTrials = strcmp(Trials.Participant, Participants{Indx_P}) & ...
            ismember(Trials.Session, Sessions(SessionGroups{Indx_S})) & TrialSubset;

        % check if the dataset was missing, so should output NaN
        disp(nnz(CurrentTrials))
        if nnz(CurrentTrials)==0
            continue
        end

        if exist('CheckEyes', 'var') && CheckEyes && all(isnan(Trials.EC(CurrentTrials)))
            continue
        end

        % now get all trials, selecting based on trial indices
        AllTrials = strcmp(Trials.Participant, Participants{Indx_P}) & ...
            ismember(Trials.Session, Sessions(SessionGroups{Indx_S})) & ...
            TrialSubset;
        Trials1 = AllTrials & TrialIndexes1;
        Trials2 = AllTrials & TrialIndexes2;

        Tot = nnz(AllTrials);

        % Type 1 proportion
        ProbType(Indx_P, Indx_S, 1) = nnz(Trials1)/Tot;

        % Type 2 proportion
        ProbType(Indx_P, Indx_S, 2) = nnz(Trials2)/Tot;

        % Join proportion
        ProbType(Indx_P, Indx_S, 3) = nnz(Trials1 & Trials2)/Tot;

    end
end


% % get number of trials by each type for the subset of trials that are closest
% [Tally1, ~] = tabulateTable(Trials, TrialSubset & TrialIndexes1, 'Type', 'tabulate', ...
%     Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
% [Tally2, ~] = tabulateTable(Trials, TrialSubset & TrialIndexes2, 'Type', 'tabulate', ...
%     Participants, Sessions, SessionGroups, CheckEyes);
%
% [Tally12, ~] = tabulateTable(Trials, TrialIndexes1 & TrialIndexes2, 'Type', 'tabulate', ...
%     Participants, Sessions, SessionGroups, CheckEyes);
