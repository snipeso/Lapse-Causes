% retrofit microsleep/burst timecourse scripts to produce output
% This script compares the effects of:
% - distance from center (50% split)
% - eyeclosure
% - theta burst
% - alpha bursts

% P x T x 2 % T is already normalized to the number of total trials

% clear
clc
close all

P = analysisParameters();
StatsP = P.StatsP;
Paths  = P.Paths;
Bands = P.Bands;
BandLabels = {'Theta', 'Alpha'};

%%

HedgesG = nan(1, 4);
HedgesGCI = nan(2, 4);

%%% Load distance lapses
Pool = fullfile(Paths.Pool, 'Tasks');
load(fullfile(Pool, 'ProbType_Radius.mat'), 'ProbType')

Stats = pairedttest(squeeze(ProbType(:, 1, 1)), squeeze(ProbType(:, 1, 2)), StatsP); % P x T x EovsEc
HedgesG(1) = Stats.hedgesg;
HedgesGCI(:, 1) = Stats.hedgesgCI;


%%% load microsleep lapses
Pool = fullfile(Paths.Pool, 'Eyes');
load(fullfile(Pool, 'ProbType_EC.mat'), 'ProbType')

Stats = pairedttest(squeeze(ProbType(:, 1, 1)), squeeze(ProbType(:, 1, 2)), StatsP);
HedgesG(2) = Stats.hedgesg;
HedgesGCI(:, 2) = Stats.hedgesgCI;

%%% load bursts
Pool = fullfile(Paths.Pool, 'EEG');

for Indx_B = 1:numel(BandLabels)
    load(fullfile(Pool, ['ProbType_', BandLabels{Indx_B}, '.mat']), 'ProbType')

    Stats = pairedttest(squeeze(ProbType(:, 1, 1)), squeeze(ProbType(:, 1, 2)), StatsP);
    HedgesG(2+Indx_B) = Stats.hedgesg;
HedgesGCI(:, 2+Indx_B) = Stats.hedgesgCI;
end


figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width*1, PlotProps.Figure.Height*.2])
Grid = [1 1];

Order = [2 1 4 3];
xLabels = ['Radius', 'EC', BandLabels'];
Legend = {};
Colors = getColors(4);
Orientation = 'vertical';
PlotProps = P.Manuscript;
subfigure([], Grid, [1 1], [], true, '', PlotProps)
 plotUFO(HedgesG(Order)', HedgesGCI(:, Order)', xLabels(Order), Legend, ...
        Colors(Order, :), Orientation, PlotProps)
ylabel("Hedge's g effect on lapse probability")
