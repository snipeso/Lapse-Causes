% plot outcome of task performance, to compare PVT and LAT
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
StatParameters = Parameters.Stats;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load trial data

CacheDir = fullfile(Paths.Cache, "Trial_Information");

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
[LapseCountLAT, RadiusBinsLAT] = lapse_count_by_radius(TrialsTableLAT, RadiusQuantile, Participants, ...
    Sessions.LAT, {1:3, 4:6}, MinTrialCount);

%%
%%% get questionnaire data
KSSLAT = assemble_questionnaire(fullfile(Paths.AnalyzedData, "Questionnaires/", 'LAT_All.csv'), ...
    Participants, Sessions.LAT);
% KSSLAT = [mean(KSSLAT(:, 1:3), 2, 'omitnan'), mean(KSSLAT(:, 4:6), 2, 'omitnan')];

KSSPVT = assemble_questionnaire(fullfile(Paths.AnalyzedData, "Questionnaires/", 'PVT_All.csv'), ...
    Participants, Sessions.PVT);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot

clc
close all

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Scatter.Size = 50;
Grid = [2 4];

Legend = {'EC lapses', 'EO lapses', 'Slow responses', 'Fast responses'};


figure('Units','centimeters', 'Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.4])

%%% PVT
% A: KSS
plot_questionnaire(KSSPVT, {'BL', 'SD'}, Parameters.Stats, Grid,[1 1], PlotProps.Indexes.Letters{1}, PlotProps)
ylabel('PVT sleepiness (KSS)')

% B: Reaction time distributions
plot_RTs(RTStructPVT, Grid, [1 2], PlotProps.Indexes.Letters{2}, PlotProps, [.5 2.5], [ 0.1 1.01])
ylabel('PVT reaction times (s)')

% C: Proportion of trials
plot_trial_outcome(OutcomeCountPVT, Grid, [1, 3], PlotProps.Indexes.Letters{3}, Legend, PlotProps)
ylabel('% PVT trials')
legend off

% D: proportion of trials as lapses
plot_lapses_by_threshold(LapseCountPVT, Thresholds, Grid, [1 4], PlotProps.Indexes.Letters{4}, PlotProps)
ylabel('PVT lapses EC (%lapses)')


%%% LAT

% E: KSS
plot_questionnaire(KSSLAT(:, [1 2 4 5 6 3]), {'Baseline', 'Pre', 'SD1', 'SD2','SD3', 'Post'}, Parameters.Stats, Grid,[2 1], PlotProps.Indexes.Letters{5}, PlotProps)
ylabel('LAT sleepiness (KSS)')


% F: Reaction time distributions
plot_RTs(RTStructLAT, Grid, [2 2], PlotProps.Indexes.Letters{6}, PlotProps, [.5 2.5], [ 0.1  1.01])
ylabel('LAT reaction times (s)')

% G: Proportion of trials
plot_trial_outcome(OutcomeCountLAT, Grid, [2, 3], PlotProps.Indexes.Letters{7}, Legend, PlotProps)
ylabel('% LAT trials')

% H: plot change in lapses with distance
LegendRadius = {'BL, EO', 'BL, EC', 'SD, EO', 'SD, EC'};
plot_radius_lapses(LapseCountLAT, Grid, [2 4], PlotProps.Indexes.Letters{8}, ...
    LegendRadius, [0 60], PlotProps)
ylabel('LAT lapses (% trials)')


chART.save_figure('Figure_Behavior', Paths.Results, PlotProps)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% statistics

clc
%%% LAT
disp('---LAT---')

% overall lapses
Lapses = squeeze(OutcomeCountLAT(:, 1, 1)+OutcomeCountLAT(:, 1, 4));
disp_stats_descriptive(Lapses, 'Total lapses BL:', '%', 0);

Lapses = squeeze(OutcomeCountLAT(:, 2, 1)+OutcomeCountLAT(:, 2, 4));
disp_stats_descriptive(Lapses, 'Total lapses SD:', '%', 0);

% determine proportion of lapses with eyes opened and closed
[EyesOpenOutcomeCount, EyesClosedOutcomeCount] = count_trials_by_eye_status( ...
    TrialsTableLAT, Participants,  Sessions.LAT, {1:3, 4:6});

describe_lapses(EyesOpenOutcomeCount, EyesClosedOutcomeCount, StatParameters)

%%
clc
describe_lapses_by_radius(LapseCountLAT)

%%

clc
%%% PVT
disp('---PVT---')

% overall lapses
Lapses = squeeze(OutcomeCountPVT(:, 1, 1)+OutcomeCountPVT(:, 1, 4));
disp_stats_descriptive(Lapses, 'Total lapses BL:', '%', 0);

Lapses = squeeze(OutcomeCountPVT(:, 2, 1)+OutcomeCountPVT(:, 2, 4));
disp_stats_descriptive(Lapses, 'Total lapses SD:', '%', 0);

% split by eye status
[EyesOpenOutcomeCount, EyesClosedOutcomeCount] = count_trials_by_eye_status( ...
    TrialsTablePVT, Participants,  Sessions.PVT, []);

describe_lapses(EyesOpenOutcomeCount, EyesClosedOutcomeCount, StatParameters)



%%
describe_reaction_times(MeansLAT, Quantile99LAT, StatParameters)

%%

anova_radius_sleep(LapseCountLAT, RadiusBinsLAT, StatParameters)


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


function [LapseCount, RadiusBins] = lapse_count_by_radius(TrialsTable, RadiusQuantile, Participants, Sessions, SessionGroups, MinTrialCount)

CheckEyes = true;

% get trial subsets
EO = TrialsTable.EyesClosed == 0;
EC = TrialsTable.EyesClosed == 1;
Lapses = TrialsTable.Type == 1;

% assign a distance quantile for each trial
Radius = TrialsTable.Radius;
Edges = quantile(Radius(:), 0:RadiusQuantile:1);
RadiusBins = discretize(Radius, Edges);
TrialsTable.Radius_Bins = RadiusBins;

% get number of lapses for each distance quantile
[EyesOpenLapsesCount, ~] = assemble_matrix_from_table(TrialsTable, EO & Lapses, 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

[EyesClosedLapsesCount, ~] = assemble_matrix_from_table(TrialsTable, EC & Lapses, 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

[TrialsCount, ~] = assemble_matrix_from_table(TrialsTable, [], 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

% remove participants with too few trials
MinTrialsSplit = MinTrialCount/numel(unique(RadiusBins));
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

function plot_questionnaire(Data, SessionLabels, StatsParameters, Grid, Position, Letter, PlotProps)
chART.sub_plot([], Grid, Position, [], true, Letter, PlotProps);

Stats = paired_ttest(Data, [], StatsParameters);
try
disp_stats(Stats, [1, 3], [SessionLabels{1}, ' vs ', SessionLabels{3}, ' kss:']);
catch
disp_stats(Stats, [1, 2], [SessionLabels{1}, ' vs ', SessionLabels{2}, ' kss:']);
end
chART.plot.individual_rows(Data, Stats, SessionLabels, [1 9], PlotProps, PlotProps.Color.Participants)
ylabel('Subjective sleepiness')
yticks(1:9)
% ylim([.5 9.5])
disp([Letter, ': N=', num2str(Stats.N(1, 2))])
end


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

function describe_reaction_times(Means, Quantile99, StatParameters)

%%% RTs
% change in mean RTs from BL to SD
disp_stats_descriptive(1000*Means(:, 1),'BL RT', ' ms', '%.0f');
disp_stats_descriptive(1000*Means(:, 2),'SD RT', ' ms', '%.0f');

Stats = paired_ttest(Means(:, 1), Means(:, 2), StatParameters);
disp_stats(Stats, [1 1], 'SD effect on RTs:');

% distribution of RTs to show that they don't go over 1s
SB_Indx = 2;
disp_stats_descriptive(1000*Quantile99(:, SB_Indx), 'RT for 99% of SD data:', ' ms', 0);
disp('______________________')
end


function describe_lapses(EyesOpenOutcomeCount, EyesClosedOutcomeCount, StatParameters)

% just lapses
TrialCount = EyesOpenOutcomeCount(:, :, 1) + EyesClosedOutcomeCount(:, :, 1);
ECvEOLapses = 100*EyesOpenOutcomeCount(:, :, 1)./TrialCount;

% all
TrialCount = sum(EyesOpenOutcomeCount, 3)+sum(EyesClosedOutcomeCount, 3);
EOvAllTrialsMatrix = 100*EyesOpenOutcomeCount(:, :, 1)./TrialCount; % Matrix is EO lapses, late, correct, EC lapses


% proportion of EC lapses out of overall lapses
disp_stats_descriptive(squeeze(ECvEOLapses(:, 2)), 'SD EO vs All Lapses', '%', '%.0f');
disp_stats_descriptive(squeeze(EOvAllTrialsMatrix(:, 1)), 'BL EO vs All Trials', '%', '%.0f');
disp_stats_descriptive(squeeze(EOvAllTrialsMatrix(:, 2)), 'SD EO vs All Trials', '%', '%.0f');

Stats = paired_ttest(EOvAllTrialsMatrix(:, 1), EOvAllTrialsMatrix(:, 2), StatParameters);
disp_stats(Stats, [1 1], 'SD effect on EO lapses:');

disp('______________________')
end


function anova_radius_sleep(LapseCount, RadiusBins, StatParameters)

% all radii
StatsRadius = anova2way(LapseCount(:, :, [1 3]), {'Distance', 'Time'}, string(1:numel(unique(RadiusBins))), ...
    {'BL', 'SD'}, StatParameters);

% exluding last two radii
StatsRadiusRedux = anova2way(LapseCount(:, 1:3, [1 3]), {'Distance', 'Time'}, string(1:numel(unique(RadiusBins))), ...
    {'BL', 'SD'}, StatParameters);

% all distance
disp_stats(StatsRadius, {'Distance', 'Time', 'Interaction'}, 'Distance vs Time:');
disp_stats(StatsRadiusRedux, {'Distance', 'Time', 'Interaction'}, 'Distance vs Time, first 3 quantiles:');


disp('______________________')
end


function describe_lapses_by_radius(LapseCount)
% close lapses
disp_stats_descriptive(squeeze(LapseCount(:, 1, 1)), 'BL EO close lapses', '%', '%.1f');

% far lapses
disp_stats_descriptive(squeeze(LapseCount(:, end, 1)), 'BL EO far lapses', '%', '%.1f');
disp('*')

% each distance
for Indx_Q = 1:size(LapseCount, 2)
    disp_stats_descriptive(squeeze(LapseCount(:, Indx_Q, 3)-LapseCount(:, Indx_Q, 1)), ... ...
        ['BL v SD EO lapses Q', num2str(Indx_Q)], '%', '%.1f');
end
disp('*')

disp('______________________')
end



function KSS = assemble_questionnaire(Path, Participants, Sessions)

CSV = readtable(Path);

KSS = nan(numel(Participants), numel(Sessions));

for ParticipantIdx = 1:numel(Participants)
for SessionIdx = 1:numel(Sessions)
    Row = strcmp(CSV.dataset, Participants{ParticipantIdx}) & ...
        strcmp(CSV.qID, 'BAT_1') & strcmp(CSV.Level2, Sessions{SessionIdx});
   Data = CSV.numAnswer(Row);
   if numel(Data)==1
       KSS(ParticipantIdx, SessionIdx) = Data*9;
   else
       warning('something wrong with KSS')
   end
end
end
end

