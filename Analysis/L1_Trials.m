% Gather a table of all the trials, associating burst and eye-closure
% status for each trial. Need for XXXX

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();
Participants = P.Participants;
Paths = P.Paths;
Triggers = P.Triggers;
Parameters = P.Parameters;
Bands = P.Bands;
fs = Parameters.fs; % sampling rate of data

Task = 'PVT'; % could be LAT or PVT

% Trial parameters
Window = [0 .3]; % window in which to see if there is an event or not
MinWindow = 1/2; % minimum proportion of window needed to have event to count


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load trials

% locations
Pool = fullfile(Paths.Pool, 'Tasks'); % place to save matrices so they can be plotted in next script
if ~exist(Pool, 'dir')
    mkdir(Pool)
end

MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);
BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

DataQaulity_Filepath = fullfile(Paths.Core, 'QualityCheck', 'Theta Bursts', ['DataQuality_', Task, '_Pupils.csv']); % file indicating manually identified eye
DataQuality_Table = readtable(DataQaulity_Filepath);

if strcmp(Task, 'PVT')
    Sessions = P.Sessions_PVT;
    BurstPath = MicrosleepPath; % because I don't have burst path
else
    Sessions = P.Sessions;
end

%%% get trial information
Trials = loadBehavior(Participants, Sessions, Task, Paths, false);

% get time of stim and response trigger
Trials = getTrialLatencies(Trials, BurstPath, Triggers);

% get eyes-closed info
Trials = getECtrials(Trials, MicrosleepPath, DataQuality_Table, fs, Window, MinWindow);

% get burst info (have not calculated for PVT)
if strcmp(Task, 'LAT')
    Trials = getBurstTrials(Trials, BurstPath, Bands, fs, Window, MinWindow);

    Trials.isRight = double(Trials.isRight);
end

% save
save(fullfile(Pool, [Task, '_AllTrials.mat']), 'Trials')

disp('Done!')
