clear
clc
close all
Parameters = analysisParameters();
PlotProps = Parameters.PlotProps.Manuscript;
Paths = Parameters.Paths;

CheckEyes = false; % check if person had eyes open or closed
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

    % Channels = labels2indexes(Parameters.Channels.PreROI.Back, Chanlocs);
    Channels = 1:numel(Chanlocs);
    Data = mean(TimeFrequencyEpochs(:, :, Channels, :, :), 3, 'omitnan'); % average across channels

    AllTimeFrequencyEpochs = cat(2, AllTimeFrequencyEpochs, permute(Data, [1 3 2 4 5])); % P x S x TT x F x t
end


%%

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
    Data = squeeze(mean(AllTimeFrequencyEpochs(:, SessionIdx, :, :, 1:StartPoint), 5, 'omitnan'));
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
        Data = squeeze(AllTimeFrequencyEpochs(:, SessionIdx, TrialTypeIdx, :, :));
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
% Axes.Position(1) = Axes.Position(1)-.05; 
chART.plot.pretty_colorbar('Divergent', CLim, 't-values', PlotProps)
axis off
chART.save_figure(['Figure_',TitleTag, 'TF'], Paths.Results, PlotProps)


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


