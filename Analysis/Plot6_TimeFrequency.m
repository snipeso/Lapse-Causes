clear
clc
close all
Parameters = analysisParameters();
Paths = Parameters.Paths;

Participants = Parameters.Participants;

CheckEyes = false; % check if person had eyes open or closed
Closest = false; % only use closest trials

SessionBlockLabels = {'BL', 'SD'};
CacheDir = fullfile(Paths.Cache, 'Data_Figures');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data

%%% don't check eyes (for TF and topo)
AllTimeFrequencyEpochs = [];

for SBL = SessionBlockLabels
    load(fullfile(CacheDir, ['Power_', SBL{1}, '.mat']), ...
        'TimeFrequencyEpochs', 'Chanlocs', 'TrialTime', 'Frequencies')

    Data = permute(TimeFrequencyEpochs, [1 6, 2, 3, 4 5]);
    AllTimeFrequencyEpochs = cat(2, AllTimeFrequencyEpochs, Data); % P x S x TT x Ch x F x t
end

Channels = 1:numel(Chanlocs);
MeanChannelTF = squeeze(mean(AllTimeFrequencyEpochs(:, :, :, Channels, :, :), 4, 'omitnan'));


%%% check eyes (only topo SD)
load(fullfile(CacheDir, ['Power_', SessionBlockLabels{2}, '_EO.mat']), ...
    'TimeFrequencyEpochs')

TimeFrequencyEpochsEO = TimeFrequencyEpochs;

%%% amplitude data
CacheFilename = 'LAT_TrialsTable.mat';
load(fullfile(CacheDir, CacheFilename), 'AllBurstsTable')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plot


%% Plot Main figure

PlotProps = Parameters.PlotProps.Manuscript;
MegaGrid = [1 3];
CLim = [-10 10];

PlotProps.Colorbar.Location = 'southoutside';


figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*1.3, PlotProps.Figure.Height*.7])


%%% Time frequency
miniGrid = [2 1];
Space = set_sub_figure(MegaGrid, [1 1], PlotProps, 'A');

% BL fast
chART.sub_plot(Space, miniGrid, [1 1], [], true, '', PlotProps);
SessionIdx = 1; % BL
TrialTypeIdx = 3; % fast
Data = squeeze(MeanChannelTF(:, SessionIdx, TrialTypeIdx, :, :));
Stats = ttest_timefrequency(Data, Parameters.Stats);
plot_timefrequency(Stats, TrialTime, Frequencies, CLim, PlotProps)
set(gca, 'Units', 'pixels')
Position = get(gca, 'Position');
Position(2) = Position(2)+65;
Position(4) = 290;
xlabel('')
set(gca, 'position', Position)
Position = get(gca, 'Position');
title('BL fast trials', 'FontSize', PlotProps.Text.TitleSize)

% SD lapses
chART.sub_plot(Space, miniGrid, [2 1], [], true, '', PlotProps);
SessionIdx = 2; % SD
TrialTypeIdx = 1; % lapse
Data = squeeze(MeanChannelTF(:, SessionIdx, TrialTypeIdx, :, :));
Stats = ttest_timefrequency(Data, Parameters.Stats);
plot_timefrequency(Stats, TrialTime, Frequencies, CLim, PlotProps)
set(gca, 'Units', 'pixels')
Position = get(gca, 'Position');
Position(2) = Position(2)+80;
Position(4) = 290;
set(gca, 'position', Position)
Position = get(gca, 'Position');
title('SD lapse trials', 'FontSize', PlotProps.Text.TitleSize)

Axes1 = chART.sub_plot(Space, miniGrid, [2 1], [], true, '', PlotProps);
chART.plot.pretty_colorbar('Divergent', CLim, 't-values', PlotProps)



%%% topographiesTopoPlotProps = Parameters.PlotProps.Manuscript;
TopoPlotProps.Axes.xPadding = 5;
TopoPlotProps.Axes.yPadding = 5;
TrialTypeIdx = 1; % lapse
SessionIdx = 2;
CLim = [-6 6];

Window = [-1; 1];
Ranges = [1, 4,  8, 15, 25;
    4, 8, 14, 25, 30];
BandLabels = {'Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'};
nBands = size(Ranges, 2);

miniGrid = [nBands 2];
Space = set_sub_figure(MegaGrid, [1 2], TopoPlotProps, 'B');
Space(2) = 70;
Space(4) = Space(4)-40;
Window = dsearchn(TrialTime', Window);

for RangeIdx = 1:nBands
    Range = dsearchn(Frequencies', Ranges(:, RangeIdx));

    % plot not controlling eyes
    Data = AllTimeFrequencyEpochs(:, SessionIdx, TrialTypeIdx, :, Range(1):Range(2), Window(1):Window(2));
    Data = squeeze(mean(mean(Data, 5, 'omitnan'), 6, 'omitnan')); % mean in frequency and in time

    chART.sub_plot(Space,  miniGrid, [RangeIdx 1], [], false, '', TopoPlotProps);
    paired_ttest_topography(zeros(size(Data)), Data, Chanlocs, CLim, Parameters.Stats, TopoPlotProps);
    colorbar off
    chART.plot.vertical_text(BandLabels{RangeIdx}, .15, .5, TopoPlotProps)
    if RangeIdx==1
        title('-1 to 1 s',  'FontSize', TopoPlotProps.Text.TitleSize)
    end


    % plot controlling eyes
    Data = TimeFrequencyEpochsEO(:, TrialTypeIdx, :, Range(1):Range(2), Window(1):Window(2));
    Data = squeeze(mean(mean(Data, 4, 'omitnan'), 5, 'omitnan')); % mean in frequency and in time

    chART.sub_plot(Space,  miniGrid, [RangeIdx 2], [], false, '', TopoPlotProps);
    paired_ttest_topography(zeros(size(Data)), Data, Chanlocs, CLim, Parameters.Stats, TopoPlotProps);
    colorbar off
    if RangeIdx==1
        title('Only EO', 'FontSize', TopoPlotProps.Text.TitleSize)
    end
end


% plot colobar at bottom
TopoPlotProps.Colorbar.Location = 'southoutside';
Axes = chART.sub_plot(Space, miniGrid, [nBands 1], [1 2], false, '', TopoPlotProps);
Axes.Units = 'pixels';
Axes.Position(2) = 20;
chART.plot.pretty_colorbar('Divergent', CLim, 't-values', TopoPlotProps)
Axes.Position(4) = 100;

Axes1.Units = 'pixels';
Axes1.Position(2) = Axes.Position(2);
Axes1.Position(4) = Axes.Position(4);


%%% lapses by quantiles
BandLabels = {'Theta', 'Alpha'};
Space = set_sub_figure(MegaGrid, [1 3], TopoPlotProps, 'C');
Space(2) = 70;
Space(4) = Space(4)-40;
nQuantiles = 5;

[LapseProbabilityBursts, RTs] = lapse_probability_by_quantile(AllBurstsTable, Participants, nQuantiles);

miniGrid = [2 2];
PlotProps = Parameters.PlotProps.Manuscript;

for idxBand = 1:numel(BandLabels)

    for idxSession = 1:2
        chART.sub_plot(Space, miniGrid, [idxSession, idxBand], [], true, '', PlotProps);
        Data = squeeze(LapseProbabilityBursts(:, idxSession, idxBand, :));
        zData = zScoreData(Data, 'first');
        Stats = paired_ttest(zData, [], Parameters.Stats);
        chART.plot.individual_rows(zData, Stats, string(1:nQuantiles), [], PlotProps, PlotProps.Color.Participants);

        if idxSession == 1
            title(BandLabels{idxBand})
        else
            xlabel('Amplitude quantile')
        end

        if idxBand == 1
            ylabel([SessionBlockLabels{idxSession}, ' lapse likelihood'])
        end
    end
end

chART.save_figure(['Figure_Exploration'], Paths.Results, PlotProps)




%%

Channels = 1:numel(Chanlocs);
MeanChannelTF = squeeze(mean(AllTimeFrequencyEpochs(:, :, :, Channels, :, :), 4, 'omitnan'));

Grid = [2 4];
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 25;
PlotProps.Color.Steps.Divergent = 100;
figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*1.3, PlotProps.Figure.Height*.45])
StartPoint = dsearchn(TrialTime', 0);
YLims = [-.1 .1];

TrialTypes = { 'Lapse', 'Slow', 'Fast'};

CLim = [-10 10];
for SessionIdx = 1:2
    FigureIdx = 1;
    for TrialTypeIdx = 3:-1:1
        if TrialTypeIdx < 3
            Letter2 = '';
        end

        %%% plot time-frequency
        chART.sub_plot([], Grid, [SessionIdx FigureIdx], [], true, Letter2, PlotProps);
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
        end
    end
end

Axes = chART.sub_plot([], Grid, [SessionIdx 4], [2, 1], false, '', PlotProps);
chART.plot.pretty_colorbar('Divergent', CLim, 't-values', PlotProps)
axis off
chART.save_figure(['Figure_',TitleTag, 'TimeFrequency'], Paths.Results, PlotProps)


%% topography sequence of SD lapse

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 20;
PlotProps.Colorbar.Location = 'eastoutside';
Windows = [-2,  -1, 0, 1, 2;
    -1, 0, 1, 2,  4];
Ranges = [1, 4,  8, 12, 25;
    4, 8, 12, 25, 30];

CLim = [-6 6];
TrialTypeIdx = 1; % lapse

for SessionIdx = 1:2
    figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.8])
    plot_topography_sequence(AllTimeFrequencyEpochs, Frequencies, Chanlocs, SessionIdx, ...
        TrialTypeIdx, TrialTime, Windows, Ranges, CLim, PlotProps, Parameters.Stats, [])
    chART.save_figure(['Figure_',TitleTag, 'LapseTopographies_', num2str(SessionIdx)], Paths.Results, PlotProps)
end


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function Space = set_sub_figure(Grid, Position, PlotProps, Letter)
PlotProps.Axes.xPadding = 20;
PlotProps.Axes.yPadding = 20;
Space = chART.sub_figure(Grid, Position, [], Letter, PlotProps);
Space(2) = Space(2)-Space(4)*.05;
end


function plot_spectrum(Data, Frequencies, Legend, PlotProps)

nTypes = size(Data, 2);
Colors = flip(chART.color_picker(nTypes));

hold on
for TrialTypeIdx = 1:nTypes
    Spectrum = squeeze(mean(Data(:, TrialTypeIdx, :), 1, 'omitnan'));
    plot(Frequencies, Spectrum, 'Color', [Colors(TrialTypeIdx, :), .5], 'LineWidth',PlotProps.Line.Width)
end

chART.set_axis_properties(PlotProps)

plot(Frequencies([1 end]), [0 0], 'Color', 'k', 'LineWidth', PlotProps.Line.Width*2, 'HandleVisibility', 'off')
xlim(Frequencies([1 end]))
xlabel('Frequencies (Hz)')
ylabel('Log power difference')
legend(Legend)
set(legend, 'ItemTokenSize', [10 10], 'location', 'northeast')
end

function plot_timefrequency(Stats, Time, Frequencies, CLim, PlotProps)
Data = Stats.t;
hold on
contourf(Time, Frequencies, Data, PlotProps.Color.Steps.Divergent,  'linecolor','none')
colormap(PlotProps.Color.Maps.Divergent)
chART.set_axis_properties(PlotProps)

Dims = size(Data);
Mask = zeros(Dims);
Mask(~Stats.sig) = 0.65;
image(Time, Frequencies, 0.95*ones(Dims(1), Dims(2), 3), 'AlphaData', Mask)


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
plot([0 0], Frequencies([1 end]),  'Color', 'k', 'LineWidth',PlotProps.Line.Width/2, 'HandleVisibility', 'off')

end

function plot_topography_sequence(AllData, Frequencies, Chanlocs, SessionIdx, TrialTypeIdx, TrialTime, Windows, ...
    Ranges, CLims, PlotProps, StatsParameters, Space)

% PlotProps.Stats.PlotN = true; % To see sample size
nWindows = size(Windows, 2);
nRanges = size(Ranges, 2);
PlotProps.Axes.xPadding = 10;
PlotProps.Axes.yPadding = 10;

Grid = [nRanges, nWindows];


for RangeIdx = 1:nRanges
    for WindowIdx = 1:nWindows

        Range = dsearchn(Frequencies', Ranges(:, RangeIdx));
        Window = dsearchn(TrialTime', Windows(:, WindowIdx));

        Data = AllData(:, SessionIdx, TrialTypeIdx, :, Range(1):Range(2), Window(1):Window(2));
        Data = squeeze(mean(mean(Data, 5, 'omitnan'), 6, 'omitnan'));

        chART.sub_plot(Space,  Grid, [RangeIdx WindowIdx], [], false, '', PlotProps);
        paired_ttest_topography(zeros(size(Data)), Data, Chanlocs, CLims, StatsParameters, PlotProps);
        colorbar off

        if RangeIdx==1
            title([num2str(Windows(1, WindowIdx)), '-', num2str(Windows(2, WindowIdx)), 's'])
        end

        if WindowIdx ==1
            chART.plot.vertical_text([num2str(Ranges(1, RangeIdx)), '-', num2str(Ranges(2, RangeIdx)), ' Hz'], .15, .5, PlotProps)
        end
    end
end
end



function [LapseProbability, RTs] = lapse_probability_by_quantile(AllBurstsTable, Participants, nQuantiles)
% sorts bursts into quantiles by amplitude, and identifies how many of
% those result in a lapse. Also provides RTs for funzies.

AllBurstsTable(AllBurstsTable.EyesClosed==1, :) = [];

LapseProbability = nan(numel(Participants), 2, 2, nQuantiles);
RTs = LapseProbability;

for idxParticipant = 1:numel(Participants)
    for idxSession = 1:2
        for idxBand = 1:2
            BurstIndexes = strcmp(string(AllBurstsTable.Participant), Participants{idxParticipant}) & ...
                AllBurstsTable.SessionBlock==idxSession & AllBurstsTable.Band==idxBand;
            Bursts = AllBurstsTable(BurstIndexes, :);

            if isempty(Bursts)
                continue
            end

            % assign bursts to quantiles
            Quantiles = quantile(Bursts.Amplitude, linspace(0, 1, nQuantiles+1));
            BinnedBursts = discretize(Bursts.Amplitude, Quantiles);

            % get lapse probability by quantile
            for idxQuantile = 1:nQuantiles
                QuantileBurstTypes = Bursts.TrialType(BinnedBursts==idxQuantile);
                LapseProbability(idxParticipant, idxSession, idxBand, idxQuantile) = ...
                    nnz(QuantileBurstTypes==1)/numel(QuantileBurstTypes);

                RTs(idxParticipant, idxSession, idxBand, idxQuantile) = ...
                    mean(Bursts.RT(BinnedBursts==idxQuantile));
            end
        end
    end
end
end
