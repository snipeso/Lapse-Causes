% Script to get pupillometry data synchronized to the EEG
clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Info = blinkParameters();

Paths = Info.Paths;
Refresh = true;
Triggers = Info.Triggers;

Task = 'LAT';
fs = 250;

%%% paths
% Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_EEG = fullfile(Paths.Preprocessed, 'Power', 'SET', Task);
Source_Eyes = fullfile(Paths.Preprocessed, 'Pupils', Task);
Destination_Eyes = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);
if ~exist(Destination_Eyes, 'dir')
    mkdir(Destination_Eyes);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Sync EEG

Content = getContent(Source_EEG);

% get data quality table to know which eye to use
DataQaulity_Filepath = fullfile(Paths.Core, 'QualityCheck', 'Theta Bursts', 'DataQuality_Pupils.csv'); % file indicating manually identified eye
DataQuality_Table = readtable(DataQaulity_Filepath);

% for Indx_F = 1:numel(Content) % DEBUG
parfor Indx_F = 1:numel(Content)

    T = Triggers; % stupid parfor thing
    DQ = DataQuality_Table;

    %%% load data

    Filename_EEG = Content{Indx_F};
    Filename_Eyes = replace(Filename_EEG, 'Clean.mat', 'Pupils.mat');

    if exist(fullfile(Destination_Eyes, Filename_Eyes), 'file') && ~Refresh
        disp(['Skipping ', Filename_Eyes])
        continue
    else
        disp(['Loading ', Filename_Eyes])
    end

    Levels = split(Filename_Eyes, '_');

    % EEG data
    M = load(fullfile(Source_EEG, Filename_EEG), 'EEG');
    EEG = M.EEG;
    nPnts = size(EEG.data, 2);

    % eye tracking data
    EyePath = fullfile(Source_Eyes, Filename_Eyes);
    DQ_P = DQ.(Levels{3})(strcmp(DQ.Participant, Levels{1}));

    if exist(EyePath, 'file') && DQ_P >= 0.5
        Eyes = syncEEG_Eyes(EEG, EyePath, T.SyncEyes);
    else
        % blanks in case there's no data
        Eyes.Raw = nan(2, nPnts);
        Eyes.EO = nan(1, nPnts);
        Eyes.Microsleeps = nan(1, nPnts);
    end

    Eyes.DQ = DQ_P;

    EEG.data = []; % save EEG metadata
    parsave(fullfile(Destination_Eyes, Filename_Eyes), Eyes, EEG)
end


function parsave(Path, Eyes, EEG)
save(Path, 'Eyes', 'EEG')
end


