function Parameters = analysisParameters()
% parameters for detecting bursts
% Lapses-Causes

Parameters = struct();


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Analysis paramaters

% Who, what, when
Parameters.Task = 'LAT'; % main analysis is done on LAT, but some parts use PVT

Parameters.Sessions.LAT = {'BaselineBeam', 'MainPre', 'MainPost', ...
    'Session2Beam1', 'Session2Beam2', 'Session2Beam3'};
Parameters.Sessions.Conditions.BL = {'BaselineBeam',  'MainPre', 'MainPost'};
Parameters.Sessions.Conditions.SD = { 'Session2Beam1', 'Session2Beam2', 'Session2Beam3'};

Parameters.Sessions.PVT = {'BaselineBeam', 'Session2Beam'};

Parameters.Participants = {'P01', 'P02', 'P03', 'P04', 'P05', 'P06', 'P07', 'P08', 'P09', ...
    'P10', 'P11', 'P12', 'P13', 'P14', 'P15', 'P16', 'P17', 'P19'};

% time-course and trial related information
Parameters.SampleRate = 250; % ideally this would be extracted from the EEG, but sometimes pre-allocating before loading makes the code cleaner

Parameters.Stimuli.MaxDistance = 4/6; % exclude outermost stimuli, since lapses are likely just not seeing the thing

Parameters.Trials.Window = [-2, 4]; % time around stimulus to plot
Parameters.Trials.SubWindows = [-2 0; 0 0.3; 0.3 1; 2 4]; % windows in which to average values for topographies
Parameters.Labels.TrialSubWindows = {'Pre', 'Stimulus', 'Response', 'Post'};

Parameters.Trials.MinTotalCount = 30;
Parameters.Trials.MinPerSubGroupCount = 15; % e.g. minimum lapses
Parameters.Trials.MinEventProportion = .5; % when assigning whether a thing happened for a given trial, it needs to have occured at least this much
Parameters.Trials.MaxNaNProportion = .5; % the most amount of NaNs a trial can have before excluding it

Parameters.EyeTracking.MinConfidenceThreshold = 0.5; % pupil model confidence threshold has to be larger than this number

%%% labels
Parameters.Labels.TrialOutcome = {'Lapses', 'Slow', 'Fast'};
% Labels.EyeType = [0 1]; %???
Parameters.Labels.logBands = [1 2 4 8 16 32]; % x markers for plot on log scale
Parameters.Labels.Bands = [1 4 8 15 25 35 40]; % normal scale
Parameters.Labels.FreqLimits = [1 40];
Parameters.Labels.zPower = 'PSD z-scored';
Parameters.Labels.Power = 'PSD Amplitude (\muV^2/Hz)';
Parameters.Labels.Frequency = 'Frequency (Hz)';
Parameters.Labels.Amplitude = 'Amplitude (\muV)';
Parameters.Labels.Time = 'Time (s)';
Parameters.Labels.t = 't-values';
Parameters.Labels.Correct = '% Correct';
Parameters.Labels.RT = 'RT (s)';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Locations

if exist( 'D:\LSM\Preprocessed', 'dir') % KISPI desktop
    Core = 'D:\LSM\';
    addpath('H:\Code\chART')
    addpath('H:\Code\Matcycle')
elseif exist( 'D:\Data\Raw', 'dir')
    Core = 'D:\Data\';
elseif exist( 'F:\Data\Raw', 'dir')
    Core = 'F:\Data\';
elseif  exist( 'E:\Data\Raw', 'dir')
    Core = 'E:\Data\';
else
    error('no data disk!')
    % Core = 'E:\'
end

Paths.Data = fullfile(Core, 'Preprocessed');
Paths.Core = Core;

Paths.RawData = 'G:\LSM\Data\Raw';
Paths.AnalyzedData  = fullfile(Core, 'Final'); % where data gets saved once its been turned into something else
% Paths.PooledData = fullfile(Paths.AnalyzedData, 'PooledData', 'Lapse-Causes');
Paths.Cache = fullfile(Core, 'Cache', 'Lapse-Causes');
Paths.Results = fullfile(Core, 'Results', 'Lapse-Causes');

if ~exist(Paths.Results, 'dir')
    mkdir(Paths.Results)
end

% if eeglab has not run, run it so all the subdirectories get added
if ~exist('topoplot', 'file')
    eeglab
    close all
end

% get path where these scripts were saved
CD = mfilename('fullpath');
Paths.Analysis = fullfile(extractBefore(CD, 'Lapse-Causes'), 'Lapse-Causes');

% get all folders in functions
Subfolders = deblank(string(ls(fullfile(Paths.Analysis, 'functions')))); % all content
Subfolders(contains(Subfolders, '.')) = []; % remove all files

for Indx_F = 1:numel(Subfolders)
    addpath(fullfile(Paths.Analysis, 'functions', Subfolders{Indx_F}))
end

Parameters.Paths = Paths;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% EEG info

% bands used to get bursts
Narrowbands.ThetaLow = [2 6];
Narrowbands.Theta = [4 8];
Narrowbands.ThetaAlpha = [6 10];
Narrowbands.Alpha = [8 12];
Narrowbands.AlphaHigh = [10 14];
Narrowbands.Sigma = [12 16];

Parameters.Narrowbands = Narrowbands;

Bands.Theta = [4 8]; % up to but not including the second edge
Bands.Alpha = [8 14]; 
Parameters.Bands = Bands;


Triggers.SyncEyes = 'S192';
Triggers.Start = 'S  1';
Triggers.End = 'S  2';
Triggers.Stim = 'S  3';
Triggers.Resp = 'S  4';
Triggers.FA = 'S  5';
Triggers.StartBlank = 'S  6';
Triggers.EndBlank = 'S  7';
Triggers.Alarm = 'S  8';
Triggers.LeftBlock = 'S 10';
Triggers.RightBlock = 'S 11';
Triggers.Tones = 'S 12';

% Triggers.Extras = {'boundary', Triggers.Start, Triggers.End, Triggers.Resp, ...
%     Triggers.FA, Triggers.StartBlank, Triggers.EndBlank, Triggers.Alarm, ...
%     Triggers.LeftBlock, Triggers.RightBlock, Tones}; TODO see if needs
%     removing


Parameters.Triggers = Triggers;

Parameters.PlotProps.Manuscript = chART.load_plot_properties({'LSM', 'Manuscript'});
Parameters.Manuscript.Figure.Width = 22;

Parameters.PlotProps.Powerpoint = chART.load_plot_properties({'LSM', 'Powerpoint'});
Parameters.PlotProps.Poster = chART.load_plot_properties({'LSM', 'Poster'});

%%% channel clusters

Frontspot = [22 15 9 23 18 16 10 3 24 19 11 4 124 20 12 5 118 13 6 112];
Backspot = [66 71 76 84 65 70 75 83 90 69 74 82 89];
Centerspot = [129 7 106 80 55 31 30 37 54 79 87 105 36 42 53 61 62 78 86 93 104 35 41 47  52 92 98 103 110, 60 85 51 97];

Channels.PreROI.Front = Frontspot;
Channels.PreROI.Center = Centerspot;
Channels.PreROI.Back = Backspot;

Parameters.Channels = Channels;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% statistics

Stats = struct();

Stats.ANOVA.ES = 'eta2';
% Stats.ANOVA.ES_lims = [0 1];
Stats.ANOVA.nBoot = 2000;
Stats.ANOVA.pValue = 'pValueGG';
Stats.ttest.nBoot = 2000;
Stats.ttest.dep = 'pdep'; % use 'dep' for ERPs, pdep for power
Stats.Alpha = .05;
Stats.Trend = .1;
Stats.Paired.ES = 'hedgesg';
% Stats.Paired.Benchmarks = -2:.5:2;
% Stats.FreqBin = 1; % # of frequencies to bool in spectrums stats
% Stats.minProminence = .1; % minimum prominence for when finding clusters of g values
Parameters.Stats = Stats;



