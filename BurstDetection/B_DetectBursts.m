% loads in filtered data, finds the bursts in each channel, removes the
% overlapping ones.
% for Lapse-Causes

clear
clc
close all

Info = burstParameters();

Paths = Info.Paths;
Bands = Info.Bands;
BandLabels = fieldnames(Bands);

Task = 'LAT';
Refresh = true;

% Parameters for bursts
BT = Info.CriteriaSets;
Min_Peaks = [];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get bursts


% folder locations
Source = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task); % normal data
Source_Filtered = fullfile(Paths.Preprocessed, 'Clean', 'Waves_Filtered', Task); % extremely filtered data
Source_Cuts = fullfile(Paths.Preprocessed, 'Cutting', 'Cuts', Task); % timepoints marked as artefacts
Destination = fullfile(Paths.Data, 'EEG', 'Bursts_AllChannels', Task);

if ~exist(Destination, 'dir')
    mkdir(Destination)
end

Content = getContent(Source);
for Indx_F = 103%1:numel(Content)

    % load data
    Filename_Source = Content{Indx_F};
    Filename_Filtered = replace(Filename_Source, 'Clean.mat', 'Filtered.mat');
    Filename_Destination = replace(Filename_Source, 'Clean.mat', 'Bursts.mat');
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
        NoiseEEG = remove_noise(EEG, fullfile(Source_Cuts, Filename_Cuts));
        Keep_Points = ~isnan(NoiseEEG.data(1, :));
    else
        Keep_Points = ones(1, EEG.pnts);
    end


    % need to concatenate structures
    FiltEEG = EEG;
    FiltEEG.Band = [];

    for Indx_B = 1:numel(BandLabels) % get bursts for all provided bands

        % load in filtered data
        Band = Bands.(BandLabels{Indx_B});
        F = load(fullfile(Source_Filtered, BandLabels{Indx_B}, Filename_Filtered));
        FiltEEG(Indx_B) = F.FiltEEG;
    end

    % get bursts in all data
    AllBursts = getAllBursts(EEG, FiltEEG, BT, Min_Peaks, Bands, Keep_Points);

    % keep track of how much data is being used
    EEG.keep_points = Keep_Points;
    EEG.clean_t = nnz(Keep_Points);

    EEG.data = []; % only save the extra ICA information

    % save structures
    parsave(Destination, Filename_Destination, AllBursts, EEG)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function parsave(Destination, Filename_Destination, AllBursts, EEG)
save(fullfile(Destination, Filename_Destination), "AllBursts", "EEG")
end

