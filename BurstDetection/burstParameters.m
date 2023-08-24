function Parameters = burstParameters()
% parameters for detecting bursts
% Lapses-Causes

Parameters = struct();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Burst Parameters

%%% parameters to find bursts in single channels
% irregular shaped bursts
Idx = 1; % this is to make it easier to try things out in the sandbox
CriteriaSets = struct();
CriteriaSets(Idx).PeriodConsistency = .6;
CriteriaSets(Idx).MonotonicityInAmplitude = .6;
CriteriaSets(Idx).FlankConsistency = 0.6;
CriteriaSets(Idx).AmplitudeConsistency = 0.6;
CriteriaSets(Idx).MinCyclesPerBurst = 4;
% % without periodneg, to capture bursts that accelerate/decelerate

% short bursts
Idx = 2;
CriteriaSets(Idx).PeriodConsistency = .7;
CriteriaSets(Idx).MonotonicityInAmplitude = .9;
CriteriaSets(Idx).PeriodNeg = true;
CriteriaSets(Idx).FlankConsistency = 0.3;
CriteriaSets(Idx).MinCyclesPerBurst = 3;

% dirty bursts, relies on shape but low other criteria
Idx = 3; 
CriteriaSets(Idx).PeriodConsistency = .5;
CriteriaSets(Idx).MonotonicityInTime = .4;
CriteriaSets(Idx).MonotonicityInAmplitude = .4;
CriteriaSets(Idx).ReversalRatio = 0.6;
CriteriaSets(Idx).ShapeConsistency = .2;
CriteriaSets(Idx).FlankConsistency = .5;
CriteriaSets(Idx).MinCyclesPerBurst = 3;
CriteriaSets(Idx).AmplitudeConsistency = .4;
CriteriaSets(Idx).MinCyclesPerBurst = 4;
CriteriaSets(Idx).PeriodNeg = true;

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

Sessions = {'BaselineBeam', 'MainPre', 'MainPost', 'Session2Beam1', 'Session2Beam2', 'Session2Beam3'};
Parameters.Sessions = Sessions;

Parameters.Participants = {'P01', 'P02', 'P03', 'P04', 'P05', 'P06', 'P07', 'P08', 'P09',
    'P10', 'P11', 'P12', 'P13', 'P14', 'P15', 'P16', 'P17', 'P19'};
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



