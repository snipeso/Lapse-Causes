% gets the data showing the probability of eyesclosed over time for each
% trial outcome type.

clear
clc
% close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

OnlyClosestStimuli = false; % only use closest trials
CheckEyes = true; % only used eyes-open trials
ChannelsCount = 123;

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

EyetrackingDir = fullfile(Paths.Data, 'Pupils', ['Raw_', num2str(SampleRate), 'Hz'], Task);
BurstDir = fullfile(Paths.AnalyzedData, 'EEG', 'Bursts_New', Task);
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

TrialTime = linspace(TrialWindow(1), TrialWindow(2), SampleRate*(TrialWindow(2)-TrialWindow(1))); % time vector
TotBands = numel(fieldnames(Bands));

% specify only close trials, or all trials
TitleTag = '';

if CheckEyes
    TitleTag = [TitleTag, '_EO'];
    EyesOpenTrials = TrialsTable.EyesClosed == 0;
    EyetrackingQualityTable = readtable(fullfile(Paths.QualityCheck, 'EyeTracking', ...
        ['DataQuality_', Task, '_Pupils.csv']));
else
    EyesOpenTrials = true(size(TrialsTable, 1), 1);
    EyetrackingQualityTable = [];
end

if OnlyClosestStimuli
    TitleTag = [ TitleTag, '_Close'];
    MaxStimulusDistance = quantile(TrialsTable.Radius, MaxStimulusDistance);
else
    MaxStimulusDistance = max(TrialsTable.Radius);
end



for idxSessionBlock = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = SessionBlocks.(SessionBlockLabels{idxSessionBlock});

    % set up blanks
    ProbBurstStimLockedTopography = nan(numel(Participants), 3, ChannelsCount, TotBands, numel(TrialTime)); % P x TT x Ch x B x t matrix with final probabilities
    ProbBurstRespLockedTopography = ProbBurstStimLockedTopography;

    ProbBurstStimLocked =  nan(numel(Participants), 3, TotBands, numel(TrialTime));  % P x TT x B x t
    ProbBurstRespLocked = ProbBurstStimLocked;

    ProbabilityBurstTopography = zeros(numel(Participants), ChannelsCount, TotBands, 2); % get general probability of a burst for a given session block (to control for when z-scoring)
    ProbabilityBurst = zeros(numel(Participants), TotBands, 2);

    for idxParticipant = 1:numel(Participants)
        [PooledTrialsStim, PooledTrialsResp, PooledTrialsTable, BurstProbability, Chanlocs] = ...
            pool_burst_trials(TrialsTable, EyetrackingQualityTable, BurstDir, ...
            Bands, EyesOpenTrials, EyetrackingDir, Participants{idxParticipant}, Sessions, MaxStimulusDistance, ...
            TrialWindow, SampleRate, ConfidenceThreshold);


        if isempty(PooledTrialsTable)
            warning('empty table')
            continue
        end

        [ProbBurstStimLocked(idxParticipant, :, :, :), ProbBurstStimLockedTopography(idxParticipant, :, :, :, :)] = ...
            probability_burst_by_outcome(PooledTrialsStim, PooledTrialsTable, MaxNaNProportion, MinTrials, false);

        [ProbBurstRespLocked(idxParticipant, :, :, :), ProbBurstRespLockedTopography(idxParticipant, :, :, :, :)] = ...
            probability_burst_by_outcome(PooledTrialsResp, PooledTrialsTable(PooledTrialsTable.Type~=1, :), MaxNaNProportion, MinTrials, true);

        % calculate general probability of a burst
        ProbabilityBurst(idxParticipant, :, :) = BurstProbability; % TODO RENAME

        disp(['Finished ', Participants{idxParticipant}])
    end

    %%% save
    save(fullfile(EyeclosureCacheDir, ['Bursts_', SessionBlockLabels{idxSessionBlock}, TitleTag, '.mat']), ...
        'ProbBurstRespLockedTopography', 'ProbBurstStimLockedTopography', ...
        'ProbBurstStimLocked', 'ProbBurstRespLocked', 'Chanlocs', ...
        'TrialTime', 'ProbabilityBurst', 'ProbabilityBurstTopography')
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [PooledTrialsStim, PooledTrialsResp, PooledTrialsTable, BurstProbability, Chanlocs] = ...
    pool_burst_trials(TrialsTable, EyetrackingQualityTable, BurstDir, ...
    Bands, EyesOpenTrials, EyetrackingDir, Participant, Sessions, MaxStimulusDistance, ...
    TrialWindow, SampleRate, ConfidenceThreshold)
% EyeclosureTimepointCount is a 1 x 2 array indicating the total number of
% points in the pooled sessions that has eyes closed and the total number of
% points.

% initialize variables
PooledTrialsStim = [];
PooledTrialsResp = [];
PooledTrialsTable = table();

AllBurstTimes = [];

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

    if ~isempty(EyetrackingQualityTable)
        CleanTimepoints = check_eyes_open(CleanTimepoints, EyetrackingDir, ...
            EyetrackingQualityTable, ConfidenceThreshold, Participant, Sessions{idxSession}, SampleRate);
    end

    % determine when there is a burst
    TotChannels = numel(EEGMetadata.chanlocs);
    BurstTimes = bursts2time_all_channels(Bursts, Bands, TotChannels, CleanTimepoints);
    AllBurstTimes = cat(3, AllBurstTimes, BurstTimes);

    % cut into trials
    [TrialsStim, TrialsResp] = chop_bands_trials(BurstTimes, TrialsTable, CurrentTrials, TrialWindow, SampleRate);

    % pool sessions
    PooledTrialsStim = cat(1, PooledTrialsStim,  TrialsStim);
    PooledTrialsResp = cat(1, PooledTrialsResp, TrialsResp);

    % pool info
    % [BurstCountTopography, BurstCount] = overall_burst_probability(BurstTimes, BurstCountTopography, BurstCount);
    PooledTrialsTable = cat(1, PooledTrialsTable, TrialsTable(CurrentTrials, :));
end

BurstProbability = overall_burst_probability2(AllBurstTimes);

Chanlocs = EEGMetadata.chanlocs;

end

function BurstProbability = overall_burst_probability2(AllBurstTimes)


ChannelCount = size(AllBurstTimes, 1);
% NaNs = isnan(AllBurstTimes(1, 1, :));

BurstGlobality = squeeze(sum(AllBurstTimes, 1)./ChannelCount);

BurstProbability = cat(2, mean(BurstGlobality, 2, 'omitnan'), std(BurstGlobality, [], 2, 'omitnan')); % rename to burstprob
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


function BurstTimes = bursts2time_all_channels(Bursts, Bands, TotChannels, CleanTimepoints)
% BurstTimes is a Ch x B x t matrix of 1s, zeros, and nans for when there
% are bursts.

Freqs = [Bursts.BurstFrequency];
Channels = [Bursts.ChannelIndex];
Pnts = numel(CleanTimepoints);

BandLabels = fieldnames(Bands);
BurstTimes = zeros(TotChannels, numel(BandLabels), Pnts);

for Indx_B = 1:numel(BandLabels)
    for Indx_Ch = 1:TotChannels
        Band = Bands.(BandLabels{Indx_B});
        BurstTimeSingleBand = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2) & ...
            Channels==Indx_Ch), Pnts);
        BurstTimeSingleBand(not(CleanTimepoints)) = nan;
        BurstTimes(Indx_Ch, Indx_B, :) = BurstTimeSingleBand;
    end
end
end


function [TrialsStim, TrialsResp] = chop_bands_trials(BurstTimes, TrialsTable, ...
    CurrentTrials, TrialWindow, SampleRate)

BandCount = size(BurstTimes, 2);
ChannelCount = size(BurstTimes, 1);
TrialWindowTimepoints = SampleRate*(TrialWindow(2)-TrialWindow(1));

TrialsStim = nan(nnz(CurrentTrials), ChannelCount,  BandCount, TrialWindowTimepoints); % T x Ch x B x t
TrialsResp = nan(nnz(CurrentTrials&TrialsTable.Type~=1), ChannelCount,  BandCount, TrialWindowTimepoints);

for idxBand = 1:BandCount
    SingleBandTimes = squeeze(BurstTimes(:, idxBand, :));

    TrialsStim(:, :, idxBand, :) = chop_trials(SingleBandTimes, SampleRate, ...
        TrialsTable.StimTimepoint(CurrentTrials), TrialWindow);

    TrialsResp(:, :, idxBand, :) = chop_trials(SingleBandTimes, SampleRate, ...
        TrialsTable.RespTimepoint(CurrentTrials & TrialsTable.Type~=1), TrialWindow);
end
end


function [ProbBurstTopography, ProbBurst] = overall_burst_probability(BurstTimes, ProbBurstTopography, ProbBurst)

ChannelCount = size(BurstTimes,1);

for idxBand = 1:size(BurstTimes, 2)
    SingleBandTimes = squeeze(BurstTimes(:, idxBand, :));
    NaNs = isnan(SingleBandTimes(1, :));

    % get general probability of bursts by band
    ProbBurstTopography(:, idxBand, :) = ...
        tally_timepoints(squeeze(ProbBurstTopography(:, idxBand, :)), SingleBandTimes);

    % SingleBandTimesPooled = double(squeeze(any(SingleBandTimes==1, 1))); % TODO: sum
    SingleBandTimesPooled = squeeze(sum(SingleBandTimes==1, 1)./ChannelCount);

    SingleBandTimesPooled(NaNs) = nan; % make sure that artefacts are nans and not 0s
    ProbBurst(idxBand, :) = tally_timepoints(ProbBurst(idxBand, :), SingleBandTimesPooled);
end
end


function [ProbabilityBurst, ProbabilityBurstTopography] = probability_burst_by_outcome(Trials, TrialsTable, MaxNaNProportion, MinTrials, onlyResponses)

BandsCount = size(Trials, 3);
ChannelCount = size(Trials, 2);
TimeCount = size(Trials, 4);

ProbabilityBurst = nan(3, BandsCount, TimeCount);
ProbabilityBurstTopography = nan(3, ChannelCount, BandsCount, TimeCount);

for idxBand = 1:BandsCount

    % run separately for each channel
    for idxChannel = 1:ChannelCount
        ProbabilityBurstTopography(:, idxChannel,  idxBand, :) = probability_of_event_by_outcome( ...
            squeeze(Trials(:, idxChannel, idxBand, :)), TrialsTable, MaxNaNProportion, MinTrials, onlyResponses);
    end

    TrialsPooled = pool_channels(squeeze(Trials(:, :, idxBand, :)));

    % run on pooled data
    ProbabilityBurst(:, idxBand, :) = probability_of_event_by_outcome( ...
        TrialsPooled, TrialsTable, MaxNaNProportion, MinTrials, onlyResponses);
end
end


function PooledTrials = pool_channels(Trials)
% Trials is a Tr x Ch x t boolean, returns a Tr x t boolean, with nans

ChannelCount = size(Trials, 2);
% PooledTrials = double(squeeze(any(Trials==1, 2)));
PooledTrials = squeeze(sum(Trials==1, 2)./ChannelCount);
Nans = squeeze(isnan(Trials(:, 1, :)));

PooledTrials(Nans) = nan;
end
