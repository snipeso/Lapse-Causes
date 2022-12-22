function plotTimecourse(t, Data, Baseline, YLims, LineLabels, Text, Colors, StatsP, PlotProps)
% plots the timecourse locked to stimulus onset.
% Data is a P x TT x t matrix

%%% Get stats
if ~isempty(StatsP)
    Data1 = repmat(Baseline, 1, size(Data, 3)); % baseline
    Data2 = Data;
    Stats = pairedttest(Data1, Data2, StatsP);
    Stats.timepoints = t;
    Stats.lines = LineLabels;
    Dims = size(Data1);

    Sig = Stats.p_fdr <= StatsP.Alpha;
else
    Dims = size(Data);
    Sig = zeros(Dims(2), Dims(3));
end

if ~isempty(YLims)
    Range = YLims;
    ylim(YLims)
else
    Range = [min(Data(:)), max(Data(:))];
end

hold on
 plot([0 0], Range, 'Color', 'k', 'LineWidth',PlotProps.Line.Width/2, 'HandleVisibility', 'off')
if ~all(isnan(Data(:, end, :))) % plot stim patch
    rectangle('position', [0 Range(1) 0.5, diff(Range)], 'EdgeColor','none', ...
        'FaceColor', [PlotProps.Color.Generic, .15],'HandleVisibility','off')
end
if ~isempty(Text)
text(.1, Range(2)-.05*diff(Range), Text, 'FontName', PlotProps.Text.FontName, 'FontSize', PlotProps.Text.LegendSize)
end

plot([min(t), max(t)], [mean(Baseline, 'omitnan'), mean(Baseline, 'omitnan')], ...
    ':', 'Color', PlotProps.Color.Generic, 'LineWidth', PlotProps.Line.Width/2, 'HandleVisibility', 'off')

Data_Means = squeeze(mean(Data, 1, 'omitnan'));
CI = nan(2, size(Data, 2), size(Data, 3));

PlotProps.HandleVisibility = 'off';
plotAngelHair(t, Data, Colors, [], PlotProps)
plotFuzzyCaterpillars(Data_Means, CI, t, 15, logical(Sig), Colors, PlotProps)


if ~isempty(LineLabels)
    legend([LineLabels, 'p<.05'])
    set(legend, 'ItemTokenSize', [10 10], 'location', 'northwest')
end

xlabel('Time (s)')