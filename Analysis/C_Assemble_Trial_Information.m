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
MinTrialCount = Parameters.Trials.MinTotalCount;
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

    TrialsTable = load_trials_from_cache(Task{1}, fullfile(Paths.Cache, 'TrialsTables'));
    if ~isempty(TrialsTable)
        continue
    end

    TrialsTable = load_task_output(Participants, Sessions.(Task{1}), Task{1}, Paths, false);


    %%% determine whether eyes were open or closed
    EyetrackingQualityTable = readtable(fullfile(Paths.QualityCheck, 'EyeTracking', ...
        ['DataQuality_', Task{1}, '_Pupils.csv']));

    EyetrackingDir = fullfile(Paths.Data, 'Pupils', ['Raw_', num2str(SampleRate), 'Hz'], Task{1});

    TrialsTable = were_eyes_closed(TrialsTable, EyetrackingQualityTable, EyetrackingDir, ...
        TrialWindow, MinEventProportion,  MaxNanProportion, ConfidenceThreshold, Triggers);


    % save to cache for future
    save(CachePath, 'TrialsTable')

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function TrialsTable = load_trials_from_cache(Task, CacheDir)

% location of cache
CacheString = strjoin({Task, 'TrialTable.mat'}, '_');
CachePath = fullfile(CacheDir, CacheString);

% load from cache
if exist(CachePath, 'file') && ~Refresh
    load(CachePath, 'TrialsTable')
    return
end

% set up cache
if ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end

TrialsTable = table();
end


function TrialsTable = were_eyes_closed(TrialsTable, EyetrackingQualityTable, EyetrackingDir, ...
    TrialWindow, MinEventProportion, MaxNanProportion, ConfidenceThreshold, Triggers)

Participants = unique(TrialsTable.Participant);
Sessions = unique(TrialsTable.Session);

TrialsTable.EyesClosed = nan(size(TrialsTable, 1), 1);

for Participant = Participants
    for Session = Sessions

        % trial info for current recording
        CurrentTrials = find(strcmp(TrialsTable.Participant, Participant{1}) & ...
            strcmp(TrialsTable.Session, Session{1}));
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

        [Starts, Ends] = window_timepoints(EEGMetadata, Triggers, TrialWindow);
        if numel(Starts) ~=nTrials
            error(['missing trials for ', Participant{1}, Session{1}])
        end

        DQ = EyetrackingQualityTable.(Session{1})(strcmp(DataQuality_Table.Participant, Participant{1}));
        TaskTime = identify_task_timepoints(EEGMetadata, Triggers);
        Eye = check_eye_dataquality(Eyes, DQ, ConfidenceThreshold, TaskTime);
        EyeClosed = detect_eyeclosure(Eye, SampleRate, Threshold);

        EyesClosedTrials = did_it_happen(Starts, Ends, EyeClosed, MinEventProportion, MaxNanProportion);
        TrialsTable.EyesClosed(CurrentTrials) = EyesClosedTrials;
    end
    disp(['Finished syncing eye data for ', Participant{1}, Session{1}])
end
end


function [Starts, Ends] = window_timepoints(EEG, Triggers, Window)

SampleRate = EEG.srate;
Latencies = [EEG.event.latency];
Types = {EEG.event.type};
StimLatencyIndexes = strcmp(Types, Triggers.Stim);
StimLatencies = Latencies(StimLatencyIndexes);

Starts = StimLatencies-Window(1)*SampleRate;
Ends = StimLatencies+Window(2)*SampleRate;
end

function itHappened = did_it_happen(Starts, Ends, EventVector, MinWindow, MinNanProportion)
itHappened = nan(size(Starts));
for idxTrial = 1:numel(Starts)
    V = EventVector(Starts(idxTrial):Ends(idxTrial));
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