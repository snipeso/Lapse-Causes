clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

RerunAnalysis = true;
OnlyEyesOpen = false; % only used eyes-open trials
OnlyClosestStimuli = false; % only use closest trials


Parameters = analysisParameters();
Paths = Parameters.Paths;
Participants = Parameters.Participants;
Sessions = Parameters.Sessions;
TrialWindow = Parameters.Trials.SubWindows(2, :);
MinEventProportion = Parameters.Trials.MinEventProportion;
MaxStimulusDistanceProportion = Parameters.Stimuli.MaxDistance;
MaxNanProportion = Parameters.Trials.MaxNaNProportion;
Triggers = Parameters.Triggers;
SampleRate = Parameters.SampleRate;
ConfidenceThreshold = Parameters.EyeTracking.MinConfidenceThreshold;
Bands = Parameters.Bands;
BandLabels = fieldnames(Bands);
Task = 'LAT';
BurstDir = fullfile(Paths.AnalyzedData, 'EEG', 'Bursts_Lapse-Causes', Task);

SessionBlocks = Parameters.Sessions.Conditions;
SessionBlockLabels = fieldnames(SessionBlocks);
Window = [-1 0];
% Window = [.5 1.5];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% if already assembled, load from cache
TrialCacheDir = fullfile(Paths.Cache, 'Trial_Information');
CacheFilename = 'LAT_TrialsTable.mat';
load(fullfile(TrialCacheDir, CacheFilename), 'TrialsTable')

BurstsCacheDir = fullfile(Paths.Cache, 'Data_Figures');

% if requested, exclude trials during which eyes were closed during the
% stimulus window
[EyesOpenTrialIndexes, EyetrackingQualityTable, TitleTag] = ...
    only_eyes_open_trials(TrialsTable, OnlyEyesOpen, Paths, Task);


% if requested, exclude furthest trials
[MaxStimulusDistance, TitleTag] = max_stimulus_distance(TrialsTable, ...
    OnlyClosestStimuli, MaxStimulusDistanceProportion, TitleTag);

%%% get burst information

for Band = BandLabels'
    TrialsTable.(['Amplitude', Band{1}]) = nan(size(TrialsTable, 1), 1);
end

AllBurstsTable = table();
for idxParticipant = 1:numel(Participants)
    for idxSessionBlock = 1:numel(SessionBlockLabels) % loop through BL and SD

        Sessions = SessionBlocks.(SessionBlockLabels{idxSessionBlock});
        for idxSession = 1:numel(Sessions)
            Participant = Participants{idxParticipant};

            % trial info for current recording
            CurrentTrials = find(strcmp(TrialsTable.Participant, Participant) & ...
                strcmp(TrialsTable.Session, Sessions{idxSession}) & ...
                TrialsTable.Radius < MaxStimulusDistance & EyesOpenTrialIndexes);

            % load in eye data
            Bursts = load_datafile(BurstDir, Participant, Sessions{idxSession}, 'Bursts');
            if isempty(Bursts); continue; end

            % identify task, artifact free, eyes open timepoints
            EEGMetadata = load_datafile(BurstDir, Participant, Sessions{idxSession}, 'EEGMetadata');
            SampleRate = EEGMetadata.srate;

            % get average amplitudes of bursts of each band before each
            % trial

            for idxTrial = CurrentTrials'
                for idxBand = 1:numel(BandLabels)
                    WindowPoints = TrialsTable.StimTimepoint(idxTrial) + Window*SampleRate;

                    OverlapBursts = find_overlapping_bursts(Bursts, WindowPoints(1), WindowPoints(2));
                    BandBursts = find_band_bursts(OverlapBursts, Bands.(BandLabels{idxBand}));
                    if isempty(BandBursts)
                        continue
                    end

                    TrialsTable.(['Amplitude', BandLabels{idxBand}])(idxTrial) = mean([BandBursts.Amplitude]);

                    % assign trial type to burst structure
                    TrialOutcome = TrialsTable.Type(idxTrial);
                    EyesClosed = TrialsTable.EyesClosed(idxTrial);
                    RT = TrialsTable.RT(idxTrial);
                    AllBurstsTable = aggregate_burst_info(AllBurstsTable,  BandBursts, ...
                        Participant, idxSessionBlock, idxSession, idxBand, TrialOutcome, EyesClosed, ...
                        RT);
                end
            end

        end
    end
    disp(['Finished ', Participant])
end

%%% save new trial table
save(fullfile(BurstsCacheDir, CacheFilename), 'TrialsTable', 'AllBurstsTable')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function OverlapBursts = find_overlapping_bursts(Bursts, StartWindow, EndWindow)

Starts = [Bursts.Start];
Ends = [Bursts.End];

KeepBurstIndexes = Starts<EndWindow & Ends>StartWindow;
OverlapBursts = Bursts(KeepBurstIndexes);
end

function OverlapBursts = find_band_bursts(Bursts, Band)

Frequencies = [Bursts.BurstFrequency];

KeepBurstIndexes = Frequencies>=Band(1) & Frequencies<Band(2);
OverlapBursts = Bursts(KeepBurstIndexes);
end

function AllBurstTable = aggregate_burst_info(AllBurstTable, Bursts, Participant, ...
    idxSessionBlock, idxSession, idxBand, TrialOutcome, EyesClosed, RT)

KeepInfo = {'CyclesCount', 'Amplitude', 'BurstFrequency', 'DurationPoints', 'ChannelIndex', 'ChannelIndexLabel', 'Start'};

BurstTable = struct();
for idxBurst = 1:numel(Bursts)
    for Field = KeepInfo
        BurstTable(idxBurst).(Field{1}) = mean(Bursts(idxBurst).(Field{1}));
    end
end

BurstTable = struct2table(BurstTable);
nBursts = size(BurstTable, 1);
BurstTable.TrialType = repmat(TrialOutcome, nBursts, 1);
BurstTable.EyesClosed = repmat(EyesClosed, nBursts, 1);
BurstTable.Session = repmat(idxSession, nBursts, 1);
BurstTable.SessionBlock = repmat(idxSessionBlock, nBursts, 1);
BurstTable.Band = repmat(idxBand, nBursts, 1);
BurstTable.Participant = repmat(Participant, nBursts, 1);
BurstTable.RT = repmat(RT, nBursts, 1);

AllBurstTable = [AllBurstTable; BurstTable];
end

