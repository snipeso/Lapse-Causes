function plotTimecourse(t, Data, BL_Indx, YLims, LineLabels, Colors, StatsP, PlotProps)
% plots the timecourse locked to stimulus onset.
% Data is a P x T x t matrix

%%% Get stats
if ~isempty(StatsP)
    Data1 = squeeze(Data(:, BL_Indx, :)); % baseline
    Data2 = Data;
    Data2(:, BL_Indx, :) = []; % sessions to compare to the baseline
    Stats = pairedttest(Data1, Data2, StatsP);
    Stats.timepoints = t;
    Stats.lines = LineLabels;
    Stats.lines(BL_Indx) = [];
    Dims = size(Data1);

    Sig = [zeros(1, Dims(2)); Stats.p_fdr < StatsP.Alpha];
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
rectangle('position', [0 Range(1) 0.5, diff(Range)], 'EdgeColor','none', 'FaceColor', [PlotProps.Color.Generic, .15])
plotGloWorms(squeeze(mean(Data, 1, 'omitnan')), t, logical(Sig), Colors, PlotProps)

if ~isempty(LineLabels)
    legend([LineLabels, 'p<.05'])
    set(legend, 'ItemTokenSize', [10 10], 'location', 'northwest')
end