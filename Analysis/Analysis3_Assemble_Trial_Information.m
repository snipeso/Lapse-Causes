% Script in Lapse-Causes that plots the first figure (and stats) related to
% the LAT task performance.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Tasks = {'PVT', 'LAT'};
RerunAnalysis = true;

Parameters = analysisParameters();
Paths = Parameters.Paths;
StatParameters = Parameters.Stats;
Participants = Parameters.Participants;
Sessions = Parameters.Sessions;
TrialWindow = Parameters.Trials.SubWindows(2, :);
MinEventProportion = Parameters.Trials.MinEventProportion;
MaxNanProportion = Parameters.Trials.MaxNaNProportion;
Triggers = Parameters.Triggers;
SampleRate = Parameters.SampleRate;
ConfidenceThreshold = Parameters.EyeTracking.MinConfidenceThreshold;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Assemble trial data

for Task = Tasks

    % if already assembled, load from cache
    CacheDir = fullfile(Paths.Cache, 'Trial_Information');
    CacheFilename = [Task{1}, '_TrialsTable.mat'];
    TrialsTable = load_trials_from_cache(CacheDir, CacheFilename, RerunAnalysis);
    if ~isempty(TrialsTable)
        continue
    end

    % load output from raw data (or intermediate cache)
    TrialsTable = load_task_output(Participants, Sessions.(Task{1}), Task{1}, Paths, false);

    % determine stimulus trigger times
    EyetrackingDir = fullfile(Paths.Data, 'Pupils', ['Raw_', num2str(SampleRate), 'Hz'], Task{1});
    TrialsTable = trigger_times(TrialsTable, EyetrackingDir, Triggers);

    %%% determine whether eyes were open or closed
    EyetrackingQualityTable = readtable(fullfile(Paths.QualityCheck, 'EyeTracking', ...
        ['DataQuality_', Task{1}, '_Pupils.csv']));

    TrialsTable = eyes_closed_trials(TrialsTable, EyetrackingQualityTable, EyetrackingDir, ...
        TrialWindow, MinEventProportion,  MaxNanProportion, ConfidenceThreshold, Triggers);


    % save to cache for future
    save(fullfile(CacheDir, CacheFilename), 'TrialsTable')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function TrialsTable = load_trials_from_cache(CacheDir, CacheFile, RerunAnalysis)
CachePath = fullfile(CacheDir, CacheFile);

% load from cache
if exist(CachePath, 'file') && ~RerunAnalysis
    load(CachePath, 'TrialsTable')
    return
else
    TrialsTable = table();
end

% set up cache
if ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end
end


function TrialsTable = trigger_times(TrialsTable, MetadataDir, Triggers)

Participants = unique(TrialsTable.Participant);
Sessions = unique(TrialsTable.Session);

TrialsTable.StimTimepoint = nan(size(TrialsTable, 1), 1);
TrialsTable.RespTimepoint = nan(size(TrialsTable, 1), 1);


for Participant = Participants'
    for Session = Sessions'

        % trial info for current recording
        CurrentTrials = find(strcmp(TrialsTable.Participant, Participant{1}) & ...
            strcmp(TrialsTable.Session, Session{1}));
        nTrials = nnz(CurrentTrials);
        if isempty(nTrials) || nTrials < 5
            warning(['Missing ', Participant{1}, Session{1}])
            continue
        end
        EEGMetadata = load_datafile(MetadataDir, Participant{1}, Session{1}, 'EEGMetadata');
        if isempty(EEGMetadata);continue;end

        Events = EEGMetadata.event;
        Latencies = [Events.latency];
        Types = {Events.type};

        % gather stimulus latencies
        StimLatencyIndexes = find(strcmp(Types, Triggers.Stim));
        StimLatencies = Latencies(StimLatencyIndexes);

        if numel(StimLatencies) ~= nTrials
            error('mismatch trials and triggers stimuli')
        end
        TrialsTable.StimTimepoint(CurrentTrials) = StimLatencies;

        % gather response latencies

        RespLatencyIndexes = StimLatencyIndexes+1; % only responses immediately after a stimulus
        NextTriggerType = Types(RespLatencyIndexes);
        NotResponses = ~strcmp(NextTriggerType, Triggers.Resp);
        RespLatencyIndexes(NotResponses) = [];
        RespLatencies = Latencies(RespLatencyIndexes);
        ResponseCurrentTrials = CurrentTrials; % skip lapses
        ResponseCurrentTrials(NotResponses) = [];

        TrialsTable.RespTimepoint(ResponseCurrentTrials) = RespLatencies;
    end
end
end


function TrialsTable = eyes_closed_trials(TrialsTable, EyetrackingQualityTable, EyetrackingDir, ...
    TrialWindow, MinEventProportion, MaxNanProportion, ConfidenceThreshold, Triggers)

Participants = unique(TrialsTable.Participant);
Sessions = unique(TrialsTable.Session);

TrialsTable.EyesClosed = nan(size(TrialsTable, 1), 1);

for Participant = Participants'
    for Session = Sessions'

        % trial info for current recording
        CurrentTrials = strcmp(TrialsTable.Participant, Participant{1}) & ...
            strcmp(TrialsTable.Session, Session{1});
        nTrials = nnz(CurrentTrials);
        if isempty(nTrials) || nTrials < 5
            warning(['Missing ', Participant{1}, Session{1}])
            continue
        end

        % load in eye data
        Eyes = load_datafile(EyetrackingDir, Participant{1}, Session{1}, 'Eyes');
        if isempty(Eyes);continue;end

        % load in metadata
        EEGMetadata = load_datafile(EyetrackingDir, Participant{1}, Session{1}, 'EEGMetadata');
        SampleRate = EEGMetadata.srate;

        % detrmine if eyes were closed during trial
        CleanEyeIndx = EyetrackingQualityTable.(Session{1})(strcmp(EyetrackingQualityTable.Participant, Participant{1}));
        EyeClosed = clean_eyeclosure_data(Eyes, EEGMetadata, Triggers, CleanEyeIndx, SampleRate, ConfidenceThreshold);

        EyesClosedTrials = chop_trials(EyeClosed, SampleRate, EEGMetadata.event, Triggers.Stim, TrialWindow);

        if size(EyesClosedTrials, 1) ~=nTrials
            error(['missing trials for ', Participant{1}, Session{1}])
        end

        EyesWereClosed = did_it_happen(EyesClosedTrials, MinEventProportion, MaxNanProportion);
        TrialsTable.EyesClosed(CurrentTrials) = EyesWereClosed;
    end

    disp(['Finished syncing eye data for ', Participant{1}])
end
end


function itHappened = did_it_happen(TrialData, MinWindow, MinNanProportion)
TrialCount = size(TrialData, 1);
itHappened = nan(TrialCount, 1);
for idxTrial = 1:TrialCount
    V = TrialData(idxTrial, :);
    Pnts = numel(V);
    if nnz(isnan(V))/Pnts > MinNanProportion
        itHappened(idxTrial) = nan;
    elseif nnz(V==1)/Pnts > MinWindow
        itHappened(idxTrial) = 1;
    else
        itHappened(idxTrial) = 0;
    end
end
end