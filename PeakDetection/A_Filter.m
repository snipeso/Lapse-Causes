% Rereferences to mastoids, filters data above 2.5 Hz

clear
clc
close all

Info = peakParameters();
Paths = Info.Paths;
Task = 'LAT';
Refresh = false;

HP = 2.5; % high-pass filter (Hz)
Mastoids = [57 100]; % channels to re-reference

Source = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Destination = fullfile(Paths.Preprocessed, 'Clean', 'Waves_Filtered', Task, 'HP2_5');

if ~exist(Destination, 'dir')
    mkdir(Destination)
end

% loop through all files
Content = getContent(Source);
for Indx_F = 1:numel(Content)

    Filename_Source = Content{Indx_F};

    Filename_Destination = replace(Filename_Source, 'Clean.mat', 'Filtered.mat');

    if exist(fullfile(Destination, Filename_Destination), 'file') && ~Refresh
        disp(['Skipping ', Filename_Source])
        continue
    end

    m = load(fullfile(Source, Filename_Source), 'EEG');
    EEG = m.EEG;

    fs = EEG.srate;

    FiltEEG = EEG;

    % rereference
    FiltEEG = pop_reref(FiltEEG, labels2indexes(Mastoids, EEG.chanlocs));

    % filter
    FiltEEG.data = hpfilt(FiltEEG.data, fs, HP);
    FiltEEG.Band = HP;

    % save
    save(fullfile(Destination, Filename_Destination), 'FiltEEG', '-v7.3')
    disp(['Finished ', Filename_Destination])
end

