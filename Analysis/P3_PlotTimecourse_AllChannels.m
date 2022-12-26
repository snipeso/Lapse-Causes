% plot the timecourses showing relationship of bursts with lapses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
Sessions = P.Sessions;
TallyLabels = P.Labels.Tally;
Paths = P.Paths;
Task = P.Labels.Task;
Channels = P.Channels;
StatsP = P.StatsP;
Bands = P.Bands;
BandLabels = fieldnames(Bands);

TitleTag = strjoin({'Timecourse', 'Topoplot'}, '_');

Pool = fullfile(Paths.Pool, 'EEG');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data

load(fullfile(Pool, 'ProbBurst_Channels.mat'), 'ProbBurst_Stim', 'ProbBurst_Resp', ...
    'GenProbBurst', 'Chanlocs')

nWindows = size(ProbBurst_Stim, 5);


%% plot theta and alpha

PlotProps = P.Manuscript;
PlotProps.Colorbar.Location = 'north';
Grid = [5 2];
miniGrid = [3 3];
CLims = [-8 8];

Types = [3 2 1];
WindowTitles = {["Pre", "[-1.5, 0]"], ["Stimulus", "[0, 0.4]"], ["Response", "[.25 1]"]};

figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.45])
for Indx_B = 1:2

    Space = subaxis(Grid, [4 Indx_B], [4 1], PlotProps.Indexes.Letters{Indx_B}, PlotProps);
    Space(2) = Space(2)-Space(4)*.05;
    for Indx_TT = 1:3

        % stim windows
        for Indx_W = 1:nWindows
            Data = squeeze(ProbBurst_Stim(:, Types(Indx_TT), :, Indx_B, Indx_W));
            Baseline = squeeze(GenProbBurst(:, :, Indx_B));

            subfigure(Space, miniGrid, [Indx_TT, Indx_W], [], false, '', PlotProps);
            topoDiff(Baseline, Data, Chanlocs, CLims, StatsP, PlotProps);
            colorbar off

            if Indx_TT ==1
                title(WindowTitles{Indx_W})
            end

            % plot horizontal text
            if Indx_W == 1
                X = get(gca, 'XLim');
                Y = get(gca, 'YLim');
                text(X(1)-diff(X)*.2, Y(1)+diff(Y)*.5, TallyLabels{Types(Indx_TT)}, ...
                    'FontSize', PlotProps.Text.TitleSize, 'FontName', PlotProps.Text.FontName, ...
                    'FontWeight', 'Bold', 'HorizontalAlignment', 'Center', 'Rotation', 90);
            end
        end

       
        if Indx_TT ==1
            title(WindowTitles{Indx_W})
        end

    end
    
    A = subfigure([], Grid, [5, Indx_B], [], false, '', PlotProps);
    A.Position(4) = A.Position(4)*2;
    A.Position(2) = A.Position(2)-.1;
    plotColorbar('Divergent', CLims, [BandLabels{Indx_B}, ' t-values'], PlotProps)
end
        saveFig('Figure_4', Paths.PaperResults, PlotProps)










%% Plot raw topoplots

Grid = [3 4];
CLims = [-8 8];

Types = [3 2 1];
WindowTitles = {'Pre', 'Stimulus', 'Response', 'Post'};

for Indx_B = 1:2
    figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width*.8, PlotProps.Figure.Height*.45])
    for Indx_TT = 1:3

        % stim windows
        for Indx_W = 1:nWindows
            Data = squeeze(ProbBurst_Stim(:, Types(Indx_TT), :, Indx_B, Indx_W));
            Baseline = squeeze(GenProbBurst(:, :, Indx_B));

            subfigure([], Grid, [Indx_TT, Indx_W], [], false, '', PlotProps);
            topoDiff(Baseline, Data, Chanlocs, CLims, StatsP, PlotProps);
            colorbar off

            if Indx_TT ==1
                title(WindowTitles{Indx_W})
            end

            % plot horizontal text
            if Indx_W == 1
                X = get(gca, 'XLim');
                Y = get(gca, 'YLim');
                text(X(1)-diff(X)*.1, Y(1)+diff(Y)*.5, TallyLabels{Types(Indx_TT)}, ...
                    'FontSize', PlotProps.Text.TitleSize, 'FontName', PlotProps.Text.FontName, ...
                    'FontWeight', 'Bold', 'HorizontalAlignment', 'Center', 'Rotation', 90);
            end
        end

        % post-response window
        Indx_W=Indx_W+1;
        Data = squeeze(ProbBurst_Resp(:,  Types(Indx_TT), :, Indx_B, 2));
        Baseline = squeeze(GenProbBurst(:, :, Indx_B));

        if all(isnan(Data))
            continue
        end
        subfigure([], Grid, [Indx_TT, Indx_W], [], false, '', PlotProps);
        topoDiff(Baseline, Data, Chanlocs, CLims, StatsP, PlotProps);
        colorbar off

        if Indx_TT ==1
            title(WindowTitles{Indx_W})
        end

    end
    
    subfigure([], Grid, [Indx_TT, Indx_W], [], false, '', PlotProps);
    plotColorbar('Divergent', CLims, 't-values', PlotProps)
        saveFig([TitleTag, '_Probof_raw_', BandLabels{Indx_B}], Paths.PaperResults, PlotProps)
end

