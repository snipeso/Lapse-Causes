function [Data, TimeEEG] = sync_eyes(EEG, SyncTrigger, Pupil, DiameterColumnName, Annotations)
% synchronize pupil data to EEG data based on first trigger in Annotations
% EEG is an EEGLAB data structure.
% Trigger0 is a string of the first trigger type in annotations
% Pupil is a table with the timestamps and whatever pupil data is of
% interest.
% ColumnName is the name of the pupil data of interest. TODO: could make it
% a list.
% Annotations is the table of all the triggers that pupilcapture picked up.

% To prove how wonderfully successful the synchronization is, I recommend
% loading in EEG data before ICA removal, then run this:
% figure;plot(Time, EEG.data(8, :))
% hold on
% plot(Time, Data(2, :)*100)

disp(['Synchronizing eye data for ', EEG.filename])

Eyes = [0 1];
SmoothFactor = 10;

PupilDetectionMethodTypes = unique(Pupil.method);
if numel(PupilDetectionMethodTypes) ~= 1
    error('Too many method types')
end

TimeEEG = shift_eeg_time(EEG, SyncTrigger);
Data = nan(2, numel(TimeEEG)); % nest of nans to pad the data if its not long enough, or missing

for idxEye = 1:numel(Eyes) % both eyes

    % skip if there's no data for that eye
    if ~any(Pupil.eye_id == Eyes(idxEye))
        continue
    end

     Time_Pupil = shift_pupil_time(Pupil, Annotations, Eyes(idxEye));

    % select data and smooth it
    PupilData = Pupil.(DiameterColumnName)(Pupil.eye_id == Eyes(idxEye));
    PupilDataSmooth = smooth(PupilData, SmoothFactor);

    % resample to EEG sample rate (reduces computation time)
    [PupilDataSmooth, TimePupilEEGSampleRate] = resample(PupilDataSmooth, Time_Pupil, EEG.srate);

    Data = adjust_pupil_data(Data, idxEye, PupilDataSmooth, TimePupilEEGSampleRate, TimeEEG);    
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function Time = shift_eeg_time(EEG, SyncTrigger)

% get sample point of starting trigger
T0TriggerIndex = find(strcmp({EEG.event.type}, SyncTrigger), 1, 'first');

% get time point of T0 in seconds
T0EEG = EEG.event(T0TriggerIndex).latency/EEG.srate;

% create time vector in seconds
TimeEEG = linspace(0, EEG.pnts/EEG.srate, EEG.pnts)';
T0EEGIndex = dsearchn(TimeEEG, T0EEG); % identify location of trigger

Time = TimeEEG-TimeEEG(T0EEGIndex); % shift time vector so T0 is actually second 0
end


function Time = shift_pupil_time(Pupil, Annotations, Eye)

% create time vector in seconds for pupil timestamps
TimePupil = Pupil.pupil_timestamp(Pupil.eye_id == Eye); % get timestamps of specific eye
T0TriggerIndex = dsearchn(TimePupil, Annotations.timestamp(1)); % location of first trigger

Time = TimePupil - TimePupil(T0TriggerIndex);
end


function Data = adjust_pupil_data(Data, idxEye, PupilDataSmooth, TimePupilEEGSampleRate, TimeEEG)

% identify time of sync trigger for both timelines
T0Pupil = dsearchn(TimePupilEEGSampleRate, 0);
T0EEG = dsearchn(TimeEEG, 0);

EndPupil = TimePupilEEGSampleRate(end);
EndEEG = TimeEEG(end);

if EndPupil <= EndEEG
    Points = numel(TimePupilEEGSampleRate)-T0Pupil;
    Data(idxEye, T0EEG:T0EEG+Points) = PupilDataSmooth(T0Pupil:end);
else
    EndEye = dsearchn(TimePupilEEGSampleRate, EndEEG)-1;
    Points = numel(PupilDataSmooth(T0Pupil:EndEye));
    Data(idxEye, T0EEG:T0EEG+Points-1) = PupilDataSmooth(T0Pupil:EndEye);
end
end
