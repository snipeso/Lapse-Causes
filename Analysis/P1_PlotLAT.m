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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load trial data

%%% get trial data
Pool = fullfile(Paths.Pool, 'Tasks');
load(fullfile(Pool, 'AllTrials.mat'), 'Trials') % from script Load_Trials

% get trial subsets
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

clc

Grid = [1 3];
CheckEyes = true;

figure('Units','centimeters', 'Position',[0 0  PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

%%% A: Reaction time distributions
XLim = [.5 2.5];

subfigure([], Grid, [1 1], [1 1], true, PlotProps.Indexes.Letters{1}, PlotProps);
hold on
plot([0 3], [.5 .5], 'Color', PlotProps.Color.Generic, 'LineStyle', ':', 'LineWidth', 1) % demarkation of when answer is late
plotFlames(FlameStruct, PlotProps.Color.Participants, .15, PlotProps)
ylabel('Reaction times (s)')
xlim(XLim)
legend off

disp('A: N=18')


%%% B: Proportion of trials

% assemble data
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

% display how much data is in not-plotted task types
NotPlotted = 100*mean(sum(EC_Matrix(:, :, 2:3), 3)./Tots, 'omitnan');

% info on figure
disp(['B: N=', num2str(numel(BadParticipants) - nnz(BadParticipants))])
disp(['Not plotted data in B: ', num2str(NotPlotted(2), '%.2f'), '%'])



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

% remove participants with any NaNs
BadParticipants = any(any(isnan(LapseTally), 3), 2);
LapseTally(BadParticipants, :, :) = nan;

% plot parameters
Colors = [flip(getColors([1 2], '', 'gray')); PlotProps.Color.Types(1, :); Red(1, :)]; % generic for BL, lapse color for SD
YLim = [0 60];

% plot
subfigure([], Grid, [1 3], [1 1], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotSpikeBalls(LapseTally, [], {'BL (EO)', 'BL (EC)', 'SD (EO)', 'SD (EC)'}, ...
    Colors, 'IQ', PlotProps)
ylabel('Lapses (% trials)')
ylim(YLim)
xlabel('Distance from center (quantiles)')
set(legend, 'Location','northwest')

disp(['C: N=' num2str(nnz(~BadParticipants))])

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
IQ = 1000*quantile(Q99(:, SB_Indx), [.25 .75]);
disp(['RT for 99% of SD data (MEAN [Min Max]): ', num2str(mean(1000*Q99(:, SB_Indx), 'omitnan'), '%.0f'), ...
    ' ms (IQ: ', num2str(IQ(1), '%.0f'), ', ' num2str(IQ(2), '%.0f'), ')'])


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

%%
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



%% calculate
Stats_Radius = anova2way(LapseTally(:, :, [1 3]), {'Distance', 'Time'}, string(1:numel(unique(Bins))), ...
    {'BL', 'SD'}, StatsP);
Stats_Radius_Redux = anova2way(LapseTally(:, 1:3, [1 3]), {'Distance', 'Time'}, string(1:numel(unique(Bins))), ...
    {'BL', 'SD'}, StatsP);

%% lapses by quantile
clc

%{'BL (EO)', 'BL (EC)', 'SD (EO)', 'SD (EC)'}

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



% %% effect of bursts on RTs
%
% clc
%
% Bands = P.Bands;
% BandLabels = fieldnames(Bands);
% SB_Indx = 2;
%
% load(fullfile(Pool, 'Burst_RTs.mat'), 'RTs')
%
% for Indx_B = 1:numel(BandLabels)
%     Stats = pairedttest(squeeze(RTs(:, SB_Indx, Indx_B, 1)), ...
%         squeeze(RTs(:, SB_Indx, Indx_B, 2)), StatsP);
% dispStat(Stats, [1 1], [BandLabels{Indx_B}, ' effect on RTs:']);
%
% end




