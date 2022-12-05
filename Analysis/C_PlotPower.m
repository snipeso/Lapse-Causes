








BandLabels = fieldnames(Bands);

StatsP = P.StatsP;
PlotProps = P.Manuscript;














%% plot late vs correct and lapse vs correct


Grid = [2 numel(BandLabels)];
CLims_Diff = [-7 7];

for Indx_S = 1:2

    figure('Units','normalized', 'position', [0 0 .5 .5])
    for Indx_T = 1:2
        for Indx_B = 1:numel(BandLabels)

            BL = squeeze(bData(:, Indx_S, 3, :, Indx_B));
            Tr = squeeze(bData(:, Indx_S, Indx_T, :, Indx_B));

            subfigure([], Grid, [Indx_T, Indx_B], [], false, '', PlotProps)
            Stats = topoDiff(BL, Tr, Chanlocs, CLims_Diff, StatsP, PlotProps);
            colorbar off
            colormap(gca, Format.Color.Maps.Divergent)

            title([BandLabels{Indx_B}, ' ', P.Labels.Tally{Indx_T}], 'FontSize', PlotProps.Text.TitleSize)
        end
    end
end

