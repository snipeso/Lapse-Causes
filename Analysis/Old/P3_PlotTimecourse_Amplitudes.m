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

TitleTag = strjoin({'Timecourse'}, '_');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data

load(fullfile(Paths.Pool, 'EEG', 'Amplitudes.mat'), 'Amplitudes_Stim', 'Amplitudes_Resp', 't')
t_burst = t;
sAmp_Stim =  smoothFreqs(Amplitudes_Stim, t_burst, 'last', .5);
sAmp_temp_Stim = permute(sAmp_Stim, [1 2 4 3]);
zAmp_Stim = zScoreData(sAmp_temp_Stim, 'last');
zAmp_Stim = permute(zAmp_Stim, [1 2 4 3]);

sAmp_Resp =  smoothFreqs(Amplitudes_Resp, t_burst, 'last', .5);
sAmp_temp_Resp = permute(sAmp_Resp, [1 2 4 3]);
zAmp_Resp = zScoreData(sAmp_temp_Resp, 'last');
zAmp_Resp = permute(zAmp_Resp, [1 2 4 3]);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots and stats


%% z-scored timecourse

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [-3.5 5];

Grid = [1 2];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

chART.sub_plot([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zAmp_Stim(:, :, 1, :)), 2), ...
    [], Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Amplitude of Theta (z-scored)')
legend off


chART.sub_plot([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zAmp_Stim(:, :, 2, :)), 2),  ...
    [], Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Amplitude of Alpha (z-scored)')
legend off

saveFig([TitleTag, '_Amp_zscored'], Paths.PaperResults, PlotProps)


%% raw timecoure

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [0 300];

Grid = [1 2];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

chART.sub_plot([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sAmp_Stim(:, :, 1, :)), 2), ...
    [], Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Amplitude of theta')
legend off


chART.sub_plot([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sAmp_Stim(:, :, 2, :)), 2), ...
    [], Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Amplitude of alpha')
legend off

saveFig([TitleTag, '_Amp_raw'], Paths.PaperResults, PlotProps)


%% z-scored timecourse response

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [-3.5 5];

Grid = [1 2];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

chART.sub_plot([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zAmp_Resp(:, :, 1, :)), 2), ...
    [], Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Amplitude of Theta (z-scored)')
legend off


chART.sub_plot([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zAmp_Resp(:, :, 2, :)), 2),  ...
    [], Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Amplitude of Alpha (z-scored)')
legend off

saveFig([TitleTag, '_Amp_zscored_resp'], Paths.PaperResults, PlotProps)




%% raw timecoure responses

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [0 300];

Grid = [1 2];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.3])

chART.sub_plot([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sAmp_Resp(:, :, 1, :)), 2), ...
    [], Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Amplitude of theta')
legend off

chART.sub_plot([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sAmp_Resp(:, :, 2, :)), 2),  ...
    [], Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Amplitude of alpha')
legend off

saveFig([TitleTag, '_Amp_raw_resp'], Paths.PaperResults, PlotProps)