function Trials = getECtrials(Trials, EyePath, DataQuality_Table, fs, Window, MinWindow)
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
        nTrials = nnz(CurrentTrials);

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

        [EyeOpen, ~] = classifyEye(Eye, fs, ConfidenceThreshold);

        % determine based on amount of eyes closed time, whether classify
        % trial as EC
        for Indx_T = 1:nTrials
            StimT = round(fs*Trials.StimTime(CurrentTrials(Indx_T)));
            Start = StimT+Window(1)*fs;
            End = StimT+Window(2)*fs;

            Pnts = numel(Start:End);
            EO = EyeOpen(Start:End);

            if nnz(isnan(EO))/Pnts > MinWindow
                Trials.EC(CurrentTrials(Indx_T)) = nan;

            elseif nnz(EO==0)/Pnts > MinWindow
                Trials.EC(CurrentTrials(Indx_T)) = 1;

            else
                Trials.EC(CurrentTrials(Indx_T)) = 0;
            end
        end
    end

    disp(['Finished ', Participants{Indx_P}])
end