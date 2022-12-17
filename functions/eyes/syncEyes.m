function [Data, Time] = syncEyes(EEG, Trigger0, Pupil, ColumnName, Annotations)
% synchronize pupil data to EEG data based on first trigger in Annotations
% EEG is an EEGLAB data structure.
% Trigger0 is a string of the first trigger type in annotations
% Pupil is a table with the timestamps and whatever pupil data is of
% interest.
% ColumnName is the name of the pupil data of interest. TODO: could make it
% a list.
% Annotations is the table of all the triggers that pupilcapture picked up.

disp(['Synchronizing eye data for ', EEG.filename])

Eyes = unique(Pupil.eye_id);

% get sample point of starting trigger
T0_Indx = find(strcmp({EEG.event.type}, Trigger0), 1, 'first');

% get time point of T0 in seconds
T0_EEG = EEG.event(T0_Indx).latency/EEG.srate;

% create time vector in seconds
t_EEG = linspace(0, EEG.pnts/EEG.srate, EEG.pnts)';
T0_EEG_indx = dsearchn(t_EEG, T0_EEG); % identify location of trigger
Time = t_EEG-t_EEG(T0_EEG_indx); % shift time vector so T0 is actually second 0

Data = nan(2, numel(Time));

for Indx_I = 1:numel(Eyes) % both eyes

    % create time vector in seconds for pupil timestamps
    t_Pupil = Pupil.pupil_timestamp(Pupil.eye_id == Eyes(Indx_I)); % get timestamps of specific eye
    T0_Indx = dsearchn(t_Pupil, Annotations.timestamp(1)); % location of first trigger
    Time_Pupil = t_Pupil - t_Pupil(T0_Indx);

    % select data and smooth it
    D = smooth(Pupil.(ColumnName)(Pupil.eye_id == Eyes(Indx_I)), 10);

    % resample to EEG rate (reduces computation time)
    [D, T] = resample(D, Time_Pupil, EEG.srate);

    Start_Eye = dsearchn(T, 0);
    Start_EEG = dsearchn(Time, 0);

    End_Eye = T(end);
    End_EEG = Time(end);

    if End_Eye <= End_EEG
        Points = numel(T)-Start_Eye;
        Data(Indx_I, Start_EEG:Start_EEG+Points) = D(Start_Eye:end);
    else
        EndEye = dsearchn(T, End_EEG)-1;
        Points = numel(D(Start_Eye:EndEye));
        Data(Indx_I, Start_EEG:Start_EEG+Points-1) = D(Start_Eye:EndEye);
    end
end