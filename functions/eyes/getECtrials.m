function Trials = getECtrials(Trials, MicrosleepPath, fs)
% using EEG and microsleep data with same sampling rate, identifies which
% trials had more than 50% eyes closed

disp('Getting eye open/closed status for trials')

Participants = unique(Trials.Participant);
Sessions = unique(Trials.Session);

Trials.EC = nan(size(Trials, 1), 1);

% timewindow relative to stim onset to see if eyes were open or closed
StartWindow = 0;
EndWindow = 1;

ConfidenceThreshold = 0.5;
MinEO = 0.5; % faction of trial that needs to be EO to be considered EO
MinNaN = 0.5; % fraction of trial time to consider whether NAN

Filenames = getContent(MicrosleepPath);

for Indx_P = 1:numel(Participants)
    for Indx_S = 1:numel(Sessions)

        % trial info for current recording
        CurrentTrials = find(strcmp(Trials.Participant, Participants{Indx_P}) & ...
            strcmp(Trials.Session, Sessions{Indx_S}));
        nTrials = nnz(CurrentTrials);

        % load in eye data
        Eyes = loadMATFile(MicrosleepPath, Participants{Indx_P}, Sessions{Indx_S}, 'Eyes');
        if isempty(Eyes); continue; end

        if isnan(Eyes.DQ) || Eyes.DQ == 0 || Eyes.DQ < 1
            warning(['Bad data in ',  Participants{Indx_P}, Sessions{Indx_S}])
            continue
        end

        Eye = round(Eyes.DQ); % which eye

        [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), fs, ConfidenceThreshold); % not using internal microsleep identifier so that I'm flexible

        % determine based on amount of eyes closed time, whether classify
        % trial as EC
        for Indx_T = 1:nTrials
            StimT = Trials.StimTime(CurrentTrials(Indx_T));
            Start = round(fs*(StimT+StartWindow));
            End = round(fs*(StimT+EndWindow));
            if nnz(isnan(EyeOpen(Start:End)))/numel(Start:End) > MinNaN
                Trials.EC(CurrentTrials(Indx_T)) = nan;
            elseif nnz(EyeOpen(Start:End))/numel(Start:End) < MinEO
                Trials.EC(CurrentTrials(Indx_T)) = 1;
            else
                Trials.EC(CurrentTrials(Indx_T)) = 0;
                %                 Trials.EC(CurrentTrials(Indx_T))
                %                 =nnz(EyeOpen(Start:End))/numel(Start:End); % debug
            end
        end
    end
    disp(['Finished ', Participants{Indx_P}])
end