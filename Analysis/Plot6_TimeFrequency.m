clear
clc
close all
Parameters = analysisParameters();
PlotProps = Parameters.PlotProps.Manuscript;
Paths = Parameters.Paths;

CheckEyes = true; % check if person had eyes open or closed
Closest = false; % only use closest trials
SessionBlockLabel = 'BL';

TitleTag = SessionBlockLabel;
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



%%

Grid = [1 3];
PlotProps.Axes.xPadding = 25;
figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.23])

% CLim = [-.2 .2];
CLim = [-10 10];

% Channels = labels2indexes(Parameters.Channels.PreROI.Back, Chanlocs);
Channels = 1:numel(Chanlocs);


chART.sub_plot([], Grid, [1 1], [], true, '', PlotProps);
Data = squeeze(mean(TimeFrequencyEpochs(:, 3, Channels, :, :), 3, 'omitnan')); % average across channels
Stats = ttest_timefrequency(Data, Parameters.Stats);
plot_timefrequency(Stats, TrialTime, Frequencies, CLim, 'Fast', PlotProps)
colorbar off
    
chART.sub_plot([], Grid, [1 2], [], true, '', PlotProps);
Data = squeeze(mean(TimeFrequencyEpochs(:, 2, Channels, :, :), 3, 'omitnan')); % average across channels
Stats = ttest_timefrequency(Data, Parameters.Stats);
plot_timefrequency(Stats, TrialTime, Frequencies, CLim, 'Slow', PlotProps)
colorbar off

    
chART.sub_plot([], Grid, [1 3], [], true, '', PlotProps);
Data = squeeze(mean(TimeFrequencyEpochs(:, 1, Channels, :, :), 3, 'omitnan')); % average across channels
Stats = ttest_timefrequency(Data, Parameters.Stats);
plot_timefrequency(Stats, TrialTime, Frequencies, CLim, 'Lapse', PlotProps)
chART.save_figure(['Figure_',TitleTag, 'TF'], Paths.Results, PlotProps)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function plot_timefrequency(Stats, Time, Frequencies, CLim, Title, PlotProps)


Data = Stats.t;
hold on
contourf(Time, Frequencies, Data, 30,  'linecolor','none')
chART.set_axis_properties(PlotProps)

Dims = size(Data);
Mask = zeros(Dims);
Mask(~Stats.sig) = 0.5;
image(Time, Frequencies, ones(Dims(1), Dims(2), 3), 'AlphaData', Mask)

if isempty(CLim)
    Quantiles = quantile(Data(:), [.1 .99]);
Lim = max(abs(Quantiles));
    CLim = [-Lim Lim];
end
clim(CLim)
ylim([Frequencies(1), Frequencies(end)])

PlotProps.Colorbar.Location = 'eastoutside';
chART.plot.pretty_colorbar('Divergent', CLim, 'difference log power', PlotProps)

title(Title, 'FontSize',PlotProps.Text.TitleSize)
xlabel('Time (s)')
ylabel('Frequency (Hz)')
set(gca, 'TickDir', 'in')
hold on
plot([0 0], Frequencies([1 end]),  'Color', 'k', 'LineWidth',PlotProps.Line.Width/2, 'HandleVisibility', 'off')
end


