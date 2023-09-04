function [Matrix, Things] = assemble_matrix_from_table(Trials, TrialIndexes, Column, ...
    Aggregator, Participants, Sessions, SessionGroups, CheckEyes)
% Trials is a table. Trial Indexes is 1s and 0s indicating which trials to
% use. Column is the label of the column on which to do the Aggregator
% operation. SessionGroups is optional, to pool multiple sessions.
% CheckEyes is optional, and it checks whether the eye-tracking data even
% exists for that trial
% puts data from table into a matrix
% in Lapse-Causes

if isempty(TrialIndexes)
    TrialIndexes = ones(size(Trials, 1), 1);
end

if exist('SessionGroups', 'var') && ~isempty(SessionGroups)
    nSessions = numel(SessionGroups);
else
    nSessions = numel(Sessions);
    SessionGroups = num2cell(1:nSessions);
end

if strcmp(Aggregator, 'tabulate')
    Data = Trials.(Column);
    if isnumeric(Data)
        Data(isnan(Data)) = [];
    end
    Table = tabulate(Data);
    Things = Table(:, 1);
    Matrix = nan(numel(Participants), nSessions, numel(Things));

    if islogical(Things)
        Things = string(double(Things));
    end
else
    Things = [];
    Matrix = nan(numel(Participants), nSessions);
end

for Indx_P = 1:numel(Participants)
    for Indx_S = 1:nSessions

        % get all trials for that session+participant
        CurrentTrials = strcmp(Trials.Participant, Participants{Indx_P}) & ...
            ismember(Trials.Session, Sessions(SessionGroups{Indx_S}));
        Data = Trials.(Column)(CurrentTrials);

        % check if the dataset was missing, so should output NaN
        if isempty(Data)
            continue
        end

        if exist('CheckEyes', 'var') && CheckEyes && all(isnan(Trials.EyesClosed(CurrentTrials)))
            continue
        end

        % now get all trials, selecting based on trial indices
        CurrentTrials = strcmp(Trials.Participant, Participants{Indx_P}) & ...
            ismember(Trials.Session, Sessions(SessionGroups{Indx_S})) & ...
            TrialIndexes;

        Data = Trials.(Column)(CurrentTrials);

        if isnumeric(Data)
            Data(isnan(Data)) = [];
        end

        switch Aggregator
            case 'sum'
                Matrix(Indx_P, Indx_S) = sum(Data, 'omitnan');
            case 'mean'
                Matrix(Indx_P, Indx_S) = mean(Data, 'omitnan');
            case 'top10mean'
                Data = sort(Data);
                Top10 = quantile(Data, .1);
                Matrix(Indx_P, Indx_S) = mean(Data(Data<Top10), 'omitnan');
            case 'bottom10mean'
                Data = sort(Data);
                Bottom10 = quantile(Data, .9);
                Matrix(Indx_P, Indx_S) = mean(Data(Data>Bottom10), 'omitnan');
            case 'median'
                Matrix(Indx_P, Indx_S) = median(Data, 'omitnan');
            case 'std'
                Matrix(Indx_P, Indx_S) = std(Data, 'omitnan');
            case 'tabulate'

                if numel(Things) > 1
                    Table = tabulate(Data);

                    if isempty(Table)
                        Matrix(Indx_P, Indx_S, :) = 0;
                    else
                        Tots = zeros(numel(Things), 1);
                        Tots(ismember(Things, Table(:, 1))) = Table(:, 2);
                        Matrix(Indx_P, Indx_S, :) = Tots;
                    end
                else
                    Matrix(Indx_P, Indx_S) = numel(Data);
                end
        end
    end
end