
StatsP = P.StatsP;
PlotProps = P.Manuscript;
TitleTag = 'Timecourses';



load(fullfile(Paths.Pool, 'Eyes', 'ProbMicrosleep.mat'), 'ProbMicrosleep', 't', 'GenProbMicrosleep')
t_microsleep = t;
sProbMicrosleep =  smooth_frequencies(ProbMicrosleep, t_microsleep, 'last', .5);
zProbMicrosleep = zScoreData(sProbMicrosleep, 'first');


load(fullfile(Paths.Pool, 'EEG', 'ProbBurst.mat'), 'ProbBurst', 't',  'GenProbBurst')
t_burst = t;
sProbBurst =  smooth_frequencies(ProbBurst, t_burst, 'last', .5);
zProbBurst = zScoreData(permute(sProbBurst, [1 2 4 3]), 'last');
zProbBurst = permute(zProbBurst, [1 2 4 3]);

%%

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [-1.5 2];

Grid = [1 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.4])

chART.sub_plot([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps)
plotTimecourse(t_microsleep, flip(zProbMicrosleep, 2), GenProbMicrosleep, Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')


chART.sub_plot([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps)
plotTimecourse(t_burst, flip(squeeze(zProbBurst(:, :, 1, :)), 2), GenProbBurst(:, 1), Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of Theta (z-scored)')
legend off


chART.sub_plot([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps)
plotTimecourse(t_burst, flip(squeeze(zProbBurst(:, :, 2, :)), 2),  GenProbBurst(:, 2), Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of Alpha (z-scored)')
legend off

saveFig([TitleTag, '_Probof_zscored'], Paths.Results, PlotProps)



%%

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [0 .7];

Grid = [1 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.4])

chART.sub_plot([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps)
plotTimecourse(t_microsleep, flip(sProbMicrosleep, 2), GenProbMicrosleep, Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of eyes closed')


chART.sub_plot([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps)
plotTimecourse(t_burst, flip(squeeze(sProbBurst(:, :, 1, :)), 2), GenProbBurst(:, 1), Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta')
legend off


chART.sub_plot([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps)
plotTimecourse(t_burst, flip(squeeze(sProbBurst(:, :, 2, :)), 2),  GenProbBurst(:, 2), Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha')
legend off

saveFig([TitleTag, '_Probof_raw'], Paths.Results, PlotProps)




%% alpha hemifield effect

load(fullfile(Paths.Pool, 'EEG', 'ProbBurst.mat'), 'HemiProbBurst', 't',  'ProbBurstHemifield')


%%
StatsP = P.StatsP;
PlotProps = P.Manuscript;
TitleTag = 'Timecourses';


sHemiProbBurst =  smooth_frequencies(ProbBurstHemifield, t, 'last', .5);

%%
Range = [];
figure
% plotTimecourse(t, flip(sHemiProbBurst, 2),  HemiProbBurst, Range, {'Left', 'Right'}, getColors(3), StatsP, PlotProps)
plotTimecourse(t, flip(sHemiProbBurst, 2),  HemiProbBurst, Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)

ylim(Range)
ylabel('Probability of alpha')








