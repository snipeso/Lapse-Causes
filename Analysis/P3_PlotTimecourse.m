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



load(fullfile(Paths.Pool, 'Eyes', 'ProbMicrosleep.mat'), 'ProbMicrosleep_Stim', 'ProbMicrosleep_Resp', 't', 'GenProbMicrosleep')
t_microsleep = t;
sProbMicrosleep_Stim =  smoothFreqs(ProbMicrosleep_Stim, t_microsleep, 'last', .5);
zProbMicrosleep_Stim = zScoreData(cat(3, sProbMicrosleep_Stim, repmat(GenProbMicrosleep, 1, 3)), 'first');
zGenProbMicrosleep_Stim = squeeze(zProbMicrosleep_Stim(:, 1, end));
zProbMicrosleep_Stim(:, :, end) = [];

sProbMicrosleep_Resp =  smoothFreqs(ProbMicrosleep_Resp, t_microsleep, 'last', .5);
zProbMicrosleep_Resp = zScoreData(cat(3, sProbMicrosleep_Resp, repmat(GenProbMicrosleep, 1, 3)), 'first');
zGenProbMicrosleep_Resp = squeeze(zProbMicrosleep_Resp(:, 1, end));
zProbMicrosleep_Resp(:, :, end) = [];



load(fullfile(Paths.Pool, 'EEG', 'ProbBurst.mat'), 'ProbBurst_Stim', 'ProbBurst_Resp', 't',  'GenProbBurst')
t_burst = t;
sProbBurst_Stim =  smoothFreqs(ProbBurst_Stim, t_burst, 'last', .5);
Temp = repmat(GenProbBurst, 1, 1, 3);
sProbBurst_temp_Stim = cat(4, sProbBurst_Stim, permute(Temp, [1 3 2]));
sProbBurst_temp_Stim = permute(sProbBurst_temp_Stim, [1 2 4 3]);
zProbBurst_Stim = zScoreData(sProbBurst_temp_Stim, 'last');
zProbBurst_Stim = permute(zProbBurst_Stim, [1 2 4 3]);
zGenProbBurst_Stim = squeeze(zProbBurst_Stim(:, 1, :, end));
zProbBurst_Stim(:, :, :, end) = [];

sProbBurst_Resp =  smoothFreqs(ProbBurst_Resp, t_burst, 'last', .5);
sProbBurst_temp_Resp = cat(4, sProbBurst_Resp, permute(Temp, [1 3 2]));
sProbBurst_temp_Resp = permute(sProbBurst_temp_Resp, [1 2 4 3]);
zProbBurst_Resp = zScoreData(sProbBurst_temp_Resp, 'last');
zProbBurst_Resp = permute(zProbBurst_Resp, [1 2 4 3]);
zGenProbBurst_Resp = squeeze(zProbBurst_Resp(:, 1, :, end));
zProbBurst_Resp(:, :, :, end) = [];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots and stats


%% Figure 1


PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [-3.5 5];

Grid = [2 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_microsleep, flip(zProbMicrosleep_Stim, 2), zGenProbMicrosleep_Stim, ...
    Range, flip(TallyLabels), 'Stimulus', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')


subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 1, :)), 2), ...
    zGenProbBurst_Stim(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta (z-scored)')
legend off


subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 2, :)), 2),  ...
    zGenProbBurst_Stim(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha (z-scored)')
legend off


%%% response locked


subfigure([], Grid, [2 1], [], true, PlotProps.Indexes.Letters{4}, PlotProps);
plotTimecourse(t_microsleep, flip(zProbMicrosleep_Resp, 2), zGenProbMicrosleep_Stim, ...
    Range, flip(TallyLabels), 'Response', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')
legend off

subfigure([], Grid, [2 2], [], true, PlotProps.Indexes.Letters{5}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 1, :)), 2), ...
    zGenProbBurst_Resp(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta (z-scored)')
legend off


subfigure([], Grid, [2 3], [], true, PlotProps.Indexes.Letters{6}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 2, :)), 2),  ...
    zGenProbBurst_Resp(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha (z-scored)')
legend off




saveFig('Figure_3', Paths.PaperResults, PlotProps)











%% z-scored timecourse

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [-3.5 5];

Grid = [1 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_microsleep, flip(zProbMicrosleep_Stim, 2), zGenProbMicrosleep_Stim, ...
    Range, flip(TallyLabels), 'Stimulus', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')


subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 1, :)), 2), ...
    zGenProbBurst_Stim(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of Theta (z-scored)')
legend off


subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 2, :)), 2),  ...
    zGenProbBurst_Stim(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of Alpha (z-scored)')
legend off

saveFig([TitleTag, '_Probof_zscored'], Paths.PaperResults, PlotProps)


%% raw timecoure

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [0 1];

Grid = [1 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_microsleep, flip(sProbMicrosleep_Stim, 2), GenProbMicrosleep, ...
    Range, flip(TallyLabels), 'Stimulus', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of eyes closed')


subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Stim(:, :, 1, :)), 2), ...
    GenProbBurst(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta')
legend off


subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Stim(:, :, 2, :)), 2), ...
    GenProbBurst(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha')
legend off

saveFig([TitleTag, '_Probof_raw'], Paths.PaperResults, PlotProps)


%% z-scored timecourse response

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [-3.5 5];

Grid = [1 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_microsleep, flip(zProbMicrosleep_Resp, 2), zGenProbMicrosleep_Stim, ...
    Range, flip(TallyLabels), 'Response', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')


subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 1, :)), 2), ...
    zGenProbBurst_Resp(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of Theta (z-scored)')
legend off


subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 2, :)), 2),  ...
    zGenProbBurst_Resp(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of Alpha (z-scored)')
legend off

saveFig([TitleTag, '_Probof_zscored_resp'], Paths.PaperResults, PlotProps)




%% raw timecoure responses

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [0 1];

Grid = [1 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_microsleep, flip(sProbMicrosleep_Resp, 2), GenProbMicrosleep, ...
    Range, flip(TallyLabels), 'Response', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of eyes closed')


subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Resp(:, :, 1, :)), 2), ...
    GenProbBurst(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta')
legend off

subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Resp(:, :, 2, :)), 2),  ...
    GenProbBurst(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha')
legend off

saveFig([TitleTag, '_Probof_raw_resp'], Paths.PaperResults, PlotProps)