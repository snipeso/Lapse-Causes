% from the raw files, finds the most recent iteration, load in data
clear
clc
close all

Info = blinkParameters();

Raw = 'G:\LSM\Data\Raw';
Task = 'LAT';
Destination = fullfile('E:\Data\Preprocessed\Pupils\', Task);
Refresh = false;

Destination_Format = 'Pupils';
% Folders where raw data is located
Template = 'PXX';
Ignore = {'CSVs', 'other', 'Lazy', 'P00', 'Applicants'};

[Subfolders, Datasets] = AllFolderPaths(Raw, ...
    Template, false, Ignore);


for Indx_D = 1:size(Datasets,1) % loop through participants
    for Indx_F = 1:size(Folders.Subfolders, 1) % loop through all subfolders

         Path = fullfile(Raw, deblank(Datasets{Indx_D}), Subfolders{Indx_F}, 'exports');
        Filename = join([deblank(Datasets{Indx_D}), Levels(:)', [Destination_Format, '.mat']], '_');

        if ~Refresh && exist(fullfile(Destination, Filename), 'file')
            disp(['Already did ' Filename])
            continue
        end

        % identify meaningful folders traversed
        Levels = split(Subfolders{Indx_F}, '\');
        Levels(cellfun('isempty',Levels)) = []; % remove blanks
        Levels(strcmpi(Levels, 'EyeTracking')) = []; % remove uninformative level that its an EEG

        % find the most recent export
        Exports = deblank(string(ls(Path)));
        Exports(contains(Exports, '.')) = []; % exclude files
        Exports(strcmp(Exports(:, 1), '0')) = []; % only folders that are numbered

        % load pupil data
        Pupil = readtable(fullfile(Path, Exports(end), 'pupil_positions.csv'));

        % load trigger data
        Annotations = readtable(fullfile(Path, Exports(end), 'annotations.csv'));


        %%% save
        save(fullfile(Destination, Filename), 'Pupil', 'Annotations')
    end
end