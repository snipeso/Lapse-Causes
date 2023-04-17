function AJP = adjustedJointProportion(Trials, TrialSubset, EventType, Window, ...
    TrialType, Participants, MinTots)
% Outputs a P x 2 matrix, with col1 indicating the expected joint
% proportion, adjusted as a proportion of total events, and col2 the
% observed joint proportion, adjusted by total events


if isempty(TrialSubset)
    TrialSubset = ones(size(Trials, 1), 1);
end

AJP = nan(numel(Participants), 3);

for Indx_P = 1:numel(Participants)

    % get all trials for that session+participant
    AllTrials = strcmp(Trials.Participant, Participants{Indx_P}) & TrialSubset;

    % check if the dataset was missing, so should output NaN
    if nnz(AllTrials)<MinTots
        continue
    end

    % proportion of trials with that trial type (e.g. % lapses)
    TT = Trials.Type == TrialType;
    TTProp = nnz(AllTrials & TT)/nnz(AllTrials);

    % proportion of pre-trial event
    Ev = Trials.([EventType, '_', Window, '_BR'])==1;
    EvProp = nnz(AllTrials & Ev)/nnz(AllTrials);

    % observed joint proportion
    OJ = Trials.([EventType, '_', Window])== 1 & TT;
    OJProp =  nnz(AllTrials & OJ)/nnz(AllTrials);

    % expected joint proportion
%     EJProp = TTProp * EvProp;

    AJP(Indx_P, 1) = EvProp;
    AJP(Indx_P, 2) = TTProp;
    AJP(Indx_P, 3) =OJProp;

    %
    %     % adjust to proportion of event
    %     AJP(Indx_P, 1) = EJProp/EvProp; %NB: this is the same as TTprop
    %     AJP(Indx_P, 2) = OJProp/EvProp;
    %     if OJProp/EvProp>1 % if EVProp ==0, this gets to infinity
    %  AJP(Indx_P, 2) = 1;
    %     end
end
