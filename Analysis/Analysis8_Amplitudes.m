% script to assemble information about burst amplitudes related to trial
% outcome, when those bursts appear just before the stimulus. Parts of this
% didn't make it into the final paper.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

RerunAnalysis = true;
OnlyEyesOpen = true; % only use eyes-open trials
OnlyClosestStimuli = false; % only use closest trials (legacy, never used)
Window = [-1 0]; % only take bursts before stimulus, otherwise affected by how the stimulus affects the bursts

Parameters = analysisParameters();
Paths = Parameters.Paths;
Participants = Parameters.Participants;
Sessions = Parameters.Sessions;
MaxStimulusDistanceProportion = Parameters.Stimuli.MaxDistance;
SampleRate = Parameters.SampleRate;
Bands = Parameters.Bands;
BandLabels = fieldnames(Bands);
Task = Parameters.Task;

BurstDir = fullfile(Paths.AnalyzedData, 'EEG', 'Bursts_Lapse-Causes', Task);
DestinationCacheDir = fullfile(Paths.Cache, 'Data_Figures');


SessionBlocks = Parameters.Sessions.Conditions;
SessionBlockLabels = fieldnames(SessionBlocks);

Windows = Parameters.Trials.SubWindows;
WindowLabel = Parameters.Labels.TrialSubWindows;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Analysis


%%% load information trials
TrialCacheDir = fullfile(Paths.Cache, 'Trial_Information');
CacheFilename = 'LAT_TrialsTable.mat';
load(fullfile(TrialCacheDir, CacheFilename), 'TrialsTable')

% if requested, exclude trials during which eyes were closed during the
% stimulus window
[EyesOpenTrialIndexes, ~, TitleTag] = ...
    only_eyes_open_trials(TrialsTable, OnlyEyesOpen, Paths, Task);

% if requested, exclude furthest trials
[MaxStimulusDistance, TitleTag] = max_stimulus_distance(TrialsTable, ...
    OnlyClosestStimuli, MaxStimulusDistanceProportion, TitleTag);


% set up new trial table, to have a column for each window (not used in
% paper)
for Band = BandLabels'
    for Window = WindowLabel
        TrialsTable.(['Amp', Window{1} Band{1}]) = nan(size(TrialsTable, 1), 1);
    end
end

% assign unique ID to each trial, because multiple bursts come before same
% trial, and it's important to exclude data based on too few unique trials.
TrialsTable.UniqueTrial = transpose(1:size(TrialsTable, 1));


%%% get burst information
AllBurstsTable = table();
for idxParticipant = 1:numel(Participants)
    Participant = Participants{idxParticipant};

    for idxSessionBlock = 1:numel(SessionBlockLabels) % loop through BL and SD
        Sessions = SessionBlocks.(SessionBlockLabels{idxSessionBlock});

        for idxSession = 1:numel(Sessions)

            % trial info for current recording
            CurrentTrials = find(strcmp(TrialsTable.Participant, Participant) & ...
                strcmp(TrialsTable.Session, Sessions{idxSession}) & ...
                TrialsTable.Radius < MaxStimulusDistance & EyesOpenTrialIndexes);

            % load in eye data
            Bursts = load_datafile(BurstDir, Participant, Sessions{idxSession}, 'Bursts');
            if isempty(Bursts); continue; end

            % get average amplitudes of bursts of each band before each
            % trial
            for idxTrial = CurrentTrials'
                for idxBand = 1:numel(BandLabels)

                    for idxWindow = 1:size(Windows, 1)
                        Window = Windows(idxWindow, :);
                        WindowPoints = TrialsTable.StimTimepoint(idxTrial) + Window*SampleRate;

                        % get bursts within each window
                        BandBursts = find_band_bursts(Bursts, Bands.(BandLabels{idxBand}));
                        OverlapBursts = find_overlapping_bursts(BandBursts, WindowPoints(1), WindowPoints(2));
                        if isempty(OverlapBursts)
                            continue
                        end

                        % average amplitudes
                        Amplitudes = [OverlapBursts.Amplitude];
                        InWindow = [OverlapBursts.PeakInWindow]; % only consider peaks within the window, since the stimulus will affect the subsequent oscillations
                        TrialsTable.(['Amp', WindowLabel{idxWindow}, BandLabels{idxBand}])(idxTrial) = mean(Amplitudes(InWindow));

                        % assign trial type to burst structure
                        if idxWindow == 1 % only for pre
                            TrialOutcome = TrialsTable.Type(idxTrial);
                            EyesClosed = TrialsTable.EyesClosed(idxTrial);
                            RT = TrialsTable.RT(idxTrial);
                            Trial = TrialsTable.UniqueTrial(idxTrial);
                            AllBurstsTable = aggregate_burst_info(AllBurstsTable,  OverlapBursts, ...
                                Participant, idxSessionBlock, idxSession, idxBand, TrialOutcome, EyesClosed, ...
                                RT, Trial);
                        end
                    end
                end
            end
            disp(['finished ', Sessions{idxSession}])
        end
    end
    disp(['Finished ', Participant])
end

%%% save new trial table
save(fullfile(DestinationCacheDir, CacheFilename), 'TrialsTable', 'AllBurstsTable')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function OverlapBursts = find_band_bursts(Bursts, Band)
Frequencies = [Bursts.BurstFrequency];
KeepBurstIndexes = Frequencies>=Band(1) & Frequencies<Band(2);
OverlapBursts = Bursts(KeepBurstIndexes);
end


function OverlapBursts = find_overlapping_bursts(Bursts, StartWindow, EndWindow)
% select bursts that overlap with window, and identify the exact cycles in
% that window

Starts = [Bursts.Start];
Ends = [Bursts.End];

KeepBurstIndexes = Starts<EndWindow & Ends>StartWindow;
OverlapBursts = Bursts(KeepBurstIndexes);

% keep track only of cycles within the window
for idxBurst = 1:numel(OverlapBursts)
    Peaks = [OverlapBursts(idxBurst).NegPeakIdx];
    OverlapBursts(idxBurst).PeakInWindow = Peaks >= StartWindow & Peaks <= EndWindow;
end
end



function AllBurstTable = aggregate_burst_info(AllBurstTable, Bursts, Participant, ...
    idxSessionBlock, idxSession, idxBand, TrialOutcome, EyesClosed, RT, TrialID)

% information of bursts to average
KeepInfo = {'CyclesCount', 'Amplitude', 'BurstFrequency', 'DurationPoints', 'ChannelIndex', 'ChannelIndexLabel', 'Start'};
BurstTable = struct();
for idxBurst = 1:numel(Bursts)
    for Field = KeepInfo
        BurstTable(idxBurst).(Field{1}) = mean(Bursts(idxBurst).(Field{1}));
    end
end

% information on burst that is unique to each burst
BurstTable = struct2table(BurstTable);
nBursts = size(BurstTable, 1);
BurstTable.TrialType = repmat(TrialOutcome, nBursts, 1);
BurstTable.EyesClosed = repmat(EyesClosed, nBursts, 1);
BurstTable.Session = repmat(idxSession, nBursts, 1);
BurstTable.SessionBlock = repmat(idxSessionBlock, nBursts, 1);
BurstTable.Band = repmat(idxBand, nBursts, 1);
BurstTable.Participant = repmat(Participant, nBursts, 1);
BurstTable.RT = repmat(RT, nBursts, 1);
BurstTable.TrialID = repmat(TrialID, nBursts, 1);

% append to megatable
AllBurstTable = [AllBurstTable; BurstTable];
end

