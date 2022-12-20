% retrofit microsleep/burst timecourse scripts to produce output
% This script compares the effects of:
% - distance from center (50% split)
% - eyeclosure
% - theta burst
% - alpha bursts

% P x T x 2 % T is already normalized to the number of total trials

clear
clc
close all

P = analysisParameters();
StatsP = P.StatsP;
Paths  = P.Paths;
Bands = P.Bands;
BandLabels = fieldnames(Bands)';
PlotProps = P.Manuscript;
TitleTag = 'ES';

%%

%%% load in data

HedgesG = nan(1, 5);
HedgesGCI = nan(2, 5);
xLabels = {};

% eyes closed lapses
[HedgesG, HedgesGCI, xLabels] = loadG(1, HedgesG, HedgesGCI, xLabels, 'EC', ...
    fullfile(Paths.Pool, 'Eyes', 'ProbType_EC.mat'), StatsP);

% Sleep deprivation
[HedgesG, HedgesGCI, xLabels] = loadG(2, HedgesG, HedgesGCI, xLabels, 'SD (EO)', ...
    fullfile(Paths.Pool, 'Tasks', 'ProbType_SD.mat'), StatsP);

% Load distance lapses
[HedgesG, HedgesGCI, xLabels] = loadG(3, HedgesG,HedgesGCI, xLabels, 'Distance (EO)', ...
    fullfile(Paths.Pool, 'Tasks', 'ProbType_Radius.mat'), StatsP);

% Bursts
[HedgesG, HedgesGCI, xLabels] = loadG(4, HedgesG, HedgesGCI, xLabels, 'Alpha (EO)', fullfile(Paths.Pool, 'EEG', 'ProbType_Alpha.mat'), StatsP);
[HedgesG, HedgesGCI, xLabels] = loadG(5, HedgesG, HedgesGCI, xLabels, 'Theta (EO)', fullfile(Paths.Pool, 'EEG', 'ProbType_Theta.mat'), StatsP);


figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width*1, PlotProps.Figure.Height*.2])
Grid = [1 1];

Legend = {};
Colors = getColors(5);
Orientation = 'vertical';
PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 50;
subfigure([], Grid, [1 1], [], true, '', PlotProps);
plotUFO(HedgesG', HedgesGCI', xLabels, Legend, Colors, Orientation, PlotProps)
ylabel("Hedge's g effect on lapse probability")

saveFig(TitleTag, Paths.PaperResults, PlotProps)


function [HedgesG, HedgesGCI, Labels] = loadG(Indx, HedgesG, HedgesGCI, Labels, Label, Location, StatsP)

load(Location, 'ProbType')

Stats = pairedttest(squeeze(ProbType(:, 1, 1)), squeeze(ProbType(:, 1, 2)), StatsP); % P x T x EovsEc
HedgesG(Indx) = Stats.hedgesg;
HedgesGCI(:, Indx) = Stats.hedgesgCI;

Labels{Indx} = Label;

end
