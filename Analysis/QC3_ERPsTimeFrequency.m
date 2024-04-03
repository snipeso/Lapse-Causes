%%% this script provides benchmarks for how many cycles it takes to produce
%%% a given patch in a time-frequency plot


clear
clc
close all


Parameters = analysisParameters();
PlotProps = Parameters.PlotProps.Manuscript;

SignalCycles = 1:5;

Frequencies = [1:20];
Frequencies = reshape(Frequencies, 4, []);
MaxFrequency = max(Frequencies(:));

Range = [-10 10];
Srate = 128;
t_total = linspace(Range(1), Range(2), diff(Range)*Srate);
Start = dsearchn(t_total', 0);
CycleRange = [3, 15];

TFCycles = logspace(log10(CycleRange(1)),log10(CycleRange(2)),numel(1:MaxFrequency));

FinalMap = (max(SignalCycles)+1)*ones(MaxFrequency, numel(t_total));

figure('Units','normalized', 'OuterPosition',[0 0 1 1])
for idxFrequencyRow = 1:size(Frequencies, 1)
    for idxFrequencyCol = 1:size(Frequencies, 2)
        Freq = Frequencies(idxFrequencyRow, idxFrequencyCol);

        % calculate
        TF = nan(numel(SignalCycles), numel(t_total));
        for idxSigCycles = numel(SignalCycles):-1:1
            % get power for any given number of cycles
            SigCyc = SignalCycles(idxSigCycles);
            t = linspace(0, (1/Freq)*SigCyc, (1/Freq)*SigCyc*Srate);
            Sine = sin(2*pi*t*Freq);
            Signal = zeros(1, numel(t_total));
            Signal(Start:Start+numel(Sine)-1) = Sine;
            [Power, ~, ~] = time_frequency(Signal, Srate, Freq, TFCycles(Freq), TFCycles(Freq), 3);

            TF(idxSigCycles, :) = squeeze(Power);

            % create
            Max = max(TF(idxSigCycles, :));
            StartPatch = find(TF(idxSigCycles, :)>Max*.5, 1, 'first');
            EndPatch = find(TF(idxSigCycles, :)>Max*.5, 1, 'last');
            FinalMap(Freq, StartPatch:EndPatch) = SigCyc;
        end

        % plot
        chART.sub_plot([], size(Frequencies), [idxFrequencyRow, idxFrequencyCol], [], false, '', PlotProps)
        imagesc(t_total, SignalCycles, TF)
        xlim([-0.5 4])
        colormap(PlotProps.Color.Maps.Linear)
        title([num2str(Freq), ' Hz'])
        clc
        colorbar
    end
end

chART.save_figure('ERP_Time', Parameters.Paths.Results, PlotProps)


%%

FinalMapPlot = FinalMap;
FinalMapPlot(~ismember(1:MaxFrequency, Frequencies(:)), :) = []; % remove frequencies for which didnt calculate cycles

Max =  max(FinalMapPlot(:));
figure('Units','normalized', 'Position',[0 0 .7 .5])
hold on
% contourf(t_total, sort(Frequencies(:)), FinalMapPlot, 40, 'edgecolor','none')
imagesc(t_total, sort(Frequencies(:)), FinalMapPlot)
chART.set_axis_properties(PlotProps)
% clim([0,Max+0.5])
clim([0.5,Max+0.5])
colormap(chART.color_picker(Max, 'rainbow'))
xlim([-.5 4])
plot([0 0], [0 MaxFrequency+1], 'k', 'LineWidth',2)
ylim([.5 20.5])
xlabel('Time (s)')
ylabel('Frequency (Hz)')
h = colorbar('location', 'eastoutside', 'Color', 'k', ...
   'Ticks', 1:6);

    ylabel(h, '# cycles', 'FontName', PlotProps.Text.FontName, ...
        'FontSize', PlotProps.Text.AxisSize,'Color', 'k')


chART.save_figure('ERP_Timefrequency', Parameters.Paths.Results, PlotProps)

