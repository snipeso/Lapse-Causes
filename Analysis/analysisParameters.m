function Parameters = analysisParameters()
% parameters for detecting bursts
% Lapses-Causes

Parameters = struct();


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Analysis paramaters

% Who, what, when
Parameters.Task = 'LAT';

Parameters.Sessions = {'BaselineBeam', 'MainPre', 'MainPost', ...
    'Session2Beam1', 'Session2Beam2', 'Session2Beam3'};

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
Bands.ThetaLow = [2 6];
Bands.Theta = [4 8];
Bands.ThetaAlpha = [6 10];
Bands.Alpha = [8 12];
Bands.AlphaHigh = [10 14];
Bands.Sigma = [12 16];

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
%     Triggers.LeftBlock, Triggers.RightBlock, Tones};


Parameters.Triggers = Triggers;

Parameters.PlotProps.Manuscript = chART.load_plot_properties({'LSM', 'Manuscript'});
Parameters.Manuscript.Figure.Width = 22;

Parameters.PlotProps.Powerpoint = chART.load_plot_properties({'LSM', 'Powerpoint'});
Parameters.PlotProps.Poster = chART.load_plot_properties({'LSM', 'Poster'});



