% Figure (and stats) about the burt detection

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

TitleTag = strjoin({'Power', 'Burstless'}, '_');


Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
BandLabels = {'Theta', 'Alpha'};

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script


load(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent', 'TimeSpent_Eyes')
load(fullfile(Pool, strjoin({TitleTag, 'ChData.mat'}, '_')), 'ChData', 'AllFields', 'Chanlocs', 'Freqs')



%% plot EEG with and without bursts

% Grid = [4 2];
Grid = [1 5];
PlotProps = P.Manuscript;
PlotProps.Axes.yPadding = 18;
PlotProps.Axes.xPadding = 18;
PlotProps.HandleVisibility = 'on';
xLog = true;
xLims = [2 30];
yLims = [-2.4 2.4];

NormBand = [1 4];
NormBand_Indx = dsearchn(Freqs, NormBand');

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.35])

%%% theta
SB = 2;
B_Indx = 1;
Ch_Indx = 1;


Data = log(squeeze(ChData(:, SB, [B_Indx, 3], Ch_Indx, :)));

Delta = squeeze(mean(Data(:, 1, NormBand_Indx(1):NormBand_Indx(2)), 3, 'omitnan'));
Shift = Delta - mean(Delta, 'omitnan');
Data = Data - Shift;

subfigure([], Grid, [1 1], [1 2], true, PlotProps.Indexes.Letters{1}, PlotProps);
% subfigure([], Grid, [3 1], [3 1], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotSpectrumMountains(Data, Freqs', xLog, xLims, PlotProps, P.Labels);

% plot also BL theta, with all bursts
BL = squeeze(mean(log(ChData(:, 1, 3, Ch_Indx, :))-Shift, 1, 'omitnan'));
hold on
plot(log(Freqs), BL, ...
    'Color', PlotProps.Color.Generic, 'LineStyle','--', 'LineWidth', 1)

ylim(yLims)
legend({'', 'Front SD theta burst power', 'Front BL power'}, 'location', 'southwest')
set(legend, 'ItemTokenSize', [15 15])
ylabel('Log PSD amplitude (\muV^2/Hz)')


%%% alpha
SB = 1;
B_Indx = 2;
Ch_Indx = 3;

Data = log(squeeze(ChData(:, SB, [B_Indx, 3], Ch_Indx, :)));

Delta = squeeze(mean(Data(:, 1, NormBand_Indx(1):NormBand_Indx(2)), 3, 'omitnan'));
Shift = Delta - mean(Delta, 'omitnan');
Data = Data - Shift;

subfigure([], Grid, [1 3], [1 2], true, PlotProps.Indexes.Letters{2}, PlotProps);
% subfigure([], Grid, [3 2], [3 1], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotSpectrumMountains(Data, Freqs', xLog, xLims, PlotProps, P.Labels);
legend({'', 'Back BL alpha burst power'}, 'location', 'southwest')
set(legend, 'ItemTokenSize', [15 15])
ylim(yLims)

Legend = [append(BandLabels, ' bursts'), 'Both'];
YLim = [0 100];

ThetaColor = getColors(1, '', 'red');
AlphaColor = getColors(1, '', 'yellow');
Colors = [ThetaColor; AlphaColor; getColors(1, '', 'orange')];

%%% stacked bar plot for time spent
Data  = 100*squeeze(mean(TimeSpent, 1, 'omitnan'));

subfigure([], Grid, [1 5], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
% subfigure([], Grid, [4 1], [1 2], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotStackedBars(Data(:, [1 3 2]), SB_Labels, YLim, Legend([1 3 2]), Colors([1 3 2], :), PlotProps);
% view([90 90])
ylabel('Recording duration (%)')

saveFig('Figure_2', Paths.PaperResults, PlotProps)



%% provide descriptives

% NB: its a little suspicious that its identical (this would happen if not
% synchronized), so at somepoint double check

SB_Indx = 2;
EyeLabels = {'EO', 'EC'};

clc

for Indx_B = 1:numel(BandLabels)
    for Indx_E = 1:numel(EyeLabels)
        Data = 100*squeeze(TimeSpent_Eyes(:, SB_Indx, Indx_B, Indx_E));
        MEAN = num2str(mean(Data, 'omitnan'), '%.1f');
        STD = num2str(std(Data, 'omitnan'), '%.1f');
        disp(['Time spent in ', BandLabels{Indx_B} ' ', EyeLabels{Indx_E}, ': ', MEAN, ', ', STD])
    end
end


disp('_______________________________')
%% Percent SD theta removed

clc
StatsP = P.StatsP;

Bands = P.Bands;
ChLabels = fieldnames(Channels.preROI);

Theta = dsearchn(Freqs, Bands.Theta');


for Indx_Ch = 1:3

    disp([ChLabels{Indx_Ch}])
    %     sdTheta_Intact = squeeze(mean(log(ChData(:, 2, 3, Indx_Ch, Theta(1):Theta(2))), ...
    %         5, 'omitnan'));
    %     blTheta_Intact = squeeze(mean(log(ChData(:, 1, 3, Indx_Ch, Theta(1):Theta(2))), ...
    %         5, 'omitnan'));
    %     sdTheta_Burstless = squeeze(mean(log(ChData(:, 2, 1, Indx_Ch, Theta(1):Theta(2))), ...
    %         5, 'omitnan'));

    sdTheta_Intact = squeeze(mean((ChData(:, 2, 3, Indx_Ch, Theta(1):Theta(2))), ...
        5, 'omitnan'));
    blTheta_Intact = squeeze(mean((ChData(:, 1, 3, Indx_Ch, Theta(1):Theta(2))), ...
        5, 'omitnan'));
    sdTheta_Burstless = squeeze(mean((ChData(:, 2, 1, Indx_Ch, Theta(1):Theta(2))), ...
        5, 'omitnan'));

    %     PrcntIntact = 100*(sdTheta_Intact-sdTheta_Burstless)./sdTheta_Intact;

%     PrcntIntact = 100*mean(sdTheta_Intact-sdTheta_Burstless, 'omitnan')/mean(sdTheta_Intact-blTheta_Intact);

    disp(['Prcnt removed SD: ' num2str(mean(PrcntIntact, 'omitnan'), '%.1f')])

    Stats = pairedttest(blTheta_Intact, sdTheta_Intact, StatsP);
    dispStat(Stats, [1 1], 'Intact change from BL:');

    Stats = pairedttest(blTheta_Intact, sdTheta_Burstless, StatsP);
    dispStat(Stats, [1 1], 'Burstless change from BL:');

    disp('****')

end




