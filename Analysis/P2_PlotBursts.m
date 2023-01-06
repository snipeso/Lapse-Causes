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
StatsP = P.StatsP;

TitleTag = strjoin({'Power', 'Burstless'}, '_');


Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
BandLabels = {'Theta', 'Alpha'};

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script


load(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent')
load(fullfile(Pool, strjoin({TitleTag, 'bChData.mat'}, '_')), 'ChData', 'sData', 'AllFields', 'Chanlocs', 'Freqs')



%% plot EEG with and without bursts

clc

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

%%% A: theta
SB = 2;
B_Indx = 1;
Ch_Indx = 1;


Data = log(squeeze(ChData(:, SB, [B_Indx, 3], Ch_Indx, :)));

Delta = squeeze(mean(Data(:, 1, NormBand_Indx(1):NormBand_Indx(2)), 3, 'omitnan'));
Shift = Delta - mean(Delta, 'omitnan');
Data = Data - Shift;

subfigure([], Grid, [1 1], [1 2], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotSpectrumMountains(Data, Freqs', xLog, xLims, PlotProps, P.Labels);

% plot also BL theta, with all bursts
BL = squeeze(mean(log(ChData(:, 1, 1, Ch_Indx, :))-Shift, 1, 'omitnan'));
hold on
plot(log(Freqs), BL, ...
    'Color', PlotProps.Color.Generic, 'LineStyle','--', 'LineWidth', 1)

ylim(yLims)
legend({'', 'Front SD theta burst power', 'Front BL power'}, 'location', 'southwest')
set(legend, 'ItemTokenSize', [15 15])
ylabel('Log PSD amplitude (\muV^2/Hz)')

disp(['A: N = ', num2str(nnz(~any(any(isnan(Data), 3), 2)))])

%%% B: alpha
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

disp(['B: N = ', num2str(nnz(~any(any(isnan(Data), 3), 2)))])


%%% C: stacked bar plot for time spent
Data = 100*squeeze(mean(TimeSpent, 1, 'omitnan'));

subfigure([], Grid, [1 5], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotStackedBars(Data(:, [1 3 2]), SB_Labels, YLim, Legend([1 3 2]), Colors([1 3 2], :), PlotProps);

ylabel('Recording duration (%)')

disp(['C: N = ', num2str(nnz(~any(any(isnan(TimeSpent), 3), 2)))])


saveFig('Figure_2', Paths.PaperResults, PlotProps)




%% plot all for inspection % DEBUG

% 
% %%% theta
% SB = 2;
% B_Indx = 1;
% Ch_Indx = 1;
% 
% 
% Data = log(squeeze(ChData(:, SB, [B_Indx, 3], Ch_Indx, :)));
% BL = log(squeeze(ChData(:, 1, [B_Indx, 3], Ch_Indx, :)));
% 
% 
% plotParticipantMountains(BL, Data, Freqs', xLog, xLims, PlotProps, P.Labels, Participants);


%% Percent SD theta removed with bursts

clc



% power with bursts
sdTheta_Intact = squeeze(lchbData(:, 2, 3, 1)); % P x S x B (T, A, I) x F
blTheta_Intact = squeeze(lchbData(:, 1, 3, 1));

% power without bursts
sdTheta_Burstless = squeeze(lchbData(:, 2, 1, 1));
blTheta_Burstless = squeeze(lchbData(:, 1, 1, 1));

% percentage of sdTheta that got gobbled up by bursts
sdBurst = sdTheta_Intact-sdTheta_Burstless;
blBurst = blTheta_Intact-blTheta_Burstless;
sdTheta = sdTheta_Intact-blTheta_Intact;
PrcntSDTheta = 100*(sdBurst-blBurst)./sdTheta;

% remove participants for which there's not enough of a theta increase
% (if sdTheta is too small, the percent change baloons)
PrcntSDTheta(sdTheta<.01) = nan;
dispDescriptive(PrcntSDTheta, 'Theta power removed:', '%', 0);

Stats = pairedttest(blTheta_Intact, sdTheta_Intact, StatsP);
dispStat(Stats, [1 1], 'Intact change from BL:');

Stats = pairedttest(blTheta_Burstless, sdTheta_Burstless, StatsP);
dispStat(Stats, [1 1], 'Burstless change from BL:');

disp('****')


%% percentages of bursts change BL vs SD

clc

% theta
Data_BL = 100*squeeze(sum(TimeSpent(:, 1, [1 3]), 3));
dispDescriptive(Data_BL, 'BL Theta', '%', 0);

Data_SD = 100*squeeze(sum(TimeSpent(:, 2, [1 3]), 3));
dispDescriptive(Data_SD, 'SD Theta', '%', 0);

Stats = pairedttest(Data_BL, Data_SD, StatsP);
dispStat(Stats, [1 1], 'Theta bursts BLvsSD:');
disp('   ')


% alpha
Data_BL = 100*squeeze(sum(TimeSpent(:, 1, [2 3]), 3));
dispDescriptive(Data_BL, 'BL alpha', '%', 0);

Data_SD = 100*squeeze(sum(TimeSpent(:, 2, [2 3]), 3));
dispDescriptive(Data_SD, 'SD alpha', '%', 0);

Stats = pairedttest(Data_BL, Data_SD, StatsP);
dispStat(Stats, [1 1], 'alpha BLvsSD:');



%% identify participants that don't show an increase in theta bursts with SD

clc

% get data
ThetaSD = squeeze(sum(TimeSpent(:, 2, [1 3]), 3)); % add both "pure" theta, and overlapping with alpha
ThetaBL = squeeze(sum(TimeSpent(:, 1, [1 3]), 3));

Data = [ThetaBL, ThetaSD];

% identify participants that don't show enough increase
Increase = 100*(ThetaSD-ThetaBL)./ThetaBL;
Remove = Increase<=50;

disp(['Removing ', num2str(nnz(Remove)), ' participants: '])
disp(Participants(Remove))

% re-calculate change from BL to SD
Data_BL = 100*squeeze(sum(TimeSpent(:, 1, [1 3]), 3));
Data_SD = 100*squeeze(sum(TimeSpent(:, 2, [1 3]), 3));
Stats = pairedttest(Data_BL(~Remove), Data_SD(~Remove), StatsP);
dispStat(Stats, [1 1], 'Theta bursts BLvsSD (redux):');

% make sure there's enough power
STD1 = std(Data_BL,0, 'omitnan');
STD2 = std(Data_SD,0, 'omitnan');
pooledSTD = sqrt((STD1^2+STD2^2)/2);

PWR = sampsizepwr('t', [mean(Data_BL, 'omitnan'), pooledSTD], ...
    mean(Data_SD, 'omitnan'), [], nnz(~isnan(Data_BL+Data_SD)));
disp(['Power for theta increase (before redux): ', num2str(PWR, '%.2f')])


% make sure there's enough power
STD1 = std(Data_BL(~Remove),0, 'omitnan');
STD2 = std(Data_SD(~Remove),0, 'omitnan');
pooledSTD = sqrt((STD1^2+STD2^2)/2);

PWR = sampsizepwr('t', [mean(Data_BL(~Remove), 'omitnan'), pooledSTD], ...
    mean(Data_SD(~Remove), 'omitnan'), [], nnz(~Remove));
disp(['Power for theta increase (after redux): ', num2str(PWR, '%.2f')])


