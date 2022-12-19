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

MinTots = P.Parameters.MinTots; % minimum total of trials for that participant to be considered

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};

Sessions = [SessionBlocks.BL, SessionBlocks.SD]; % different representation for the tabulateTable function
SessionGroups = {1:3, 4:6};

TitleTag = strjoin({'LapseCauses', 'Behavior'}, '_');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load trial data

%%% get trial data
Pool = fullfile(Paths.Pool, 'Tasks');
load(fullfile(Pool, 'AllTrials.mat'), 'Trials') % from script Load_Trials

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
Q99 = MEANS; % keep track of distribution for description of RTs
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots & stats

%% Plot all behavior information

Grid = [1 3];
CheckEyes = true;

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
% [EO_Matrix, ~] = tabulateTable(Trials, EO & Closest, 'Type', 'tabulate', ...
%     Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
% [EC_Matrix, ~] = tabulateTable(Trials, EC & Closest, 'Type', 'tabulate', ...
%     Participants, Sessions, SessionGroups, CheckEyes);

[EO_Matrix, ~] = tabulateTable(Trials, EO, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
[EC_Matrix, ~] = tabulateTable(Trials, EC, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

Tots = sum(EO_Matrix, 3)+sum(EC_Matrix, 3);

% remove participants who dont have enough trials
BadParticipants = Tots<MinTots;
Tots(BadParticipants) = nan;

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

% plot parameters
Colors = [flip(getColors([1 2], '', 'gray')); PlotProps.Color.Types(1, :); Red(1, :)]; % generic for BL, lapse color for SD
YLim = [0 80];

% plot
subfigure([], Grid, [1 3], [1 1], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotSpikeBalls(LapseTally, [], {'BL (EO)', 'BL (EC)', 'SD (EO)', 'SD (EC)'}, Colors, PlotProps)
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

disp('***********')

%%% lapses
EO_Lapses = squeeze(EO_Matrix(:, :, 1));
EC_Lapses = squeeze(EC_Matrix(:, :, 1));

% total lapses EO SD
disp(['Total SD EO lapses (Mean, STD): ', num2str(mean(EO_Lapses(:, 2), 'omitnan'), '%.2f'), ...
    ', ',  num2str(std(EO_Lapses(:, 2), 'omitnan'), '%.2f')])

MinLapses = P.Parameters.MinTypes;
disp(['# participants with at least ', num2str(MinLapses), ' EO lapses: ', num2str(nnz(EO_Lapses(:, 2)>MinLapses))])

disp('*')
% change in number of lapses from BL to SD EO
% Tots = sum(EO_Matrix, 3, 'omitnan')+sum(EC_Matrix, 3, 'omitnan');
Tots = sum(EO_Matrix, 3)+sum(EC_Matrix, 3);

Tots(Tots<MinTots) = nan;

EO_Lapses = EO_Lapses./Tots;

Stats = pairedttest(EO_Lapses(:, 1), EO_Lapses(:, 2), StatsP);
dispStat(Stats, [1 1], 'SD effect on EO lapses:');

% EC
EC_Lapses = EC_Lapses./Tots;

Stats = pairedttest(EC_Lapses(:, 1), EC_Lapses(:, 2), StatsP);
dispStat(Stats, [1 1], 'SD effect on EC lapses:');










