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

Grid = [1 2];

figure('Units','centimeters', 'Position',[0 0  PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
hold on
plot([0 3], [.5 .5], 'Color', PlotProps.Color.Generic, 'LineStyle', ':', 'LineWidth', .5)
plotFlames(FlameStruct, PlotProps.Color.Participants, .1, PlotProps)
ylabel('Reaction times (s)')
xlim([.5 2.5])
legend off


