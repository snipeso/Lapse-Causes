% Using eyetracking data, identify when participants had eyes open or
% closed.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load in and set parameters for analysis

Tasks = {'PVT', 'LAT'};
RerunAnalysis = false;
PupilDetectionMethodType = '2d c++'; % either 2D or 3D; 3D is not as good

Parameters = analysisParameters();
Paths = Parameters.Paths;
Participants = Parameters.Participants;
SampleRate = Parameters.SampleRate; % established here, so that it's consistent across scripts
Triggers = Parameters.Triggers;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run analysis

for Task = Tasks

    % assemble locations
    PupilTablesDir = fullfile(Paths.Data, 'Pupils', 'Raw', Task{1});
    PupilsDir = fullfile(Paths.Data, 'Pupils', ['Raw_', num2str(SampleRate), 'Hz'], Task{1});

    if ~exist(PupilsDir, 'dir')
        mkdir(PupilsDir)
    end

    EEGDir = fullfile(Paths.CleanEEG, Task{1}); % so that it can be synchronized
    Sessions = Parameters.Sessions.(Task{1});

    % convert raw pupil data, get Pupil and Annotations; saves to disk
    import_raw_pupil_tables(Paths.RawData, PupilTablesDir, Task{1}, RerunAnalysis)

    for Participant = Participants
        for Session = Sessions

            % load in data
            EEG = load_datafile(EEGDir, Participant{1}, Session{1}, 'EEG');
            if isempty(EEG); continue; end
            Pupil = load_datafile(PupilTablesDir, Participant{1}, Session{1}, 'Pupil');
            if isempty(Pupil); continue; end
            Annotations = load_datafile(PupilTablesDir, Participant{1}, Session{1}, 'Annotations');
            if isempty(Annotations); continue; end

            check_trigger_annotations_match(EEG, Annotations);

            % select only one method type
            Pupil = Pupil(strcmp(Pupil.method, PupilDetectionMethodType), :);

            EEG = adjust_triggers_PVT(Task{1}, EEG, Triggers);
            [Eyes, ~] = sync_eyes(EEG, Triggers.SyncEyes, Pupil, 'confidence', Annotations);

            % save
            EEGMetadata = EEG;
            EEGMetadata.data = [];
            FilenamePupils = [strjoin({Participant{1}, Task{1}, Session{1}}, '_'), '.mat'];
            save(fullfile(PupilsDir, FilenamePupils), 'Eyes', 'EEGMetadata')
        end
        disp(['Finished ', Participant{1}])
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions


function check_trigger_annotations_match(EEG, Annotations)
% check that there's the same number of stimuli triggers in both EEG and
% annotations file

TriggerTypes = {EEG.event.type};
TriggerTimes = [EEG.event.latency];

if nnz(strcmp(TriggerTypes, {'S  3'})) ~= nnz(strcmp(Annotations.label, 'Stim')) % if not the same number...

    % check if first 2 stimuli have the same intertrial interval for EEG and
    % annotations (in case the eye tracking was cut short)
    First2StimEyes = find(strcmp(Annotations.label, 'Stim'), 2);
    EyesITI = diff(Annotations.timestamp(First2StimEyes)-Annotations.timestamp(1));

    First2StimEEG = find(strcmp(TriggerTypes, 'S  3'), 2);
    EEGITI = diff(TriggerTimes(First2StimEEG)/EEG.srate);

    if abs(EyesITI-EEGITI) < 0.1
        warning([' EEG vs annotations asynchronized length in ', EEG.filename])
    elseif size(Annotations, 1)==1
        warning(['Usin manual synchronization in ', EEG.filename])
    else
        error(['Something REALLY wrong with EEG vs annotations synchronization in ', EEG.filename])
    end
end
end


function EEG = adjust_triggers_PVT(Task, EEG, Triggers)
if strcmp(Task, 'PVT')
    StartTrialIndx = find(strcmp({EEG.event.type}, Triggers.SyncEyes), 1, 'first');
    StartStimIndx = find(strcmp({EEG.event.type}, 'S  3'), 1, 'first');
    EEG.event(StartTrialIndx).latency = EEG.event(StartStimIndx).latency;
end
end

