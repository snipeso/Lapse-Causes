% Script in Lapse-Causes that plots the first figure (and stats) related to
% the LAT task performance.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();
Participants = P.Participants;
Paths = P.Paths;
PlotProps = P.Manuscript;
StatsP = P.StatsP;

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};

Sessions = [SessionBlocks.BL, SessionBlocks.SD]; % different representation for the tabulateTable function
SessionGroups = {1:3, 4:6};

TitleTag = strjoin({'LapseCauses', 'Behavior'}, '_');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load trial data

%%% get trial data
Pool = fullfile(Paths.Pool, 'Tasks');
load(fullfile(Pool, 'AllTrials.mat'), 'Trials') % from script: TODO

% get trial subsets
Q = quantile(Trials.Radius, 0.5);
Closest = Trials.Radius<=Q;
Furthest = Trials.Radius>Q;

EO = Trials.EC == 0;
EC = Trials.EC == 1;

Lapses = Trials.Type == 1;


%%% assemble reaction times into structure for flame plot
FlameStruct = struct();
MEANS = nan(numel(Participants), 2);
Q99 = MEANS;
for Indx_SB = 1:2
    for Indx_P = 1:numel(Participants)
        RTs = Trials.RT(strcmp(Trials.Participant, Participants{Indx_P}) &...
            contains(Trials.Session, SessionBlocks.(SB_Labels{Indx_SB})));
        RTs(isnan(RTs)) = [];
        FlameStruct.(SB_Labels{Indx_SB}).(Participants{Indx_P}) = RTs;
        
        MEANS(Indx_P, Indx_SB) = mean(RTs);
        Q99(Indx_P, Indx_SB) = quantile(RTs, .99);
    end
end


%%% stats & QC plot for lapses in closest or furthest 50% for script: TODO

% get number of trials by each type for the subset of trials that are closest
[ClosestTally, ~] = tabulateTable(Trials(Closest & EO, :), 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups); % P x SB x TT
[FurthestTally, ~] = tabulateTable(Trials(Furthest & EO, :), 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups);

% make relative to total trials
ClosestProb = ClosestTally./sum(ClosestTally, 3, 'omitnan');
FurthestProb = FurthestTally./sum(FurthestTally, 3, 'omitnan');

% use only SD data
ProbType = cat(3, squeeze(ClosestProb(:, 2, :)), squeeze(FurthestProb(:, 2, :))); % P x TT x D
save(fullfile(Pool, 'ProbType_Radius.mat'), 'ProbType')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots & stats

%% Plot all behavior information

Grid = [1 3];

figure('Units','centimeters', 'Position',[0 0  PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

%%% A: Reaction time distributions
XLim = [.5 2.5];

subfigure([], Grid, [1 1], [1 1], true, PlotProps.Indexes.Letters{1}, PlotProps);
hold on
plot([0 3], [.5 .5], 'Color', PlotProps.Color.Generic, 'LineStyle', ':', 'LineWidth', .5) % demarkation of when answer is late
plotFlames(FlameStruct, PlotProps.Color.Participants, .15, PlotProps)
ylabel('Reaction times (s)')
xlim(XLim)
legend off


%%% B: Proportion of trials

% assemble data
[EO_Matrix, ~] = tabulateTable(Trials(EO & Closest, :), 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups); % P x SB x TT
[EC_Matrix, ~] = tabulateTable(Trials(EC & Closest, :), 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups);

Tots = sum(EO_Matrix, 3)+sum(EC_Matrix, 3);
Matrix = cat(3, EO_Matrix, EC_Matrix(:, :, 1));
Data = squeeze(mean(100*Matrix./Tots, 1, 'omitnan')); % average, normalizing totals

% assemble plot parameters
Order = [4 1 2 3]; % order in which to have trial types

YLim = [0 100];
XLim = [0.33 2.66];

Red = getColors([1 4], '', 'red'); % dark red for lapses EC
Colors = [PlotProps.Color.Types; Red(1, :)];
Colors = Colors(Order, :);

AllTallyLabels = {'Lapses (EO)', 'Late', 'Correct', 'Lapses (EC)'};
AllTallyLabels = AllTallyLabels(Order);

Data = Data(:, Order);

% plot
subfigure([], Grid, [1, 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);

plotStackedBars(Data, SB_Labels, YLim, AllTallyLabels, Colors, PlotProps)
ylabel('% trials')
set(legend, 'location', 'northwest')
xlim(XLim)


%%% C: plot change in lapses with distance

% assign a distance quantile for each trial
qBin = .2; % bin size for quantiles
Radius = Trials.Radius;
Edges = quantile(Radius(:), 0:qBin:1);
Bins = discretize(Radius, Edges);
Trials.Radius_Bins = Bins;

% get number of lapses for each distance quantile
[LapsesTally, ~] = tabulateTable(Trials(EO & Lapses, :), 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups);
[Tots, ~] = tabulateTable(Trials(EO, :), 'Radius_Bins', 'tabulate', ...
    Participants, Sessions, SessionGroups);

LapsesTally = 100*LapsesTally./Tots; % P x SB x RB
LapsesTally = permute(LapsesTally, [1 3 2]); % P x RB x SB

% plot parameters
Colors = [PlotProps.Color.Generic; PlotProps.Color.Types(1, :)]; % generic for BL, lapse color for SD
YLim = [0 80];

% plot
subfigure([], Grid, [1 3], [1 1], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotSpikeBalls(LapsesTally, [], {'BL', 'SD'}, Colors, PlotProps)
ylabel('Lapses (% trials)')
ylim(YLim)
xlabel('Distance from center (quantiles)')
set(legend, 'Location','northwest')

% saveFig('LAT', Paths.PaperResults, PlotProps)


%% reaction time descriptions

clc

%%% RTs
% change in mean RTs from BL to SD
Stats = pairedttest(MEANS(:, 1), MEANS(:, 2), StatsP);
dispStat(Stats, [1 1], 'SD effect on RTs:');

% distribution of RTs to show that they don't go over 1s
SB_Indx = 2;
disp(['RT for 99% of SD data (MEAN [Min Max]): ', num2str(mean(Q99(:, SB_Indx), 'omitnan'), '%.2f'), ...
    ' [', num2str(min(Q99(:, SB_Indx)), '%.2f'), ', ' num2str(max(Q99(:, SB_Indx)), '%.2f'), ']'])


%%% lapses







