clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

CheckEyes = false; % check if person had eyes open or closed
Closest = false; % only use closest trials
SessionGroup = 'BL';


Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
TallyLabels = Parameters.Labels.TrialOutcome; % rename to outcome labels TODO
StatParameters = Parameters.Stats;
Windows = Parameters.Trials.SubWindows;
WindowTitles = {["Pre", "[-2, 0]"], ["Stimulus", "[0, 0.3]"], ["Response", "[0.3 1]"], ["Post", "[2 4]"]};
Bands = Parameters.Bands;
BandLabels = fieldnames(Bands);
CacheDir = fullfile(Paths.Cache, 'Data_Figures');



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
    'BurstStimLockedTopography', 'BurstDescriptivesTopography')

WindowedStim = average_windows(BurstStimLockedTopography, TrialTime, Windows);
WindowCount = size(Windows, 1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot

%%

PlotProps = Parameters.PlotProps.Manuscript;
CLims = [-7 7];
PlotProps.Text.AxisSize = 14;
PlotProps.Text.TitleSize = 16;
PlotProps.Text.IndexSize = 20;
PlotProps.Figure.Padding = 20;
PlotProps.Colorbar.Location = 'north';
Grid = [5 2];
miniGrid = [3 WindowCount];

Types = [3 2 1];

% figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width*1.3, PlotProps.Figure.Height*.6])
figure('Units','normalized', 'Position',[0 0 .5, .45])
for idxBand = 1:2 % subplot A and B

    Space = set_sub_figure(Grid, [4 idxBand], PlotProps, PlotProps.Indexes.Letters{idxBand});
    for idxOutcome = 1:3 % rows
        for idxWindow = 1:WindowCount % columns
            Data = squeeze(WindowedStim(:, Types(idxOutcome), :, idxBand, idxWindow));
            Baseline = squeeze(BurstDescriptivesTopography(:, :, idxBand));

            if idxWindow == 1
                PlotProps.Stats.PlotN = true;
            else
                PlotProps.Stats.PlotN = false;
            end

            Stats = plot_burst_probability_change_topoplot(Data, Baseline, ...
                StatParameters, Chanlocs, Space, miniGrid, [idxOutcome, idxWindow], ...
                CLims, PlotProps);
            write_titles(idxWindow, idxOutcome, WindowTitles, TallyLabels, Types, PlotProps)

            disp_topo_stats(Stats, Chanlocs, TallyLabels{Types(idxOutcome)}, ...
                BandLabels{idxBand}, WindowTitles{idxWindow})
        end
        disp('__________')
    end
    plot_colorbar(PlotProps, Grid, [5, idxBand], CLims, BandLabels{idxBand})
end
chART.save_figure(['Figure_',TitleTag, '_Topography'], Paths.Results, PlotProps)


%%
close all

Windows = {'Pre', 'Stim', 'Resp', 'Post'};

idxOutcome = 1;
for idxBand = 1:2
    for idxWindow = 1:WindowCount
        Data = squeeze(WindowedStim(:, Types(idxOutcome), :, idxBand, idxWindow));
        Baseline = squeeze(BurstDescriptivesTopography(:, :, idxBand));
        plot_individual_differences(Data, Baseline, Participants, Chanlocs, PlotProps)
        chART.save_figure(strjoin(['IndividualTopos',TitleTag, ...
            BandLabels(idxBand), Windows(idxWindow), TallyLabels(idxOutcome)], '_'), Paths.Results, PlotProps)
    end
end


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function Space = set_sub_figure(Grid, Position, PlotProps, Letter)
PlotProps.Axes.xPadding = 20;
PlotProps.Axes.yPadding = 20;
Space = chART.sub_figure(Grid, Position, [4 1], Letter, PlotProps);
Space(2) = Space(2)-Space(4)*.05;
end

function Stats = plot_burst_probability_change_topoplot(Data, Baseline, StatParameters, ...
    Chanlocs, Space, miniGrid, Position, CLims, PlotProps)

PlotProps.Axes.xPadding = 5;
PlotProps.Axes.yPadding = 5;

chART.sub_plot(Space, miniGrid, Position, [], false, '', PlotProps);
Stats = paired_ttest_topography(Baseline, Data, Chanlocs, CLims, StatParameters, PlotProps);
colorbar off
end


function disp_topo_stats(Stats, Chanlocs, OutcomeType, BandLabel, WindowTitle)

String = strjoin({BandLabel, OutcomeType, char(WindowTitle(1)), ...
    '; globality:' [num2str(round(100*nnz(Stats.sig)/numel(Stats.sig))), '%'], ...
    'max ch:', }, ' ');
disp_highest_tvalue(Stats, Chanlocs, String);
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
chART.plot.pretty_colorbar('Divergent', CLims, 't value', PlotProps)
end


