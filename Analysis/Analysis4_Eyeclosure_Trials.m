% gets the data showing the probability of eyesclosed over time for each
% trial outcome type.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

OnlyClosestStimuli = true; % only use closest trials


Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
TrialWindow = Parameters.Trials.Window;
SampleRate = Parameters.SampleRate;
ConfidenceThreshold = Parameters.EyeTracking.MinConfidenceThreshold;
MaxNaNProportion = Parameters.Trials.MaxNaNProportion;
MaxStimulusDistance = Parameters.Stimuli.MaxDistance;
SessionBlocks = Parameters.Sessions.Conditions;
Triggers = Parameters.Triggers;



EyetrackingPath = fullfile(Paths.Data, 'Pupils', ['Raw_', num2str(SampleRate), 'Hz'], Task);
CacheDir = fullfile(Paths.Cache, 'Trial_Information');
CacheFilename = [Task, '_TrialsTable.mat'];

SessionBlockLabels = fieldnames(SessionBlocks);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

% get trial information
load(fullfile(CacheDir, CacheFilename), 'TrialsTable')

EyetrackingQualityTable = readtable(fullfile(Paths.QualityCheck, 'EyeTracking', ...
    ['DataQuality_', Task, '_Pupils.csv']));

TrialTime = linspace(TrialWindow(1), TrialWindow(2), SampleRate*(TrialWindow(2)-TrialWindow(1))); % time vector

% specify only close trials, or all trials
TitleTag = '';
if OnlyClosestStimuli
    TitleTag = [ TitleTag, '_Close'];
    MaxStimulusDistance = quantile(TrialsTable.Radius, MaxStimulusDistance);
else
    MaxStimulusDistance = max(TrialsTable.Radius);
end


for Indx_SB = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = SessionBlocks.(SessionBlockLabels{Indx_SB});

    % initialize variables
    EyesClosedStim = nan(numel(Participants), 3, numel(TrialTime)); % P x TT x t matrix with final probabilities
    EyesClosedResp = EyesClosedStim;
    ProbabilityEyesClosed = nan(numel(Participants), 1); % get general probability of a microsleep for a given session block (to control for when z-scoring)

    for idxParticipant = 1:numel(Participants)

        [PooledTrialsStim, PooledTrialsResp, PooledTrialsTable, EyeclosureTimepointCount] = ...
            pool_eyeclosures(TrialsTable, EyetrackingQualityTable, EyetrackingPath, ...
            Participants{idxParticipant}, Sessions, MaxStimulusDistance, TrialWindow, Triggers, SampleRate);

        if isempty(PooledTrialsTable)
            warning('empty table')
            continue
        end

        % get probability of microsleep (in time) for each trial type
        [EyesClosedStim(idxParticipant, :, :), EyesClosedResp(idxParticipant, :, :)] = ...
            getProbTrialType(AllTrials_Stim, AllTrials_Resp, AllTrials_Table, MaxNaNProportion, minTrials);


        % calculate general probability of a microsleep
        ProbabilityEyesClosed(idxParticipant) =  MicrosleepTimepoints(1)./MicrosleepTimepoints(2);
        disp(['Finished ', Participants{idxParticipant}])
    end

    %%% save
    save(fullfile(Pool, ['ProbMicrosleep_', SessionBlockLabels{Indx_SB}, TitleTag, '.mat']), 'EyesClosedStim', 'EyesClosedResp', 'TrialTime', 'ProbabilityEyesClosed')



end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [PooledTrialsStim, PooledTrialsResp, PooledTrialsTable, EyeclosureTimepointCount] = ...
    pool_eyeclosures(TrialsTable, EyetrackingQualityTable, EyetrackingPath, ...
    Participant, Sessions, MaxStimulusDistance, TrialWindow, Triggers, SampleRate)

% initialize variables
PooledTrialsStim = []; % need to pool all trials across sessions in a given session block
PooledTrialsResp = [];
PooledTrialsTable = table();
EyeclosureTimepointCount = [0 0]; % total number of points in recording that is a microsleep; total number of points, pooling sessions

for idxSession = 1:numel(Sessions)

    % trial info for current recording
    CurrentTrials = strcmp(TrialsTable.Participant, Participant) & ...
        strcmp(TrialsTable.Session, Sessions{idxSession}) & TrialsTable.Radius < MaxStimulusDistance;

    % load in eye data
    Eyes = load_datafile(EyetrackingPath, Participant, Sessions{idxSession}, 'Eyes');
    if isempty(Eyes); continue; end
    EEGMetadata = load_datafile(EyetrackingPath, Participant, Sessions{idxSession}, 'EEGMetadata');

    % identify eyes closed timepoints
    CleanEyeIndex = EyetrackingQualityTable.(Sessions{idxSession})(strcmp(EyetrackingQualityTable.Participant, Participant));
    EyeClosed = clean_eyeclosure_data(Eyes, EEGMetadata, Triggers, CleanEyeIndex, SampleRate, ConfidenceThreshold);

    % chop into trials
    EyeClosedStimLocked = chop_trials(EyeClosed, SampleRate, EEGMetadata.event, Triggers.Stim, TrialWindow);
    EyeClosedRespLocked = chop_trials(EyeClosed, SampleRate, EEGMetadata.event, Triggers.Resp, TrialWindow);

    % pool sessions
    PooledTrialsStim = cat(1, PooledTrialsStim,  EyeClosedStimLocked);
    PooledTrialsResp = cat(1, PooledTrialsResp, EyeClosedRespLocked);

    % pool info
    PooledTrialsTable = cat(1, PooledTrialsTable, TrialsTable(CurrentTrials, :)); % important that it be in the same order!
    EyeclosureTimepointCount = tally_timepoints(EyeclosureTimepointCount, EyeClosed);
end
end


