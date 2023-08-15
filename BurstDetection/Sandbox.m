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

Task = 'PVT'; % Game or Standing
Session = 'Session2Beam';
Participant = 'P10';

Source = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task); % normal data
Filename_Source = strjoin({Participant, Task, Session, 'Clean.mat'}, '_');

load(fullfile(Source, Filename_Source), 'EEG')
SampleRate = EEG.srate;


%% select data and plot spectrum

Channel = 11;

% select data
DataBroadband = EEG.data(labels2indexes(Channel, EEG.chanlocs), :);

[Power, Frequencies] = cycy.utils.compute_power(DataBroadband, SampleRate);

figure
cycy.plot.power_spectrum(Power, Frequencies, true, true)

%% filter data

Range = [4 9]; % select a range that is wide enough to cover the variability you expect for a specific band (i.e. start and end of the oscillatory bump in the power spectrum)

DataNarrowband = cycy.utils.highpass_filter(DataBroadband, SampleRate, Range(1)); % if you want, you can specify other aspects of the filter; see function
DataNarrowband = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, Range(2));


%% Single channel

CriteriaSet = struct();
CriteriaSet.MonotoncityInTime = .8;
CriteriaSet.PeriodConsistency = .6;
CriteriaSet.MonotoncityInAmplitude = .6;
CriteriaSet.FlankConsistency = .6;
CriteriaSet.AmplitudeConsistency = .6;
CriteriaSet.MinCyclesPerBurst = 3;

% detect cycles
Cycles = cycy.detect_cycles(DataBroadband, DataNarrowband);
AugmentedCycles = cycy.measure_cycle_properties(DataBroadband, Cycles, SampleRate);

% detect bursts
[Bursts, Diagnostics] = cycy.aggregate_cycles_into_bursts(AugmentedCycles, CriteriaSet);


cycy.plot.cycles_and_criteria(DataBroadband, SampleRate, DataNarrowband, ...
    AugmentedCycles, CriteriaSet, Bursts);
cycy.plot.criteriaset_diagnostics(Diagnostics)
% cycy.plot.properties_distributions(AugmentedCycles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

load(fullfile(Source, Filename_Source), 'EEG')
SampleRate = EEG.srate;

for Indx_B = 1:numel(BandLabels) % get bursts for all provided bands

    % load in filtered data
    Band = Bands.(BandLabels{Indx_B});
    F = load(fullfile(Source_Filtered, BandLabels{Indx_B}, Filename_Filtered));
    FiltEEG(Indx_B) = F.FiltEEG;
end


%%

% short
% BT = struct();
% BT.PeriodConsistency = .3;
% BT.Amplitude = 25;
% Min_Peaks = 3;
% BT.isProminent = 1;
% BT.isTruePeak = 1;

% long
% BT = struct();
% BT.MonotoncityInTime = .5;
% BT.PeriodConsistency = .5;
% BT.MonotoncityInAmplitude = .6;
% BT.isTruePeak = 1;
% BT.FlankConsistency = .5;
% BT.AmplitudeConsistency = .5;
% BT.MinCyclesPerBurst = 6;
% BT.periodMeanConsistency = .5;
% Min_Peaks = 6;

% clean
CriteriaSet = struct();
CriteriaSet.MonotoncityInTime = .6;
CriteriaSet.PeriodConsistency = .6;
CriteriaSet.periodMeanConsistency = .6;
CriteriaSet.MonotoncityInAmplitude = .6;
CriteriaSet.isTruePeak = 1;
CriteriaSet.FlankConsistency = .5;
CriteriaSet.AmplitudeConsistency = .5;
% BT.Amplitude = 10;
Min_Peaks = 3;


%%% single channel

Ch = 23;
Indx_B = 2;
Sign = 1;

Ch = labels2indexes(Ch, EEG.chanlocs);

Signal = Sign*EEG.data(Ch, :);
fSignal = Sign*FiltEEG(Indx_B).data(Ch, :);

Peaks = peakDetection(Signal, fSignal);
Peaks = peakProperties(Signal, Peaks, SampleRate);
CriteriaSet.period = 1./Bands.(BandLabels{Indx_B}); % add period threshold
[Bursts, BurstPeakIDs, Diagnostics] = findBursts(Peaks, CriteriaSet, Min_Peaks, Keep_Points);

plotBursts(Signal, SampleRate, Peaks, BurstPeakIDs, CriteriaSet)

%% Everything

% short
CriteriaSet = struct();
CriteriaSet(1).PeriodConsistency = .3;
CriteriaSet(1).Amplitude = 25;
CriteriaSet(1).MinCyclesPerBurst = 3;
CriteriaSet(1).isProminent = 1;
CriteriaSet(1).isTruePeak = 1;

% long
CriteriaSet(2).MonotoncityInTime = .5;
CriteriaSet(2).PeriodConsistency = .5;
CriteriaSet(2).MonotoncityInAmplitude = .6;
CriteriaSet(2).isTruePeak = 1;
CriteriaSet(2).FlankConsistency = .5;
CriteriaSet(2).AmplitudeConsistency = .5;
CriteriaSet(2).MonotoncityInAmplitudeAdj = .5;
CriteriaSet(2).MinCyclesPerBurst = 6;
CriteriaSet(2).periodMeanConsistency = .5;

% clean
CriteriaSet(3).MonotoncityInTime = .6;
CriteriaSet(3).PeriodConsistency = .6;
CriteriaSet(3).periodMeanConsistency = .6;
CriteriaSet(3).MonotoncityInAmplitude = .6;
CriteriaSet(3).isTruePeak = 1;
CriteriaSet(3).FlankConsistency = .5;
CriteriaSet(3).AmplitudeConsistency = .6;
CriteriaSet(3).MinCyclesPerBurst = 4;

% get bursts in all data
AllBursts = getAllBursts(EEG, FiltEEG, CriteriaSet, [], Bands, Keep_Points);


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
plot(log(Freqs), log(mean(Power, 1)), 'LineWidth',2)
plot(log(Freqs), log(mean(Power1, 1)), 'LineWidth',2)
legend({'original', 'burstless'})
xlim(log([1 40]))


Info = struct();

Info.Tasks = {'Fixation', 'Standing', 'Oddball'};

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Burst Parameters

%%% parameters to find bursts in single channels

Info.MinCyclesPerBurst = 4;

Info.Max_Minutes = 6; % first number of clean minutes to look for bursts in

CriteriaSet = struct();
CriteriaSet.MonotoncityInTime = .6;
CriteriaSet.PeriodConsistency = .6;
CriteriaSet.periodMeanConsistency = .6;
CriteriaSet.MonotoncityInAmplitude = .6;
CriteriaSet.isTruePeak = 1;
CriteriaSet.FlankConsistency = .5;
CriteriaSet.AmplitudeConsistency = .6;
Info.CriteriaSets = CriteriaSet;


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

