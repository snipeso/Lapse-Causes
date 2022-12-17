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
Bands.Theta = [4 8];
Bands.Alpha = [8 12];
BandLabels = {'Theta', 'Alpha'};


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
load(fullfile(Pool, 'ProbType_Bursts.mat'), 'ProbType')

for Indx_B = 1:numel(BandLabels)
    Stats = pairedttest(squeeze(ProbType(:, 1, Indx_B, 1)), squeeze(ProbType(:, 1, Indx_B, 2)), StatsP);
    HedgesG(2+Indx_B) = Stats.hedgesg;
HedgesGCI(:, 2+Indx_B) = Stats.hedgesgCI;
end


%%
figure
Order = 1:4;
xLabels = ['Radius', 'EC', BandLabels];
Legend = {};
Colors = getColors(4);
Orientation = 'vertical';
PlotProps = P.Manuscript;
 plotUFO(HedgesG(Order)', HedgesGCI(:, Order)', xLabels(Order), Legend, ...
        Colors(Order, :), Orientation, PlotProps)
ylabel("Hedge's G")
