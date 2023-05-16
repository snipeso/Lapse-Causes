% plot Hedge's g to sample size

clear
clc
close all


P = analysisParameters();
PlotProps = P.Manuscript;
Paths = P.Paths;

N  = [2:20, 30:10:90, 100:100:1000];

d = nan(size(N)); % cohen's d
for Indx = 1:numel(N)
 d(Indx) = sampsizepwr('t', [0, 1], [], .8, N(Indx)); % by setting the M1 to 0 and STD to 1, M2 becomes cohen's d
end

g = d./(sqrt(N./(N-1))); % hedge's g (Becker 2000)

n18 = dsearchn(N', 18);
n10 = dsearchn(N', 10);

figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width*.4, PlotProps.Figure.Height*.3])
hold on
plot(g, N, 'LineWidth',PlotProps.Line.Width, 'Color','k')
scatter(g(n18), N(n18), 100, getColors(1, '', 'purple'), 'filled')
text(g(n18), N(n18), '   N=18', 'FontName', PlotProps.Text.FontName, 'Color', getColors(1, '', 'purple'))
scatter(g(n10), N(n10), 100, getColors(1, '', 'orange'), 'filled')
text(g(n10), N(n10), '   N=10', 'FontName', PlotProps.Text.FontName, 'Color', getColors(1, '', 'orange'))
setAxisProperties(PlotProps)
set(gca, 'YScale', 'log')
set(gca, 'YGrid', 'on', 'XGrid', 'on')
xlabel("Hedge's g")
ylabel('Required sample size (log scale)')
xlim([0 1.5])
ylim([5 1000])
axis square

saveFig('EffectSizeSample', Paths.PaperResults, PlotProps)