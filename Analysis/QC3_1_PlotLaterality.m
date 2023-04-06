clear
clc
close all


P = analysisParameters();
Bands = P.Bands;
StatsP = P.StatsP;
Paths = P.Paths;
BandLabels = fieldnames(Bands);


Pool = fullfile(Paths.Pool, 'EEG');

%%% load info

load(fullfile(Pool, 'Laterality_BL.mat'), 'ProbBurst', 'Chanlocs') % P x H x Ch x B
BL = ProbBurst;

load(fullfile(Pool, 'Laterality_SD.mat'), 'ProbBurst')
SD = ProbBurst;

ProbBurst = cat(6, BL, SD);
ProbBurst = permute(ProbBurst, [1, 6, 2 3 4 5]); % P x SB x H x Ch x B

% zscore
zProbBurst = zScoreData(ProbBurst, 'last');

%% plot

PlotProps = P.Manuscript;
SB_Labels = {'BL', 'SD'};
Grid = [2 2];
CLims = [-5 5];


figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width*.5, PlotProps.Figure.Height*.43])
for Indx_B = 1:2
    for Indx_SB = 1:2

        Left = squeeze(zProbBurst(:, Indx_SB, 1, :, Indx_B));
        Right = squeeze(zProbBurst(:, Indx_SB, 2, :, Indx_B));


        subfigure([], Grid, [Indx_B, Indx_SB], [], false, '', PlotProps);
        Stats = topoDiff(Left, Right, Chanlocs, CLims, StatsP, PlotProps);
        disp(Stats.N)
        % plotTopoplot(mean(Left, 1, 'omitnan'), [], Chanlocs, [], 'prob', 'Linear', PlotProps)
        title([SB_Labels{Indx_SB}, ' ', BandLabels{Indx_B}])
    end
end



