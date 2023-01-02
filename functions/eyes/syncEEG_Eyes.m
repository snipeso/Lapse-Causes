function EyeData = syncEEG_Eyes(EEG, Source, SyncTrigger)
% synchronizes pupil data to EEG.
% Source is the folder and filename where to get eye info.
% Eyes is a struct with fields EO, which is the boolean of whether eyes
% were open, and Raw, which is the simple trace.
% in lapse-causes

ConfidenceThreshold = 0.5;
SmoothFactor = 10; % I just picked a number that worked

load(Source, 'Annotations', 'Pupil')

EyeData = struct('Raw', [], 'EO', []);
EyeIDs = unique(Pupil.eye_id);


[Eyes, ~] = syncEyes(EEG, SyncTrigger, Pupil, 'confidence', Annotations);
EyeData.Raw = Eyes;

for Indx_E = 1:numel(EyeIDs)

    [EyeOpen, Microsleeps] = classifyEye(Eyes(Indx_E, :), EEG.srate, ConfidenceThreshold);

    EyeData.EO(Indx_E, 1:EEG.pnts) = EyeOpen;
    EyeData.Microsleeps(Indx_E, 1:EEG.pnts) = Microsleeps;
end