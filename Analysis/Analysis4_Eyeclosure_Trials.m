% gets the data showing the probability of eyesclosed over time for each
% trial outcome type.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

OnlyClosestStimuli = false; % only use closest trials

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
TrialWindow = Parameters.Trials.Window;
SampleRate = Parameters.SampleRate;
ConfidenceThreshold = Parameters.EyeTracking.MinConfidenceThreshold;
MaxNaNProportion = Parameters.Trials.MaxNaNProportion;
MaxStimulusDistanceProportion = Parameters.Stimuli.MaxDistance;
SessionBlocks = Parameters.Sessions.Conditions;
SessionBlockLabels = fieldnames(SessionBlocks);
Triggers = Parameters.Triggers;
MinTrials = Parameters.Trials.MinPerSubGroupCount;

% locations
EyetrackingDir = fullfile(Paths.Data, 'Pupils', ['Raw_', num2str(SampleRate), 'Hz'], Task);
TrialCacheDir = fullfile(Paths.Cache, 'Trial_Information');
CacheFilename = [Task, '_TrialsTable.mat'];

EyeclosureCacheDir = fullfile(Paths.Cache, 'Data_Figures');
if ~exist(EyeclosureCacheDir, 'dir')
    mkdir(EyeclosureCacheDir)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

%%% get trial information
load(fullfile(TrialCacheDir, CacheFilename), 'TrialsTable')

EyetrackingQualityTable = readtable(fullfile(Paths.QualityCheck, 'EyeTracking', ...
    ['DataQuality_', Task, '_Pupils.csv']));

TrialTime = linspace(TrialWindow(1), TrialWindow(2), SampleRate*(TrialWindow(2)-TrialWindow(1))); % time vector

 [MaxStimulusDistance, TitleTag] = max_stimulus_distance(TrialsTable, ...
     OnlyClosestStimuli, MaxStimulusDistanceProportion);

 
 %%% get eyes closued information

for idxSessionBlock = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = SessionBlocks.(SessionBlockLabels{idxSessionBlock});

    % initialize variables
    EyesClosedStimLocked = nan(numel(Participants), 3, numel(TrialTime)); % P x TT x t matrix with final probabilities
    EyesClosedRespLocked = EyesClosedStimLocked;
    EyeclosureDescriptives = nan(numel(Participants), 2); 

    for idxParticipant = 1:numel(Participants)

        [PooledTrialsStim, PooledTrialsResp, PooledTrialsTable, PooledEyeclosureDescriptives] = ...
            pool_eyeclosure_trials(TrialsTable, EyetrackingQualityTable, EyetrackingDir, ...
            Participants{idxParticipant}, Sessions, MaxStimulusDistance, TrialWindow, ...
            Triggers, SampleRate, ConfidenceThreshold);

        if isempty(PooledTrialsTable)
            warning('empty table')
            continue
        end

        % get probability of eyesclosed (in time) for each trial type
        EyesClosedStimLocked(idxParticipant, :, :) = probability_of_event_by_outcome( ...
            PooledTrialsStim, PooledTrialsTable, MaxNaNProportion, MinTrials, false);

        EyesClosedRespLocked(idxParticipant, :, :) = probability_of_event_by_outcome( ...
            PooledTrialsResp, PooledTrialsTable(PooledTrialsTable.Type~=1, :), ...
            MaxNaNProportion, MinTrials, true);

        EyeclosureDescriptives(idxParticipant, :) =  PooledEyeclosureDescriptives;
        disp(['Finished ', Participants{idxParticipant}])
    end

    % save
    save(fullfile(EyeclosureCacheDir, ['Eyeclosures_', SessionBlockLabels{idxSessionBlock}, TitleTag, '.mat']), ...
        'EyesClosedStimLocked', 'EyesClosedRespLocked', 'TrialTime', 'EyeclosureDescriptives')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [MaxStimulusDistance, TitleTag] = max_stimulus_distance(TrialsTable, ...
    OnlyClosestStimuli, MaxStimulusDistanceProportion)
% specify only close trials, or all trials
TitleTag = '';
if OnlyClosestStimuli
    TitleTag = [ TitleTag, '_Close'];
    MaxStimulusDistance = quantile(TrialsTable.Radius, MaxStimulusDistanceProportion);
else
    MaxStimulusDistance = max(TrialsTable.Radius);
end
end


function [PooledTrialsStim, PooledTrialsResp, PooledTrialsTable, EyeclosureDescriptives] = ...
    pool_eyeclosure_trials(TrialsTable, EyetrackingQualityTable, EyetrackingPath, ...
    Participant, Sessions, MaxStimulusDistance, TrialWindow, Triggers, SampleRate, ConfidenceThreshold)
% pool trials from multiple sessions, into a single session block

% initialize variables
PooledTrialsStim = [];
PooledTrialsResp = [];
PooledTrialsTable = table();
AllEyeClosed = [];

for idxSession = 1:numel(Sessions)

    % trial info subset
    CurrentTrials = strcmp(TrialsTable.Participant, Participant) & ...
        strcmp(TrialsTable.Session, Sessions{idxSession}) & TrialsTable.Radius < MaxStimulusDistance;

    % load in eye data
    Eyes = load_datafile(EyetrackingPath, Participant, Sessions{idxSession}, 'Eyes');
    if isempty(Eyes); continue; end
    EEGMetadata = load_datafile(EyetrackingPath, Participant, Sessions{idxSession}, 'EEGMetadata');

    % identify eyes closed timepoints
    CleanEyeIndex = EyetrackingQualityTable.(Sessions{idxSession})(...
        strcmp(EyetrackingQualityTable.Participant, Participant));
    EyeClosed = clean_eyeclosure_data(Eyes, EEGMetadata, Triggers, CleanEyeIndex, SampleRate, ConfidenceThreshold);

    % chop into trials
    EyeClosedStimLocked = chop_trials(EyeClosed, SampleRate, TrialsTable.StimTimepoint(CurrentTrials), TrialWindow);
    EyeClosedRespLocked = chop_trials(EyeClosed, SampleRate, TrialsTable.RespTimepoint(CurrentTrials & TrialsTable.Type~=1), TrialWindow);

    % pool sessions
    PooledTrialsStim = cat(1, PooledTrialsStim,  EyeClosedStimLocked);
    PooledTrialsResp = cat(1, PooledTrialsResp, EyeClosedRespLocked);

    % pool info
    PooledTrialsTable = cat(1, PooledTrialsTable, TrialsTable(CurrentTrials, :)); % important that it be in the same order!
    AllEyeClosed = cat(2, AllEyeClosed, EyeClosed);
end

EyeclosureDescriptives = cat(2, mean(AllEyeClosed, 2, 'omitnan'), std(AllEyeClosed, [], 2, 'omitnan'));
end





