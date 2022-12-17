% Script to get pupillometry data synchronized to the EEG
clear
clc
close all

Info = blinkParameters();


Paths = Info.Paths;
Refresh = false;
Triggers = Info.Triggers;

Task = 'LAT';
fs = 250;


Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_Eyes = fullfile(Paths.Preprocessed, 'Pupils', Task);
Destination_Eyes = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);
if ~exist(Destination_Eyes, 'dir')
    mkdir(Destination_Eyes);
end


Content = getContent(Source_EEG);

DataQaulity_Filepath = fullfile(Paths.Core, 'QualityCheck', 'Theta Bursts', 'DataQuality_Pupils.csv');
DataQuality_Table = readtable(DataQaulity_Filepath);

% for Indx_F = 1:numel(Content)
parfor Indx_F = 1:numel(Content)
    
    T = Triggers;
    DQ = DataQuality_Table;

    Filename_EEG = Content{Indx_F};
    Filename_Eyes = replace(Filename_EEG, 'Clean.mat', 'Pupils.mat');
    if exist(fullfile(Destination_Eyes, Filename_Eyes), 'file') && ~Refresh
        disp(['Skipping ', Filename_Eyes])
        continue
    else
        disp(['Loading ', Filename_Eyes])
    end

    M = load(fullfile(Source_EEG, Filename_EEG), 'EEG');
    EEG = M.EEG;
    nPnts = size(EEG.data, 2);

    EyePath = fullfile(Source_Eyes, Filename_Eyes);
    Levels = split(Filename_Eyes, '_');
    DQ_P = DQ.(Levels{3})(strcmp(DQ.Participant, Levels{1}));
    Eyes = struct();
    if exist(EyePath, 'file') && DQ_P >= 0.5
        try
        Eyes = syncEEG_Eyes(EEG, EyePath, T.SyncEyes);
        catch
            continue
        end
    else
        Eyes.Raw = nan(2, nPnts);
        Eyes.EO = nan(1, nPnts);
        Eyes.Microsleeps = nan(1, nPnts);
    end
     Eyes.DQ = DQ_P;

    parsave(fullfile(Destination_Eyes, Filename_Eyes), Eyes)
end


function parsave(Path, Eyes)
save(Path, 'Eyes')
end


