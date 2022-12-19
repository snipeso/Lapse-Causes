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


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Some data matrices

MinTots = P.Parameters.MinTots; % minimum total of trials for that participant to be considered


SessionBlocks = P.SessionBlocks;
Sessions = [SessionBlocks.BL, SessionBlocks.SD]; % different representation for the tabulateTable function
SessionGroups = {1:3, 4:6};

Q = quantile(Trials.Radius, 0.5);
Closest = Trials.Radius<=Q;
Furthest = Trials.Radius>Q;

EO = Trials.EC == 0;
EC = Trials.EC == 1;

%%% stats & QC plot for lapses in closest or furthest 50% for script: TODO

CheckEyes = false;

% get number of trials by each type for the subset of trials that are closest
[ClosestTally, ~] = tabulateTable(Trials, Closest, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
[FurthestTally, ~] = tabulateTable(Trials, Furthest, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

% make relative to total trials
ClosestTots = sum(ClosestTally, 3, 'omitnan');
ClosestProb = ClosestTally./ClosestTots;

FurthestTots = sum(FurthestTally, 3, 'omitnan');
FurthestProb = FurthestTally./FurthestTots;

% use only SD data
SB_Indx = 2;
ProbType = cat(3, squeeze(ClosestProb(:, SB_Indx, :)), squeeze(FurthestProb(:, SB_Indx, :))); % P x TT x D

% remove data that has too few trials
MinTotsSplit = MinTots/2; % half, since splitting trials by distance
BadParticipants = ClosestTots(:, SB_Indx) < MinTotsSplit | FurthestTots(:, SB_Indx) < MinTotsSplit;
ProbType(BadParticipants, :, :) = nan;

% save
Pool = fullfile(Paths.Pool, 'Tasks'); % place to save matrices so they can be plotted in next script
save(fullfile(Pool, 'ProbType_Radius.mat'), 'ProbType')



%%% proportion of lapses based on eye status

SB_Indx = 2;

% load tally split by EO and EC trials
[EO_Matrix, ~] = tabulateTable(Trials, EO, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
[EC_Matrix, ~] = tabulateTable(Trials, EC, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes);

Tot_EO = sum(EO_Matrix, 3);
Tot_EC = sum(EC_Matrix, 3);

% normalize by total trials per each eye condition
EO_Matrix = EO_Matrix./Tot_EO;
EC_Matrix = EC_Matrix./Tot_EC;

ProbType = cat(3, squeeze(EO_Matrix(:, SB_Indx, :)), squeeze(EC_Matrix(:, SB_Indx, :))); % P x TT x E

% remove participants who dont have enough trials
BadParticipants = Tot_EC(:, SB_Indx)<MinTots | Tot_EO(:, SB_Indx)<MinTots;

ProbType(BadParticipants, :, :) = nan;

Pool = fullfile(Paths.Pool, 'Combo'); % place to save matrices so they can be plotted in next script
save(fullfile(Pool, 'ProbType_EC.mat'), 'ProbType')