% Evaluates the quality of the burst detection, by plotting the change in
% spectrum of the data with and without bursts, and providing ratios
% quantifying how much power was captured by the bursts.
clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% parameters

WelchWindow = 8;
Overlap = .5;
MinDuration = 60;
FooofFittingFrequencyRange = [2 40]; % some low-frequency noise
RerunAnalysis = false; % if analysis has already been run, set to false if you want to use the cache

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
Channels = Parameters.Channels.PreROI;
Bands = Parameters.Bands;
SessionBlocks = Parameters.Sessions.Conditions;
Labels = Parameters.Labels;
StatParameters = Parameters.Stats;
SampleRate = Parameters.SampleRate;

SourceEEG = fullfile(Paths.Data, 'Clean', 'Waves', Task);
SourceBursts = fullfile(Paths.AnalyzedData, 'EEG', 'Bursts_Lapse-Causes', Task);
ScriptName = 'Plot2_BurstDetection';
CacheDir = fullfile(Paths.Cache, ScriptName);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% analysis


%%% Theta
[ThetaPowerIntactSpectrum, ThetaPowerBurstsSpectrum, ThetaPowerBurstlessSpectrum, Frequencies, ThetaTimeSpent] = ...
    whitened_burst_power_by_ROI(SourceEEG, SourceBursts, Participants, SessionBlocks, 2, Channels, 'Front', ...
    Bands, 'Theta', WelchWindow, Overlap, MinDuration, FooofFittingFrequencyRange, SampleRate, CacheDir, RerunAnalysis);

% average theta power
BandIndex = 1;
[ThetaPowerIntact, ~, ThetaPowerBurstless] = ...
    average_band(ThetaPowerIntactSpectrum, ThetaPowerBurstsSpectrum, ThetaPowerBurstlessSpectrum, ...
    Frequencies, Bands, BandIndex);

%%
%%% Alpha
[AlphaPowerIntactSpectrum, AlphaPowerBurstsSpectrum, AlphaPowerBurstlessSpectrum, ~, AlphaTimeSpent] = ...
    whitened_burst_power_by_ROI(SourceEEG, SourceBursts, Participants, SessionBlocks, 1, Channels, 'Back', ...
    Bands, 'Alpha', WelchWindow, Overlap, MinDuration, FooofFittingFrequencyRange, SampleRate, CacheDir, RerunAnalysis);
%%

% average alpha power
BandIndex = 2;
[AlphaPowerIntact, ~, AlphaPowerBurstless] = ...
    average_band(AlphaPowerIntactSpectrum, AlphaPowerBurstsSpectrum, AlphaPowerBurstlessSpectrum, ...
    Frequencies, Bands, BandIndex);


% burst properties
[BurstAmplitudes, BurstDurations] = burst_properties(SourceBursts, ...
    Participants, SessionBlocks, Bands, SampleRate, CacheDir, RerunAnalysis);

%%

%%% Plot
%%%%%%%%%%%%%

clc

Grid = [2 3];
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 30;
PlotProps.Axes.xPadding = 30;
PlotProps.HandleVisibility = 'on';
xLog = false;
xLims = [3 17];

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width*.75, PlotProps.Figure.Height*.5])

%%% change in quantities of bursts
XLabels = fieldnames(SessionBlocks);
Colors = PlotProps.Color.Participants(1:numel(Participants), :);

% theta
Data = 100*ThetaTimeSpent;

chART.sub_plot([], Grid, [1 1], [1 1], true, PlotProps.Indexes.Letters{1}, PlotProps);
Stats = plot_change_in_time(Data, XLabels, [], [0 100], Colors, StatParameters, PlotProps);
ylabel('% recording')
title('Theta bursts')

disp_stats(Stats, [1 2], 'Change in theta bursts with time awake');


% alpha
Data = 100*AlphaTimeSpent;

chART.sub_plot([], Grid, [2 1], [1 1], true, PlotProps.Indexes.Letters{3}, PlotProps);
Stats = plot_change_in_time(Data, XLabels, [], [0 100], Colors, StatParameters, PlotProps);
title('Alpha bursts')
ylabel('% recording')

disp_stats(Stats, [1 2], 'Change in alpha bursts with time awake');



%%% Change in whitened power spectra

% theta
Data = cat(2, permute(ThetaPowerBurstlessSpectrum, [1 3 2]), permute(ThetaPowerIntactSpectrum, [1 3 2]));

chART.sub_plot([], Grid, [1 2], [1 2], true, PlotProps.Indexes.Letters{2}, PlotProps);
plot_spectrum_increase(Data, Frequencies, xLog, xLims, PlotProps, Labels);
legend({'Individual', 'Group average'})
set(legend, 'ItemTokenSize', [10 10])
title('Theta burst power')
ylabel('Periodic power (\muV^2/Hz)')
ylim([-.5 19])

% alpha
Data = cat(2, permute(AlphaPowerBurstlessSpectrum, [1 3 2]), permute(AlphaPowerIntactSpectrum, [1 3 2]));

chART.sub_plot([], Grid, [2 2], [1 2], true, PlotProps.Indexes.Letters{4}, PlotProps);
plot_spectrum_increase(Data, Frequencies, xLog, xLims, PlotProps, Labels);
title('Alpha burst power')
ylabel('Periodic power (\muV^2/Hz)')
ylim([-.5 12])

chART.save_figure('Figure_2', Paths.Results, PlotProps)


%% single participant

P = 7;

figure
plot_spectrum_increase(Data(7, :, :), Frequencies, xLog, xLims, PlotProps, Labels);

%% Statistics
%%%%%%%%%%%%%

clc

% percentage of periodic power reduction
% intact periodic power - burstless periodic power / intact periodic power
ThetaPercentReduction = 100*(ThetaPowerIntact - ThetaPowerBurstless)./ThetaPowerIntact;
disp_stats_descriptive(ThetaPercentReduction, 'Theta percent reduction', '%', 0);

AlphaPercentReduction = 100*(AlphaPowerIntact - AlphaPowerBurstless)./AlphaPowerIntact;
disp_stats_descriptive(AlphaPercentReduction, 'Alpha percent reduction', '%', 0);


%% burst descriptives
clc

BandLabels = fieldnames(Bands);
SessionLabels = fieldnames(SessionBlocks);


for idxBand = 1:2
    for idxSessionBlock = 1:2
        disp_stats_descriptive(squeeze(BurstAmplitudes(:, idxSessionBlock, idxBand)), ...
            [BandLabels{idxBand}, ' ', SessionLabels{idxSessionBlock}], ' miV', 0);

        disp_stats_descriptive(squeeze(BurstDurations(:, idxSessionBlock, idxBand)), ...
            [BandLabels{idxBand}, ' ', SessionLabels{idxSessionBlock}], ' s', 2);
    end
end

%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

%%%%%%%%%%%
%%% Analysis functions

function [PowerIntactSpectrum, PowerBurstsSpectrum, PowerBurstlessSpectrum, ...
    Frequencies, TimeSpent] = whitened_burst_power_by_ROI(Source_EEG, Source_Bursts, ...
    Participants, SessionBlocks, SessionIndex, Channels, ChannelFieldname, ...
    Bands, BandFieldname, WelchWindow, Overlap, MinDuration, ...
    FooofFittingFrequencyRange, SampleRate, CacheDir, RerunAnalysis)

Band = Bands.(BandFieldname);
SessionBlockLabels = fieldnames(SessionBlocks);
ChannelIndexes = Channels.(ChannelFieldname);

%%% cache
% location of cache
CacheString = strjoin({'burst_power_by_ROI', ...
    SessionBlockLabels{SessionIndex}, ...
    ChannelFieldname, ...
    BandFieldname, ...
    num2str(WelchWindow), ...
    num2str(Overlap), ...
    num2str(MinDuration)}, '_');
CacheString = [replace(CacheString, '.', '-'), '.mat'];
CachePath = fullfile(CacheDir, CacheString);

% load from cache
if exist(CachePath, 'file') && ~RerunAnalysis
    load(CachePath, 'PowerIntactSpectrum', 'PowerBurstsSpectrum', 'PowerBurstlessSpectrum', 'Frequencies', 'TimeSpent')
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
        Chanlocs = EEGAllSessions.(SessionBlock{1}).chanlocs;

        % cut up data based on whether there were bursts or not
        [EEGIntact, EEGBursts, EEGBurstless] = chop_EEG_by_bursts( ...
            EEGAllSessions, BurstsAllSessions, Band, MinDuration, SampleRate);

        % determine how much time was spent in each band
        TotalTime = size(EEGIntact, 2)/SampleRate;
        BurstTime = size(EEGBursts, 2)/SampleRate;
        TimeSpent(idxParticipant, idxSessionBlock) = BurstTime/TotalTime;

        % calculate power for the selected region of interest
        [Power, Freqs] = compute_whitened_power_ROI(EEGIntact, SampleRate, ...
            labels2indexes(ChannelIndexes, Chanlocs), WelchWindow, Overlap, FooofFittingFrequencyRange);

        % save to general matrix
        if ~exist('PowerIntactSpectrum', 'var') && ~isempty(Freqs) % if first time calculating power
            PowerIntactSpectrum = nan(numel(Participants), numel(SessionBlockLabels), numel(Freqs));
            PowerBurstlessSpectrum = PowerIntactSpectrum;
            PowerBurstsSpectrum = PowerIntactSpectrum;
        end

        PowerIntactSpectrum(idxParticipant, idxSessionBlock, :) = Power;
        PowerBurstsSpectrum(idxParticipant, idxSessionBlock, :) = compute_whitened_power_ROI( ...
            EEGBursts, SampleRate, labels2indexes(ChannelIndexes, Chanlocs), ...
            WelchWindow, Overlap, FooofFittingFrequencyRange);
        PowerBurstlessSpectrum(idxParticipant, idxSessionBlock, :) = compute_whitened_power_ROI( ...
            EEGBurstless, SampleRate, labels2indexes(ChannelIndexes, Chanlocs), ...
            WelchWindow, Overlap, FooofFittingFrequencyRange);

        if ~isempty(Freqs)
            Frequencies = Freqs; % do this in case the last recording is empty
        end
    end
    disp(['Finished ', Participants{idxParticipant}])
end

% select only power spectra of interest
PowerIntactSpectrum = squeeze(PowerIntactSpectrum(:, SessionIndex, :));
PowerBurstlessSpectrum = squeeze(PowerBurstlessSpectrum(:, SessionIndex, :));
PowerBurstsSpectrum = squeeze(PowerBurstsSpectrum(:, SessionIndex, :));

% save to cache for future
save(CachePath, 'PowerIntactSpectrum', 'PowerBurstsSpectrum', 'PowerBurstlessSpectrum', 'Frequencies', 'TimeSpent')
end


function [EEGIntactAllSessions, EEGBurstsAllSessions, EEGBurstlessAllSessions] = chop_EEG_by_bursts( ...
    EEGAllSessions, BurstsAllSessions, Band, MinDuration, SampleRate)

Sessions = fieldnames(EEGAllSessions);

EEGIntactAllSessions = [];
EEGBurstsAllSessions = [];
EEGBurstlessAllSessions = [];

for Session = Sessions'
    if isempty(EEGAllSessions.(Session{1}))
        continue
    end
    EEGIntact = EEGAllSessions.(Session{1}).data;
    EEGIntactAllSessions = cat(2, EEGIntactAllSessions, EEGIntact);

    [EEGBursts, EEGBurstless] = split_eeg_by_bursts(EEGIntact, BurstsAllSessions.(Session{1}), Band);

    EEGBurstsAllSessions = cat(2, EEGBurstsAllSessions, EEGBursts);
    EEGBurstlessAllSessions = cat(2, EEGBurstlessAllSessions, EEGBurstless);
end

%%% remove artefact timepoints
EEGIntactAllSessions(:, any(isnan(EEGIntactAllSessions), 1)) = [];
EEGBurstsAllSessions(:, any(isnan(EEGBurstsAllSessions), 1)) = [];
EEGBurstlessAllSessions(:, any(isnan(EEGBurstlessAllSessions), 1)) = [];


%%% check minimum duration
if size(EEGBurstsAllSessions, 2) < SampleRate*MinDuration
    EEGBurstsAllSessions = [];
end

if size(EEGBurstlessAllSessions, 2) < SampleRate*MinDuration
    EEGBurstlessAllSessions = [];
end
end


function [EEGBursts, EEGBurstless] = split_eeg_by_bursts(EEGData, Bursts, Band)

% get bursts of relevant band
BurstFrequencies = [Bursts.BurstFrequency];
BurstsInRangeIndexes = Band(1) <= BurstFrequencies & ...
    BurstFrequencies < Band(2);
Bursts = Bursts(BurstsInRangeIndexes);

% identify timepoints with bursts
TimepointsCount = size(EEGData, 2);
BurstTimepoints = windows2array([Bursts.ClusterStart], [Bursts.ClusterEnd], TimepointsCount);

% split EEG data accordingly
EEGBursts = EEGData(:, BurstTimepoints);
EEGBurstless = EEGData(:, ~BurstTimepoints);

end


function [WhitenedPower, FooofFrequencies] = compute_whitened_power_ROI( ...
    EEGData, SampleRate, Channels, WelchWindow, Overlap, FooofFittingFrequencyRange)
if isempty(EEGData)
    WhitenedPower = nan;
    FooofFrequencies = [];
    return
end
[Power, Frequencies] = cycy.utils.compute_power(EEGData(Channels, :), SampleRate, WelchWindow, Overlap);
Power = mean(Power, 1); % select and average ROI

% smooth data, because otherwise sometimes fooof doesn't work :(
SmoothSpan = 2;
Power = cycy.utils.smooth_spectrum(Power, Frequencies, SmoothSpan);
[WhitenedPower, FooofFrequencies] = whiten_spectrum(Power, Frequencies, FooofFittingFrequencyRange);
end


function [PowerIntact, PowerBursts, PowerBurstless] = ...
    average_band(PowerIntactSpectrum, PowerBurstsSpectrum, PowerBurstlessSpectrum, ...
    Frequencies, Bands, BandIndex)
PowerIntact = band_spectrum(PowerIntactSpectrum, Frequencies, Bands, 'last');
PowerIntact = PowerIntact(:, BandIndex);
PowerBursts = band_spectrum(PowerBurstsSpectrum, Frequencies, Bands, 'last');
PowerBursts = PowerBursts(:, BandIndex);
PowerBurstless = band_spectrum(PowerBurstlessSpectrum, Frequencies, Bands, 'last');
PowerBurstless = PowerBurstless(:, BandIndex);
end


function [BurstAmplitudes, BurstDurations] = burst_properties(SourceBursts, ...
    Participants, SessionBlocks, Bands, SampleRate, CacheDir, RerunAnalysis)

BandLabels = fieldnames(Bands);
SessionBlockLabels = fieldnames(SessionBlocks);

% location of cache
CacheString = 'burst_properties.mat';
CachePath = fullfile(CacheDir, CacheString);

% load from cache
if exist(CachePath, 'file') && ~RerunAnalysis
    load(CachePath, 'BurstAmplitudes', 'BurstDurations')
    return
end

%%% load burst data
BurstAmplitudes = nan(numel(Participants), numel(SessionBlockLabels), 2); % P x S x B
BurstDurations = BurstAmplitudes;

for idxParticipant = 1:numel(Participants)
    Participant = Participants{idxParticipant};
    for idxSessionBlock = 1:numel(SessionBlockLabels)

        % load in burst data
        SessionBlock = SessionBlocks.(SessionBlockLabels{idxSessionBlock});
        [~, BurstsAllSessions] = load_sessionblock_data(SourceBursts, [], ...
            Participant, SessionBlock, 'Bursts');

        % concatenate all data from session block
        Bursts = struct();
        for Session = fieldnames(BurstsAllSessions)'
            Bursts = cat_struct(Bursts, BurstsAllSessions.(Session{1}));
        end

        Freqs = [Bursts.BurstFrequency];

        for idxBand = 1:numel(BandLabels)

            % select bursts of band
            Band = Bands.(BandLabels{idxBand});
            BurstsBand = Bursts(Freqs>=Band(1) & Freqs<Band(2));

            % assemble properties of bursts
            Amplitudes = [BurstsBand.Amplitude];
            if isempty(Amplitudes)
                continue
            end
            BurstAmplitudes(idxParticipant, idxSessionBlock, idxBand) = mean(Amplitudes);
            BurstDurations(idxParticipant, idxSessionBlock, idxBand) = mean([BurstsBand.DurationPoints]/SampleRate);
        end
    end
    disp(['Finished ', Participant])
end

save(CachePath, 'BurstAmplitudes', 'BurstDurations')
end

