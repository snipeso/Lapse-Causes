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
FooofFittingFrequencyRange = [1 40];
Refresh = false; % if analysis has already been run, set to false if you want to use the cache

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
Participants = {'P02', 'P03'};
Channels = Parameters.Channels.PreROI;
Bands = Parameters.Bands;
SessionBlocks = Parameters.Sessions.Conditions;
Labels = Parameters.Labels;
StatParameters = Parameters.Stats;

Source_EEG = fullfile(Paths.Data, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.AnalyzedData, 'EEG', 'Bursts_New', Task);
CacheDir = fullfile(Paths.Cache, mfilename);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% analysis

%%% Theta

[ThetaPowerIntactSpectrum, ThetaPowerBurstsSpectrum, ThetaPowerBurstlessSpectrum, Frequencies, ThetaTimeSpent] = ...
    whitened_burst_power_by_ROI(Source_EEG, Source_Bursts, Participants, SessionBlocks, Channels, 'Front', ...
    Bands, 'Theta', WelchWindow, Overlap, MinDuration, FooofFittingFrequencyRange, CacheDir, Refresh);

% get only SD session
SessionIndex = 2;
ThetaPowerIntactSpectrum = squeeze(ThetaPowerIntactSpectrum(:, SessionIndex, :));
ThetaPowerBurstlessSpectrum = squeeze(ThetaPowerBurstlessSpectrum(:, SessionIndex, :));
ThetaPowerBurstsSpectrum = squeeze(ThetaPowerBurstsSpectrum(:, SessionIndex, :));

% average theta power
ThetaPowerIntact = band_spectrum(ThetaPowerIntactSpectrum, Frequencies, Bands, 'last');
ThetaPowerIntact = ThetaPowerIntact(:, 1);
ThetaPowerBursts = band_spectrum(ThetaPowerBurstsSpectrum, Frequencies, Bands, 'last');
ThetaPowerBursts = ThetaPowerBursts(:, 1);
ThetaPowerBurstless = band_spectrum(ThetaPowerBurstlessSpectrum, Frequencies, Bands, 'last');
ThetaPowerBurstless = ThetaPowerBurstless(:, 1);

%%% Alpha

[AlphaPowerIntactSpectrum, AlphaPowerBurstsSpectrum, AlphaPowerBurstlessSpectrum, ~, AlphaTimeSpent] = ...
    whitened_burst_power_by_ROI(Source_EEG, Source_Bursts, Participants, SessionBlocks, Channels, 'Back', ...
    Bands, 'Alpha', WelchWindow, Overlap, MinDuration, FooofFittingFrequencyRange, CacheDir, Refresh);

% get only BL session
SessionIndex = 1;
AlphaPowerIntactSpectrum = squeeze(AlphaPowerIntactSpectrum(:, SessionIndex, :));
AlphaPowerBurstlessSpectrum = squeeze(AlphaPowerBurstlessSpectrum(:, SessionIndex, :));
AlphaPowerBurstsSpectrum = squeeze(AlphaPowerBurstsSpectrum(:, SessionIndex, :));

% average alpha power
AlphaPowerIntact = band_spectrum(AlphaPowerIntactSpectrum, Frequencies, Bands, 'last');
AlphaPowerIntact = AlphaPowerIntact(:, 2);
AlphaPowerBursts = band_spectrum(AlphaPowerBurstsSpectrum, Frequencies, Bands, 'last');
AlphaPowerBursts = AlphaPowerBursts(:, 2);
AlphaPowerBurstless = band_spectrum(AlphaPowerBurstlessSpectrum, Frequencies, Bands, 'last');
AlphaPowerBurstless = AlphaPowerBurstless(:, 2);


%% Statistics
%%%%%%%%%%%%%

clc

% percentage of periodic power reduction
% intact periodic power - burstless periodic power / intact periodic power
ThetaPercentReduction = 100*(ThetaPowerIntact - ThetaPowerBurstless)./ThetaPowerIntact;
descriptive_distribution(ThetaPercentReduction, 'Theta percent reduction', '%', 0);

AlphaPercentReduction = 100*(AlphaPowerIntact - AlphaPowerBurstless)./AlphaPowerIntact;
descriptive_distribution(AlphaPercentReduction, 'Alpha percent reduction', '%', 0);

% burst ratio power
% burstless periodic power / burst periodic power
ThetaBurstRatio = ThetaPowerBurstless./ThetaPowerBursts;
descriptive_distribution(ThetaBurst, 'Theta burst power ratio', '', 2);

AlphaBurstRatio = AlphaPowerBurstless./AlphaPowerBursts;
descriptive_distribution(AlphaBurst, 'Alpha burst power ratio', '', 2);




%%% Plot
%%%%%%%%%%%%%
%%
clc

Grid = [1 6];
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 18;
PlotProps.Axes.xPadding = 18;
PlotProps.HandleVisibility = 'on';
xLog = false;
xLims = [2 15];

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.35])

%%% change in quantities of bursts
XLabels = fieldnames(SessionBlocks);
Colors = PlotProps.Color.Participants(1:numel(Participants), :);

% theta
Data = 100*ThetaTimeSpent;

chART.sub_plot([], Grid, [1 1], [1 1], true, PlotProps.Indexes.Letters{1}, PlotProps);
Stats = plot_change_in_time(Data, XLabels, [], [0 100], Colors, StatParameters, PlotProps);
ylabel('% recording')
title('Theta bursts')

disp_stats(Stats, [2 2], 'Change in theta bursts with time awake')


% alpha
Data = 100*AlphaTimeSpent;

chART.sub_plot([], Grid, [1 1], [1 1], true, PlotProps.Indexes.Letters{1}, PlotProps);
Stats = plot_change_in_time(Data, XLabels, [], [0 100], Colors, StatParameters, PlotProps);
ylabel('% recording')
title('Alpha bursts')

disp_stats(Stats, [2 2], 'Change in alphs bursts with time awake')



%%% Change in whitened power spectra

% theta
Data = cat(2, ThetaPowerBurstlessSpectrum(:, 2, :), ThetaPowerIntactSpectrum(:, 2, :));

chART.sub_plot([], Grid, [1 3], [1 2], true, PlotProps.Indexes.Letters{3}, PlotProps);
plot_spectrum_increase(Data, Frequencies, xLog, xLims, PlotProps, Labels);
title('Power spectra without THETA bursts')
ylabel('Whitened Power (\muV^2/Hz)')


% alpha
Data = cat(2, AlphaPowerBurstlessSpectrum(:, 2, :), AlphaPowerIntactSpectrum(:, 2, :));

chART.sub_plot([], Grid, [1 5], [1 2], true, PlotProps.Indexes.Letters{4}, PlotProps);
plot_spectrum_increase(Data, Frequencies, xLog, xLims, PlotProps, Labels);
title('Power spectra without ALPHA bursts')
ylabel('Whitened Power (\muV^2/Hz)')

chART.save_figure('Figure_2', Paths.Results, PlotProps)



%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

%%%%%%%%%%%
%%% Analysis functions

function [PowerIntact, PowerBursts, PowerBurstless, Frequencies, TimeSpent] = ...
    whitened_burst_power_by_ROI(Source_EEG, Source_Bursts, Participants, SessionBlocks, Channels, ChannelFieldname, ...
    Bands, BandFieldname, WelchWindow, Overlap, MinDuration, FooofFittingFrequencyRange, CacheDir, Refresh)

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
        [Power, Freqs] = compute_whitened_power_ROI(EEGIntact, SampleRate, ...
            labels2indexes(ChannelIndexes, Chanlocs), WelchWindow, Overlap, FooofFittingFrequencyRange);

        % save to general matrix
        if ~exist('PowerIntact', 'var') && ~isempty(Freqs) % if first time calculating power
            PowerIntact = nan(numel(Participants), numel(SessionBlockLabels), numel(Freqs));
            PowerBurstless = PowerIntact;
            PowerBursts = PowerIntact;
        end

        PowerIntact(idxParticipant, idxSessionBlock, :) = Power;
        PowerBursts(idxParticipant, idxSessionBlock, :) = compute_whitened_power_ROI( ...
            EEGBursts, SampleRate, labels2indexes(ChannelIndexes, Chanlocs), ...
            WelchWindow, Overlap, FooofFittingFrequencyRange);
        PowerBurstless(idxParticipant, idxSessionBlock, :) = compute_whitened_power_ROI( ...
            EEGBurstless, SampleRate, labels2indexes(ChannelIndexes, Chanlocs), ...
            WelchWindow, Overlap, FooofFittingFrequencyRange);

        if ~isempty(Freqs)
            Frequencies = Freqs; % do this in case the last recording is empty
        end
    end
    disp(['Finished ', Participants{idxParticipant}])
end
end



function [EEGIntactAllSessions, EEGBurstsAllSessions, EEGBurstlessAllSessions] = chop_EEG_by_bursts( ...
    EEGAllSessions, BurstsAllSessions, Band, MinDuration)

Sessions = fieldnames(EEGAllSessions);
SampleRate = EEGAllSessions.(Sessions{1}).srate;

EEGIntactAllSessions = [];
EEGBurstsAllSessions = [];
EEGBurstlessAllSessions = [];

for Session = Sessions'
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


function [WhitenedPower, FooofFrequencies] = compute_whitened_power_ROI(EEGData, SampleRate, Channels, WelchWindow, Overlap, FooofFittingFrequencyRange)
if isempty(EEGData)
    WhitenedPower = nan;
    FooofFrequencies = [];
    return
end
[Power, Frequencies] = cycy.utils.compute_power(EEGData, SampleRate, WelchWindow, Overlap);
Power = mean(Power(Channels, :), 1);% select and average ROI

[WhitenedPower, FooofFrequencies] = whiten_spectrum(Power, Frequencies, FooofFittingFrequencyRange);
end
