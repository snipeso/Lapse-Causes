% This script conducts a time-frequency analysis across the entire EEG
% recording. The next script will then epoch the data. A special thanks to
% Sven Leach and Maria Dimitriades for the script for the wavelet
% transformation.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load in and set parameters for analysis
RerunAnalysis = true; % false to skip files already analyzed

% load in parameters that are in common across scripts
Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Sessions = Parameters.Sessions.(Task);
Participants = Parameters.Participants;
Triggers = Parameters.Triggers;

Frequencies = 1:35;
CycleRange = [3, 15]; % chosen without thinking too hard about it. Sue me.


% set paths and files
EEGSource = fullfile(Paths.CleanEEG, Task);
EEGSourceCuts = fullfile(Paths.Data, 'Cutting', 'Cuts', Task); % timepoints marked as artefacts
Destination = fullfile(Paths.AnalyzedData, 'EEG', 'TimeFrequency_Broad', Task);
if ~exist(Destination, 'dir')
    mkdir(Destination)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Analysis

Filenames = list_filenames(EEGSource);
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
    CleanTimepoints = identify_clean_timepoints(fullfile(EEGSourceCuts, FilenameCuts), EEG);

    % get timepoints of the task
    TaskPoints = identify_task_timepoints(EEG, Triggers);

    % only use clean task timepoints
    KeepTimepoints = CleanTimepoints & TaskPoints;
    
    % run wavelets
    [Power, ~, ~] = time_frequency(EEG.data, EEG.srate, Frequencies, CycleRange(1), CycleRange(2));

    % nan noise
    Power(:, :, ~KeepTimepoints) = nan;

    % keep track of how much data is being used
    EEGMetadata = EEG;
    EEGMetadata.data = [];
    EEGMetadata.pnts = size(EEG.data, 2); % just making sure its correct
    EEGMetadata.CleanTaskTimepoints = KeepTimepoints;
    EEGMetadata.CleanTaskTimepointsCount = nnz(KeepTimepoints);
    EEGMetadata.data = []; % only save the metadata

    % save
    save(fullfile(Destination, FilenameDestination), 'Power', 'Frequencies', 'EEGMetadata', '-v7.3')
    disp(['Finished ', FilenameSource])
end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function CleanTimepoints = identify_clean_timepoints(CutsPath, EEG)
TimepointsCount = size(EEG.data, 2);

if exist(CutsPath, 'file')
    NoiseEEG = remove_noise(EEG, CutsPath);
    CleanTimepoints = ~isnan(NoiseEEG.data(1, :));
else
    warning(['no cuts filepath ' CutsPath])
    CleanTimepoints = ones(1, TimepointsCount);
end
end