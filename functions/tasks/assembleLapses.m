function [LapsesCount, EyesOpenOutcomeCount, EyesClosedOutcomeCount] = assembleLapses(TrialsTable, Participants, Sessions, SessionGroups, MinTrialCount)
% Gather data as matrix of P x SB x TT as percent of trials

% get trial subsets
EO = TrialsTable.EyesClosed == 0;
EC = TrialsTable.EyesClosed == 1;

CheckEyes = true;

[EyesOpenOutcomeCount, ~] = assemble_matrix_from_table(TrialsTable, EO, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
[EyesClosedOutcomeCount, ~] = assemble_matrix_from_table(TrialsTable, EC, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

TotalTrialsCount = sum(EyesOpenOutcomeCount, 3)+sum(EyesClosedOutcomeCount, 3);
OutcomeCount = cat(3, EyesOpenOutcomeCount, EyesClosedOutcomeCount(:, :, 1));

% remove participants who dont have enough trials
BadParticipants = TotalTrialsCount<MinTrialCount;
TotalTrialsCount(BadParticipants) = nan;

BadParticipants = any(any(isnan(OutcomeCount), 3), 2); % remove anyone missing any data at any point
OutcomeCount(BadParticipants, :, :) = nan;


% normalize by total trials
LapsesCount = 100*OutcomeCount./TotalTrialsCount;


% display how much data is in not-plotted task types
NotPlotted = 100*mean(sum(EyesClosedOutcomeCount(:, :, 2:3), 3)./TotalTrialsCount, 'omitnan');

% indicate how much data was removed
disp(['N=', num2str(numel(BadParticipants) - nnz(BadParticipants))])
disp(['Not plotted data: ', num2str(NotPlotted(2), '%.2f'), '%'])


% indicate proportion of lapses that are eyes-closed
EOL = squeeze(LapsesCount(:, 2, 1));
ECL = squeeze(LapsesCount(:, 2, 4));

disp_stats_descriptive( 100*ECL./(EOL+ECL), 'EC lapses:', '% lapses', 0);
disp_stats_descriptive(ECL, 'EC lapses:', '% tot', 0);


% total number of lapses
OutcomeCount(:, :, 1) =  OutcomeCount(:, :, 1) + OutcomeCount(:, :, 4);
OutcomeCount = OutcomeCount(:, :, 1:3);

D = 100*OutcomeCount./TotalTrialsCount;
disp_stats_descriptive(squeeze(D(:, 1, 1)), 'BL lapses:', '% tot', 0);
disp_stats_descriptive(squeeze(D(:, 2, 1)), 'SD lapses:', '% tot', 0);