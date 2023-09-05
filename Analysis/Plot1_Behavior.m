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


OutcomeCountLAT = assemble_trial_outcome_count(TrialsTableLAT, Participants, ...
   Sessions.LAT, {1:3, 4:6}, MinTrialCount);

RadiusQuantile = 1/6; % bin size for quantiles
LapseCountLAT = lapse_count_by_radius(TrialsTableLAT, RadiusQuantile, Participants, ...
    Sessions.LAT, {1:3, 4:6}, MinTrialCount);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot

clc

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 25;
PlotProps.Axes.yPadding = 25;
Grid = [2 3];

Legend = {'EC Lapses', 'EO Lapses', 'Slow responses', 'Fast responses'};


figure('Units','centimeters', 'Position',[0 0  PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

%%% PVT
% A: Reaction time distributions
plot_RTs(RTStructPVT, Grid, [1 1], PlotProps.Indexes.Letters{1}, PlotProps, [.5 2.5], [ 0.1  1.01])
ylabel('PVT reaction times (s)')

% B: Proportion of trials
plot_trial_outcome(OutcomeCountPVT, Grid, [1, 2], PlotProps.Indexes.Letters{2}, Legend, PlotProps)
ylabel('% PVT trials')
legend off

% C: proportion of trials as lapses
 plot_lapses_by_threshold(LapseCountPVT, Thresholds, Grid, [1 3], PlotProps.Indexes.Letters{3}, PlotProps)
ylabel('PVT lapses with EC (% lapses)')


%%% LAT
% D: Reaction time distributions
plot_RTs(RTStructLAT, Grid, [2 1], PlotProps.Indexes.Letters{4}, PlotProps, [.5 2.5], [ 0.1  1.01])
ylabel('LAT reaction times (s)')

% E: Proportion of trials
plot_trial_outcome(OutcomeCountLAT, Grid, [2, 2], PlotProps.Indexes.Letters{5}, ...
    Legend, PlotProps)
ylabel('% LAT trials')

% F: plot change in lapses with distance
LegendRadius = {'BL, EO', 'BL, EC', 'SD, EO', 'SD, EC'};
plot_radius_lapses(LapseCountLAT, Grid, [2 3], PlotProps.Indexes.Letters{6}, ...
    LegendRadius, [0 60], PlotProps)
ylabel('LAT lapses (% trials)')


chART.save_figure('Figure_1', Paths.Results, PlotProps)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% statistics



disp_stats_descriptive(LapseCountPVT(:, 3), 'Proportion of PVT Lapses:', '%', 0);





%%
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


function LapseCount = lapse_count_by_radius(TrialsTable, RadiusQuantile, Participants, Sessions, SessionGroups, MinTrialCount)

CheckEyes = true;

% get trial subsets
EO = TrialsTable.EyesClosed == 0;
EC = TrialsTable.EyesClosed == 1;
Lapses = TrialsTable.Type == 1;

% assign a distance quantile for each trial
Radius = TrialsTable.Radius;
Edges = quantile(Radius(:), 0:RadiusQuantile:1);
Bins = discretize(Radius, Edges);
TrialsTable.Radius_Bins = Bins;

% get number of lapses for each distance quantile
[EyesOpenLapsesCount, ~] = assemble_matrix_from_table(TrialsTable, EO & Lapses, 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

[EyesClosedLapsesCount, ~] = assemble_matrix_from_table(TrialsTable, EC & Lapses, 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

[TrialsCount, ~] = assemble_matrix_from_table(TrialsTable, [], 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

% remove participants with too few trials
MinTrialsSplit = MinTrialCount/numel(unique(Bins));
TrialsCount(TrialsCount<MinTrialsSplit) = nan;

LapseCount = cat(2, EyesOpenLapsesCount, EyesClosedLapsesCount);
TrialsCount = cat(2, TrialsCount, TrialsCount);
LapseCount = 100*LapseCount./TrialsCount; % P x SB x RB

LapseCount = LapseCount(:, [1 3 2 4], :); % EO BL, EC Bl, EO SD, EC SD
LapseCount = permute(LapseCount, [1 3 2]); % P x RB x SB

% remove participants with any NaNs
BadParticipants = any(any(isnan(LapseCount), 3), 2);
LapseCount(BadParticipants, :, :) = nan;
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

disp([Letter, ': N=', num2str(numel(fieldnames(DataStruct.BL)))])
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

disp([Letter, ': N=' num2str(sum(~isnan(mean(mean(OutcomeCount, 2), 3))))])
end


function plot_lapses_by_threshold(LapseCount, Thresholds, Grid, Position, Letter, PlotProps)
chART.sub_plot([], Grid, Position, [1 1], true, Letter, PlotProps);
Red = chART.color_picker([1 4], '', 'red'); % dark red for lapses EC
chART.plot.average_rows(LapseCount, Thresholds, {}, 'IQ', PlotProps, Red(1, :))
xlabel('Lapse threshold (s)')

disp([Letter, ': N=', num2str(nnz(~isnan(mean(LapseCount, 2))))])
end


function plot_radius_lapses(LapseCount, Grid, Position, Letter, Legend, YLim, PlotProps)

Red = chART.color_picker([1 4], '', 'red'); % dark red for lapses EC
Colors = [flip(chART.color_picker([1 2], '', 'gray'));
    chART.color_picker(1, '', 'red');
    Red(1, :)]; % generic for BL, lapse color for SD

chART.sub_plot([], Grid, Position, [1 1], true, Letter, PlotProps);
chART.plot.average_rows(LapseCount, [], Legend, 'IQ', PlotProps, Colors)
ylim(YLim)
xlabel('Distance from center (quantiles)')
set(legend, 'Location','northwest')

disp([Letter, ': N=', num2str(nnz(~isnan(mean(mean(LapseCount, 2), 3))))])
end



%%%%%%%%%%%%%%%%%%%%
%%% statistics

function describe_reaction_times()

%%% RTs
% change in mean RTs from BL to SD
dispDescriptive(1000*MeansLAT(:, 1),'BL RT', ' ms', '%.0f');
dispDescriptive(1000*MeansLAT(:, 2),'SD RT', ' ms', '%.0f');

Stats = paired_ttest(MeansLAT(:, 1), MeansLAT(:, 2), StatsP);
disp_stats(Stats, [1 1], 'SD effect on RTs:');

% distribution of RTs to show that they don't go over 1s
SB_Indx = 2;
dispDescriptive(1000*Quantile99LAT(:, SB_Indx), 'RT for 99% of SD data:', ' ms', 0);
end


function display_lapse_outcome()
% TODO

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

end


function describe_lapses()



%%% LAT
disp('---LAT---')
[Data, EO_Matrix, EC_Matrix] = assembleLapses(TrialsTableLAT, Participants, Sessions, SessionGroups, MinTrialCount);

% just lapses
Tots = EO_Matrix(:, :, 1) + EC_Matrix(:, :, 1);
ECvEO_Lapses = 100*EO_Matrix(:, :, 1)./Tots;

% all
Tots = sum(EO_Matrix, 3)+sum(EC_Matrix, 3);
EOvAll_Matrix = 100*EO_Matrix(:, :, 1)./Tots; % Matrix is EO lapses, late, correct, EC lapses


% proportion of EC lapses out of overall lapses
dispDescriptive(squeeze(ECvEO_Lapses(:, 2)), 'SD EO vs All Lapses', '%', '%.0f');
dispDescriptive(squeeze(EOvAll_Matrix(:, 1)), 'BL EO vs All Trials', '%', '%.0f');
dispDescriptive(squeeze(EOvAll_Matrix(:, 2)), 'SD EO vs All Trials', '%', '%.0f');

Stats = paired_ttest(EOvAll_Matrix(:, 1), EOvAll_Matrix(:, 2), StatsP);
disp_stats(Stats, [1 1], 'SD effect on EO lapses:');
disp('*')


%%% PVT
disp('---PVT---')
    TrialsTablePVT.Type = OldTypesPVT;
[Data, EO_Matrix, EC_Matrix] = assembleLapses(TrialsTablePVT, Participants, [Sessions_PVT(2), Sessions_PVT(2)], [],  MinTrialCount);

% just lapses
Tots = EO_Matrix(:, :, 1) + EC_Matrix(:, :, 1);
ECvEO_Lapses = 100*EO_Matrix(:, :, 1)./Tots;

% all
Tots = sum(EO_Matrix, 3)+sum(EC_Matrix, 3);
EOvAll_Matrix = 100*EO_Matrix(:, :, 1)./Tots; % Matrix is EO lapses, late, correct, EC lapses


% proportion of EC lapses out of overall lapses
dispDescriptive(squeeze(ECvEO_Lapses(:, 2)), 'SD EO vs All Lapses', '%', '%.0f');
dispDescriptive(squeeze(EOvAll_Matrix(:, 2)), 'SD EO vs All Trials', '%', '%.0f');
disp('*')
end


function anova_radius_sleep()

% all radii
Stats_Radius = anova2way(LapseTally(:, :, [1 3]), {'Distance', 'Time'}, string(1:numel(unique(Bins))), ...
    {'BL', 'SD'}, StatsP);

% exluding last two radii
Stats_Radius_Redux = anova2way(LapseTally(:, 1:3, [1 3]), {'Distance', 'Time'}, string(1:numel(unique(Bins))), ...
    {'BL', 'SD'}, StatsP);


end


function lapses_by_quantile()
% close lapses
dispDescriptive(squeeze(LapseTally(:, 1, 1)), 'BL EO close lapses', '%', '%.1f');

% far lapses
dispDescriptive(squeeze(LapseTally(:, end, 1)), 'BL EO far lapses', '%', '%.1f');
disp('*')

% each distance
for Indx_Q = 1:size(LapseTally, 2)
    dispDescriptive(squeeze(LapseTally(:, Indx_Q, 3)-LapseTally(:, Indx_Q, 1)), ... ...
        ['BL v SD EO lapses Q', num2str(Indx_Q)], '%', '%.1f');
end
disp('*')


% all distance
disp_stats(Stats_Radius, {'Distance', 'Time', 'Interaction'}, 'Distance vs Time:');
disp_stats(Stats_Radius_Redux, {'Distance', 'Time', 'Interaction'}, 'Distance vs Time, first 3 quantiles:');



end
