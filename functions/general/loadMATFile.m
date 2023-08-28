function DataOut = loadMATFile(Path, Participant, Session, Variable)
% loads a mat file, returns something empty if nothing is there

% get filename
Filenames = list_filenames(Path);
Filename = Filenames(contains(Filenames, Participant) & ...
    contains(Filenames, Session));

if isempty(Filename)
    warning(['No data in ', Participant, '_' Session])
    DataOut = [];
    return
end

% load data
Data = load(fullfile(Path, Filename), Variable);

DataOut = Data.(Variable);