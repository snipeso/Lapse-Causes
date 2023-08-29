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

Source_EEG = fullfile(Paths.Data, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.AnalyzedData, 'EEG', 'Bursts_New', Task);
CacheDir = fullfile(Paths.Cache, mfilename);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% analysis

% get power values
[ThetaPowerIntact, ThetaPowerBursts, ThetaPowerBurstless, Frequencies, ThetaTimeSpent] = ...
    whitened_burst_power_by_ROI(Source_EEG, Source_Bursts, Participants, SessionBlocks, Channels, 'Front', ...
    Bands, 'Theta', WelchWindow, Overlap, MinDuration, FooofFittingFrequencyRange, CacheDir, Refresh);

% [AlphaPowerIntact, AlphaPowerBursts, AlphaPowerBurstless, ~, AlphaTimeSpent] = ...
%     whitened_burst_power_by_ROI(Source_EEG, Source_Bursts, Participants, SessionBlocks, Channels, 'Back', ...
%     Bands, 'Alpha', WelchWindow, Overlap, MinDuration, FooofFittingFrequencyRange, CacheDir, Refresh);


%% Statistics
%%%%%%%%%%%%%

% percentage of periodic power reduction
% intact periodic power - burstless periodic power / intact periodic power



% burst ratio power
% burstless periodic power / burst periodic power




%%% Plot
%%%%%%%%%%%%%


%%
Grid = [1 5];
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 18;
PlotProps.Axes.xPadding = 18;
PlotProps.HandleVisibility = 'on';
xLog = false;
xLims = [2 14];

chART.sub_plot([], Grid, [1 1], [1 2], true, PlotProps.Indexes.Letters{1}, PlotProps);
Data = cat(2, ThetaPowerIntact(:, 2, :), ThetaPowerBurstless(:, 2, :));
plotSpectrumMountains(Data, Frequencies, xLog, xLims, PlotProps, P.Labels);



%%
clc

Grid = [1 5];
PlotProps = P.Manuscript;
PlotProps.Axes.yPadding = 18;
PlotProps.Axes.xPadding = 18;
PlotProps.HandleVisibility = 'on';
xLog = true;
xLims = [2 30];
yLims = [-2.4 2.4];

NormBand = [1 4];
NormBand_Indx = dsearchn(Freqs, NormBand');

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.35])

%%% A: theta
SB = 2;
B_Indx = 1;
Ch_Indx = 1;


Data = log(squeeze(ChData(:, SB, [B_Indx, 3], Ch_Indx, :)));

Delta = squeeze(mean(Data(:, 1, NormBand_Indx(1):NormBand_Indx(2)), 3, 'omitnan'));
Shift = Delta - mean(Delta, 'omitnan');
Data = Data - Shift;

subfigure([], Grid, [1 1], [1 2], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotSpectrumMountains(Data, Freqs', xLog, xLims, PlotProps, P.Labels);

% plot also BL theta, with all bursts
BL = squeeze(mean(log(ChData(:, 1, 1, Ch_Indx, :))-Shift, 1, 'omitnan'));
hold on
plot(log(Freqs), BL, ...
    'Color', PlotProps.Color.Generic, 'LineStyle','--', 'LineWidth', 1)

ylim(yLims)
legend({'', 'Front SD theta burst power', 'Front BL power'}, 'location', 'southwest')
set(legend, 'ItemTokenSize', [15 15])
ylabel('Log PSD amplitude (\muV^2/Hz)')

disp(['A: N = ', num2str(nnz(~any(any(isnan(Data), 3), 2)))])

%%% B: alpha
SB = 1;
B_Indx = 2;
Ch_Indx = 3;

Data = log(squeeze(ChData(:, SB, [B_Indx, 3], Ch_Indx, :)));

Delta = squeeze(mean(Data(:, 1, NormBand_Indx(1):NormBand_Indx(2)), 3, 'omitnan'));
Shift = Delta - mean(Delta, 'omitnan');
Data = Data - Shift;

subfigure([], Grid, [1 3], [1 2], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotSpectrumMountains(Data, Freqs', xLog, xLims, PlotProps, P.Labels);
legend({'', 'Back BL alpha burst power'}, 'location', 'southwest')
set(legend, 'ItemTokenSize', [15 15])
ylim(yLims)

Legend = [append(BandLabels, ' bursts'), 'Both'];
YLim = [0 100];

ThetaColor = getColors(1, '', 'red');
AlphaColor = getColors(1, '', 'yellow');
Colors = [ThetaColor; AlphaColor; getColors(1, '', 'orange')];

disp(['B: N = ', num2str(nnz(~any(any(isnan(Data), 3), 2)))])


%%% C: stacked bar plot for time spent
Data = 100*squeeze(mean(TimeSpent, 1, 'omitnan'));

subfigure([], Grid, [1 5], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotStackedBars(Data(:, [1 3 2]), SB_Labels, YLim, Legend([1 3 2]), Colors([1 3 2], :), PlotProps);

ylabel('Recording duration (%)')

disp(['C: N = ', num2str(nnz(~any(any(isnan(TimeSpent), 3), 2)))])


saveFig('Figure_2', Paths.PaperResults, PlotProps)






%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

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
