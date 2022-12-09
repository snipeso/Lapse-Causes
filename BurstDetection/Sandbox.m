clear
clc
close all

Info = burstParameters();
Paths = Info.Paths;
Bands = Info.Bands;
BandLabels = fieldnames(Bands);

% place to try different parameters for burst detection

% Task = 'Game'; % Game or Standing
% Session = 'Session2';
% Participant = 'P10';

Task = 'LAT'; % Game or Standing
Session = 'Session2Comp';
Participant = 'P15';

Filename_Source = strjoin({Participant, Task, Session, 'Clean.mat'}, '_');



%%


Min_Peaks = 4;

BT = struct();
BT.monotonicity = .6;
BT.periodConsistency = .6;
BT.periodMeanConsistency = .6;
BT.efficiency = .6;
BT.truePeak = 1;
BT.flankConsistency = .5;
BT.ampConsistency = .6;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
Source = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task); % normal data
Source_Filtered = fullfile(Paths.Preprocessed, 'Clean', 'Waves_Filtered', Task); % extremely filtered data
Source_Cuts = fullfile(Paths.Preprocessed, 'Cutting', 'Cuts', Task); % timepoints marked as artefacts


% load data
Filename_Filtered = replace(Filename_Source, 'Clean.mat', 'Filtered.mat');
Filename_Cuts = replace(Filename_Source, 'Clean.mat', 'Cuts.mat');

M = load(fullfile(Source, Filename_Source), 'EEG');
EEG = M.EEG;
fs = EEG.srate;

% get timepoints without noise
NoiseEEG = nanNoise(EEG, fullfile(Source_Cuts, Filename_Cuts));
Keep_Points = ~isnan(NoiseEEG.data(1, :));

% need to concatenate structures
FiltEEG = EEG;
FiltEEG.Band = [];

for Indx_B = 1:numel(BandLabels) % get bursts for all provided bands

    % load in filtered data
    Band = Bands.(BandLabels{Indx_B});
    F = load(fullfile(Source_Filtered, BandLabels{Indx_B}, Filename_Filtered));
    FiltEEG(Indx_B) = F.FiltEEG;
end


%%

% short
BT = struct();
BT.periodConsistency = .3;
BT.amplitude = 25;
Min_Peaks = 3;
BT.isProminent = 1;
BT.truePeak = 1;

% long
% BT = struct();
% BT.monotonicity = .5;
% BT.periodConsistency = .5;
% BT.efficiency = .6;
% BT.truePeak = 1;
% BT.flankConsistency = .5;
% BT.ampConsistency = .5;
% BT.efficiencyAdj = .5;
% BT.Min_Peaks = 6;
% BT.periodMeanConsistency = .5;
% Min_Peaks = 6;

% clean
% BT = struct();
% BT.monotonicity = .6;
% BT.periodConsistency = .6;
% BT.periodMeanConsistency = .6;
% BT.efficiency = .6;
% BT.truePeak = 1;
% BT.flankConsistency = .5;
% BT.ampConsistency = .5;
% % BT.amplitude = 10;
% Min_Peaks = 3;


%%% single channel

Ch = 11;
Indx_B = 2;


Ch = labels2indexes(Ch, EEG.chanlocs);

Signal = EEG.data(Ch, :);
fSignal = FiltEEG(Indx_B).data(Ch, :);

Peaks = peakDetection(Signal, fSignal);
Peaks = peakProperties(Signal, Peaks, fs);
BT.period = 1./Bands.(BandLabels{Indx_B}); % add period threshold
[Bursts, BurstPeakIDs, Diagnostics] = findBursts(Peaks, BT, Min_Peaks, Keep_Points);

plotBursts(Signal, fs, Peaks, BurstPeakIDs, BT)

%% Everything

% short
BT = struct();
BT(1).periodConsistency = .3;
BT(1).amplitude = 25;
BT(1).Min_Peaks = 3;
BT(1).isProminent = 1;
BT(1).truePeak = 1;

% long
BT(2).monotonicity = .5;
BT(2).periodConsistency = .5;
BT(2).efficiency = .6;
BT(2).truePeak = 1;
BT(2).flankConsistency = .5;
BT(2).ampConsistency = .5;
BT(2).efficiencyAdj = .5;
BT(2).Min_Peaks = 6;
BT(2).periodMeanConsistency = .5;

% clean
BT(3).monotonicity = .6;
BT(3).periodConsistency = .6;
BT(3).periodMeanConsistency = .6;
BT(3).efficiency = .6;
BT(3).truePeak = 1;
BT(3).flankConsistency = .5;
BT(3).ampConsistency = .6;
BT(3).Min_Peaks = 4;

% get bursts in all data
AllBursts = getAllBursts(EEG, FiltEEG, BT, [], Bands, Keep_Points);


previewBursts(EEG, 20, AllBursts, 'BT')


%%
Bursts = burstPeakProperties(AllBursts, EEG);
        Bursts = meanBurstPeakProperties(Bursts); % just does the mean of the main peak's properties


%% Final distibution of bursts

figure
Freqs = 1./[Bursts.Mean_period];
histogram(Freqs)


%% power in and out of bursts
Freqs = 1./[Bursts.Mean_period];
% histogram(Freqs)

WelchWindow = 8; % duration of window to do FFT
Overlap = .75; % overlap of hanning windows for FFT

BurstBand = Freqs>=8 & Freqs <=12;
% BurstBand = Freqs
EEG1 = pop_select(EEG, 'nopoint', [[AllBursts(BurstBand).Start]', [AllBursts(BurstBand).End]']);

 [Power, Freqs] = powerEEG(EEG, WelchWindow, Overlap);
 [Power1, ~] = powerEEG(EEG1, WelchWindow, Overlap);

 %

figure('units', 'normalized', 'Position', [0 0 .5 .5])
subplot(1, 3, 1)
plot(log(Freqs), log(Power)', 'Color', [.5 .5 .5 .2], 'LineWidth', 1)
title('Original Data')
xlim(log([1 40]))

subplot(1, 3, 2)
plot(log(Freqs), log(Power1)', 'Color', [.5 .5 .5 .2], 'LineWidth', 1)
title('Burstless Data')
xlim(log([1 40]))


subplot(1, 3, 3)
hold on
plot(log(Freqs), log(mean(Power, 2)), 'LineWidth',2)
plot(log(Freqs), log(mean(Power1, 2)), 'LineWidth',2)
legend({'original', 'burstless'})
xlim(log([1 40]))


Info = struct();

Info.Tasks = {'Fixation', 'Standing', 'Oddball'};

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Burst Parameters

%%% parameters to find bursts in single channels

Info.Min_Peaks = 4;

Info.Max_Minutes = 6; % first number of clean minutes to look for bursts in

BT = struct();
BT.monotonicity = .6;
BT.periodConsistency = .6;
BT.periodMeanConsistency = .6;
BT.efficiency = .6;
BT.truePeak = 1;
BT.flankConsistency = .5;
BT.ampConsistency = .6;
Info.BurstThresholds = BT;


%%% Parameters to aggregate across channels
Info.MinCoherence = .7;
Info.MinCorr = .8;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Locations

if exist( 'D:\Data\Raw', 'dir')
    Core = 'D:\Data\';
elseif exist( 'F:\Data\Raw', 'dir')
    Core = 'F:\Data\';
elseif  exist( 'E:\Data\Raw', 'dir')
    Core = 'E:\Data\';
else
    error('no data disk!')
    % Core = 'E:\'
end

Paths.Preprocessed = fullfile(Core, 'Preprocessed');
Paths.Core = Core;

Paths.Datasets = 'G:\LSM\Data\Raw';
Paths.Data  = fullfile(Core, 'Final'); % where data gets saved once its been turned into something else
Paths.Results = fullfile(Core, 'Results', 'Theta_Bursts');

% if eeglab has not run, run it so all the subdirectories get added
if ~exist('topoplot', 'file')
    eeglab
    close all
end

% same for matcycle scripts, saved to a different repo (https://github.com/hubersleeplab/matcycle)
addMatcyclePaths()

% get path where these scripts were saved
CD = mfilename('fullpath');
% Paths.Analysis = fullfile(extractBefore(Paths.Analysis, 'Analysis'));
Paths.Analysis = fullfile(extractBefore(CD, '2process_Bursts'), '2process_Bursts');

% get all folders in functions
Subfolders = deblank(string(ls(fullfile(Paths.Analysis, 'functions')))); % all content
Subfolders(contains(Subfolders, '.')) = []; % remove all files

for Indx_F = 1:numel(Subfolders)
    addpath(fullfile(CD, Subfolders{Indx_F}))
end

Info.Paths = Paths;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EEG info

% bands used to get bursts
Bands.ThetaLow = [2 6];
Bands.Theta = [4 8];
Bands.ThetaAlpha = [6 10];
Bands.Alpha = [8 12];
Bands.AlphaHigh = [10 14];

% % bands used to
% PowerBands.Delta = [1 4];
% PowerBands.Theta = [4 8];
% PowerBands.Alpha = [8 12];
% PowerBands.Beta = [15 25];
% Info.PowerBands = PowerBands;

Info.Bands = Bands;

