
StatsP = P.StatsP;

TitleTag = 'Timecourses';

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 20;

load(fullfile(Paths.Pool, 'Eyes', 'ProbMicrosleep.mat'), 'ProbMicrosleep', 't')
sProbMicrosleep =  smoothFreqs(ProbMicrosleep, t, 'last', .5);
zProbMicrosleep = zScoreData(sProbMicrosleep, 'first');


load(fullfile(Paths.Pool, 'EEG', 'ProbBurst.mat'), 'ProbBurst', 't')
sProbBurst =  smoothFreqs(ProbBurst, t, 'last', .5);
zProbBurst = zScoreData(permute(sProbBurst, [1 2 4 3]), 'last');
zProbBurst = permute(zProbBurst, [1 2 4 3]);

%%
Range = [-1.5 2];

Grid = [1 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.4])

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps)
plotTimecourse(t, flip(zProbMicrosleep, 2), 1, Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')


subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps)
plotTimecourse(t, flip(squeeze(zProbBurst(:, :, 1, :)), 2), 1, Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of Theta (z-scored)')
legend off


subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps)
plotTimecourse(t, flip(squeeze(zProbBurst(:, :, 2, :)), 2), 1, Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of Alpha (z-scored)')
legend off

saveFig([TitleTag, '_Probof'], Paths.Results, PlotProps)