% plot the timecourses showing relationship of bursts with lapses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
Sessions = P.Sessions;
TallyLabels = P.Labels.Tally;
Paths = P.Paths;
Task = P.Labels.Task;
Channels = P.Channels;
StatsP = P.StatsP;

TitleTag = strjoin({'Timecourse'}, '_');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data



load(fullfile(Paths.Pool, 'Eyes', 'ProbMicrosleep.mat'), 'ProbMicrosleep', 't', 'GenProbMicrosleep')
t_microsleep = t;
sProbMicrosleep =  smoothFreqs(ProbMicrosleep, t_microsleep, 'last', .5);
zProbMicrosleep = zScoreData(cat(3, sProbMicrosleep, repmat(GenProbMicrosleep, 1, 3)), 'first');
zGenProbMicrosleep = squeeze(zProbMicrosleep(:, 1, end));
zProbMicrosleep(:, :, end) = [];

load(fullfile(Paths.Pool, 'EEG', 'ProbBurst.mat'), 'ProbBurst', 't',  'GenProbBurst')
t_burst = t;
sProbBurst =  smoothFreqs(ProbBurst, t_burst, 'last', .5);
Temp = repmat(GenProbBurst, 1, 1, 3);
sProbBurst_temp = cat(4, sProbBurst, permute(Temp, [1 3 2]));
sProbBurst_temp = permute(sProbBurst_temp, [1 2 4 3]);
zProbBurst = zScoreData(sProbBurst_temp, 'last');
zProbBurst = permute(zProbBurst, [1 2 4 3]);
zGenProbBurst = squeeze(zProbBurst(:, 1, :, end));
zProbBurst(:, :, :, end) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots and stats


%% z-scored timecourse

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [-3.5 4.1];

Grid = [1 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_microsleep, flip(zProbMicrosleep, 2), zGenProbMicrosleep, Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')


subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst(:, :, 1, :)), 2), zGenProbBurst(:, 1), Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of Theta (z-scored)')
legend off


subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst(:, :, 2, :)), 2),  zGenProbBurst(:, 2), Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of Alpha (z-scored)')
legend off

saveFig([TitleTag, '_Probof_zscored'], Paths.PaperResults, PlotProps)


%% raw timecoure

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [0 1];

Grid = [1 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.4])

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_microsleep, flip(sProbMicrosleep, 2), GenProbMicrosleep, Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of eyes closed')


subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst(:, :, 1, :)), 2), GenProbBurst(:, 1), Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta')
legend off


subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst(:, :, 2, :)), 2),  GenProbBurst(:, 2), Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha')
legend off

saveFig([TitleTag, '_Probof_raw'], Paths.PaperResults, PlotProps)
