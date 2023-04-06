% plot the timecourses showing relationship of bursts with lapses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants_sdTheta;
Participants = ones(1, 18);
TallyLabels = P.Labels.Tally;
Paths = P.Paths;
StatsP = P.StatsP;
Bands = P.Bands;
BandLabels = fieldnames(Bands);

CheckEyes = false; % check if person had eyes open or closed
Closest = false; % only use closest trials
SessionGroup = 'BL';

% Windows_Stim = [-1 0;  .3 .75; 1 1.5]; % time windows to aggregate info
Windows_Stim = [-1 0;  0 .3; .3 1];
% Windows_Stim = [0 .3];


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

% remove all data from participants missing any of the trial types
for Indx_B = 1:2
    for Indx_Ch = 1:TotChannels
        ProbBurst_Stim(:, :, Indx_Ch, Indx_B, :)= ...
            removeBlankParticipants(squeeze(ProbBurst_Stim(:, :, Indx_Ch, Indx_B, :)));
    end
end

% remove low sdTheta participants for obvious reasons
ProbBurst_Stim(~Participants, :, :, :, :) = nan;

%  z-score
[zProbBurst_Stim, zGenProbBurst] = ...
    zscoreTimecourse(ProbBurst_Stim, GenProbBurst, 4);
% zProbBurst_Stim = ProbBurst_Stim;
% zGenProbBurst = GenProbBurst;

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
PlotProps.Colorbar.Location = 'north';
Grid = [5 2];
miniGrid = [3 3];
CLims = [-8 8];

Types = [3 2 1];
WindowTitles = {["Pre", "[-1, 0]"], ["Stimulus", "[0, 0.3]"], ["Response", "[.3 1]"]};

figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.45])
for Indx_B = 1:2

    Space = subaxis(Grid, [4 Indx_B], [4 1], PlotProps.Indexes.Letters{Indx_B}, PlotProps);
    Space(2) = Space(2)-Space(4)*.05;
    for Indx_TT = 1:3

        % stim windows
        for Indx_W = 1:nWindows
            Data = squeeze(wProbBurst_Stim(:, Types(Indx_TT), :, Indx_B, Indx_W));
            Baseline = squeeze(zGenProbBurst(:, :, Indx_B));

            subfigure(Space, miniGrid, [Indx_TT, Indx_W], [], false, '', PlotProps);
            Stats = topoDiff(Baseline, Data, Chanlocs, CLims, StatsP, PlotProps);
            % plotTopoplot(mean(Baseline, 1, 'omitnan'), [], Chanlocs, [], 'zvalues', 'Linear', PlotProps)
            % colorbar
            colorbar off

            W= WindowTitles{Indx_W};
            String = strjoin({BandLabels{Indx_B}, TallyLabels{Types(Indx_TT)}, char(W(1))}, ' ');
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

        if Indx_TT ==1
            title(WindowTitles{Indx_W})
        end

    end

    A = subfigure([], Grid, [5, Indx_B], [], false, '', PlotProps);
    A.Position(4) = A.Position(4)*2;
    A.Position(2) = A.Position(2)-.1;
    plotColorbar('Divergent', CLims, [BandLabels{Indx_B}, ' t-values'], PlotProps)
end
saveFig(['Figure_4_', TitleTag], Paths.PaperResults, PlotProps)
