function Parameters = burstParameters()
% parameters for detecting bursts
% Lapses-Causes

Parameters = struct();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Burst Parameters

%%% parameters to find bursts in single channels

% short
CriteriaSets = struct();
CriteriaSets(1).PeriodConsistency = .3;
CriteriaSets(1).Amplitude = 25;
CriteriaSets(1).MinCyclesPerBurst = 3;
CriteriaSets(1).isProminent = 1;
CriteriaSets(1).isTruePeak = 1;

% long
CriteriaSets(2).MonotoncityInTime = .5;
CriteriaSets(2).PeriodConsistency = .5;
CriteriaSets(2).MonotoncityInAmplitude = .6;
CriteriaSets(2).isTruePeak = 1;
CriteriaSets(2).FlankConsistency = .5;
CriteriaSets(2).AmplitudeConsistency = .5;
CriteriaSets(2).MinCyclesPerBurst = 6;


% clean
CriteriaSets(3).MonotoncityInTime = .6;
CriteriaSets(3).PeriodConsistency = .6; % C
CriteriaSets(3).MonotoncityInAmplitude = .6;
CriteriaSets(3).isTruePeak = 1; % A
CriteriaSets(3).FlankConsistency = .5; % D
CriteriaSets(3).AmplitudeConsistency = .6;% E
CriteriaSets(3).MinCyclesPerBurst = 4;

Parameters.CriteriaSets = CriteriaSets;


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
Paths.Results = fullfile(Core, 'Results', 'Lapse-Causes');

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

Parameters.Triggers = Triggers;

Parameters.PlotProps.Manuscript = chART.load_plot_properties({'LSM', 'Manuscript'});
Parameters.PlotProps.Powerpoint = chART.load_plot_properties({'LSM', 'Powerpoint'});
Parameters.PlotProps.Poster = chART.load_plot_properties({'LSM', 'Poster'});



