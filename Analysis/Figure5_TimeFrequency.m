% plots the final exploratory analyses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% parameters

Parameters = analysisParameters();
Paths = Parameters.Paths;

Participants = Parameters.Participants;

SessionBlockLabels = {'BL', 'SD'};
CacheDir = fullfile(Paths.Cache, 'Data_Figures');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data

%%% don't check eyes (for timefrequency and topography)
AllTimeFrequencyEpochs = [];

for SBL = SessionBlockLabels
    load(fullfile(CacheDir, ['Power_', SBL{1}, '.mat']), ...
        'TimeFrequencyEpochs', 'Chanlocs', 'TrialTime', 'Frequencies')

    Data = permute(TimeFrequencyEpochs, [1 6, 2, 3, 4 5]);
    AllTimeFrequencyEpochs = cat(2, AllTimeFrequencyEpochs, Data); % P x S x TT x Ch x F x t
end

Channels = 1:numel(Chanlocs);
MeanChannelTF = squeeze(mean(AllTimeFrequencyEpochs(:, :, :, Channels, :, :), 4, 'omitnan'));


%%% check eyes (only topography EW)
load(fullfile(CacheDir, ['Power_', SessionBlockLabels{2}, '_EO.mat']), ...
    'TimeFrequencyEpochs')

TimeFrequencyEpochsEO = TimeFrequencyEpochs;

%%% amplitude data (already set for eyes-open).
CacheFilename = 'LAT_TrialsTable.mat';
load(fullfile(CacheDir, CacheFilename), 'AllBurstsTable')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot


%% Plot Main figure
% plotted in pieces, that I then assemble in powerpoint.

PlotProps = Parameters.PlotProps.Manuscript;
CLim = [-10 10];

%%% Time frequency

% BL fast trials
figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*.33, PlotProps.Figure.Height*.25])

SessionIdx = 1; % BL
TrialTypeIdx = 3; % fast
Data = squeeze(MeanChannelTF(:, SessionIdx, TrialTypeIdx, :, :));
Stats = ttest_timefrequency(Data, Parameters.Stats);
plot_timefrequency(Stats, TrialTime, Frequencies, CLim, PlotProps)
xlabel('')
title('BL fast trials', 'FontSize', PlotProps.Text.TitleSize)

chART.save_figure('Figure_Exploration_TF_BL', Paths.Results, PlotProps)

% EW slow trials
figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*.33, PlotProps.Figure.Height*.25])
SessionIdx = 2; % EW
TrialTypeIdx = 1; % lapse
Data = squeeze(MeanChannelTF(:, SessionIdx, TrialTypeIdx, :, :));
Stats = ttest_timefrequency(Data, Parameters.Stats);
plot_timefrequency(Stats, TrialTime, Frequencies, CLim, PlotProps)
title('EW lapse trials', 'FontSize', PlotProps.Text.TitleSize)

chART.save_figure('Figure_Exploration_TF_EW', Paths.Results, PlotProps)

% colorbar
figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*.33, PlotProps.Figure.Height*.25])
PlotProps.Colorbar.Location = 'southoutside';
chART.plot.pretty_colorbar('Divergent', CLim, 't-values', PlotProps)
chART.save_figure('Figure_Exploration_TF_colorbar', Paths.Results, PlotProps)


%%% topographies around lapses
%%
TopoPlotProps = Parameters.PlotProps.Manuscript;
TopoPlotProps.Axes.xPadding = 5;
TopoPlotProps.Axes.yPadding = 5;
TrialTypeIdx = 1; % lapse
SessionIdx = 2; % EW
CLim = [-6 6];

Windows = [-2, 0;
            0, .3];
WindowTitles = {["EW Lapses", "[-2, 0]"], ["EW Lapses","[0 0.3]"]};
BandRanges = [1, 4,  8, 15, 25;
    4, 8, 14, 25, 30];
BandLabels = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
nBands = size(BandRanges, 2);
nWindows = size(Windows, 1);
Grid = [nBands nWindows];
Windows = dsearchn(TrialTime', Windows(:));
Windows = reshape(Windows, nWindows, []);

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*.33, PlotProps.Figure.Height*.53])
for RangeIdx = 1:nBands
    for WindowIdx = 1:nWindows
    Range = dsearchn(Frequencies', BandRanges(:, RangeIdx));

    % plot not controlling eyes
     Data = TimeFrequencyEpochsEO(:, TrialTypeIdx, :, Range(1):Range(2), Windows(WindowIdx, 1):Windows(WindowIdx, 2));
     Data = squeeze(mean(mean(Data, 4, 'omitnan'), 5, 'omitnan')); % mean in frequency and in time

    chART.sub_plot([],  Grid, [RangeIdx WindowIdx], [], false, '', TopoPlotProps);
    paired_ttest_topography(zeros(size(Data)), Data, Chanlocs, CLim, Parameters.Stats, TopoPlotProps);
    colorbar off
    if WindowIdx ==1
    chART.plot.vertical_text(BandLabels{RangeIdx}, .15, .5, TopoPlotProps)
    end
    if RangeIdx==1
        % title('Lapses [-1 to 1 s]',  'FontSize', TopoPlotProps.Text.TitleSize)
         title(WindowTitles{WindowIdx},  'FontSize', TopoPlotProps.Text.TitleSize)
    end


    % % plot controlling eyes
    % Data = TimeFrequencyEpochsEO(:, TrialTypeIdx, :, Range(1):Range(2), Window(1):Window(2));
    % Data = squeeze(mean(mean(Data, 4, 'omitnan'), 5, 'omitnan')); % mean in frequency and in time
    % 
    % chART.sub_plot([],  Grid, [RangeIdx 2], [], false, '', TopoPlotProps);
    % paired_ttest_topography(zeros(size(Data)), Data, Chanlocs, CLim, Parameters.Stats, TopoPlotProps);
    % colorbar off
    % if RangeIdx==1
    %     title('Only EO', 'FontSize', TopoPlotProps.Text.TitleSize)
    % end
    end
end

chART.save_figure('Figure_Exploration_topopower', Paths.Results, PlotProps)


% colobar
figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*.33, PlotProps.Figure.Height*.25])
TopoPlotProps.Colorbar.Location = 'southoutside';
chART.plot.pretty_colorbar('Divergent', CLim, 't-values', TopoPlotProps)
chART.save_figure('Figure_Exploration_topopower_colorbar', Paths.Results, PlotProps)


%%
clc

%%% lapses by amplitude quantiles
SessionLabels = {'BL', 'EW'};
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding=30;
PlotProps.Axes.xPadding = 20;
Grid = [2 2];

BandLabels = {'Theta', 'Alpha'};
nQuantiles = 10;
MinTotalBursts = 10;
MinTotalTrials = Parameters.Trials.MinPerSubGroupCount;

% calculate proportion of bursts that anticipate a lapse for each quantile
[LapseProbabilityBursts, Amplitudes, RTs] = lapse_probability_by_quantile(AllBurstsTable, Participants, nQuantiles, MinTotalBursts, MinTotalTrials);

%%% plot
figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*.45, PlotProps.Figure.Height*.6])
for idxBand = 1:numel(BandLabels)
    for idxSession = 1:2

        % prepare data
        Data = squeeze(LapseProbabilityBursts(:, idxSession, idxBand, :));
        zData = zScoreData(Data, 'first');
        Stats = paired_ttest(zData, [], Parameters.Stats);
         disp_stats(Stats, [1 nQuantiles], BandLabels{idxBand});
         disp_stats_descriptive(100*Data(:, 1), 'Q1:', '%', 0);
         disp_stats_descriptive(100*Data(:, end), 'Qend:', '%', 0);

        % plot
        chART.sub_plot([], Grid, [idxSession, idxBand], [], false, '', PlotProps);
        chART.plot.individual_rows(zData, Stats, string(1:nQuantiles), [.75, 2.75], PlotProps, PlotProps.Color.Participants);
        ylim([-2.5 4.2])
        if idxSession == 1
            title(BandLabels{idxBand})
        else
            xlabel('Burst amplitudes (\muV)')
        end

        if idxBand == 1
            ylabel([SessionLabels{idxSession}, ' lapse likelihood (z-scored)'])
        end

        % display amplitudes of quantiles
        Amps = squeeze(Amplitudes(:, idxSession, idxBand, :));
        xticklabels(round(mean(Amps, 1, 'omitnan')))
        for idxQuantile = 1:nQuantiles
            disp_stats_descriptive(Amps(:, idxQuantile), [SessionLabels{idxSession}, ' ', BandLabels{idxBand}, ' Q', num2str(idxQuantile)], 'miV', 0);
        end
    end
end

chART.save_figure('Figure_Exploration_Amplitudes', Paths.Results, PlotProps)


%% provide actual average change in lapse proportion to have a feel how big the effect really is
clc
SessionIdx = 2; % only for EW for sanity

disp('increase in lapses during EW: ')
for BandIdx = 1:2
    % Data = squeeze(LapseProbabilityBursts(:, SessionIdx, BandIdx, [1 end]));
    % disp_stats_descriptive(diff(Data, 1, 2)*100, BandLabels{BandIdx}, '%', 0);

     Data = squeeze(LapseProbabilityBursts(:, SessionIdx, BandIdx, :));
    Stats = paired_ttest(Data, [], Parameters.Stats);
    disp_stats(Stats, [1 nQuantiles], BandLabels{BandIdx});
end


%% Suppl figure of all time-frequency plots

Channels = 1:numel(Chanlocs);
MeanChannelTF = squeeze(mean(AllTimeFrequencyEpochs(:, :, :, Channels, :, :), 4, 'omitnan'));

Grid = [2 4];
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 25;
PlotProps.Color.Steps.Divergent = 100;
StartPoint = dsearchn(TrialTime', 0);
YLims = [-.1 .1];
TrialTypes = { 'Lapse', 'Slow', 'Fast'};
CLim = [-10 10];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.45])
for SessionIdx = 1:2
    FigureIdx = 1;
    for TrialTypeIdx = 3:-1:1
        if TrialTypeIdx < 3
            Letter2 = '';
        end

        %%% plot time-frequency
        chART.sub_plot([], Grid, [SessionIdx FigureIdx], [], true, '', PlotProps);
        FigureIdx = FigureIdx+1;
        Data = squeeze(MeanChannelTF(:, SessionIdx, TrialTypeIdx, :, :));
        Stats = ttest_timefrequency(Data, Parameters.Stats);
        plot_timefrequency(Stats, TrialTime, Frequencies, CLim, PlotProps)
        if SessionIdx ==1
            title(TrialTypes{TrialTypeIdx})
            xlabel('')
        end
        if TrialTypeIdx < 3
            ylabel('')
        elseif TrialTypeIdx == 3
            chART.plot.vertical_text(SessionLabels{SessionIdx}, .35, .5, PlotProps)
        end
    end
end

Axes = chART.sub_plot([], Grid, [SessionIdx 4], [2, 1], false, '', PlotProps);
chART.plot.pretty_colorbar('Divergent', CLim, 't-values', PlotProps)
axis off
chART.save_figure('Figure_All_TimeFrequency', Paths.Results, PlotProps)



%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [LapseProbability, Amplitudes, RTs] = lapse_probability_by_quantile(AllBurstsTable, Participants, nQuantiles, MinBurstsQuantile, MinTrials)
% sorts bursts into quantiles by amplitude, and identifies how many of
% those result in a lapse. Also provides RTs for funzies.

AllBurstsTable(AllBurstsTable.EyesClosed==1, :) = [];

LapseProbability = nan(numel(Participants), 2, 2, nQuantiles);
Amplitudes = LapseProbability;
RTs = LapseProbability;


for idxParticipant = 1:numel(Participants)
    for idxBand = 1:2

        % for quality check: see if effect holds with constant quantiles
        % BurstIndexes = strcmp(string(AllBurstsTable.Participant), Participants{idxParticipant}) & ...
        %     AllBurstsTable.Band==idxBand;
        % Bursts = AllBurstsTable(BurstIndexes, :);
        % Quantiles = quantile(Bursts.Amplitude, linspace(0, 1, nQuantiles+1));

        for idxSession = 1:2
            BurstIndexes = strcmp(string(AllBurstsTable.Participant), Participants{idxParticipant}) & ...
                AllBurstsTable.SessionBlock==idxSession & AllBurstsTable.Band==idxBand;
            Bursts = AllBurstsTable(BurstIndexes, :);

            if size(Bursts, 1) < MinBurstsQuantile
                LapseProbability(idxParticipant, idxSession, idxBand, idxQuantile) = nan;
                Amplitudes(idxParticipant, idxSession, idxBand, idxQuantile) = nan;
                RTs(idxParticipant, idxSession, idxBand, idxQuantile) = nan;
                continue
            end

            % % assign bursts to quantiles
            Quantiles = quantile(Bursts.Amplitude, linspace(0, 1, nQuantiles+1));
            BinnedBursts = discretize(Bursts.Amplitude, Quantiles);

            % get lapse probability by quantile
            for idxQuantile = 1:nQuantiles
                QuantileBurstTypes = Bursts.TrialType(BinnedBursts==idxQuantile);
                TrialIDs = Bursts.TrialID(BinnedBursts==idxQuantile);

                if numel(QuantileBurstTypes) < MinBurstsQuantile || numel(unique(TrialIDs)) < MinTrials
                    continue
                end

                LapseProbability(idxParticipant, idxSession, idxBand, idxQuantile) = ...
                    nnz(QuantileBurstTypes==1)/numel(QuantileBurstTypes);

                Amplitudes(idxParticipant, idxSession, idxBand, idxQuantile) = ...
                    mean(Bursts.Amplitude(BinnedBursts==idxQuantile));

                RTs(idxParticipant, idxSession, idxBand, idxQuantile) = ...
                    mean(Bursts.RT(BinnedBursts==idxQuantile));
            end
        end
    end
end
end


%%%%%%%%%%%%%%%%%
%%% plots

function plot_timefrequency(Stats, Time, Frequencies, CLim, PlotProps)

% plot t-values
Data = Stats.t;
hold on
contourf(Time, Frequencies, Data, PlotProps.Color.Steps.Divergent,  'linecolor','none')
colormap(PlotProps.Color.Maps.Divergent)
chART.set_axis_properties(PlotProps)

% plot statistics mask
Dims = size(Data);
Mask = zeros(Dims);
Mask(~Stats.sig) = 0.65;
image(Time, Frequencies, 0.95*ones(Dims(1), Dims(2), 3), 'AlphaData', Mask)

% set limits and labels
if isempty(CLim)
    Quantiles = quantile(Data(:), [.1 .99]);
    Lim = max(abs(Quantiles));
    CLim = [-Lim Lim];
end
clim(CLim)
ylim([Frequencies(1), Frequencies(end)])
xlabel('Time (s)')
ylabel('Frequency (Hz)')
set(gca, 'TickDir', 'in')

% stim start line
plot([0 0], Frequencies([1 end]),  'Color', 'k', 'LineWidth',PlotProps.Line.Width/2, 'HandleVisibility', 'off')
end
