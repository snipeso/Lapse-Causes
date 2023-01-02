function plotParticipantMountains(BL, Data, Freqs, xLog, xLims, PlotProps, Labels, Participants)
% plots spectrum changes of all participants, with mean change on top in
% black. Based on chART plotMountains().
% Data is a P x 2 x F matrix.
% xLog is either true or false, about whether the x axis should be logged.
% Lapse-causes

Dims = size(Data);

 if xLog
  X = log(Freqs);

        % ignore all negative values, they won't get patched (sorry)
        RM = X<=0;
        X(RM) = [];
        Data = Data(:, :, ~RM);
        BL = BL(:, :, ~RM);

 end

Data1 = squeeze(Data(:, 1, :));
Data2 = squeeze(Data(:, 2, :));

BL1 = squeeze(BL(:, 1, :));
BL2 = squeeze(BL(:, 2, :));


% plot data
figure('Units','normalized', 'OuterPosition', [0 0 1 1])

for Indx_P = 1:Dims(1)

            subplot(4, 5, Indx_P)

    % plot axis ticks
    if xLog
      
        Lims = log(xLims);
        xticks(log(Labels.logBands))
        xticklabels(Labels.logBands)

    else
        X = Freqs;
        Lims = xLims;
        xticks(Labels.Bands)
        xticklabels(Labels.Bands)
    end

    plotMountains(Data1(Indx_P, :), Data2(Indx_P, :), X, 'pos', PlotProps.Color.Participants(Indx_P, :), PlotProps)
    hold on
    plotMountains(BL1(Indx_P, :), BL2(Indx_P, :), X, 'pos', [0 0 0], PlotProps)
title(Participants{Indx_P})


    xlabel(Labels.Frequency)
    set(gca,'FontName', PlotProps.Text.FontName, 'FontSize', PlotProps.Text.AxisSize, 'XGrid', 'on')
    h=gca; h.XAxis.TickLength = [0 0];

    if ~isempty(xLims)
        xlim(Lims)
    end

end


