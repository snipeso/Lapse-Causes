% Figure (and stats) about the burt detection

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

TitleTag = strjoin({'LapseCauses', 'LAT', 'Power', 'Burstless'}, '_');


Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
BandLabels = {'Theta', 'Alpha'};

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script


load(fullfile(Pool, strjoin({TitleTag, 'ChData.mat'}, '_')), 'ChData', 'AllFields', 'Chanlocs', 'Freqs')
load(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent')


%% plot EEG with and without bursts

Grid = [4 2];
PlotProps = P.Manuscript;
PlotProps.Axes.yPadding = 18;
PlotProps.Axes.xPadding = 18;
xLog = true;
xLims = [2 30];
yLims = [-2.5 2.5];

NormBand = [1 4];
NormBand_Indx = dsearchn(Freqs, NormBand');

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width*.8, PlotProps.Figure.Height*.42])

%%% theta
SB = 2;
B_Indx = 1;
Ch_Indx = 1;


Data = log(squeeze(ChData(:, SB, [B_Indx, 3], Ch_Indx, :)));

Delta = squeeze(mean(Data(:, 1, NormBand_Indx(1):NormBand_Indx(2)), 3, 'omitnan'));
Shift = Delta - mean(Delta, 'omitnan'); 
Data = Data - Shift;

subfigure([], Grid, [3 1], [3 1], true, PlotProps.Indexes.Letters{1}, PlotProps);
 plotSpectrumMountains(Data, Freqs', xLog, xLims, PlotProps, P.Labels);
ylim(yLims)
legend({ 'Theta burst power'}, 'location', 'southwest')
set(legend, 'ItemTokenSize', [5 5])
title('Front, sleep deprivation')
ylabel('Log PSD amplitude (\muV^2/Hz)')


%%% alpha
SB = 1;
B_Indx = 2;
Ch_Indx = 3;

Data = log(squeeze(ChData(:, SB, [B_Indx, 3], Ch_Indx, :)));

Delta = squeeze(mean(Data(:, 1, NormBand_Indx(1):NormBand_Indx(2)), 3, 'omitnan'));
Shift = Delta - mean(Delta, 'omitnan'); 
Data = Data - Shift;

subfigure([], Grid, [3 2], [3 1], true, PlotProps.Indexes.Letters{2}, PlotProps);
 plotSpectrumMountains(Data, Freqs', xLog, xLims, PlotProps, P.Labels);
 legend({'Alpha burst power'}, 'location', 'southwest')
 set(legend, 'ItemTokenSize', [5 5])
ylim(yLims)
title('Back, baseline')


Legend = [append(BandLabels, ' bursts'), 'Both'];
YLim = [0 100];

ThetaColor = getColors(1, '', 'red');
AlphaColor = getColors(1, '', 'yellow');
Colors = [ThetaColor; AlphaColor; getColors(1, '', 'orange')];

%%% stacked bar plot for time spent
Data  = 100*squeeze(mean(TimeSpent, 1, 'omitnan'));

subfigure([], Grid, [4 1], [1 2], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotStackedBars(Data(:, [1 3 2]), SB_Labels, YLim, Legend([1 3 2]), Colors([1 3 2], :), PlotProps);
view([90 90])
ylabel('Recording duration (%)')

% saveFig('Bursts', Paths.PaperResults, PlotProps)



%% provide descriptives

clc

for Indx_B = 1:numel(BandLabels)
disp(['Time spent in ', BandLabels{Indx_B} ' EO:'])
disp(['Time spent in ', BandLabels{Indx_B} ' EC:'])
end



