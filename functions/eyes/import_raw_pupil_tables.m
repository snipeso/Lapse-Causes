function import_raw_pupil_tables(RawPupilDir, DestinationDir, Task, RerunAnalysis)
% from the output produced by PupilPlayer, saved in the LSM data structure,
% this goes folder by folder, snd resaves the content into a mat file in
% the destination folder of choice.

% loop through entire dataset to find relevant pupil folders
TemplateDir = 'PXX';
IgnoreDir = {'CSVs', 'other', 'Lazy', 'P00', 'Applicants', 'Uncertain'};

[SubDir, Participants] = raw_data_paths(RawPupilDir, TemplateDir, false, IgnoreDir);
SubDir(~contains(SubDir, 'EyeTracking')) = [];
SubDir(~contains(SubDir, Task)) = [];


if isempty(Participants) || strcmp(Participants, "")
    warning('Couldnt find raw data')
    return
end

if ~exist(DestinationDir, 'dir')
    mkdir(DestinationDir)
end

for Participant = Participants % loop through participants
    for Dir = SubDir % loop through all subfolders
        Path = fullfile(RawPupilDir, deblank(Participant{1}), Dir{1}, 'exports');

        if ~exist(Path, 'dir')
            warning(['missing ', Path])
            continue
        end

        Filename = assemble_filename(Dir{1}, Participant{1});

        % check if already imported
        if ~RerunAnalysis && exist(fullfile(DestinationDir, Filename), 'file')
            disp(['Already did ' Filename])
            continue
        end

        % get raw filenames
        Path = most_recent_pupil_path(Path);
        Files = list_filenames(Path);
        if ~any(contains(Files, 'pupil_positions')) || ~any(contains(Files, 'annotations'))
            warning(['missing content in ', char(Path)])
            continue
        end

        % load pupil data
        Pupil = readtable(fullfile(Path, 'pupil_positions.csv'));

        % load trigger data
        Annotations = readtable(fullfile(Path, 'annotations.csv'));

        %%% save
        save(fullfile(DestinationDir, Filename), 'Pupil', 'Annotations')
        disp(['Finished ', char(Path)])
    end
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function Filename = assemble_filename(SubDir, Participant)
% identify meaningful folders traversed

Metadata = split(SubDir, '\'); % the location of the file indicates the task, session, etc
Metadata(cellfun('isempty',Metadata)) = []; % remove blanks
Metadata(strcmpi(Metadata, 'EyeTracking')) = []; % remove uninformative level that its an EEG

Filename = [strjoin([deblank(Participant), Metadata(:)'], '_'), '.mat'];
Filename = Filename{1};
end


function Path = most_recent_pupil_path(Path)
% pupil player creates numerically ascending folders every time you
% re-export the pupil data from their gui. This takes the latest one.
Exports = deblank(string(ls(Path)));
Exports(contains(Exports, '.')) = []; % exclude files
Exports(strcmp(Exports(:, 1), '0')) = []; % only folders that are numbered

Path = fullfile(Path, Exports(end));
end