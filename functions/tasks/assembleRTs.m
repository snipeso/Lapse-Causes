function [FlameStruct, MEANS, Q99] = assembleRTs(Trials, Participants, Sessions, SessionLabels)
% from a table of all trials, gets reaction times into struct needed for
% overlapping flame plot.
% Sessions can be either a structure, like Struct.BL = {'BaselinePre',
% 'BaselinePost'}; or just a cell array.


if isstruct(Sessions)
    SessionLabels = fieldnames(Sessions);
elseif ~exist("SessionLabels", 'var') || isempty(SessionLabels)
    SessionLabels = Sessions;
end

nSessions = numel(SessionLabels);

FlameStruct = struct();
MEANS = nan(numel(Participants), nSessions);
Q99 = MEANS; % keep track of distribution for description of RTs
for Indx_S = 1:nSessions
    for Indx_P = 1:numel(Participants)

        if isstruct(Sessions)
            Session = Sessions.(SessionLabels{Indx_S}); % can be more than one
        else
            Session = Sessions{Indx_S};
        end

        RTs = Trials.RT(strcmp(Trials.Participant, Participants{Indx_P}) &...
            contains(Trials.Session, Session));
        RTs(isnan(RTs)) = [];
        FlameStruct.(SessionLabels{Indx_S}).(Participants{Indx_P}) = RTs;

        MEANS(Indx_P, Indx_S) = mean(RTs);
        Q99(Indx_P, Indx_S) = quantile(RTs, .99);
    end
end
