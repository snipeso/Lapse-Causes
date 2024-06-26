function plot_spectrum_increase(Data, Freqs, xLog, xLims, PlotProps, Labels)
% plots spectrum changes of all participants, with mean change on top in
% black. Based on chART plotMountains().
% Data is a P x 2 x F matrix.
% xLog is either true or false, about whether the x axis should be logged.
% Lapse-causes


% plot axis ticks
if xLog
    X = log(Freqs);
    Lims = log(xLims);
    xticks(log(Labels.logBands))
    xticklabels(Labels.logBands)
    
    % ignore all negative values, they won't get patched (sorry)
    RM = X<=0;
    X(RM) = [];
    Data = Data(:, :, ~RM);
    
else
    X = Freqs;
    Lims = xLims;
    xticks(Labels.Bands)
    xticklabels(Labels.Bands)
end

xlabel(Labels.Frequency)

Data1 = squeeze(Data(:, 1, :));
Data2 = squeeze(Data(:, 2, :));


% plot data
if size(Data1, 1) < 5
    PlotMean = false;
else
    PlotMean = true;
end
chART.plot.increases_from_baseline(Data1, Data2, X, 'pos', PlotMean, PlotProps, PlotProps.Color.Participants)

set(gca, 'XGrid', 'on')
h=gca; h.XAxis.TickLength = [0 0];

if ~isempty(xLims)
    xlim(Lims)
end
