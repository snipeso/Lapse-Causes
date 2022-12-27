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
Bands = P.Bands;

TitleTag = strjoin({'Power', 'Burstless'}, '_');


Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
BandLabels = {'Theta', 'Alpha'};

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script


load(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent', 'TimeSpent_Eyes')
load(fullfile(Pool, strjoin({TitleTag, 'bChData.mat'}, '_')), 'ChData', 'sData', 'AllFields', 'Chanlocs', 'Freqs')



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
Data = 100*squeeze(mean(TimeSpent, 1, 'omitnan'));

subfigure([], Grid, [1 5], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotStackedBars(Data(:, [1 3 2]), SB_Labels, YLim, Legend([1 3 2]), Colors([1 3 2], :), PlotProps);

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

%%% reduce whole-brain data
lData = zScoreData(sData, 'last');
lchData = mean(lData, 4, 'omitnan'); % average all channels together
lchbData = squeeze(bandData(lchData, Freqs', Bands, 'last')); % P x SB x B (T, A, N) x F

lchData = squeeze(lchData);


yLims  = [-1 1.5];
figure
Data = squeeze(lchData(:, 2, [1 3], :));
plotSpectrumMountains(Data, Freqs', xLog, xLims, PlotProps, P.Labels);


% plot also BL theta, with all bursts
BL = mean(squeeze(lchData(:, 1, 3, :)), 1);
hold on
plot(log(Freqs), BL, ...
    'Color', PlotProps.Color.Generic, 'LineStyle','--', 'LineWidth', 1)

% ylim(yLims)
legend({'', 'SD theta burst power', 'Front BL power'}, 'location', 'southwest')
set(legend, 'ItemTokenSize', [15 15])
ylabel('PSD amplitude (z-scored)')



%%

clc
StatsP = P.StatsP;

Theta = dsearchn(Freqs, Bands.Theta');

sdTheta_Intact = squeeze(lchbData(:, 2, 3, 1)); % P x S x B (T, A, I) x F
blTheta_Intact = squeeze(lchbData(:, 1, 3, 1));
% blTheta_Intact = squeeze(lchbData(:, 1, 1, 1));
sdTheta_Burstless = squeeze(lchbData(:, 2, 1, 1));

%     PrcntIntact = 100*(sdTheta_Intact-sdTheta_Burstless)./sdTheta_Intact;

Intact = sdTheta_Intact-blTheta_Intact;
Burstless = sdTheta_Burstless-blTheta_Intact;
PrcntSDTheta = 100*(Intact-Burstless)./Intact;

dispDescriptive(PrcntSDTheta, 'Theta removed:', '%', 0);

Stats = pairedttest(blTheta_Intact, sdTheta_Intact, StatsP);
dispStat(Stats, [1 1], 'Intact change from BL:');

Stats = pairedttest(blTheta_Intact, sdTheta_Burstless, StatsP);
dispStat(Stats, [1 1], 'Burstless change from BL:');

disp('****')






