function Trials = getECtrials(Trials, EyePath, DataQuality_Table, fs, Windows, MinWindow, WindowColumns)
% using EEG and microsleep data with same sampling rate, identifies which
% trials had more than MinWindow eyes closed.
% Trials is table of trials
% EyePath is folder location with mat files containing structure Eyes
% (output from C_SyncEyes.m).
% Window is a 1 x 2 array in seconds of start and stop relative to stimulus
% MinWindow is a fraction of the window to consider the trial having eyes
% closed.


disp('Getting eye open/closed status for trials')

ConfidenceThreshold = 0.5; % threshold for deciding if eyes were open or closed

Participants = unique(Trials.Participant);
Sessions = unique(Trials.Session);

% create column
Trials.EC = nan(size(Trials, 1), 1);

for Indx_P = 1:numel(Participants)
    for Indx_S = 1:numel(Sessions)

        % trial info for current recording
        CurrentTrials = find(strcmp(Trials.Participant, Participants{Indx_P}) & ...
            strcmp(Trials.Session, Sessions{Indx_S}));

        % load in eye data
        Eyes = loadMATFile(EyePath, Participants{Indx_P}, Sessions{Indx_S}, 'Eyes');

        if isempty(Eyes)
            continue
        end

        % only consider time of task (so that it ignores bad data from
        % around task)
        TaskTime = zeros(1, size(Eyes.Raw, 2));
        Start = round((Trials.StimTime(CurrentTrials(1))-1)*fs);
        End = round((Trials.StimTime(CurrentTrials(end))+1)*fs);
        TaskTime(Start:End) = 1;

        % check if data during task is ok
        DQ = DataQuality_Table.(Sessions{Indx_S})(strcmp(DataQuality_Table.Participant, Participants{Indx_P}));
        Eye = checkEyes(Eyes, DQ, ConfidenceThreshold, TaskTime);

        if isempty(Eye)
            continue
        end

        % get eyes closed (have to flip eye)
        [EyeOpen, ~] = classifyEye(Eye, fs, ConfidenceThreshold);
        EyeClosed = flipVector(EyeOpen);


        % determine based on amount of eyes closed time, whether classify
        % trial as EC
        Trials = getTrialStatus(Trials, 'EC', CurrentTrials, EyeClosed, fs, Windows, MinWindow, WindowColumns);
       
    end

    disp(['Finished ', Participants{Indx_P}])
end