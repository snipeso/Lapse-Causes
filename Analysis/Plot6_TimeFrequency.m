clear
clc
close all
Parameters = analysisParameters();
Paths = Parameters.Paths;

CheckEyes = true; % check if person had eyes open or closed
Closest = false; % only use closest trials


SessionBlockLabels = {'BL', 'SD'};

AllTimeFrequencyEpochs = [];

for SBL = SessionBlockLabels
    TitleTag = SBL{1};
    if CheckEyes
        TitleTag = [TitleTag, '_EO'];
    end

    if Closest
        TitleTag = [TitleTag, '_Close'];
        EyeclosureTag = '_Close';
    else
        EyeclosureTag = '';
    end

    CacheDir = fullfile(Paths.Cache, 'Data_Figures');


    load(fullfile(CacheDir, ['Power_', TitleTag, '.mat']), ...
        'TimeFrequencyEpochs', 'Chanlocs', 'TrialTime', 'Frequencies')

    Data = permute(TimeFrequencyEpochs, [1 6, 2, 3, 4 5]);
    AllTimeFrequencyEpochs = cat(2, AllTimeFrequencyEpochs, Data); % P x S x TT x Ch x F x t
end


%%

    % Channels = labels2indexes(Parameters.Channels.PreROI.Back, Chanlocs);
    Channels = 1:numel(Chanlocs);
MeanChannels = squeeze(mean(AllTimeFrequencyEpochs(:, :, :, Channels, :, :), 4, 'omitnan'));

Grid = [2 5];
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 25;
PlotProps.Color.Steps.Divergent = 100;
figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*1.3, PlotProps.Figure.Height*.45])
FigureIdx = 1;
StartPoint = dsearchn(TrialTime', 0);
YLims = [-.1 .1];

TrialTypes = { 'Lapse', 'Slow', 'Fast'};

CLim = [-10 10];
for SessionIdx = 1:2

    if SessionIdx ==1
        Letter1 = 'A';
        Letter2 = 'B';
    else
        Letter1 = '';
        Letter2 = '';
    end

    %%% plot pre-stimulus power  %TODO remove
    chART.sub_plot([], Grid, [SessionIdx 1], [], true, Letter1, PlotProps);
    Data = squeeze(mean(MeanChannels(:, SessionIdx, :, :, 1:StartPoint), 5, 'omitnan'));
    plot_spectrum(Data, Frequencies, TrialTypes, PlotProps)
    ylim([YLims])
    if SessionIdx ==2
        legend off
    else
        xlabel('')
    end

    FigureIdx = 2;  
    for TrialTypeIdx = 3:-1:1
        if TrialTypeIdx < 3
            Letter2 = '';
        end

        %%% plot time-frequency
        chART.sub_plot([], Grid, [SessionIdx FigureIdx], [], true, Letter2, PlotProps);
        FigureIdx = FigureIdx+1;
        Data = squeeze(MeanChannels(:, SessionIdx, TrialTypeIdx, :, :));
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

Axes = chART.sub_plot([], Grid, [SessionIdx 5], [2, 1], false, '', PlotProps);
chART.plot.pretty_colorbar('Divergent', CLim, 't-values', PlotProps)
axis off
chART.save_figure(['Figure_',TitleTag, 'TimeFrequency'], Paths.Results, PlotProps)





%% Topography sandbox

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';

% Range = dsearchn(Frequencies', [4; 8]);
% Start = 1;
% End = dsearchn(TrialTime', 2);
% SessionIdx = 2;
% TrialType = 1;

Range = [15; 30];
Window = [0; 1];
SessionIdx = 1;
TrialTypeIdx = 3;
CLims = [];


figure('Units','centimeters','Position', [0 0 10 10])

plot_topography_sequence(AllTimeFrequencyEpochs, Frequencies, Chanlocs, ...
    SessionIdx, TrialTypeIdx, TrialTime, Window, ...
    Range, CLims, PlotProps, Parameters.Stats)


%% topography sequence of fast response

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
Windows = [-2,  0, .1, .5, 1, 2;
            0, .1, .5,  1, 2, 4];
Ranges = [1, 4,  8, 12, 25;
          4, 8, 12, 25, 30];

CLims = [-10 10];
TrialTypeIdx = 3; % fast
SessionIdx = 1; % BL

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*1.3, PlotProps.Figure.Height*.8])
plot_topography_sequence(AllTimeFrequencyEpochs, Frequencies, Chanlocs, SessionIdx, ...
    TrialTypeIdx, TrialTime, Windows, Ranges, CLims, PlotProps, Parameters.Stats)
chART.save_figure(['Figure_',TitleTag, 'FastTopographies'], Paths.Results, PlotProps)


%% topography sequence of SD lapse

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Colorbar.Location = 'eastoutside';
Windows = [-2,  -1, 1, 2;
            -1, 0, 2,  4];
Ranges = [1, 4,  8, 12, 25;
          4, 8, 12, 25, 30];

CLims = [-6 6];
TrialTypeIdx = 1; % lapse

for SessionIdx = 1:2
figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*.8, PlotProps.Figure.Height*.8])
plot_topography_sequence(AllTimeFrequencyEpochs, Frequencies, Chanlocs, SessionIdx, ...
    TrialTypeIdx, TrialTime, Windows, Ranges, CLims, PlotProps, Parameters.Stats)
chART.save_figure(['Figure_',TitleTag, 'LapseTopographies_', num2str(SessionIdx)], Paths.Results, PlotProps)
end


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions


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
Mask(~Stats.sig) = 0.7;
image(Time, Frequencies, ones(Dims(1), Dims(2), 3), 'AlphaData', Mask)


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
    Ranges, CLims, PlotProps, StatsParameters)

nWindows = size(Windows, 2);
nRanges = size(Ranges, 2);

Grid = [nRanges, nWindows];


for RangeIdx = 1:nRanges
    for WindowIdx = 1:nWindows

        Range = dsearchn(Frequencies', Ranges(:, RangeIdx));
        Window = dsearchn(TrialTime', Windows(:, WindowIdx));

        Data = AllData(:, SessionIdx, TrialTypeIdx, :, Range(1):Range(2), Window(1):Window(2));
        Data = squeeze(mean(mean(Data, 5, 'omitnan'), 6, 'omitnan'));

          chART.sub_plot([],  Grid, [RangeIdx WindowIdx], [], false, '', PlotProps);
        paired_ttest_topography(zeros(size(Data)), Data, Chanlocs, CLims, StatsParameters, PlotProps);
        colorbar off

        if RangeIdx==1
            title([num2str(Windows(1, WindowIdx)), '-', num2str(Windows(2, WindowIdx)), 's'])
        end

        if WindowIdx ==1
            chART.plot.vertical_text([num2str(Ranges(1, RangeIdx)), '-', num2str(Ranges(2, RangeIdx)), 'Hz'], .15, .5, PlotProps)
        end
    end
end
end
