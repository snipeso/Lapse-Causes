
StatsP = P.StatsP;

PlotProps = P.Manuscript;
sProbMicrosleep =  smoothFreqs(ProbMicrosleep, t, 'last', .2);
zProbMicrosleep = zScoreData(sProbMicrosleep, 'first');


%%
Range = [-1.5 2];

figure
hold on
% plotAngelHair(t, zProbMicrosleep(:, [3 2 1], :), PlotProps.Color.Participants, {'Correct', 'Late', 'Lapses'}, PlotProps)
plotTimecourse(t, flip(zProbMicrosleep, 2), 1, Range, flip(TallyLabels), getColors(3), StatsP, PlotProps)
ylim(Range)
