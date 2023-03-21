% loads in filtered data, finds the bursts in each channel, removes the
% overlapping ones.
% for Lapse-Causes

clear
clc
close all

Info = peakParameters();
Paths = Info.Paths;

Band = [5 9];
BandLabel = '5_9';
Task = 'LAT';
Refresh = true;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get peaks

% folder locations
Source = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task); % normal data
Source_Filtered = fullfile(Paths.Preprocessed, 'Clean', 'Waves_Filtered', Task, 'HP2_5'); % extremely filtered data
Source_Cuts = fullfile(Paths.Preprocessed, 'Cutting', 'Cuts', Task); % timepoints marked as artefacts
Destination = fullfile(Paths.Data, 'EEG', 'Peaks_AllChannels', BandLabel, Task);

if ~exist(Destination, 'dir')
    mkdir(Destination)
end

Content = getContent(Source);
parfor Indx_F = 1:numel(Content)

    % load data
    Filename_Source = Content{Indx_F};
    Filename_Filtered = replace(Filename_Source, 'Clean.mat', 'Filtered.mat');
    Filename_Destination = replace(Filename_Source, 'Clean.mat', 'Peaks.mat');
    Filename_Cuts = replace(Filename_Source, 'Clean.mat', 'Cuts.mat');

    if exist(fullfile(Destination, Filename_Destination), 'file') && ~Refresh
        disp(['Skipping ', Filename_Destination])
        continue
    elseif contains(Filename_Source, 'P00')
        continue
    else
        disp(['Loading ', Filename_Source])
    end

    M = load(fullfile(Source, Filename_Source), 'EEG');
    EEG = M.EEG;
    fs = EEG.srate;

    % get timepoints without noise
    if exist(fullfile(Source_Cuts, Filename_Cuts), 'file')
        NoiseEEG = nanNoise(EEG, fullfile(Source_Cuts, Filename_Cuts));
        Keep_Points = ~isnan(NoiseEEG.data(1, :));
    else
        Keep_Points = ones(1, EEG.pnts);
    end

    % need to concatenate structures
    F = load(fullfile(Source_Filtered, Filename_Filtered));
    FiltEEG= F.FiltEEG;

    % detect negative peaks
    Peaks = getHungPeaks(FiltEEG, Band, Keep_Points);


    % keep track of how much data is being used
    EEG = FiltEEG;
    EEG.keep_points = Keep_Points;
    EEG.clean_t = nnz(Keep_Points);
    EEG.band = Band;

    EEG.data = []; % only save the extra ICA information

    % save structures
    parsave(Destination, Filename_Destination, Peaks, EEG)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function parsave(Destination, Filename_Destination, AllPeaks, EEG)
save(fullfile(Destination, Filename_Destination), "AllPeaks", "EEG")
end

