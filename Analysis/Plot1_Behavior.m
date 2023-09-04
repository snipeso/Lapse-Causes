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


% Get PVT trial data
load(fullfile(CacheDir, 'PVT_TrialsTable.mat'), 'TrialsTable') % from script Load_Trials
TrialsTablePVT = TrialsTable;
OldTypesPVT = TrialsTablePVT.Type; % TODO: remove

[RTStructPVT, ~, ~] = assemble_reaction_times(TrialsTablePVT, Participants, Sessions.PVT, SessionBlockLabels);


% get LAT trial data
load(fullfile(CacheDir, 'PVT_TrialsTable.mat'), 'TrialsTable') % from script Load_Trials
TrialsTableLAT = TrialsTable;

[RTStructLAT, MeansLAT, Quantile99LAT, Quantile01LAT] = assemble_reaction_times( ...
    TrialsTableLAT, Participants, SessionBlocks);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot

clc

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 25;
PlotProps.Axes.yPadding = 25;
Grid = [2 3];

figure('Units','centimeters', 'Position',[0 0  PlotProps.Figure.Width, PlotProps.Figure.Height*.5])


%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PVT

%%% A: Reaction time distributions
plot_RTs(RTStructPVT, Grid, [1 1], PlotProps.Indexes.Letters{1}, PlotProps, [.5 2.5], [ 0.1  1.01])
ylabel('PVT reaction times (s)')

disp(['A: N=', num2str(numel(unique(TrialsTablePVT.Participant)))])


%%% B: Proportion of trials

% split into types based on RTs
TrialsTablePVT.Type = OldTypesPVT;
TrialsTablePVT.Type(~isnan(TrialsTablePVT.RT)) = 1; % full lapse
TrialsTablePVT.Type(TrialsTablePVT.RT<.5) = 3; % correct

% assemble trial types
disp('B: ')
Data = assembleLapses(TrialsTablePVT, Participants, Sessions.PVT, [], MinTrialCount);

% disp EC vs 

Data = squeeze(mean(Data, 1, 'omitnan')); % average, normalizing totals

% assemble plot parameters
TallyOrder = [4 1 2 3]; % order in which to have trial types

YLim = [0 100];
XLim = [0.33 2.66];

Red = chART.color_picker([1 4], '', 'red'); % dark red for lapses EC
TallyColors = [chART.color_picker(3); Red];
TallyColors = TallyColors(TallyOrder, :);

AllTallyLabels = {'EO Lapses', 'Slow responses', 'Fast responses', 'EC Lapses'};
AllTallyLabels = AllTallyLabels(TallyOrder);
AllTallyLabels_PVT = AllTallyLabels;
AllTallyLabels_PVT(3) = {''};

Data = Data(:, TallyOrder);

% plot
chART.sub_plot([], Grid, [1, 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);

chART.plot.plotStackedBars(Data, SessionBlockLabels, YLim, AllTallyLabels_PVT, TallyColors, PlotProps)
ylabel('% PVT trials')
set(legend, 'location', 'northwest')
xlim(XLim)


%%% C: proportion of trials as lapses

CheckEyes = true;

% get trial subsets
EO_Trials = TrialsTablePVT.EyesClosed == 0;
EC_Trials = TrialsTablePVT.EyesClosed == 1;

% assemble data
Thresholds = .3:.1:1;
LapseTally = nan(numel(Participants), numel(Thresholds));

for Indx_T = 1:numel(Thresholds)

    TrialsTablePVT.Type = OldTypesPVT;
    TrialsTablePVT.Type(~isnan(TrialsTablePVT.RT)) = 1; % full lapse
    TrialsTablePVT.Type(TrialsTablePVT.RT<Thresholds(Indx_T)) = 3; % correct

    [EO_Matrix, ~] = assemble_matrix_from_table(TrialsTablePVT, EO_Trials, 'Type', 'tabulate', ...
        Participants, Sessions_PVT, [], CheckEyes); % P x SB x TT
    [EC_Matrix, ~] = assemble_matrix_from_table(TrialsTablePVT, EC_Trials, 'Type', 'tabulate', ...
        Participants, Sessions_PVT, [], CheckEyes);


    EO = squeeze(EO_Matrix(:, 2, 1));
    EC = squeeze(EC_Matrix(:, 2, 1));
    Tot = EO+EC;

    LapseTally(:, Indx_T) = 100*EC./Tot;
end

% plot
chART.sub_plot([], Grid, [1 3], [1 1], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotSpikeBalls(LapseTally, Thresholds, {}, ...
    TallyColors(1, :), 'IQ', PlotProps)
xlabel('Lapse threshold (s)')
ylabel('PVT lapses with EC (% lapses)')

disp_stats_descriptive(LapseTally(:, 3), 'Proportion of PVT Lapses:', '%', 0);


%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LAT

%%% D: Reaction time distributions
plot_RTs(RTStructLAT, Grid, [2 1], PlotProps.Indexes.Letters{4}, PlotProps, [.5 2.5], [ 0.1  1.01])
ylabel('LAT reaction times (s)')

disp(['D: N=', num2str(numel(unique(TrialsTableLAT.Participant)))])


%%% E: Proportion of trials

% assemble data
disp('E: ')
[Data, EO_Matrix, EC_Matrix] = assembleLapses(TrialsTableLAT, Participants, Sessions, SessionGroups, MinTrialCount);
Data = squeeze(mean(Data, 1, 'omitnan')); % average, normalizing totals
Data = Data(:, TallyOrder);

% plot
YLim = [0 100];
XLim = [0.33 2.66];

chART.sub_plot([], Grid, [2, 2], [], true, PlotProps.Indexes.Letters{5}, PlotProps);

plotStackedBars(Data, SessionBlockLabels, YLim, AllTallyLabels, TallyColors, PlotProps)
ylabel('% LAT trials')
set(legend, 'location', 'northwest')
xlim(XLim)


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
