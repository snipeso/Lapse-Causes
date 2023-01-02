function Info = blinkParameters()
% parameters for detecting bursts
% Lapses-Causes

Info = struct();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Burst Parameters

%%% parameters to find bursts in single channels


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Locations

% if exist( 'D:\Data\Raw', 'dir')
%     Core = 'D:\Data\';
% elseif exist( 'F:\Data\Raw', 'dir')
%     Core = 'F:\Data\';
% elseif  exist( 'E:\Data\Raw', 'dir')
%     Core = 'E:\Data\';
% else
%     error('no data disk!')
%     % Core = 'E:\'
% end

Core = 'D:\LSM\Data\';
Paths.Preprocessed = fullfile(Core, 'Preprocessed');
Paths.Core = Core;

Paths.Datasets = 'G:\LSM\Data\Raw';
Paths.Data  = fullfile(Core, 'Final'); % where data gets saved once its been turned into something else
Paths.Results = fullfile(Core, 'Results', 'Lapse-Causes');

Info.Participants = {'P01', 'P02', 'P03', 'P04', 'P05', 'P06', 'P07', 'P08', ...
    'P09', 'P10', 'P11', 'P12', 'P13', 'P14', 'P15', 'P16', 'P17', 'P19'};

Info.Sessions = {'BaselineBeam', 'MainPre', 'MainPost', 'Session2Beam1', 'Session2Beam2', 'Session2Beam3'};

% if eeglab has not run, run it so all the subdirectories get added
if ~exist('topoplot', 'file')
    eeglab
    close all
end


% get path where these scripts were saved
CD = mfilename('fullpath');
% Paths.Analysis = fullfile(extractBefore(Paths.Analysis, 'Analysis'));
Paths.Analysis = fullfile(extractBefore(CD, 'Lapse-Causes'), 'Lapse-Causes');

% get all folders in functions
Subfolders = deblank(string(ls(fullfile(Paths.Analysis, 'functions')))); % all content
Subfolders(contains(Subfolders, '.')) = []; % remove all files

for Indx_F = 1:numel(Subfolders)
    addpath(fullfile(Paths.Analysis, 'functions', Subfolders{Indx_F}))
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

Channels = struct();
Frontspot = [22 15 9 23 18 16 10 3 24 19 11 4 124 20 12 5 118 13 6 112 21 17 14 25 8 26 2 27 123 28 117];
Backspot = [66 71 76 84 65 70 75 83 90 69 74 82 89 59 58 64 68 73 81 88 94 95 96 67 72 77 91];
Centerspot = [129 7 106 80 55 31 30 37 54 79 87 105 36 42 53 61 62 78 86 93 104 41 47  52 92 98 103 60 85];

Channels.preROI.Front = Frontspot;
Channels.preROI.Center = Centerspot;
Channels.preROI.Back = Backspot;

Channels.Hemifield.Right = [1:5, 8:10, 14, 76:80, 82:87, 88:125];
Channels.Hemifield.Left = [12, 13, 18:54, 56:61, 63:71, 73, 74];
Info.Channels = Channels;




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

Info.Triggers = Triggers;


Pix = get(0,'screensize');
if Pix(3) < 2000
    Format = getProperties({'LSM', 'SmallScreen'});
else
    Format = getProperties({'LSM', 'LargeScreen'});
end

Manuscript = getProperties({'LSM', 'Manuscript'});
Powerpoint =  getProperties({'LSM', 'Powerpoint'});
Poster =  getProperties({'LSM', 'Poster'});

Info.Manuscript = Manuscript; % for papers
Info.Powerpoint = Powerpoint; % for presentations
Info.Poster = Poster;
Info.Format = Format; % plots just to view data