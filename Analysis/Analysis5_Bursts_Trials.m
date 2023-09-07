% gets the data showing the probability of eyesclosed over time for each
% trial outcome type.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

OnlyClosestStimuli = true; % only use closest trials
CheckEyes = true; % only used eyes-open trials

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
MinTrials = Parameters.Trials.MinPerSubGroupCount;
Bands = Parameters.Bands;

EyetrackingPath = fullfile(Paths.Data, 'Pupils', ['Raw_', num2str(SampleRate), 'Hz'], Task);
TrialCacheDir = fullfile(Paths.Cache, 'Trial_Information');
CacheFilename = [Task, '_TrialsTable.mat'];

EyeclosureCacheDir = fullfile(Paths.Cache, 'Data_Figures');
if ~exist(EyeclosureCacheDir, 'dir')
    mkdir(EyeclosureCacheDir)
end

SessionBlockLabels = fieldnames(SessionBlocks);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

% get trial information
load(fullfile(TrialCacheDir, CacheFilename), 'TrialsTable')

EyetrackingQualityTable = readtable(fullfile(Paths.QualityCheck, 'EyeTracking', ...
    ['DataQuality_', Task, '_Pupils.csv']));

TrialTime = linspace(TrialWindow(1), TrialWindow(2), SampleRate*(TrialWindow(2)-TrialWindow(1))); % time vector
TotBands = numel(fieldnames(Bands));

% specify only close trials, or all trials
TitleTag = '';

if CheckEyes
    TitleTag = [TitleTag, '_EO'];
    EyesOpenTrials = Trials.EyesClosed == 0;
else
    EyesOpenTrials = true(size(Trials, 1), 1);
end

if OnlyClosestStimuli
    TitleTag = [ TitleTag, '_Close'];
    MaxStimulusDistance = quantile(TrialsTable.Radius, MaxStimulusDistance);
else
    MaxStimulusDistance = max(TrialsTable.Radius);
end



for idxSessionBlock = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = P.SessionBlocks.(SessionBlockLabels{idxSessionBlock});

    % set up blanks
    ProbBurstStimLockedTopography = nan(numel(Participants), 3, TotChannels, TotBands, numel(t_window)); % P x TT x Ch x B x t matrix with final probabilities
    ProbBurstRespLockedTopography = ProbBurstStimLockedTopography;

    ProbBurstStimLocked =  nan(numel(Participants), 3, TotBands, numel(t_window));  % P x TT x B x t
    ProbBurstRespLocked = ProbBurstStimLocked;

    ProbBurstTopography = zeros(numel(Participants), TotChannels, TotBands, 2); % get general probability of a burst for a given session block (to control for when z-scoring)
    ProbBurst = zeros(numel(Participants), TotBands, 2);

    for idxParticipant = 1:numel(Participants)


    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [PooledTrialsStim, PooledTrialsResp, PooledTrialsTable, BurstTimepointCount] = ...
    pool_burst_trials(TrialsTable, EyetrackingQualityTable, BurstDir, CheckEyes, ...
    Bands, EyesOpenTrials, EyetrackingDir, ...
    Participant, Sessions, MaxStimulusDistance, TrialWindow, Triggers, SampleRate, ConfidenceThreshold)
% EyeclosureTimepointCount is a 1 x 2 array indicating the total number of
% points in the pooled sessions that has eyes closed and the total number of
% points.

% initialize variables
PooledTrialsStim = [];
PooledTrialsResp = [];
PooledTrialsTable = table();

for idxSession = 1:numel(Sessions)

    % trial info for current recording
    CurrentTrials = strcmp(TrialsTable.Participant, Participant) & ...
        strcmp(TrialsTable.Session, Sessions{idxSession}) & ...
        TrialsTable.Radius < MaxStimulusDistance & EyesOpenTrials;

    % load in eye data
    Bursts = load_datafile(BurstDir, Participant, Sessions{idxSession}, 'Bursts');
    if isempty(Bursts); continue; end

    % identify task, artifact free, eyes open timepoints
    EEGMetadata = load_datafile(BurstDir, Participant, Sessions{idxSession}, 'EEGMetadata');
CleanTimepoints = EEGMetadata.CleanTaskTimepoints;
CleanTimepoints = check_eyes_open(CleanTimepoints, EyetrackingDir, ...
    EyetrackingQualityTable, ConfidenceThreshold, Participant, Session, SampleRate);

TotChannels = numel(EEGMetadata.chanlocs);
BurstTimes = bursts2time_all_channels(Bursts, Bands, TotChannels, CleanTimepoints);

    % chop into trials
    EyeClosedStimLocked = chop_trials(EyeClosed, SampleRate, TrialsTable.StimTimepoint(CurrentTrials), TrialWindow);
    EyeClosedRespLocked = chop_trials(EyeClosed, SampleRate, TrialsTable.RespTimepoint(CurrentTrials & TrialsTable.Type~=1), TrialWindow);

    % pool sessions
    PooledTrialsStim = cat(1, PooledTrialsStim,  EyeClosedStimLocked);
    PooledTrialsResp = cat(1, PooledTrialsResp, EyeClosedRespLocked);

    % pool info
    PooledTrialsTable = cat(1, PooledTrialsTable, TrialsTable(CurrentTrials, :)); % important that it be in the same order!
    BurstTimepointCount = tally_timepoints(BurstTimepointCount, EyeClosed);
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
if numel(EyeClosed) ~= CleanTimepoints
    error(['mismatch datapoints ', Participant, Session])
end
CleanTimepoints(EyeClosed==1) = 0;
end


function BurstTimes = bursts2time_all_channels(Bursts, Bands, TotChannels, CleanTimepoints)
% BurstTimes is a Ch x B x t matrix of 1s, zeros, and nans for when there
% are bursts.

Freqs = [Bursts.Frequency];
Channels = [Bursts.Channel];
Pnts = numel(CleanTimepoints);

BandLabels = fieldnames(Bands);
BurstTimes = zeros(TotChannels, numel(BandLabels), Pnts);

for Indx_B = 1:numel(BandLabels)
    for Indx_Ch = 1:TotChannels
        Band = Bands.(BandLabels{Indx_B});
        BT = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2) & ...
            Channels==Indx_Ch), Pnts);
        BT(not(CleanTimepoints)) = nan;
        BurstTimes(Indx_Ch, Indx_B, :) = BT;
    end
end
end


