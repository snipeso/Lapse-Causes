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
if nnz(strcmp(EventTypes, {'S  3'})) ~= nnz(strcmp(Annotations.label, 'Stim'))
    error(['Something wrong with EEG vs annotations in ', EEG.filename])
end

% set up structure
EyeData = struct('Raw', [], 'EO', []);

% select only one method type
Pupil = Pupil(strcmp(Pupil.method, MethodType), :);

% sync pupil data to EEG
[Eyes, ~] = syncEyes(EEG, SyncTrigger, Pupil, 'confidence', Annotations);
EyeData.Raw = Eyes;