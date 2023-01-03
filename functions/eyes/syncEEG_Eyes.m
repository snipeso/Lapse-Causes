function EyeData = syncEEG_Eyes(EEG, Source, SyncTrigger)
% synchronizes pupil data to EEG.
% Source is the folder and filename where to get eye info.
% Eyes is a struct with fields EO, which is the boolean of whether eyes
% were open, and Raw, which is the simple trace.
% in lapse-causes

MethodType = '2d c++';

% load data
load(Source, 'Annotations', 'Pupil')


% check if the EEG and annotations match
EventTypes = {EEG.event.type}; 
EventTimes = [EEG.event.latency];
if nnz(strcmp(EventTypes, {'S  3'})) ~= nnz(strcmp(Annotations.label, 'Stim'))
    
    % check if first 2 stimuli are the same distance for EEG and
    % annotations (in case the eye tracking was cut short)
    First2_Eyes = find(strcmp(Annotations.label, 'Stim'), 2);
    ITI_Eyes = diff(Annotations.timestamp(First2_Eyes)-Annotations.timestamp(1));

    First2EEG = find(strcmp(EventTypes, 'S  3'), 2);
    ITI_EEG = diff(EventTimes(First2EEG)/EEG.srate);

    if abs(ITI_Eyes-ITI_EEG) < 0.1
        warning([' EEG vs annotations asynchronized length in ', EEG.filename])
    else
    error(['Something REALLY wrong with EEG vs annotations synchronization in ', EEG.filename])
    end
end

% set up structure
EyeData = struct('Raw', [], 'EO', []);

% select only one method type
Pupil = Pupil(strcmp(Pupil.method, MethodType), :);

% sync pupil data to EEG
[Eyes, ~] = syncEyes(EEG, SyncTrigger, Pupil, 'confidence', Annotations);
EyeData.Raw = Eyes;