function [Data, EO_Matrix, EC_Matrix] = assembleLapses(Trials, Participants, Sessions, SessionGroups, MinTots)
% Gather data as matrix of P x SB x TT as percent of trials

% get trial subsets
EO = Trials.EC == 0;
EC = Trials.EC == 1;

CheckEyes = true;

[EO_Matrix, ~] = tabulateTable(Trials, EO, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
[EC_Matrix, ~] = tabulateTable(Trials, EC, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

Tots = sum(EO_Matrix, 3)+sum(EC_Matrix, 3);

% remove participants who dont have enough trials
BadParticipants = Tots<MinTots;
Tots(BadParticipants) = nan;

Matrix = cat(3, EO_Matrix, EC_Matrix(:, :, 1));

BadParticipants = any(any(isnan(Matrix), 3), 2); % remove anyone missing any data at any point
Matrix(BadParticipants, :, :) = nan;


% normalize by total trials
Data = 100*Matrix./Tots;


% display how much data is in not-plotted task types
NotPlotted = 100*mean(sum(EC_Matrix(:, :, 2:3), 3)./Tots, 'omitnan');

% indicate how much data was removed
disp(['N=', num2str(numel(BadParticipants) - nnz(BadParticipants))])
disp(['Not plotted data: ', num2str(NotPlotted(2), '%.2f'), '%'])
