function [EEGAllSessions, BurstsAllSessions] = load_sessionblock_data( ...
    SourceBursts, SourceEEG, Participant, Sessions, BurstVariable)
% load EEG and/or bursts data from multiple sessions together
% TODO extend also for pupil data?
% BurstVariable should be either 'Bursts' or 'BurstClusters'

EEGAllSessions = struct();
BurstsAllSessions = struct();

for Session = Sessions
    EEGAllSessions.(Session{1}) = []; % placeholder in case skipped
     BurstsAllSessions.(Session{1}) = []; 
    if ~isempty(SourceBursts)
        % load bursts
        Bursts = load_datafile(SourceBursts, Participant, Session{1}, BurstVariable);
        if isempty(Bursts); continue; end

        % load EEG metadata
        Metadata = load_datafile(SourceBursts, Participant, Session, 'EEGMetadata');
        ValidTime = Metadata.CleanTaskTimepoints;
    else
        ValidTime = 1; % placeholder so nothing gets naned later
    end

    if ~isempty(SourceEEG)
        % load in EEG data
        EEG = load_datafile(SourceEEG, Participant, Session, 'EEG');
        if isempty(EEG); continue; end

        % remove artefact timepoints
        EEG.data(:, ~ValidTime) = nan;
    else
        EEG = [];
    end

    EEGAllSessions.(Session{1}) = EEG;
    BurstsAllSessions.(Session{1}) = Bursts;
end