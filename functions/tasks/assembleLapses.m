function [Data, EO_Matrix, EC_Matrix] = assembleLapses(Trials, Participants, Sessions, SessionGroups, MinTots)
% Gather data as matrix of P x SB x TT as percent of trials

% get trial subsets
EO = Trials.EyesClosed == 0;
EC = Trials.EyesClosed == 1;

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


% indicate proportion of lapses that are eyes-closed
EOL = squeeze(Data(:, 2, 1));
ECL = squeeze(Data(:, 2, 4));

dispDescriptive( 100*ECL./(EOL+ECL), 'EC lapses:', '% lapses', 0);
dispDescriptive(ECL, 'EC lapses:', '% tot', 0);


% total number of lapses
Matrix(:, :, 1) =  Matrix(:, :, 1) + Matrix(:, :, 4);
Matrix = Matrix(:, :, 1:3);

D = 100*Matrix./Tots;
dispDescriptive(squeeze(D(:, 1, 1)), 'BL lapses:', '% tot', 0);
dispDescriptive(squeeze(D(:, 2, 1)), 'SD lapses:', '% tot', 0);