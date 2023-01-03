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
Parameters = P.Parameters;

Radius = 2/3;
fs = Parameters.fs; % sampling rate of data
Refresh = true;

Pool = fullfile(Paths.Pool, 'Tasks'); % place to save matrices so they can be plotted in next script

Window = [0 .5];
MinWindow = .5;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load trials

if Refresh || ~exist(fullfile(Pool, 'AllTrials.mat'))
    %%% get trial information
    Trials = loadBehavior(Participants, Sessions, Task, Paths, false);

    % get time of stim and response trigger
    EEGPath = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
    Trials = getTrialLatencies(Trials, EEGPath, Triggers);

    % get eyes-closed info
    MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);
    Trials = getECtrials(Trials, MicrosleepPath, fs, Window, MinWindow);

    % get burst info
    BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task);
    Trials = getBurstTrials(Trials, BurstPath, Bands, fs, Window, MinWindow);

    % set to nan all trials that are beyond 50% radius and with eyes closed
    Trials.FinalType = Trials.Type;

    Q = quantile(Trials.Radius, 0.5);
    Trials.FinalType(Trials.Radius>Q) = nan;

    Trials.FinalType(isnan(Trials.EC)|Trials.EC==1) = nan;

    Trials.isRight = double(Trials.isRight);

    save(fullfile(Pool, 'AllTrials.mat'), 'Trials')

else
    load(fullfile(Pool, 'AllTrials.mat'), 'Trials')
end


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Some data matrices

MinTots = P.Parameters.MinTots; % minimum total of trials for that participant to be considered


SessionBlocks = P.SessionBlocks;
Sessions = [SessionBlocks.BL, SessionBlocks.SD]; % different representation for the tabulateTable function
SessionGroups = {1:3, 4:6};


%%% stats & QC plot for lapses in closest or furthest 50% for script

Q = quantile(Trials.Radius, [1/3 2/3]);
Closest = Trials.Radius<=Q(1);
Furthest = Trials.Radius>=Q(2);
EO = Trials.EC == 0;
EC = Trials.EC == 1;
CheckEyes = true;

% get number of trials by each type for the subset of trials that are closest
[ClosestTally, ~] = tabulateTable(Trials, EO&Closest, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
[FurthestTally, ~] = tabulateTable(Trials, EO&Furthest, 'Type', 'tabulate', ...
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

Pool = fullfile(Paths.Pool, 'Eyes'); % place to save matrices so they can be plotted in next script
save(fullfile(Pool, 'ProbType_EC.mat'), 'ProbType')


%%% Proportion of lapses based on burst status
% TODO: try first without excluding eyes, then excluding eyes
BandLabels = fieldnames(Bands);
Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script

SB_Indx = 2;

EO = Trials.EC == 0;
EC = Trials.EC == 1;
CheckEyes = true;

for Indx_B = 1:numel(BandLabels)
    % load tally split by EO and EC trials
    [NoBurst_Matrix, ~] = tabulateTable(Trials, EO & Trials.(BandLabels{Indx_B})==0, 'Type', 'tabulate', ...
        Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT
    [Burst_Matrix, ~] = tabulateTable(Trials, EO & Trials.(BandLabels{Indx_B})==1, 'Type', 'tabulate', ...
        Participants, Sessions, SessionGroups, CheckEyes);

    Tot_noBurst = sum(NoBurst_Matrix, 3);
    Tot_Burst = sum(Burst_Matrix, 3);

    % normalize by total trials per each eye condition
    NoBurst_Matrix = NoBurst_Matrix./Tot_noBurst;
    Burst_Matrix = Burst_Matrix./Tot_Burst;

    ProbType = cat(3, squeeze(NoBurst_Matrix(:, SB_Indx, :)), squeeze(Burst_Matrix(:, SB_Indx, :))); % P x TT x E

    % remove participants who dont have enough trials
    BadParticipants = Tot_Burst(:, SB_Indx)<MinTots | Tot_noBurst(:, SB_Indx)<MinTots;

    ProbType(BadParticipants, :, :) = nan;

    save(fullfile(Pool, ['ProbType_', BandLabels{Indx_B}, '.mat']), 'ProbType')
end


%%% effect of sleep deprivation on eyes-open lapses
[EO_Matrix, ~] = tabulateTable(Trials, EO, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, CheckEyes); % P x SB x TT

Tot_EO = sum(EO_Matrix, 3);

% normalize by total trials per each eye condition
EO_Matrix = EO_Matrix./Tot_EO;

ProbType = cat(3, permute((EO_Matrix), [1 3 2])); % P x TT x SB

% remove participants who dont have enough trials
BadParticipants = any(Tot_EO<MinTots, 2);

ProbType(BadParticipants, :, :) = nan;

Pool = fullfile(Paths.Pool, 'Tasks'); % place to save matrices so they can be plotted in next script
save(fullfile(Pool, 'ProbType_SD.mat'), 'ProbType')



%% get change in RT with bursts

CheckEyes = true;

RTs = nan(numel(Participants), numel(SessionGroups), numel(BandLabels), 2); % P x SB x B x N/Y
for Indx_B = 1:numel(BandLabels)
    % load tally split by EO and EC trials
    
    % no burst
    [RTs(:, :, Indx_B, 1), ~] = tabulateTable(Trials, EO & Trials.(BandLabels{Indx_B})==0, ...
        'RT', 'mean', Participants, Sessions, SessionGroups, CheckEyes); % P x SB

    % burst
    [RTs(:, :, Indx_B, 2), ~] = tabulateTable(Trials, EO & Trials.(BandLabels{Indx_B})==1, ...
        'RT', 'mean', Participants, Sessions, SessionGroups, CheckEyes); % P x SB
end

save(fullfile(Pool, 'Burst_RTs.mat'), 'RTs')



%%
PlotProps = P.Manuscript;
StatsP = P.StatsP;
SB_Indx = 2;
figure

for Indx_B = 1:numel(BandLabels)

    Data = squeeze(RTs(:, SB_Indx, Indx_B, :));

subplot(1, 2, Indx_B)
data2D('line', Data, {'No Burst', 'Burst'}, [], [], PlotProps.Color.Participants, StatsP, PlotProps)

end

