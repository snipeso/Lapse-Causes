% associates eye /eeg info to trials

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
% Sessions = P.Sessions;
Sessions = P.Sessions_PVT;

Paths = P.Paths;
Task = P.Labels.Task;
Task = 'PVT';
Bands = P.Bands;
Triggers = P.Triggers;
Parameters = P.Parameters;

fs = Parameters.fs; % sampling rate of data

Pool = fullfile(Paths.Pool, 'Tasks'); % place to save matrices so they can be plotted in next script

Window = [0 .5]; % window in which to see if there is an event or not
MinWindow = 1/3; % minimum proportion of window needed to have event to count

% locations
MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);
BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

DataQaulity_Filepath = fullfile(Paths.Core, 'QualityCheck', 'Theta Bursts', ['DataQuality_', Task, '_Pupils.csv']); % file indicating manually identified eye
DataQuality_Table = readtable(DataQaulity_Filepath);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load trials

%%% get trial information
Trials = loadBehavior(Participants, Sessions, Task, Paths, false);

% get time of stim and response trigger
Trials = getTrialLatencies(Trials, MicrosleepPath, Triggers);

% get eyes-closed info
Trials = getECtrials(Trials, MicrosleepPath, DataQuality_Table, fs, Window, MinWindow);

% get burst info
% Trials = getBurstTrials(Trials, BurstPath, Bands, fs, Window, MinWindow);

% Trials.isRight = double(Trials.isRight);

save(fullfile(Pool, [Task, '_AllTrials.mat']), 'Trials')

disp('Done!')
