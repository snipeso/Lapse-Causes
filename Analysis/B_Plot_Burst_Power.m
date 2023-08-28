% Evaluates the quality of the burst detection, by plotting the change in
% spectrum of the data with and without bursts, and providing ratios
% quantifying how much power was captured by the bursts.
clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% parameters

WelchWindow = 8;
Overlap = .75;
MinDuration = 60;
SmoothSpan = 2;
Refresh = false; % if analysis has already been run, set to false if you want to use the cache

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
Channels = Parameters.Channels.PreROI;
Bands = Parameters.Bands;
SessionBlocks = Parameters.Sessions.Conditions;

Source_EEG = fullfile(Paths.Data, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.AnalyzedData, 'EEG', 'Bursts_New', Task);
CacheDir = fullfile(Paths.Cache, mfilename);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% analysis


[ThetaPowerIntact, ThetaPowerBursts, ThetaPowerBurstless, Frequencies, ThetaTimeSpent] = ...
    burst_power_by_ROI(Source_EEG, Source_Bursts, Participants, SessionBlocks, Channels, 'Front', ...
    Bands, 'Theta', WelchWindow, Overlap, MinDuration, CacheDir, Refresh);



[AlphaPowerIntact, AlphaPowerBursts, AlphaPowerBurstless, ~, AlphaTimeSpent] = ...
    burst_power_by_ROI(Source_EEG, Source_Bursts, Participants, SessionBlocks, Channels, 'Back', ...
    Bands, 'Alpha', WelchWindow, Overlap, MinDuration, CacheDir, Refresh);








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [PowerIntact, PowerBursts, PowerBurstless, Frequencies, TimeSpent] = ...
    burst_power_by_ROI(Source_EEG, Source_Bursts, Participants, SessionBlocks, Channels, ChannelFieldname, ...
    Bands, BandFieldname, WelchWindow, Overlap, MinDuration, CacheDir, Refresh)

Band = Bands.(BandFieldname);
SessionBlockLabels = fieldnames(SessionBlocks);
ChannelIndexes = Channels.(ChannelFieldname);

%%% cache

% location of cache
CacheString = strjoin({'burst_power_by_ROI', Source_EEG, ChannelFieldname, BandFieldname, num2str(WelchWindow), ...
    num2str(Overlap), num2str(MinDuration)}, '_');
CacheString = [replace(CacheString, '.', '-'), '.mat'];
CachePath = fullfile(CacheDir, CacheString);

% load from cache
if exist(CachePath, 'file') && ~Refresh
    load(CachePath, 'PowerIntact', 'PowerBursts', 'PowerBurstless', 'Frequencies', 'TimeSpent')
    return
end

if ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end

%%% run analysis
TimeSpent = nan(numel(Participants), numel(SessionBlockLabels));
for idxParticipant = 1:numel(Participants)
    Participant = Participants{idxParticipant};
    for idxSessionBlock = 1:numel(SessionBlockLabels)
        SessionBlock = SessionBlocks.(SessionBlockLabels{idxSessionBlock});

        % load data from all sessions
        [EEGAllSessions, BurstsAllSessions] = load_sessionblock_data( ...
            Source_Bursts, Source_EEG, Participant, SessionBlock, 'BurstClusters');
                SampleRate = EEGAllSessions.(SessionBlock{1}).srate;
        Chanlocs = EEGAllSessions.(SessionBlock{1}).chanlocs;

        % cut up data based on whether there were bursts or not
        [EEGIntact, EEGBursts, EEGBurstless] = chop_EEG_by_bursts( ...
            EEGAllSessions, BurstsAllSessions, Band, MinDuration);

        % determine how much time was spent in each band
        TotalTime = size(EEGIntact, 2)/SampleRate;
        BurstTime = size(EEGBursts, 2)/SampleRate;
        TimeSpent(idxParticipant, idxSessionBlock) = BurstTime/TotalTime;

        % calculate power for the selected region of interest
        [Power, Freqs] = compute_power_ROI(EEGIntact, SampleRate, ...
            labels2indexes(ChannelIndexes, Chanlocs), WelchWindow, Overlap);

        % save to general matrix
        if ~exist('PowerIntact', 'var') && ~isempty(Freqs) % if first time calculating power
            PowerIntact = nan(numel(Participants), numel(SessionBlockLabels), numel(Freqs));
            PowerBurstless = PowerIntact;
            PowerBursts = PowerIntact;
        end

        PowerIntact(idxParticipant, idxSessionBlock, :) = Power;
        PowerBursts(idxParticipant, idxSessionBlock, :) = compute_power_ROI( ...
            EEGBursts, SampleRate, labels2indexes(ChannelIndexes, Chanlocs), ...
            WelchWindow, Overlap);
        PowerBurstless(idxParticipant, idxSessionBlock, :) = compute_power_ROI( ...
            EEGBurstless, SampleRate, labels2indexes(ChannelIndexes, Chanlocs), ...
            WelchWindow, Overlap);

        if ~isempty(Freqs)
            Frequencies = Freqs; % do this in case the last recording is empty
        end
    end
end
end



function [EEGIntact, EEGBursts, EEGBurstless] = chop_EEG_by_bursts( ...
    EEGAllSessions, BurstsAllSessions, Band, MinDuration)

Sessions = fieldnames(EEGAllSessions);
SampleRate = EEGAllSessions.(Sessions{1}).srate;

EEGIntact = [];
EEGBursts = [];
EEGBurstless = [];

for Session = Sessions'
    EEGIntact = cat(2, EEGIntact, EEGAllSessions.(Session{1}).data);

    % get bursts of relevant band
    BurstFrequencies = [BurstsAllSessions.(Session{1}).BurstFrequency];
    BurstsInRangeIndexes = Band(1) <= BurstFrequencies & ...
        BurstFrequencies < Band(2);
    Bursts = BurstsAllSessions.(Session{1})(BurstsInRangeIndexes);

    % remove timepoints with bursts
    ChoppedEEG = pop_select(EEGAllSessions.(Session{1}), ...
        'nopoint', [[Bursts.Start]', [Bursts.End]']);
    EEGBurstless = cat(2, EEGBurstless, ChoppedEEG.data);

    % remove timepoints without bursts
    ChoppedEEG = pop_select(EEGAllSessions.(Session{1}), ...
        'point', [[Bursts.Start]', [Bursts.End]']);
    EEGBursts = cat(2, EEGBursts, ChoppedEEG.data);
end

%%% remove artefact timepoints
EEGIntact(:, any(isnan(EEGIntact), 1)) = [];
EEGBursts(:, any(isnan(EEGBursts), 1)) = [];
EEGBurstless(:, any(isnan(EEGBurstless), 1)) = [];


%%% check minimum duration
if size(EEGBursts, 2) < SampleRate*MinDuration
    EEGBursts = [];
end

if size(EEGBurstless, 2) < SampleRate*MinDuration
    EEGBurstless = [];
end
end


function [Power, Frequencies] = compute_power_ROI(EEGData, SampleRate, Channels, WelchWindow, Overlap)
if isempty(EEGData)
    Power = nan;
    Frequencies = [];
    return
end
[Power, Frequencies] = cycy.utils.compute_power(EEGData, SampleRate, WelchWindow, Overlap);
Power = mean(Power(Channels, :), 1);% select and average ROI
end

