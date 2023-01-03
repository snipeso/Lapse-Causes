% from the raw files, finds the most recent iteration, load in data
clear
clc
close all

Info = blinkParameters();

Raw = 'D:\LSM\Data\Raw\';
Task = 'LAT';
Destination = fullfile('D:\LSM\Data\Preprocessed\Pupils\', Task);
Refresh = false;

Destination_Format = 'Pupils';
% Folders where raw data is located
Template = 'PXX';
Ignore = {'CSVs', 'other', 'Lazy', 'P00', 'Applicants', 'Uncertain'};

[Subfolders, Datasets] = AllFolderPaths(Raw, ...
    Template, false, Ignore);

if ~exist(Destination, 'dir')
    mkdir(Destination)
end

Subfolders(~contains(Subfolders, 'EyeTracking')) = [];
Subfolders(~contains(Subfolders, Task)) = [];

for Indx_D = 1:size(Datasets,1) % loop through participants
    for Indx_F = 1:size(Subfolders, 1) % loop through all subfolders

        Path = fullfile(Raw, deblank(Datasets{Indx_D}), Subfolders{Indx_F}, 'exports');

        if ~exist(Path, 'dir')
            warning(['missing ', Path])
            continue
        end


        % identify meaningful folders traversed
        Levels = split(Subfolders{Indx_F}, '\');
        Levels(cellfun('isempty',Levels)) = []; % remove blanks
        Levels(strcmpi(Levels, 'EyeTracking')) = []; % remove uninformative level that its an EEG

        Filename = join([deblank(Datasets{Indx_D}), Levels(:)', [Destination_Format, '.mat']], '_');

        if ~Refresh && exist(fullfile(Destination, Filename{1}), 'file')
            disp(['Already did ' Filename{1}])
            continue
        end

        % find the most recent export
        Exports = deblank(string(ls(Path)));
        Exports(contains(Exports, '.')) = []; % exclude files
        Exports(strcmp(Exports(:, 1), '0')) = []; % only folders that are numbered

        Path = fullfile(Path, Exports(end));
        Files = getContent(Path);
        if ~any(contains(Files, 'pupil_positions')) || ~any(contains(Files, 'annotations'))
            warning(['missing content in ', char(Path)])
            continue
        end

        % load pupil data
        Pupil = readtable(fullfile(Path, 'pupil_positions.csv'));

        % load trigger data
        Annotations = readtable(fullfile(Path, 'annotations.csv'));


        %%% save
        save(fullfile(Destination, Filename{1}), 'Pupil', 'Annotations')
        disp(['Finished ', char(Path)])
    end
end