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

Pool = fullfile(Paths.Pool, 'Tasks');
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

%% Plot all behavior information 

Grid = [1 2];

figure('Units','centimeters', 'Position',[0 0  PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

subfigure([], Grid, [1 1], [1 1], true, PlotProps.Indexes.Letters{1}, PlotProps);
hold on
plot([0 3], [.5 .5], 'Color', PlotProps.Color.Generic, 'LineStyle', ':', 'LineWidth', .5)
plotFlames(FlameStruct, PlotProps.Color.Participants, .1, PlotProps)
ylabel('Reaction times (s)')
xlim([.5 2.5])
legend off


%%%
SessionGroups = {[1:3], [4:6]};
% Colors = [getColors([1 3], '', 'blue'); getColors([1 3], '', 'yellow')];
Colors = [getColors([1 2], '', 'red'); getColors([1 2], '', 'yellow'); getColors([1 2], '', 'blue')];
% Colors = getColors([2 3], '', 'yellow');
% Colors = reshape(permute(Colors, [1 3 2]), 6, 3);

subfigure([], Grid, [1, 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);

% eyes open
Q = quantile(Trials.Radius, 0.5);
[EO_Matrix, Things] = tabulateTable(Trials(Trials.EC==0 & Trials.Radius<Q, :), 'Type', 'tabulate', Participants, Sessions, SessionGroups);
[EC_Matrix, Things] = tabulateTable(Trials(Trials.EC==1 & Trials.Radius<Q, :), 'Type', 'tabulate', Participants, Sessions, SessionGroups);
Tots = sum(EO_Matrix, 3)+sum(EC_Matrix, 3);

Matrix = cat(3, EO_Matrix, EC_Matrix);

Order = [1 4 2 5 3 6];
% Colors = Colors(Order, :);
Matrix = Matrix(:, :, Order);

AllTallyLabels = [append(TallyLabels, ' EO'), append(TallyLabels, ' EC')];
AllTallyLabels = AllTallyLabels(Order);

Data = squeeze(mean(100*Matrix./Tots, 1, 'omitnan')); % average, normalizing totals
B = bar(Data, 'stacked');
setAxisProperties(PlotProps)
ylabel('% trials')
xticklabels(SB_Labels)
legend(AllTallyLabels)
for Indx_B =1:numel(B)
    B(Indx_B).EdgeColor = 'none';
    B(Indx_B).FaceColor = Colors(Indx_B, :);
end
box off
ylim([0 100])


%%% C: plot change in lapses with distance





%% stats & QC plot for lapses in closest or furthest 50%

Q = quantile(Trials.Radius, 0.5);

[Closest, Things] = tabulateTable(Trials(Trials.Radius<Q, :), 'Type', 'tabulate', Participants, Sessions, SessionGroups);
[Furthest, ~] = tabulateTable(Trials(Trials.Radius<Q, :), 'Type', 'tabulate', Participants, Sessions, SessionGroups);

ClosestProb = Closest./sum(Closest, 3, 'omitnan');
FurthestProb = Furthest./sum(Furthest, 3, 'omitnan');

ProbLapse = cat(3, ClosestProb(:, :, 1), FurthestProb(:, :, 3));
save(fullfile(Pool, 'ProbLapse_Radius.mat'), 'ProbLapse')

