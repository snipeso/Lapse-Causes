
% gets the data showing the probability of eyesclosed over time for each
% trial outcome type.

clear
clc
close all

addpath('D:\Code\ExternalToolboxes\Morlet-Wavelet')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

OnlyClosestStimuli = false; % only use closest trials
OnlyEyesOpen = false; % only used eyes-open trials
ChannelsCount = 123; % just to pre-allocate before loading in data

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
MinTrials = Parameters.Trials.MinPerSubGroupCount;
Bands = Parameters.Bands;

Frequencies = 1:20;
TotFrequencies = numel(Frequencies);

% locations
EyetrackingDir = fullfile(Paths.Data, 'Pupils', ['Raw_', num2str(SampleRate), 'Hz'], Task);
EEGDir = fullfile(Paths.AnalyzedData, 'EEG', 'TimeFrequency', Task);
TrialCacheDir = fullfile(Paths.Cache, 'Trial_Information');
CacheFilename = [Task, '_TrialsTable.mat'];

CacheDir = fullfile(Paths.Cache, 'Data_Figures');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

%%% get trial information
load(fullfile(TrialCacheDir, CacheFilename), 'TrialsTable')

TrialTime = linspace(TrialWindow(1), TrialWindow(2), SampleRate*(TrialWindow(2)-TrialWindow(1))); % time vector

% if requested, exclude trials during which eyes were closed during the
% stimulus window
[EyesOpenTrialIndexes, EyetrackingQualityTable, TitleTag] = ...
    only_eyes_open_trials(TrialsTable, OnlyEyesOpen, Paths, Task);

% if requested, exclude furthest trials
[MaxStimulusDistance, TitleTag] = max_stimulus_distance(TrialsTable, ...
    OnlyClosestStimuli, MaxStimulusDistanceProportion, TitleTag);


%%% get power
for idxSessionBlock = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = SessionBlocks.(SessionBlockLabels{idxSessionBlock});

    % set up blanks
    TimeFrequencyEpochs = nan(numel(Participants), 3, ChannelsCount, TotFrequencies, numel(TrialTime)); % P x TT x Ch x F x t matrix with final probabilities

    for idxParticipant = 1:numel(Participants)

        [PooledTrials, PooledTrialsTable,  AllRecordingPower, Chanlocs] = pool_eeg(TrialsTable, ...
            EyetrackingQualityTable, EEGDir, EyesOpenTrialIndexes, EyetrackingDir, ...
            Participants{idxParticipant}, Sessions, MaxStimulusDistance, TrialWindow, SampleRate, ...
            ConfidenceThreshold, Frequencies, CycleRange);

        if isempty(PooledTrialsTable)
            warning('empty table')
            continue
        end

        % normalize trials
        PooledTrials = normalize_trials(PooledTrials, AllRecordingPower);
        

        % average trials by trial type
        for idxChannel = 1:numel(Chanlocs) % a hack, easier to loop here than fix everything in the function
            TimeFrequencyEpochs(idxParticipant, :, idxChannel, :, :) = average_trial_types(...
                squeeze(PooledTrials(:, idxChannel, :, :)), PooledTrialsTable, MaxNaNProportion, MinTrials);
        end

        disp(['Finished ', Participants{idxParticipant}])
    end

    %%% save
    save(fullfile(CacheDir, ['Power_', SessionBlockLabels{idxSessionBlock}, TitleTag, '.mat']), ...
        'TimeFrequencyEpochs', 'Chanlocs', 'TrialTime')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [PooledTrials, PooledTrialsTable, AllRecordingPower, Chanlocs] = pool_eeg(TrialsTable, ...
    EyetrackingQualityTable, EEGDir, EyesOpenTrials, EyetrackingDir, ...
    Participant, Sessions, MaxStimulusDistance, TrialWindow, SampleRate, ...
    ConfidenceThreshold)
% EyeclosureTimepointCount is a 1 x 2 array indicating the total number of
% points in the pooled sessions that has eyes closed and the total number of
% points.

PooledTrials = []; % Trials x Ch x F x t
PooledTrialsTable = table();
AllRecordingPower = [];

for idxSession = 1:numel(Sessions)

    % trial info for current recording
    CurrentTrials = strcmp(TrialsTable.Participant, Participant) & ...
        strcmp(TrialsTable.Session, Sessions{idxSession}) & ...
        TrialsTable.Radius < MaxStimulusDistance & EyesOpenTrials;

    % load in eye data
    Power = load_datafile(EEGDir, Participant, Sessions{idxSession}, 'Power');
    if isempty(Power); continue; end
    EEG = load_datafile(EEGDir, Participant, Sessions{idxSession}, 'EEGMetadata');
    Chanlocs = EEG.chanlocs;

    % identify task, artifact free, eyes open timepoints
    EEGMetadata = load_datafile(MetadataDir, Participant, Sessions{idxSession}, 'EEGMetadata');
    CleanTimepoints = EEGMetadata.CleanTaskTimepoints;

    if ~isempty(EyetrackingQualityTable)
        CleanTimepoints = check_eyes_open(CleanTimepoints, EyetrackingDir, ...
            EyetrackingQualityTable, ConfidenceThreshold, Participant, Sessions{idxSession}, SampleRate);
    end

    % cut into trials
    Trials = chop_power_trials(Power, TrialsTable, CurrentTrials, TrialWindow, SampleRate);

    % pool sessions
    PooledTrials = cat(1, PooledTrials, Trials);
    AllRecordingPower = cat(3, AllRecordingPower, Power);
    PooledTrialsTable = cat(1, PooledTrialsTable, TrialsTable(CurrentTrials, :));
end
end


function LogPooledTrials = normalize_trials(PooledTrials, AllRecordingPower)
% Pooled Trials is T x Ch x F x t
% AllRecording is Ch x F x t

Mean = mean(log(AllRecordingPower), 3, 'omitnan');
LogPooledTrials = nan(size(PooledTrials));

PooledTrials = log(PooledTrials);

for idxTrial = 1:size(PooledTrials, 1)
    for idxFrequency = 1:size(PooledTrials, 3)
        LogPooledTrials(idxTrial, :, idxFrequency, :) = ...
            PooledTrials(idxTrial, :, idxFrequency, :)-Mean(:, idxFrequency)';
    end
end
end



function AveragedTrials = average_trial_types(Trials, TrialsTable, MaxNaNProportion, MinTrials)
% Trials is a T x F x t matrix
% AveragedTrials is a TT x F x t matrix

MaxGapProportion = .2;
TimepointsCount = size(Trials, 3);
FrequencyCount = size(Trials, 2);

AveragedTrials = nan(3, FrequencyCount, TimepointsCount);

for idxType = 1:3

    % select subset of trials
    TrialIndexes = TrialsTable.Type==idxType;
    TypeTrials = Trials(TrialIndexes, :, :);

    % remove trials without enough data
    TypeTrials = remove_trials_too_much_nan(TypeTrials, MaxNaNProportion);

    % average trials
    Average = squeeze(mean(TypeTrials, 1, 'omitnan')); % now F x t

    % remove timepoints made with average of too few trials
    TrialCount = size(TypeTrials, 1)-squeeze(sum(isnan(TypeTrials(:, 1, :)), 1)); % number of trials for each timepoint, excluding NaNs
    Average(:, TrialCount<MinTrials) = nan;

    % interpolate missing data
    MaxSize = size(Average, 2)*MaxGapProportion;
    for idxFrequency = 1:FrequencyCount
        Average(idxFrequency, :)  = close_small_gaps(Average(idxFrequency, :), MaxSize);
    end

    if isempty(Average) || any(isnan(Average(:)))
        AveragedTrials(idxType, :, :) = nan(1, TimepointsCount);
    else
        AveragedTrials(idxType, :, :) = Average;
    end
end


end

function TypeTrialData = remove_trials_too_much_nan(TypeTrialData, MaxNaNProportion)
% remove trials that are missing too much data in time
%TypeTrialData is Trials x F x time

TrialsTime = size(TypeTrialData, 3);
NanProportion = squeeze(sum(isnan(TypeTrialData(:, 1, :)), 3))./TrialsTime;
TypeTrialData(NanProportion>MaxNaNProportion, :, :) = [];

if any(NanProportion>MaxNaNProportion)
    a=1
end
end




function CleanTimepoints = check_eyes_open(CleanTimepoints, EyetrackingPath, ...
    EyetrackingQualityTable, ConfidenceThreshold, Participant, Session, SampleRate)

% load in data
Eyes = load_datafile(EyetrackingPath, Participant, Session, 'Eyes');
if isempty(Eyes)
    warning(['no eye data, so not using ', Participant, Session])
    CleanTimepoints = zeros(size(CleanTimepoints));
    return
end
Eyes = load_datafile(EyetrackingPath, Participant, Session, 'Eyes');

% identify eyes closed timepoints
CleanEyeIndex = EyetrackingQualityTable.(Session)(strcmp(EyetrackingQualityTable.Participant, Participant));
Eye = check_eye_dataquality(Eyes, CleanEyeIndex, ConfidenceThreshold, CleanTimepoints);
EyeClosed = detect_eyeclosure(Eye, SampleRate, ConfidenceThreshold);

% assign as artefect moments of eyes closed
if numel(EyeClosed) ~= numel(CleanTimepoints)
    error(['mismatch datapoints ', Participant, Session])
end
CleanTimepoints(EyeClosed==1) = 0;
end



function Trials = chop_power_trials(Power, TrialsTable, ...
    CurrentTrials, TrialWindow, SampleRate)

FrequencyCount = size(Power, 2);
ChannelCount = size(Power, 1);
TrialWindowTimepoints = SampleRate*(TrialWindow(2)-TrialWindow(1));

Trials = nan(nnz(CurrentTrials), ChannelCount,  FrequencyCount, TrialWindowTimepoints); % T x Ch x F x t

for idxFrequency = 1:FrequencyCount
    SingleFrequencyTimes = squeeze(Power(:, idxFrequency, :));

    Trials(:, :, idxFrequency, :) = chop_trials(SingleFrequencyTimes, SampleRate, ...
        TrialsTable.StimTimepoint(CurrentTrials), TrialWindow);
end
end

