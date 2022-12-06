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

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};

PlotProps = P.Manuscript;

TitleTag = strjoin({'LapseCauses', 'LAT', 'Performance'}, '_');

Pool = fullfile(Paths.Pool, 'Power');
load(fullfile(Pool, 'AllTrials.mat'), 'Trials')


FlameStruct = struct();

for Indx_S = 1:2
    for Indx_P = 1:numel(Participants)
        RTs = Trials.RT(strcmp(Trials.Participant, Participants{Indx_P}) &...
            contains(Trials.Session, SessionBlocks.(SB_Labels{Indx_S})));
        RTs(isnan(RTs)) = [];
        FlameStruct.(SB_Labels{Indx_S}).(Participants{Indx_P}) = RTs;
    end
end

%%

Grid = [2 2];

figure('Units','centimeters', 'Position',[0 0  PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

subfigure([], Grid, [2 1], [2 1], true, PlotProps.Indexes.Letters{1}, PlotProps);
hold on
plot([0 3], [.5 .5], 'Color', PlotProps.Color.Generic, 'LineStyle', ':', 'LineWidth', .5)
plotFlames(FlameStruct, PlotProps.Color.Participants, .1, PlotProps)
ylabel('Reaction times (s)')
xlim([.5 2.5])
legend off


%%%
SessionGroups = {[1:3], [4:6]};
% Colors = [getColors(1, '', 'red'); getColors(1, '', 'green'); getColors(1, '', 'blue')];
Colors = getColors([1 3], '', 'yellow');

subfigure([], Grid, [1,2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);

% eyes open
Q = quantile(Trials.Radius, 0.5);
[EO_Matrix, Things] = tabulateTable(Trials(Trials.EC==0 & Trials.Radius<Q, :), 'Type', 'tabulate', Participants, Sessions, SessionGroups);
[EC_Matrix, Things] = tabulateTable(Trials(Trials.EC==1 & Trials.Radius<Q, :), 'Type', 'tabulate', Participants, Sessions, SessionGroups);
Tots = sum(EO_Matrix, 3)+sum(EC_Matrix, 3);
Data = squeeze(mean(100*EO_Matrix./Tots, 1, 'omitnan')); % average, normalizing totals
B = bar(Data, 'stacked');
setAxisProperties(PlotProps)
title('Eyes Open')
ylabel('% trials')
xticklabels(SB_Labels)
legend(TallyLabels)
for Indx_B =1:numel(B)
    B(Indx_B).EdgeColor = 'none';
    B(Indx_B).FaceColor = Colors(Indx_B, :);
end
box off

% eyes closed
Colors = getColors([1 3], '', 'blue');

subfigure([], Grid, [2,2], [], true, PlotProps.Indexes.Letters{3}, PlotProps);

Data = squeeze(mean(100*EC_Matrix./Tots, 1, 'omitnan')); % average, normalizing totals
B = bar(Data, 'stacked');
setAxisProperties(PlotProps)
title('Eyes Closed')
ylabel('% trials')
xticklabels(SB_Labels)
legend(TallyLabels)
for Indx_B =1:numel(B)
    B(Indx_B).EdgeColor = 'none';
    B(Indx_B).FaceColor = Colors(Indx_B, :);
end
box off


