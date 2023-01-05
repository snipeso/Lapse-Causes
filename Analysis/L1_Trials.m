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
Refresh = true; % going through eeg and eye data is slow

Pool = fullfile(Paths.Pool, 'Tasks'); % place to save matrices so they can be plotted in next script

Window = [0 .5]; % window in which to see if there is an event or not
MinWindow = 1/3; % minimum proportion of window needed to have event to count

% locations
MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);
BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load trials

if Refresh || ~exist(fullfile(Pool, 'AllTrials.mat'), 'file')
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

else
    load(fullfile(Pool, 'AllTrials.mat'), 'Trials')
end



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

