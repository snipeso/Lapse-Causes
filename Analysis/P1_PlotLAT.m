% Script in Lapse-Causes that plots the first figure (and stats) related to
% the LAT task performance.

clear
clc
% close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();
Participants = P.Participants;
Paths = P.Paths;
PlotProps = P.Manuscript;
StatsP = P.StatsP;
Task = 'LAT';

MinTots = P.Parameters.MinTots; % minimum total of trials for that participant to be considered

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};

Sessions = [SessionBlocks.BL, SessionBlocks.SD]; % different representation for the tabulateTable function
SessionGroups = {1:3, 4:6};

Pool = fullfile(Paths.Pool, 'Tasks');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load trial data

%%% Get PVT trial data
Task = 'PVT';
Sessions_PVT = P.Sessions_PVT; % different representation for the tabulateTable function
load(fullfile(Pool, [Task, '_AllTrials.mat']), 'Trials') % from script Load_Trials
Trials_PVT = Trials;
OldType = Trials_PVT.Type;

% assemble reaction times into structure for flame plot
[FlameStruct_PVT, MEANS_PVT, Q99_PVT] = assembleRTs(Trials_PVT, Participants, Sessions_PVT, SB_Labels);


%%% get LAT trial data
Task = 'LAT';

load(fullfile(Pool, [Task, '_AllTrials.mat']), 'Trials') % from script Load_Trials

% get trial subsets

Lapses = Trials.Type == 1;

% assemble reaction times into structure for flame plot
[FlameStruct, MEANS, Q99] = assembleRTs(Trials, Participants, SessionBlocks);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots & stats

%% Plot all behavior information

clc

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
PlotProps.Axes.yPadding = 25;
Grid = [2 3];

figure('Units','centimeters', 'Position',[0 0  PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PVT


%%% A: Reaction time distributions
XLim = [.5 2.5];
YLim = [ 0.1  1.01];

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
hold on
plot([0 3], [.5 .5], 'Color', PlotProps.Color.Generic, 'LineStyle', ':', 'LineWidth', 1) % demarkation of when answer is late
plotFlames(FlameStruct_PVT, PlotProps.Color.Participants, .15, PlotProps)
ylabel('PVT reaction times (s)')
xlim(XLim)
ylim(YLim)
legend off

disp(['A: N=', num2str(numel(unique(Trials_PVT.Participant)))])


%%% B: Proportion of trials

% split into types based on RTs
Trials_PVT.Type = OldType;
Trials_PVT.Type(~isnan(Trials_PVT.RT)) = 1; % full lapse
Trials_PVT.Type(Trials_PVT.RT<.5) = 3; % correct

% assemble trial types
disp('B: ')
Data = assembleLapses(Trials_PVT, Participants, Sessions_PVT, [], MinTots);
Data = squeeze(mean(Data, 1, 'omitnan')); % average, normalizing totals

% assemble plot parameters
TallyOrder = [4 1 2 3]; % order in which to have trial types

YLim = [0 100];
XLim = [0.33 2.66];

Red = getColors([1 4], '', 'red'); % dark red for lapses EC
TallyColors = [PlotProps.Color.Types; Red(1, :)];
TallyColors = TallyColors(TallyOrder, :);

AllTallyLabels = {'Lapses (EO)', 'Late', 'Correct', 'Lapses (EC)'};
AllTallyLabels = AllTallyLabels(TallyOrder);
AllTallyLabels_PVT = AllTallyLabels;
AllTallyLabels_PVT(3) = {''};

Data = Data(:, TallyOrder);

% plot
subfigure([], Grid, [1, 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);

plotStackedBars(Data, SB_Labels, YLim, AllTallyLabels_PVT, TallyColors, PlotProps)
ylabel('% PVT trials')
set(legend, 'location', 'northwest')
xlim(XLim)


%%% C: proportion of trials as lapses

% get trial subsets
EO_Trials = Trials_PVT.EC == 0;
EC_Trials = Trials_PVT.EC == 1;
Lapses = Trials_PVT.Type == 1;

% assemble data
Thresholds = .3:.1:1;
LapseTally = nan(numel(Participants), numel(Thresholds));

for Indx_T = 1:numel(Thresholds)

    Trials_PVT.Type = OldType;
    Trials_PVT.Type(~isnan(Trials_PVT.RT)) = 1; % full lapse
    Trials_PVT.Type(Trials_PVT.RT<Thresholds(Indx_T)) = 3; % correct

    [EO_Matrix, ~] = tabulateTable(Trials_PVT, EO_Trials, 'Type', 'tabulate', ...
        Participants, Sessions_PVT, [], CheckEyes); % P x SB x TT
    [EC_Matrix, ~] = tabulateTable(Trials_PVT, EC_Trials, 'Type', 'tabulate', ...
        Participants, Sessions_PVT, [], CheckEyes);


    EO = squeeze(EO_Matrix(:, 2, 1));
    EC = squeeze(EC_Matrix(:, 2, 1));
    Tot = EO+EC;

    LapseTally(:, Indx_T) = 100*EC./Tot;
end

% plot
subfigure([], Grid, [1 3], [1 1], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotSpikeBalls(LapseTally, Thresholds, {}, ...
    TallyColors(1, :), 'IQ', PlotProps)
xlabel('Lapse threshold (s)')
ylabel('PVT lapses with EC (% lapses)')


%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LAT

%%% D: Reaction time distributions
XLim = [.5 2.5];
YLim = [ 0.1  1.01];

subfigure([], Grid, [2 1], [], true, PlotProps.Indexes.Letters{4}, PlotProps);
hold on
plot([0 3], [.5 .5], 'Color', PlotProps.Color.Generic, 'LineStyle', ':', 'LineWidth', 1) % demarkation of when answer is late
plotFlames(FlameStruct, PlotProps.Color.Participants, .15, PlotProps)
ylabel('LAT reaction times (s)')
xlim(XLim)
ylim(YLim)
legend off

disp(['D: N=', num2str(numel(unique(Trials.Participant)))])


%%% E: Proportion of trials

% assemble data
disp('E: ')
[Data, EO_Matrix, EC_Matrix] = assembleLapses(Trials, Participants, Sessions, SessionGroups, MinTots);
Data = squeeze(mean(Data, 1, 'omitnan')); % average, normalizing totals
Data = Data(:, TallyOrder);

% plot
YLim = [0 100];
XLim = [0.33 2.66];

subfigure([], Grid, [2, 2], [], true, PlotProps.Indexes.Letters{5}, PlotProps);

plotStackedBars(Data, SB_Labels, YLim, AllTallyLabels, TallyColors, PlotProps)
ylabel('% LAT trials')
set(legend, 'location', 'northwest')
xlim(XLim)




%%% F: plot change in lapses with distance
% get trial subsets
EO = Trials.EC == 0;
EC = Trials.EC == 1;
Lapses = Trials.Type == 1;

% assign a distance quantile for each trial
qBin = .2; % bin size for quantiles
Radius = Trials.Radius;
Edges = quantile(Radius(:), 0:qBin:1);
Bins = discretize(Radius, Edges);
Trials.Radius_Bins = Bins;

% get number of lapses for each distance quantile
[EOLapsesTally, ~] = tabulateTable(Trials, EO & Lapses, 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

[ECLapsesTally, ~] = tabulateTable(Trials, EC & Lapses, 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

[Tots, ~] = tabulateTable(Trials, [], 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

% remove participants with too few trials
MinTotsSplit = MinTots/numel(unique(Bins));
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
subfigure([], Grid, [2 3], [1 1], true, PlotProps.Indexes.Letters{6}, PlotProps);
plotSpikeBalls(LapseTally, [], {'BL (EO)', 'BL (EC)', 'SD (EO)', 'SD (EC)'}, ...
    Colors, 'IQ', PlotProps)
ylabel('LAT lapses (% trials)')
ylim(YLim)
xlabel('Distance from center (quantiles)')
set(legend, 'Location','northwest')

disp(['F: N=' num2str(nnz(~BadParticipants))])

saveFig('Figure_1', Paths.PaperResults, PlotProps)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Stats

%% reaction time descriptions

clc

%%% RTs
% change in mean RTs from BL to SD
dispDescriptive(1000*MEANS(:, 1),'BL RT', ' ms', '%.0f');
dispDescriptive(1000*MEANS(:, 2),'SD RT', ' ms', '%.0f');

Stats = pairedttest(MEANS(:, 1), MEANS(:, 2), StatsP);
dispStat(Stats, [1 1], 'SD effect on RTs:');

% distribution of RTs to show that they don't go over 1s
SB_Indx = 2;
dispDescriptive(1000*Q99(:, SB_Indx), 'RT for 99% of SD data:', ' ms', 0);


%% lapses

%%% total lapses
[All_Matrix, ~] = tabulateTable(Trials, [], 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, false); % P x SB x TT

All_Matrix = 100*All_Matrix./sum(All_Matrix, 3, 'omitnan');

%%% EO/EC lapses
Tots = sum(EO_Matrix, 3)+sum(EC_Matrix, 3);
ECvAll_Matrix = 100*EC_Matrix(:, :, 1)./Tots; % Matrix is EO lapses, late, correct, EC lapses

% just lapses
Tots = EO_Matrix(:, :, 1) + EC_Matrix(:, :, 1);
ECvEO_Lapses = 100*EC_Matrix(:, :, 1)./Tots;


clc

% overall proportion of lapses
dispDescriptive(squeeze(All_Matrix(:, 1, 1)), 'BL Lapses', '%', '%.0f');
dispDescriptive(squeeze(All_Matrix(:, 2, 1)), 'SD Lapses', '%', '%.0f');
disp('*')

% proportion of EC lapses out of overall lapses
dispDescriptive(squeeze(ECvEO_Lapses(:, 1)), 'BL EC vs All Lapses', '%', '%.1f');
dispDescriptive(squeeze(ECvEO_Lapses(:, 2)), 'SD EC vs All Lapses', '%', '%.1f');
disp('*')

% proportion of EC lapses on overall trials
dispDescriptive(squeeze(ECvAll_Matrix(:, 1)), 'BL EC vs All Trials', '%', '%.1f');
dispDescriptive(squeeze(ECvAll_Matrix(:, 2)), 'SD EC vs All Trials', '%', '%.1f');
disp('*')

%%% lapses
EO_Lapses = squeeze(EO_Matrix(:, :, 1));
EC_Lapses = squeeze(EC_Matrix(:, :, 1));

% total lapses EO SD
dispDescriptive(EO_Lapses(:, 2), 'SD tot lapses', ' lapses', '%.0f');


MinLapses = P.Parameters.MinTypes;
disp(['# participants with at least ', num2str(MinLapses), ' EO lapses: ', num2str(nnz(EO_Lapses(:, 2)>MinLapses))])

disp('*')
% change in number of lapses from BL to SD EO
Tots = sum(EO_Matrix, 3)+sum(EC_Matrix, 3);

Tots(Tots<MinTots) = nan;

EO_Lapses = EO_Lapses./Tots;

Stats = pairedttest(EO_Lapses(:, 1), EO_Lapses(:, 2), StatsP);
dispStat(Stats, [1 1], 'SD effect on EO lapses:');

% EC
EC_Lapses = EC_Lapses./Tots;

Stats = pairedttest(EC_Lapses(:, 1), EC_Lapses(:, 2), StatsP);
dispStat(Stats, [1 1], 'SD effect on EC lapses:');



%% calculate ANOVA for radius vs sleep deprivation

% all radii
Stats_Radius = anova2way(LapseTally(:, :, [1 3]), {'Distance', 'Time'}, string(1:numel(unique(Bins))), ...
    {'BL', 'SD'}, StatsP);

% exluding last two radii
Stats_Radius_Redux = anova2way(LapseTally(:, 1:3, [1 3]), {'Distance', 'Time'}, string(1:numel(unique(Bins))), ...
    {'BL', 'SD'}, StatsP);


%% lapses by quantile
clc

% close lapses
dispDescriptive(squeeze(LapseTally(:, 1, 1)), 'BL EO close lapses', '%', '%.1f');

% far lapses
dispDescriptive(squeeze(LapseTally(:, 5, 1)), 'BL EO far lapses', '%', '%.1f');
disp('*')

% each distance
for Indx_Q = 1:size(LapseTally, 2)
    dispDescriptive(squeeze(LapseTally(:, Indx_Q, 3)-LapseTally(:, Indx_Q, 1)), ... ...
        ['BL v SD EO lapses Q', num2str(Indx_Q)], '%', '%.1f');
end
disp('*')


% all distance
dispStat(Stats_Radius, {'Distance', 'Time', 'Interaction'}, 'Distance vs Time:');
dispStat(Stats_Radius_Redux, {'Distance', 'Time', 'Interaction'}, 'Distance vs Time, first 3 quantiles:');

