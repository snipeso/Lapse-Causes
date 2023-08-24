clear
clc
close all

Parameters = burstParameters();
Paths = Parameters.Paths;
Sessions = Parameters.Sessions;
Participants = Parameters.Participants;
Bands = Parameters.Bands;
CriteriaSets = Parameters.CriteriaSets;

RunParallelBurstDetection = true;
RerunAnalysis = false;
Task = 'LAT';
MinClusteringFrequencyRange = 1; % to cluster bursts across channels

EEGSource = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
EEGSourceCuts = fullfile(Paths.Preprocessed, 'Cutting', 'Cuts', Task); % timepoints marked as artefacts
Destination = fullfile(Paths.Data, 'EEG', 'Bursts_New', Task);
if ~exist(Destination, 'dir')
    mkdir(Destination)
end

Filenames = getContent(EEGSource);
Filenames(~contains(Filenames, Sessions)) = [];
Filenames(~contains(Filenames, Participants)) = [];

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
        NoiseEEG = nanNoise(EEG, fullfile(EEGSourceCuts, FilenameCuts));
        KeepTimepoints = ~isnan(NoiseEEG.data(1, :));
    else
        KeepTimepoints = ones(1, EEG.pnts);
    end

    % filter data into narrowbands
    EEGNarrowbands = cycy.filter_eeg_narrowbands(EEG, Bands);

    % apply burst detection
    Bursts = cycy.detect_bursts_all_channels(EEG, EEGNarrowbands, Bands, ...
        CriteriaSets, RunParallelBurstDetection, KeepTimepoints);

    % keep track of how much data is being used
    EEG.CleanTimepoints = KeepTimepoints;
    EEG.CleanTimepointsCount = nnz(KeepTimepoints);
    EEG.data = []; % only save the metadata

     % get vector of points from which the burst data was pooled (task,
    % clean)
    TaskPoints = zeros(1, numel(KeepTimepoints));
    TriggerTypes = {EEG.event.type};
    TriggerLatencies = [EEG.event.latency];
    StartTask = round(TriggerLatencies(strcmp(TriggerTypes, Triggers.Start)));
    EndTask = round(TriggerLatencies(strcmp(TriggerTypes, Triggers.End)));
    TaskPoints(StartTask:EndTask) = 1;
    TaskPoints = TaskPoints & EEG.CleanTimepoints; % both when task starts and stops, and when data is clean
    EEG.TaskPoints = TaskPoints;

    % aggregate bursts into clusters across channels
    BurstClusters = cycy.aggregate_bursts_into_clusters(Bursts, EEG, MinClusteringFrequencyRange);

    % save
    save(fullfile(Destination, FilenameDestination), 'Bursts', 'BurstClusters', 'EEG')
    disp(['Finished ', FilenameSource])
end
