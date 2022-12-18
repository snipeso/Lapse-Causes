% associates eye info to trials

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
Sessions = P.Sessions;
TallyLabels = P.Labels.Tally;
Paths = P.Paths;
Task = P.Labels.Task;
Bands = P.Bands;
Channels = P.Channels;
Triggers = P.Triggers;
fs = 250; % sampling rate of data

Pool = fullfile(Paths.Pool, 'Tasks'); % place to save matrices so they can be plotted in next script


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load trials

%%% get trial information
Trials = loadBehavior(Participants, Sessions, Task, Paths, false);

% get time of stim and response trigger
EEGPath = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Trials = getTrialLatencies(Trials, EEGPath, Triggers);

% get eyes-closed info
MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task); % also 1000 fs
Trials = getECtrials(Trials, MicrosleepPath, fs);

% set to nan all trials that are beyond 50% radius and with eyes closed
Trials.FinalType = Trials.Type;

Q = quantile(Trials.Radius, 0.5);
Trials.FinalType(Trials.Radius>Q) = nan;

Trials.FinalType(isnan(Trials.EC)|Trials.EC==1) = nan;

Trials.isRight = double(Trials.isRight);

save(fullfile(Pool, 'AllTrials.mat'), 'Trials')