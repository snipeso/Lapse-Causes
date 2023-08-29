function plot_change_in_time(Data, XLabels, YLabels, YLims, Colors, StatParameters, PlotProps)

if ~isempty(StatParameters)
    Stats = paired_ttest(Data, [], StatParameters);
else
    Stats = [];
    % TODO: plot stars for group comparison
end


chART.plot.individual_rows(Data, Stats, XLabels, YLims, PlotProps, Colors)

if~isempty(YLims)
    ylim(YLims)
    
    if ~isempty(YLabels)
        yticks(linspace(YLims(1), YLims(2), numel(YLabels)))
        yticklabels(YLabels)
    end
end