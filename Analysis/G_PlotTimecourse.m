

PlotProps = P.Manuscript;
sProbMicrosleep =  smoothFreqs(ProbMicrosleep, t, 'last', .2);
zProbMicrosleep = zScoreData(sProbMicrosleep, 'first');


%%
Range = [-1.5 4];

figure
hold on
rectangle('position', [0 Range(1) 0.5, diff(Range)], 'EdgeColor','none', 'FaceColor', [PlotProps.Color.Generic, .15])
plotAngelHair(t, zProbMicrosleep(:, [3 2 1], :), PlotProps.Color.Participants, {'Correct', 'Late', 'Lapses'}, PlotProps)
ylim(Range)
