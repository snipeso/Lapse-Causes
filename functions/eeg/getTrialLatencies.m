function Trials = getTrialLatencies(Trials, EEGPath, Triggers)
% for all trials, get information of stim time and response time (if
% available). Used for finding eyes closed, bursts, etc.

Participants = unique(Trials.Participant);
Sessions = unique(Trials.Session);

Trials.StimTime = nan(size(Trials, 1), 1);
Trials.RespTime = Trials.StimTime;

% get whatever tag I used for that EEG dataset
Filenames = getContent(EEGPath);

for Indx_P = 1:numel(Participants)
    for Indx_S = 1:numel(Sessions)

        % trial info for current recording
        CurrentTrials = strcmp(Trials.Participant, Participants{Indx_P}) & ...
            strcmp(Trials.Session, Sessions{Indx_S});
        nTrials = nnz(CurrentTrials);

        % load EEG metadata
        Filename = Filenames(contains(Filenames, Participants{Indx_P}) & ...
            contains(Filenames, Sessions{Indx_S}));
        load(fullfile(EEGPath, Filename), 'EEG')
        EEG.data = []; % maybe eases up space?
        fs = EEG.srate;

        % get trigger info
        Latencies = [EEG.event.latency]/fs; % normalize to seconds
        Types = {EEG.event.type};
        StimLatencyIndexes = find(strcmp(Types, Triggers.Stim));
        StimLatencies = Latencies(StimLatencyIndexes);
        if numel(StimLatencies) ~= nTrials
            error(['missing trials for ', Filename])
        end

        % save stim times
        Trials.StimTime(CurrentTrials) = StimLatencies;

         % get response latencies
        RespLatencies = StimLatencies+fs*1; % window between stim and answer, if no answer given
        for Indx_T = 1:nTrials
            NextIndx = StimLatencyIndexes(Indx_T)+1; % next trigger
            if strcmp(Types(NextIndx), Triggers.Resp) % check if it's a response trigger
                RespLatencies(Indx_T) = Latencies(NextIndx); % save that latency
            else
                RespLatencies(Indx_T) = nan;
            end
        end

        Trials.RespTime(CurrentTrials) = RespLatencies;
    end
end