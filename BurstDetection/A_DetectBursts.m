clear
clc
close all

Parameters = burstParameters();
Paths = Parameters.Paths;
Sessions = Parameters.Sessions;
Participants = Parameters.Participants;
Bands = Parameters.Bands;
CriteriaSets = Parameters.CriteriaSets;

RunParallel = true;
Task = 'LAT';
MinFrequencyRange = 1; % to cluster bursts across channels

Source = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_Cuts = fullfile(Paths.Preprocessed, 'Cutting', 'Cuts', Task); % timepoints marked as artefacts
Destination = fullfile(Paths.Data, 'EEG', 'Bursts_New', Task);
if ~exist(Destination, 'dir')
    mkdir(Destination)
end

Filenames = getContent(Source);
Filenames(~contains(Filenames, Sessions)) = [];
Filenames(~contains(Filenames, Participants)) = [];

for Filename_Source = Filenames'
    % load data
    Filename_Destination = replace(Filename_Source, '_Clean.mat', '.mat');
    Filename_Cuts =  replace(Filename_Source, '_Clean.mat', '_Cuts.mat');

    if exist(fullfile(Destination, Filename_Destination), 'file') && ~Refresh
        disp(['Skipping ', Filename_Destination])
        continue
    else
        disp(['Loading ', Filename_Source])
    end

    load(fullfile(Source, Filename_Source), 'EEG')
    SampleRate = EEG.srate;

    % get timepoints without noise
    if exist(fullfile(Source_Cuts, Filename_Cuts), 'file')
        NoiseEEG = nanNoise(EEG, fullfile(Source_Cuts, Filename_Cuts));
        KeepTimepoints = ~isnan(NoiseEEG.data(1, :));
    else
        KeepTimepoints = ones(1, EEG.pnts);
    end


    % filter data into narrowbands
    EEGNarrowbands = cycy.filter_eeg_narrowbands(EEG, Bands);


    % apply burst detection
    Bursts = cycy.detect_bursts_all_channels(EEG, EEGNarrowbands, Bands, ...
        CriteriaSets, RunParallel, KeepTimepoints);

    % keep track of how much data is being used
    EEG.keep_points = KeepTimepoints;
    EEG.clean_t = nnz(KeepTimepoints);
    EEG.data = []; % only save the metadata


    BurstClusters = cycy.aggregate_bursts_into_clusters(Bursts, EEG, MinFrequencyRange);


    % save
    save(fullfile(Destination, Filename_Destination), 'Bursts', 'BurstClusters', 'EEG')
disp(['Finished ', Filename_Source])

end
