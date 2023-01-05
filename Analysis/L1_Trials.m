% associates eye /eeg info to trials

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
Sessions = P.Sessions;

Paths = P.Paths;
Task = P.Labels.Task;
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load trials

%%% get trial information
Trials = loadBehavior(Participants, Sessions, Task, Paths, false);

% get time of stim and response trigger
Trials = getTrialLatencies(Trials, BurstPath, Triggers);

% get eyes-closed info
Trials = getECtrials(Trials, MicrosleepPath, fs, Window, MinWindow);

% get burst info
Trials = getBurstTrials(Trials, BurstPath, Bands, fs, Window, MinWindow);

Trials.isRight = double(Trials.isRight);

save(fullfile(Pool, 'AllTrials.mat'), 'Trials')

disp('Done!')
