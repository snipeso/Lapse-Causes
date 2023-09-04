% plot outcome of tasks, to compare PVT and LAT


clear
clc
close all


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% parameters

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
MinTrialCount = Parameters.Trials.MinTotalCount;
SessionBlocks = Parameters.Sessions.Conditions;
SessionBlockLabels = fieldnames(SessionBlocks);
Sessions = Parameters.Sessions;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load trial data

CacheDir = fullfile(Paths.Cache, "C_Assemble_Trial_Information/");


%%% Get PVT trial data
load(fullfile(CacheDir, 'PVT_TrialsTable.mat'), 'TrialsTable') % from script Load_Trials
TrialsTablePVT = TrialsTable;
TraditionalOutcomePVT = TrialsTablePVT.Type;

% for violin plots of reaction times by session
[RTStructPVT, ~, ~] = assemble_reaction_times(TrialsTablePVT, Participants, Sessions.PVT, SessionBlockLabels);

% assign LAT trial outcome criteria to PVT
TrialsTablePVT.Type = TraditionalOutcomePVT;
TrialsTablePVT.Type(~isnan(TrialsTablePVT.RT)) = 1; % full lapse
TrialsTablePVT.Type(TrialsTablePVT.RT<.5) = 3; % correct

% for tally of trial outcomes by eyeclosure
OutcomeCountPVT = assemble_trial_outcome_count(TrialsTablePVT, Participants, Sessions.PVT, [], MinTrialCount);

Thresholds = .3:.1:1; % plot number of eyes closed trials with different RT thresholds
LapseCountPVT = lapse_count_by_threshold(TrialsTable, Participants, Sessions.PVT, TraditionalOutcomePVT, Thresholds);

%%% get LAT trial data
load(fullfile(CacheDir, 'LAT_TrialsTable.mat'), 'TrialsTable') % from script Load_Trials
TrialsTableLAT = TrialsTable;

[RTStructLAT, MeansLAT, Quantile99LAT, Quantile01LAT] = assemble_reaction_times( ...
    TrialsTableLAT, Participants, SessionBlocks);


OutcomeCountLAT = assemble_trial_outcome_count(TrialsTableLAT, Participants, [SessionBlocks.BL, SessionBlocks.SD], {1:3, 4:6}, MinTrialCount);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot

clc

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 25;
PlotProps.Axes.yPadding = 25;
Grid = [2 3];

Legend = {'EC Lapses', 'EO Lapses', 'Slow responses', 'Fast responses'};


figure('Units','centimeters', 'Position',[0 0  PlotProps.Figure.Width, PlotProps.Figure.Height*.5])


%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PVT

%%% A: Reaction time distributions
plot_RTs(RTStructPVT, Grid, [1 1], PlotProps.Indexes.Letters{1}, PlotProps, [.5 2.5], [ 0.1  1.01])
ylabel('PVT reaction times (s)')

disp(['A: N=', num2str(numel(unique(TrialsTablePVT.Participant)))])


%%% B: Proportion of trials

% assemble trial types
disp('B: ')
plot_trial_outcome(OutcomeCountPVT, Grid, [1, 2], PlotProps.Indexes.Letters{2}, Legend, PlotProps)
ylabel('% PVT trials')
legend off

%%% C: proportion of trials as lapses

% plot
chART.sub_plot([], Grid, [1 3], [1 1], true, PlotProps.Indexes.Letters{3}, PlotProps);
chART.plot.plotSpikeBalls(LapseCountPVT, Thresholds, {}, chART.color_picker(1, '', 'red'), 'IQ', PlotProps)
xlabel('Lapse threshold (s)')
ylabel('PVT lapses with EC (% lapses)')

disp_stats_descriptive(LapseCountPVT(:, 3), 'Proportion of PVT Lapses:', '%', 0);


%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LAT

%%% D: Reaction time distributions
plot_RTs(RTStructLAT, Grid, [2 1], PlotProps.Indexes.Letters{4}, PlotProps, [.5 2.5], [ 0.1  1.01])
ylabel('LAT reaction times (s)')

disp(['D: N=', num2str(numel(unique(TrialsTableLAT.Participant)))])


%%% E: Proportion of trials

% assemble data
disp('E: ')

plot_trial_outcome(OutcomeCountLAT, Grid, [2, 2], PlotProps.Indexes.Letters{5}, ...
    Legend, PlotProps)
ylabel('% LAT trials')


%%% F: plot change in lapses with distance
% get trial subsets
EO = TrialsTableLAT.EyesClosed == 0;
EC = TrialsTableLAT.EyesClosed == 1;
Lapses = TrialsTableLAT.Type == 1;

% assign a distance quantile for each trial
qBin = 1/6; % bin size for quantiles
Radius = TrialsTableLAT.Radius;
Edges = quantile(Radius(:), 0:qBin:1);
Bins = discretize(Radius, Edges);
TrialsTableLAT.Radius_Bins = Bins;

% get number of lapses for each distance quantile
[EOLapsesTally, ~] = assemble_matrix_from_table(TrialsTableLAT, EO & Lapses, 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

[ECLapsesTally, ~] = assemble_matrix_from_table(TrialsTableLAT, EC & Lapses, 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

[Tots, ~] = assemble_matrix_from_table(TrialsTableLAT, [], 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

% remove participants with too few trials
MinTotsSplit = MinTrialCount/numel(unique(Bins));
Tots(Tots<MinTotsSplit) = nan;

LapseTally = cat(2, EOLapsesTally, ECLapsesTally);
Tots = cat(2, Tots, Tots);
LapseTally = 100*LapseTally./Tots; % P x SB x RB

LapseTally = LapseTally(:, [1 3 2 4], :); % EO BL, EC Bl, EO SD, EC SD
LapseTally = permute(LapseTally, [1 3 2]); % P x RB x SB

% remove participants with any NaNs
BadParticipants = any(any(isnan(LapseTally), 3), 2);
LapseTally(BadParticipants, :, :) = nan;

% plot parameters
Colors = [flip(getColors([1 2], '', 'gray')); PlotProps.Color.Types(1, :); Red(1, :)]; % generic for BL, lapse color for SD
YLim = [0 60];

% plot
chART.sub_plot([], Grid, [2 3], [1 1], true, PlotProps.Indexes.Letters{6}, PlotProps);
plotSpikeBalls(LapseTally, [], {'BL, EO', 'BL, EC', 'SD, EO', 'SD, EC'}, ...
    Colors, 'IQ', PlotProps)
ylabel('LAT lapses (% trials)')
ylim(YLim)
xlabel('Distance from center (quantiles)')
set(legend, 'Location','northwest')

disp(['F: N=' num2str(nnz(~BadParticipants))])


chART.save_figure('Figure_1', Paths.Results, PlotProps)





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% statistics




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions


function NormalizedOutcomeCount = assemble_trial_outcome_count(TrialsTable, Participants, Sessions, SessionGroups, MinTrialCount)
% Gather data as matrix of P x SB x TT as percent of trials

[EyesOpenOutcomeCount, EyesClosedOutcomeCount] = count_trials_by_eye_status( ...
    TrialsTable, Participants, Sessions, SessionGroups);

OutcomeCount = cat(3, EyesOpenOutcomeCount, EyesClosedOutcomeCount); % EO Lapses, EO Late, EO Fast, EC Lapses, EC Late, EC Fast
% TotalTrialsCount = sum(EyesOpenOutcomeCount, 3)+sum(EyesClosedOutcomeCount, 3);

[OutcomeCount, TotalTrialsCount] = remove_participants_missing_data(OutcomeCount, MinTrialCount);

% normalize by total trials
NormalizedOutcomeCount = 100*OutcomeCount./TotalTrialsCount;
end


function [EyesOpenOutcomeCount, EyesClosedOutcomeCount] = count_trials_by_eye_status( ...
    TrialsTable, Participants, Sessions, SessionGroups)

% get trial subsets
EO = TrialsTable.EyesClosed == 0;
EC = TrialsTable.EyesClosed == 1;

CheckEyes = true;

[EyesOpenOutcomeCount, ~] = assemble_matrix_from_table(TrialsTable, EO, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
[EyesClosedOutcomeCount, ~] = assemble_matrix_from_table(TrialsTable, EC, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);
end


function [OutcomeCount, TotalTrialsCount] = remove_participants_missing_data(OutcomeCount, MinTrialCount)

TotalTrialsCount = sum(OutcomeCount, 3);

% remove participants who dont have enough trials
BadParticipants = TotalTrialsCount<MinTrialCount;
TotalTrialsCount(BadParticipants) = nan;

BadParticipants = any(any(isnan(OutcomeCount), 3), 2); % remove anyone missing any data at any point
OutcomeCount(BadParticipants, :, :) = nan;
end


function LapseCount = lapse_count_by_threshold(TrialsTable, Participants, Sessions, Types, Thresholds)

CheckEyes = true;

% get trial subsets
EyesOpenTrials = TrialsTable.EyesClosed == 0;
EyesClosedTrials = TrialsTable.EyesClosed == 1;

LapseCount = nan(numel(Participants), numel(Thresholds));

for Indx_T = 1:numel(Thresholds)

    TrialsTable.Type = Types;
    TrialsTable.Type(~isnan(TrialsTable.RT)) = 1; % full lapse
    TrialsTable.Type(TrialsTable.RT<Thresholds(Indx_T)) = 3; % correct

    [EyesOpenCount, ~] = assemble_matrix_from_table(TrialsTable, EyesOpenTrials, ...
        'Type', 'tabulate', Participants, Sessions, [], CheckEyes); % P x SB x TT
    [EyesClosedCount, ~] = assemble_matrix_from_table(TrialsTable, EyesClosedTrials, ...
        'Type', 'tabulate', Participants, Sessions, [], CheckEyes);

    EyesOpenLapses = squeeze(EyesOpenCount(:, 2, 1));
    EyesClosedLapses = squeeze(EyesClosedCount(:, 2, 1));

    LapseCount(:, Indx_T) = 100*EyesClosedLapses./(EyesOpenLapses+EyesClosedLapses);
end
end

%%%%%%%%%%%%%%%%%%%%%%
%%% plots

function plot_RTs(DataStruct, Grid, Position, Letter, PlotProps, XLim, YLim)
chART.sub_plot([], Grid, Position, [], true, Letter, PlotProps);
hold on
plot([0 3], [.5 .5], 'Color', PlotProps.Color.Generic, 'LineStyle', ':', 'LineWidth', 1) % demarkation of when answer is late
chART.plot.overlapping_distributions(DataStruct, PlotProps, PlotProps.Color.Participants, .15)
xlim(XLim)
ylim(YLim)
legend off
end

function plot_trial_outcome(OutcomeCount, Grid, Position, Letter, Legend, PlotProps)
% OutcomeCount should be a P x S (BL, SD) x O (EO Lapse, EO Late, EO F, EC L, EC L, EC F)

OutcomeCount = OutcomeCount(:, :, [4, 1, 2, 3]); % only look at EC Lapses, EO lapses, EO late, EO fast
OutcomeCountMeans = squeeze(mean(OutcomeCount, 1, 'omitnan'));

Red = chART.color_picker([1 4], '', 'red'); % dark red for lapses EC
TallyColors = [Red(1, :); flip(chART.color_picker(3))];


chART.sub_plot([], Grid, Position, [], true, Letter, PlotProps);
chART.plot.stacked_bars(OutcomeCountMeans, {'BL', 'SD'}, [0 100], Legend, ...
   PlotProps, TallyColors)

set(legend, 'location', 'northwest')
xlim([0.33 2.66])
end
