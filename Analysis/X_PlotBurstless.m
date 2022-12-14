
% clear
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
Channels = P.Channels;


TitleTag = strjoin({'LapseCauses', 'LAT', 'Power', 'Burstless'}, '_');


Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
Bands.Theta = [4 8];
Bands.Alpha = [8 12];
BandLabels = {'Theta', 'Alpha'};

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script


load(fullfile(Pool, strjoin({TitleTag, 'ChData.mat'}, '_')), 'bChData', 'AllFields', 'Chanlocs', 'Freqs')


%% plot EEG with and without bursts

Grid = [1 2];
PlotProps = P.Manuscript;
xLog = true;
% xLims = [3 25];
xLims = [2 30];
yLims = [-2.5 2.5];

NormBand = [1 4];
NormBand_Indx = dsearchn(Freqs, NormBand');

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

%%% theta
SB = 2;
B_Indx = 1;
Ch_Indx = 1;


Data = log(squeeze(ChData(:, SB, [B_Indx, 3], Ch_Indx, :)));

Delta = squeeze(mean(Data(:, 1, NormBand_Indx(1):NormBand_Indx(2)), 3, 'omitnan'));
Shift = Delta - mean(Delta, 'omitnan'); 
Data = Data - Shift;

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps)
 plotSpectrumMountains(Data, Freqs', xLog, xLims, PlotProps, P.Labels)
ylim(yLims)
title('SD Front Without Theta Bursts')


%%% alpha
SB = 1;
B_Indx = 2;
Ch_Indx = 3;

Data = log(squeeze(ChData(:, SB, [B_Indx, 3], Ch_Indx, :)));

Delta = squeeze(mean(Data(:, 1, NormBand_Indx(1):NormBand_Indx(2)), 3, 'omitnan'));
Shift = Delta - mean(Delta, 'omitnan'); 
Data = Data - Shift;

subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps)
 plotSpectrumMountains(Data, Freqs', xLog, xLims, PlotProps, P.Labels)
ylim(yLims)
title('BL Back Without Alpha Bursts')











