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
Bands = P.Bands;
Triggers = P.Triggers;
Channels = P.Channels;

Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
Bands.Theta = [4 8];
Bands.Alpha = [8 12];
BandLabels = {'Theta', 'Alpha'};
ROI = fieldnames(Channels.preROI);

Pool = fullfile(Paths.Pool, 'EEG');


load(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent', 'TimeSpent_ROI', 'LateralitySum', 'Laterality')



%% plot time spent with bursts

PlotProps = P.Manuscript;
Grid = [5, 3];

figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

Legend = {BandLabels, 'Both'};
YLim = [0 1];

ThetaColor = getColors(1, '', 'red');
AlphaColor = getColors(1, '', 'yellow');
Colors = [ThetaColor; AlphaColor; getColors(1, '', 'orange')];

%%% stacked bar plot for time spent
Data  = squeeze(mean(TimeSpent, 1, 'omitnan'));

subfigure([], Grid, [1 1], [1 3], false, PlotProps.Indexes.Letters{1}, PlotProps)
plotStackedBars(Data, SB_Labels, YLim, Legend, Colors, PlotProps)
view([0 90])


%%% scatter plot for time spent by ROI
% theta
Data = squeeze(TimeSpent_ROI(:, 2, :, 1));

subfigure([], Grid, [5 1], [4 1], false, PlotProps.Indexes.Letters{2}, PlotProps)
 plotScatterBox(Data, [], ROI, PlotProps.Color.Participants, YLim, PlotProps)
title('Theta SD')

% alpha
Data = squeeze(TimeSpent_ROI(:, 2, :, 2));

subfigure([], Grid, [5 2], [4 1], false, PlotProps.Indexes.Letters{3}, PlotProps)
 plotScatterBox(Data, [], ROI, PlotProps.Color.Participants, YLim, PlotProps)
title('Alpha SD')


%%% laterality
% TODO once I know the laterality distribution
SB = 2;
% 
% % number of bursts
% ThetaBursts = squeeze(mean(LateralitySum(:, SB, :, ), 1, 'omitnan'))
% 
% 
% subfigure([], Grid, [3 3], [2 1], false, PlotProps.Indexes.Letters{4}, PlotProps)
% B = bar([.8 1.2 1.8 2.2], Data, 'stacked');
% 
%     legend(Legend)
% 
% for Indx_B =1:numel(B)
%     B(Indx_B).EdgeColor = 'none';
%     B(Indx_B).FaceColor = Colors(Indx_B, :);
% end
% box off
% 
% 
% if ~isempty(YLim)
%     ylim(YLim)
% end
% 
% setAxisProperties(PlotProps)
% 

% laterality values

Data = squeeze(median(Laterality(:, SB, :, :), 1, 'omitnan'))';
CI = quantile(squeeze(Laterality(:, SB, :, :)), [.25 .75], 1)';

subfigure([], Grid, [5 3], [2 1], false, PlotProps.Indexes.Letters{5}, PlotProps)
plotUFO(Data, CI, {'Left VF', 'Right VF'}, BandLabels, [ThetaColor; AlphaColor], 'horizontal', PlotProps)










