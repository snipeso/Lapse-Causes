% Gather a table of all the trials

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();
Participants = P.Participants;
Paths = P.Paths;
Triggers = P.Triggers;
SampleRate = P.SampleRate;
TrialInfo = P.Trials;
Labels = P.Labels;

% Trial parameters
Windows = TrialInfo.SubWindows(1:3); % window in which to see if there is an event or not
WindowColumns = Labels.TrialSubWindows(1:3);
MinWindow = TrialInfo.MinEventProportion; % minimum proportion of window needed to have event to count


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load trials

% locations
Cache = fullfile(Paths.PooledData); % place to save matrices so they can be plotted in next script
if ~exist(Cache, 'dir')
    mkdir(Cache)
end

for Task = {'LAT', 'PVT'}

    EyetrackingFolder = fullfile(Paths.Data, ['Pupils_', num2str(SampleRate)], Task);
    BurstsFolder = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

    EyetrackingDataQualityPath = fullfile(Paths.Core, 'QualityCheck', 'Eyetracking', ...
        ['DataQuality_', Task, '_Pupils.csv']); % file indicating manually identified eye
    DataQualityTable = readtable(EyetrackingDataQualityPath);

    if strcmp(Task, 'PVT')
        Sessions = P.Sessions_PVT;
        BurstsFolder = EyetrackingFolder; % because I don't have burst path
    else
        Sessions = P.Sessions;
    end
    Sessions = Sessions.(Task);

    %%% get trial information
    Trials = loadBehavior(Participants, Sessions, Task, Paths, false);

    % get time of stim and response trigger
    Trials = getTrialLatencies(Trials, BurstsFolder, Triggers);

    % get eyes-closed info
    Trials = getECtrials(Trials, EyetrackingFolder, DataQualityTable, SampleRate, Windows, MinWindow, WindowColumns);

    % get burst info (have not calculated for PVT)
    if strcmp(Task, 'LAT')
        Trials = getBurstTrials(Trials, BurstsFolder, Bands, SampleRate, Windows, MinWindow, WindowColumns);

        Trials.isRight = double(Trials.isRight);
    end

    save(fullfile(Cache, [Task, '_AllTrials.mat']), 'Trials')
end

disp('Done!')