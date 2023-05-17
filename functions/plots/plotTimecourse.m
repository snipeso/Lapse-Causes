function Stats = plotTimecourse(t, Data, Baseline, YLims, LineLabels, Text, Colors, StatsP, PlotProps)
% plots the timecourse locked to stimulus onset.
% Data is a P x TT x t matrix

% BadParticipants = any(all(isnan(Data(:, [1, 2], :)), 3), 2);
% Data(BadParticipants, :, :) = nan;
StatsP.ANOVA.nBoot = 1;

%%% Get stats
if ~isempty(StatsP) && ~isempty(Baseline)
    %     Baseline(BadParticipants) = nan;
    Data1 = repmat(Baseline, 1, size(Data, 3)); % baseline
    Data2 = Data;
    Stats = pairedttest(Data1, Data2, StatsP);
    Stats.timepoints = t;
    Stats.lines = LineLabels;

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

plot([min(t), max(t)], [mean(Baseline, 'omitnan'), mean(Baseline, 'omitnan')], ...
    ':', 'Color', PlotProps.Color.Generic, 'LineWidth', PlotProps.Line.Width/2, 'HandleVisibility', 'off')

Data_Means = squeeze(mean(Data, 1, 'omitnan'));
CI = nan(2, size(Data, 2), size(Data, 3));

PlotProps.HandleVisibility = 'off';
plotAngelHair(t, Data, Colors, [], PlotProps)
plotFuzzyCaterpillars(Data_Means, CI, t, 15, logical(Sig), Colors, PlotProps)


if ~isempty(LineLabels)
    legend([LineLabels, 'p<.05'])
    set(legend, 'ItemTokenSize', [10 10], 'location', 'northeast')
end

xlabel('Time (s)')

YShift = .05*diff(Range);
if ~isempty(Text)
    text(.1, Range(2)-YShift, Text, 'FontName', PlotProps.Text.FontName, 'FontSize', PlotProps.Text.LegendSize)
end


if PlotProps.Stats.PlotN

    for Indx_TT = 1:size(Colors, 1)
        N = num2str(Stats.N(Indx_TT, 1));
        if N=='0'
            continue
        end
        text(min(t)+(max(t)-min(t))*.01, Range(2)-YShift*Indx_TT, ['N=', N], ...
            'FontName', PlotProps.Text.FontName, 'FontSize', PlotProps.Text.LegendSize,...
            'Color',Colors(Indx_TT, :))
    end
end



%%% display
if PlotProps.Stats.DispStat
Windows = [-2 -0.5;
    -0.5 .3;
    0.3, 1.5;
    1.5 4];

for Indx_L = 1:numel(LineLabels)
    disp(LineLabels{Indx_L})
    for Indx_W = 1:size(Windows, 1)

        S = abs(Stats.t(Indx_L, :));
        S(t<Windows(Indx_W, 1) | t>Windows(Indx_W, 2)) = nan;
        [~, Indx] = max(S);

        % if Sig(Indx_L, Indx)
            dispStat(Stats, [Indx_L, Indx], ['max t: ', num2str(t(Indx), '%.1f'), ' s']);
        % end

    end
    disp('_____________')
end

end