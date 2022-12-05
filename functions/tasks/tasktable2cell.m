function CellTrials = tasktable2cell(Trials, Participants, Sessions, Column)
% provides all attributes of a series of trials (like trial type) as an
% array in a cell structure of P x S.

CellTrials = cell([numel(Participants), numel(Sessions)]);

for Indx_P = 1:numel(Participants)
    for Indx_S = 1:numel(Sessions)
        Data = Trials.(Column)(strcmp(Trials.Participant, Participants{Indx_P}) & ...
            strcmp(Trials.Session, Sessions{Indx_S}));
        CellTrials{Indx_P, Indx_S} = Data;
    end
end