function [EEGAllSessions, BurstsAllSessions] = load_sessionblock_data( ...
    Source_Bursts, Source_EEG, Participant, Sessions, BurstVariable)
% load EEG and/or bursts data from multiple sessions together
% TODO extend also for pupil data?
% BurstVariable should be either 'Bursts' or 'BurstClusters'

EEGAllSessions = struct();
BurstsAllSessions = struct();

for Session = Sessions
    if ~isempty(Source_Bursts)
        % load bursts
        Bursts = load_datafile(Source_Bursts, Participant{1}, Session, BurstVariable);
        if isempty(Bursts); continue; end

        % load EEG metadata
        Metadata = load_datafile(Source_Bursts, Participant{1}, Session, 'EEG'); % TODO, when rerun, call EEGMetadata
        ValidTime = Metadata.CleanTaskTimepoints;
    else
        ValidTime = 1; % placeholder so nothing gets naned later
    end

    if ~isempty(Source_EEG)
        % load in EEG data
        EEG = load_datafile(Source_EEG, Participant{1}, Session, 'EEG');
        if isempty(EEG); continue; end

        % remove artefact timepoints
        EEG.data(:, ~ValidTime) = nan;
    else
        EEG = [];
    end

    EEGAllSessions.(Session) = EEG;
    BurstsAllSessions.(Session) = Bursts;
end