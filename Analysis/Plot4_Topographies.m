

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters
Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
TallyLabels = Parameters.Labels.TrialOutcome; % rename to outcome labels TODO
StatParameters = Parameters.Stats;
Windows = Parameters.Trials.SubWindows;
WindowTitles = {["Pre", "[-2, 0]"], ["Stimulus", "[0, 0.3]"], ["Response", "[0.3 1]"], ["Post", "[2 4]"]};
Bands = Parameters.Bands;
BandLabels = fieldnames(Bands);

CacheDir = fullfile(Paths.Cache, 'Data_Figures');

CheckEyes = true; % check if person had eyes open or closed
Closest = false; % only use closest trials


TitleTag = SessionGroup;
if CheckEyes
    TitleTag = [TitleTag, '_EO'];
end

if Closest
    TitleTag = [ TitleTag, '_Close'];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% assemble data

load(fullfile(CacheDir, ['Bursts_', TitleTag, '.mat']), 'Chanlocs','TrialTime', ...
    'ProbBurstStimLockedTopography', 'ProbabilityBurstTopography')

WindowedStim = average_windows(ProbBurstStimLockedTopography, TrialTime, Windows);
WindowCount = size(Windows, 1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot

%%

PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Figure.Padding = 15;

PlotProps.Colorbar.Location = 'north';
Grid = [5 2];
miniGrid = [3 nWindows];

Types = [3 2 1];

figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width*1.3, PlotProps.Figure.Height*.43])
for idxBand = 1:2 % subplot A and B
    
    Space = set_sub_figure(Grid, PlotProps, PlotProps.Indexes.Letters{idxBand});
    for idxOutcome = 1:3 % rows
        for idxWindow = 1:WindowCount % columns
            Data = squeeze(WindowedStim(:, Types(idxOutcome), :, idxBand, idxWindow));
            Baseline = squeeze(ProbabilityBurstTopography(:, :, idxBand));

          Stats = plot_burst_probability_change_topoplot(Data, Baseline, ...
              StatParameters, Chanlocs, Space, miniGrid, [idxOutcome, idxWindow], ...
              CLims, PlotProps);
            write_titles(idxWindow, idxOutcome, WindowTitles, TallyLabels, Types, PlotProps)
        
            disp_topo_stats(Stats, Chanlocs, TallyLabels{Types(idxOutcome)}, BandLabels{idxBand}, WindowTitles{idxWindow})
        end
        disp('__________')
    end
    plot_colorbar(PlotProps, Grid, [5, idxBand], CLims, BandLabels{idxBand})
end
chART.save_figure(['Figure_',TitleTag], Paths.Results, PlotProps)



%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function WindowedStim = average_windows(ProbTrialStim, TrialTime, Windows)

WindowsCount = size(Windows, 1);
ParticipantCount = size(ProbTrialStim, 1);
ChannelCount = size(ProbTrialStim, 3);

WindowedStim = nan(ParticipantCount, 3, ChannelCount, 2, WindowsCount);

for idxWindow = 1:WindowsCount
    Edges = dsearchn(TrialTime', Windows(idxWindow, :)');
    WindowedStim(:, :, :, :, idxWindow) = mean(ProbTrialStim(:, :, :, :, Edges(1):Edges(2)), ...
        5, 'omitnan');
end
end


%%%%%%%%%%%%
%%% plots

function Space = set_sub_figure(Grid, PlotProps, Letter)
PlotProps.Axes.xPadding = 20;
PlotProps.Axes.yPadding = 20;
Space = chART.sub_figure(Grid, [4 idxBand], [4 1], Letter, PlotProps);
Space(2) = Space(2)-Space(4)*.05;
end

function Stats = plot_burst_probability_change_topoplot(Data, Baseline, StatParameters, ...
    Chanlocs, Space, miniGrid, Position, CLims, PlotProps)

PlotProps.Axes.xPadding = 5;
PlotProps.Axes.yPadding = 5;

chART.sub_plot(Space, miniGrid, Position, [], false, '', PlotProps);
PlotProps.Stats.PlotN = false;
if idxWindow == 1
    PlotProps.Stats.PlotN = true;
end
Stats = paired_ttest_topography(Baseline, Data, Chanlocs, CLims, StatParameters, PlotProps);
colorbar off
end


function disp_topo_stats(Stats, Chanlocs, OutcomeType, BandLabel, WindowTitle)

String = strjoin({BandLabel, OutcomeType, ...
    '; tot ch:' num2str(round(100*nnz(Stats.sig)/numel(Stats.sig))), '%', ...
    'max Ch:', char(WindowTitle(1))}, ' ');
dispMaxTChanlocs(Stats, Chanlocs, String);
end

function write_titles(idxWindow, idxOutcome, WindowTitles, TallyLabels, Types, PlotProps)

if idxOutcome == 1
    title(WindowTitles{idxWindow})
end

% plot horizontal text
if idxWindow == 1
    X = get(gca, 'XLim');
    Y = get(gca, 'YLim');
    text(X(1)-diff(X)*.2, Y(1)+diff(Y)*.5, TallyLabels{Types(idxOutcome)}, ...
        'FontSize', PlotProps.Text.TitleSize, 'FontName', PlotProps.Text.FontName, ...
        'FontWeight', 'Bold', 'HorizontalAlignment', 'Center', 'Rotation', 90);
end
end


function plot_colorbar(PlotProps, Grid, Position, CLims, BandLabel)
PlotProps.Axes.xPadding = 20;
PlotProps.Axes.yPadding = 20;

A = chART.sub_plot([], Grid, Position, [], false, '', PlotProps);
A.Position(4) = A.Position(4)*2;
A.Position(2) = A.Position(2)-.1;
plotColorbar('Divergent', CLims, [BandLabel, [' t-values', zTag]], PlotProps)
end

