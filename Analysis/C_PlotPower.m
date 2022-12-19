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
Bands = P.AllBands;

StartTime = -0.5;
EndTime = 1.5;
WelchWindow = 2;

BandLabels = fieldnames(Bands);

StatsP = P.StatsP;
PlotProps = P.Manuscript;

Tag =  ['s', num2str(StartTime), '_e', num2str(EndTime), '_w', num2str(WelchWindow)];
Tag = replace(Tag, '.', '-');
TitleTag = strjoin({'LapseCauses', 'LAT', 'Power', Tag}, '_');

Pool = fullfile(Paths.Pool, 'EEG');

%% plot late vs correct and lapse vs correct

load(fullfile(Pool, strjoin({TitleTag, 'Power', 'Band', 'Topography', 'Close', 'EO', 'TrialType.mat'}, '_')), 'Data', 'Chanlocs', 'Bands', 'SessionLabels')

Grid = [2 numel(BandLabels)];
CLims_Diff = [-7 7];

for Indx_S = 1:2

    figure('Units','normalized', 'position', [0 0 .5 .5])
    for Indx_T = 1:2
        for Indx_B = 1:numel(BandLabels)

            BL = squeeze(Data(:, Indx_S, 3, :, Indx_B));
            Tr = squeeze(Data(:, Indx_S, Indx_T, :, Indx_B));

            subfigure([], Grid, [Indx_T, Indx_B], [], false, '', PlotProps);
            Stats = topoDiff(BL, Tr, Chanlocs, CLims_Diff, StatsP, PlotProps);
            colorbar off

            title([BandLabels{Indx_B}, ' ', P.Labels.Tally{Indx_T}, ' (n=', num2str(Stats.df(1)+1) ')'], 'FontSize', PlotProps.Text.TitleSize)
        end
    end
    saveFig(strjoin({TitleTag, 'LapsevsCorrect', SessionLabels{Indx_S}}), Paths.Results, PlotProps)
end



%% plot left vs right

load(fullfile(Pool, strjoin({TitleTag, 'Power', 'Band', 'Topography', 'Hemifield.mat'}, '_')), 'Data', 'Chanlocs', 'Bands', 'SessionLabels')

Grid = [2 numel(BandLabels)];
CLims_Diff = [-7 7];

figure('Units','normalized', 'position', [0 0 .5 .5])
for Indx_S = 1:2
    for Indx_B = 1:numel(BandLabels)

        BL = squeeze(Data(:, Indx_S, 1, :, Indx_B)); % left VHf
        Tr = squeeze(Data(:, Indx_S, 2, :, Indx_B)); % right VHf

        subfigure([], Grid, [Indx_S, Indx_B], [], false, '', PlotProps);
        Stats = topoDiff(BL, Tr, Chanlocs, CLims_Diff, StatsP, PlotProps);
        colorbar off
%         colormap(gca, PlotProps.Color.Maps.Divergent)

        title([BandLabels{Indx_B}, ' ', SessionLabels{Indx_S}, ' (n=', num2str(Stats.df(1)+1) ')'], 'FontSize', PlotProps.Text.TitleSize)
    end
end

saveFig([TitleTag, '_LeftvsRight'], Paths.Results, PlotProps)


%% plot EO vs EC

load(fullfile(Pool, strjoin({TitleTag, 'Power', 'Band', 'Topography', 'EC.mat'}, '_')), 'Data', 'Chanlocs', 'Bands', 'SessionLabels')

Grid = [2 numel(BandLabels)];
CLims_Diff = [-7 7];

figure('Units','normalized', 'position', [0 0 .5 .5])
for Indx_S = 1:2
    for Indx_B = 1:numel(BandLabels)

        BL = squeeze(Data(:, Indx_S, 1, :, Indx_B)); % left VHf
        Tr = squeeze(Data(:, Indx_S, 2, :, Indx_B)); % right VHf

        subfigure([], Grid, [Indx_S, Indx_B], [], false, '', PlotProps);
        Stats = topoDiff(BL, Tr, Chanlocs, CLims_Diff, StatsP, PlotProps);
        colorbar off
        
        title([BandLabels{Indx_B}, ' ', SessionLabels{Indx_S}, ' (n=', num2str(Stats.df(1)+1) ')'], 'FontSize', PlotProps.Text.TitleSize)
    end
end

saveFig([TitleTag, '_EOvsEC'], Paths.Results, PlotProps)

