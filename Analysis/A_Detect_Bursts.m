% Detects bursts in EEG data, saves them.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load in and set parameters for analysis

% set parameters for how you want to run the script this time
RunParallelBurstDetection = true; % true for faster processing
RerunAnalysis = false; % false to skip files already analyzed

%%% criteria to find bursts in single channels
% irregular shaped bursts, few criteria, but needs more cycles
Idx = 1; % this is to make it easier to skip some
CriteriaSets = struct();
CriteriaSets(Idx).PeriodConsistency = .6;
CriteriaSets(Idx).MonotonicityInAmplitude = .6;
CriteriaSets(Idx).FlankConsistency = .6;
CriteriaSets(Idx).AmplitudeConsistency = .6;
CriteriaSets(Idx).MinCyclesPerBurst = 5;
% % without periodneg, to capture bursts that accelerate/decelerate

% short bursts, strict monotonicity requirements
Idx = Idx+1;
CriteriaSets(Idx).PeriodConsistency = .7;
CriteriaSets(Idx).MonotonicityInAmplitude = .9;
CriteriaSets(Idx).PeriodNeg = true;
CriteriaSets(Idx).FlankConsistency = 0.3;
CriteriaSets(Idx).MinCyclesPerBurst = 3;

% relies on shape but low other criteria; gets most of the bursts
Idx = Idx+1;
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

MinClusteringFrequencyRange = 1; % to cluster bursts across channels


% load in parameters that are in common across scripts
Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Sessions = Parameters.Sessions.(Task);
Participants = Parameters.Participants;
Bands = Parameters.Bands;
Triggers = Parameters.Triggers;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Analysis

% set paths and files
EEGSource = fullfile(Paths.Data, 'Clean', 'Waves', Task);
EEGSourceCuts = fullfile(Paths.Data, 'Cutting', 'Cuts', Task); % timepoints marked as artefacts
Destination = fullfile(Paths.Data, 'EEG', 'Bursts_New', Task);
if ~exist(Destination, 'dir')
    mkdir(Destination)
end

Filenames = getContent(EEGSource);
Filenames(~contains(Filenames, Sessions)) = [];
Filenames(~contains(Filenames, Participants)) = [];


%%% run

for FilenameSource = Filenames'

    % load data
    FilenameDestination = replace(FilenameSource, '_Clean.mat', '.mat');
    FilenameCuts =  replace(FilenameSource, '_Clean.mat', '_Cuts.mat');

    if exist(fullfile(Destination, FilenameDestination), 'file') && ~RerunAnalysis
        disp(['Skipping ', FilenameDestination])
        continue
    else
        disp(['Loading ', FilenameSource])
    end

    load(fullfile(EEGSource, FilenameSource), 'EEG')
    SampleRate = EEG.srate;

    % get timepoints without noise
    if exist(fullfile(EEGSourceCuts, FilenameCuts), 'file')
        NoiseEEG = remove_noise(EEG, fullfile(EEGSourceCuts, FilenameCuts));
        CleanTimepoints = ~isnan(NoiseEEG.data(1, :));
    else
        CleanTimepoints = ones(1, EEG.pnts);
    end

    % get timepoints of the task
    TaskPoints = zeros(1, numel(CleanTimepoints));
    TriggerTypes = {EEG.event.type};
    TriggerLatencies = [EEG.event.latency];
    StartTask = round(TriggerLatencies(strcmp(TriggerTypes, Triggers.Start)));
    EndTask = round(TriggerLatencies(strcmp(TriggerTypes, Triggers.End)));
    TaskPoints(StartTask:EndTask) = 1;

    % only use clean task timepoints
    KeepTimepoints = CleanTimepoints & TaskPoints;

    % filter data into narrowbands
    EEGNarrowbands = cycy.filter_eeg_narrowbands(EEG, Bands);

    % apply burst detection
    Bursts = cycy.detect_bursts_all_channels(EEG, EEGNarrowbands, Bands, ...
        CriteriaSets, RunParallelBurstDetection, KeepTimepoints);

    % aggregate bursts into clusters across channels
    BurstClusters = cycy.aggregate_bursts_into_clusters(Bursts, EEG, MinClusteringFrequencyRange);

    % keep track of how much data is being used
    EEG.CleanTaskTimepoints = KeepTimepoints;
    EEG.CleanTaskTimepointsCount = nnz(KeepTimepoints);
    EEG.data = []; % only save the metadata

    % save
    save(fullfile(Destination, FilenameDestination), 'Bursts', 'BurstClusters', 'EEG')
    disp(['Finished ', FilenameSource])
end
