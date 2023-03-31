
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

MinTots = P.Parameters.MinTots; % minimum total of trials for that participant to be considered
Task = 'PVT';
Sessions = P.Sessions_PVT; % different representation for the tabulateTable function
SessionLabels = {'BL', 'SD'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load trial data

%%% get trial data
Pool = fullfile(Paths.Pool, 'Tasks');
load(fullfile(Pool, [Task, '_AllTrials.mat']), 'Trials') % from script Load_Trials

% get trial subsets
EO = Trials.EC == 0;
EC = Trials.EC == 1;

Lapses = Trials.Type == 1;

%%% assemble reaction times into structure for flame plot
FlameStruct = struct();
MEANS = nan(numel(Participants), 2);
Q99 = MEANS; % keep track of distribution for description of RTs
for Indx_S = 1:2
    for Indx_P = 1:numel(Participants)
        RTs = Trials.RT(strcmp(Trials.Participant, Participants{Indx_P}) &...
            contains(Trials.Session, Sessions{Indx_S}));
        RTs(isnan(RTs)) = [];
        FlameStruct.(SessionLabels{Indx_S}).(Participants{Indx_P}) = RTs;

        MEANS(Indx_P, Indx_S) = mean(RTs);
        Q99(Indx_P, Indx_S) = quantile(RTs, .99);
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
YLim = [ 0.1  1.01];

subfigure([], Grid, [1 1], [1 1], true, PlotProps.Indexes.Letters{1}, PlotProps);
hold on
plot([0 3], [.5 .5], 'Color', PlotProps.Color.Generic, 'LineStyle', ':', 'LineWidth', 1) % demarkation of when answer is late
plotFlames(FlameStruct, PlotProps.Color.Participants, .15, PlotProps)
ylabel('Reaction times (s)')
xlim(XLim)
ylim(YLim)
legend off

disp(['A: N=', num2str(numel(unique(Trials.Participant)))])

Trials.Type(~isnan(Trials.RT)) = 1; % full lapse
Trials.Type(Trials.RT<.6) = 3; % correct
% Trials.Type(Trials.RT>1) = 1; % full lapse


%%% B: Proportion of trials

% assemble data
[EO_Matrix, ~] = tabulateTable(Trials, EO, 'Type', 'tabulate', ...
    Participants, Sessions, [], CheckEyes); % P x SB x TT
[EC_Matrix, ~] = tabulateTable(Trials, EC, 'Type', 'tabulate', ...
    Participants, Sessions, [], CheckEyes);

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

plotStackedBars(Data, SessionLabels, YLim, AllTallyLabels, Colors, PlotProps)
ylabel('% trials')
set(legend, 'location', 'northwest')
xlim(XLim)

% display how much data is in not-plotted task types
NotPlotted = 100*mean(sum(EC_Matrix(:, :, 2:3), 3)./Tots, 'omitnan');

% info on figure
disp(['B: N=', num2str(numel(BadParticipants) - nnz(BadParticipants))])
disp(['Not plotted data in B: ', num2str(NotPlotted(2), '%.2f'), '%'])


