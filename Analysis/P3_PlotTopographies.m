% plot the timecourses showing relationship of bursts with lapses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

TallyLabels = P.Labels.Tally;
Participants = P.Participants;
Paths = P.Paths;
StatsP = P.StatsP;
Bands = P.Bands;
BandLabels = fieldnames(Bands);
Windows_Stim = P.Parameters.Topography.Windows;
WindowTitles = {["Pre", "[-2, 0]"], ["Stimulus", "[0, 0.3]"], ["Response", "[0.3 1]"], ["Post", "[2 4]"]};

CheckEyes = true; % check if person had eyes open or closed
Closest = false; % only use closest trials
ZScore = false; % best only z-scored; when raw, it's the average prob for each individual channel
SessionGroup = 'BL';

Pool = fullfile(Paths.Pool, 'EEG');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data

TitleTag = SessionGroup;
if CheckEyes
    TitleTag = [TitleTag, '_EO'];
end

if Closest
    TitleTag = [ TitleTag, '_Close'];
end

load(fullfile(Paths.Pool, 'EEG', ['ProbBurst_', TitleTag, '.mat']), 'ProbBurst_Stim', ...
    'ProbBurst_Resp', 't_window',  'GenProbBurst', 'Chanlocs')
TotChannels = size(GenProbBurst, 2);

if ZScore
    %  z-score
    [zProbBurst_Stim, zGenProbBurst] = ...
        zscoreTimecourse(ProbBurst_Stim, GenProbBurst, 4);
    TitleTag = [TitleTag, '_z-score'];
    zTag = ' (z-scored)';
    CLims = [-8 8];
else
    zProbBurst_Stim = ProbBurst_Stim;
    zGenProbBurst = GenProbBurst;
    TitleTag = [TitleTag, '_raw'];
    zTag = '';
    CLims = [-7 7];
end

%%% reduce to windows
nWindows = size(Windows_Stim, 1);

wProbBurst_Stim = nan(numel(Participants), 3, TotChannels, 2, nWindows);
for Indx_P = 1:numel(Participants)
    for Indx_TT = 1:3
        for Indx_Ch = 1:TotChannels
            for Indx_B = 1:2
                wProbBurst_Stim(Indx_P, Indx_TT, Indx_Ch, Indx_B, :) = ...
                    reduxProbEvent(squeeze(zProbBurst_Stim(Indx_P, Indx_TT, Indx_Ch, Indx_B, :))',...
                    t_window, Windows_Stim);
            end
        end
    end
end

%% plot theta and alpha

clc

PlotProps = P.Manuscript;
PlotProps.Figure.Padding = 15;

PlotProps.Colorbar.Location = 'north';
Grid = [5 2];
miniGrid = [3 nWindows];

Types = [3 2 1];
% 
figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width*1.3, PlotProps.Figure.Height*.43])
for Indx_B = 1:2

    PlotProps.Axes.xPadding = 20;
    PlotProps.Axes.yPadding = 20;
    Space = subaxis(Grid, [4 Indx_B], [4 1], PlotProps.Indexes.Letters{Indx_B}, PlotProps);
    Space(2) = Space(2)-Space(4)*.05;
    for Indx_TT = 1:3

        % stim windows
        for Indx_W = 1:nWindows
            Data = squeeze(wProbBurst_Stim(:, Types(Indx_TT), :, Indx_B, Indx_W));
            Baseline = squeeze(zGenProbBurst(:, :, Indx_B));

            PlotProps.Axes.xPadding = 5;
            PlotProps.Axes.yPadding = 5;

            chART.sub_plot(Space, miniGrid, [Indx_TT, Indx_W], [], false, '', PlotProps);
            PlotProps.Stats.PlotN = false;
            if Indx_W == 1
                PlotProps.Stats.PlotN = true;
            end
            Stats = topoDiff(Baseline, Data, Chanlocs, CLims, StatsP, PlotProps);
            colorbar off

            W= WindowTitles{Indx_W};
            String = strjoin({BandLabels{Indx_B}, TallyLabels{Types(Indx_TT)}, ...
                  '; tot ch:' num2str(round(100*nnz(Stats.sig)/numel(Stats.sig))), '%', ...
                'max Ch:', char(W(1))}, ' ');
            dispMaxTChanlocs(Stats, Chanlocs, String);

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
 disp('__________')
        if Indx_TT ==1
            title(WindowTitles{Indx_W})
        end

    end


    PlotProps.Axes.xPadding = 20;
    PlotProps.Axes.yPadding = 20;

    A = chART.sub_plot([], Grid, [5, Indx_B], [], false, '', PlotProps);
    A.Position(4) = A.Position(4)*2;
    A.Position(2) = A.Position(2)-.1;
    plotColorbar('Divergent', CLims, [BandLabels{Indx_B}, [' t-values', zTag]], PlotProps)
end
saveFig(['Figure_4_', TitleTag], Paths.PaperResults, PlotProps)



%% occipital alpha lapses pre


Data = squeeze(wProbBurst_Stim(:, 1, :,2, 1));
Baseline = squeeze(zGenProbBurst(:, :, 2));

figure
Stats = topoDiff(Baseline, Data, Chanlocs, CLims, StatsP, PlotProps);
Stats.p = Stats.p_fdr';
[~, I] = max(Stats.t);
disp_stats(Stats, [I, 1], ['Max ch: ', Chanlocs(I).labels]);

