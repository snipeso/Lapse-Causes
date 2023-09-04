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
ROI = fieldnames(Channels.preROI);

SmoothFactor = 0.2; % in seconds;

TitleTag = strjoin({'Timecourse'}, '_');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data


% burst data
load(fullfile(Paths.Pool, 'EEG', 'ProbBurst_ROI.mat'), 'ProbBurst_Stim', 'ProbBurst_Resp', 't',  'GenProbBurst')
t_burst = t;
sProbBurst_Stim = smoothFreqs(ProbBurst_Stim, t_burst, 'last', SmoothFactor);
[zProbBurst_Stim, zGenProbBurst_Stim] = ...
    zscoreTimecourse(sProbBurst_Stim, GenProbBurst, 3);


sProbBurst_Resp = smoothFreqs(ProbBurst_Resp, t_burst, 'last', SmoothFactor);
[zProbBurst_Resp, zGenProbBurst_Resp] = ...
    zscoreTimecourse(sProbBurst_Resp, GenProbBurst, 3);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots and stats


%% Figure 1


PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [-3.5 5];

Grid = [2 3];

BandLabels = {'theta', 'alpha'};

for Indx_B = 1:2
   
figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.5])
Indx = 1;

for Indx_Ch = 1:numel(ROI)

chART.sub_plot([], Grid, [1 Indx_Ch], [], true, PlotProps.Indexes.Letters{Indx}, PlotProps); Indx = Indx+1;
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, Indx_Ch, Indx_B, :)), 2), ...
    squeeze(zGenProbBurst_Stim(:, Indx_Ch, Indx_B)), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel(['Probability of ', BandLabels{Indx_B}, ' (z-scored)'])
if Indx_Ch>1
legend off
end

end

%%% response locked
for Indx_Ch = 1:numel(ROI)

chART.sub_plot([], Grid, [2 Indx_Ch], [], true, PlotProps.Indexes.Letters{Indx}, PlotProps); Indx = Indx+1;
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, Indx_Ch, Indx_B, :)), 2), ...
    squeeze(zGenProbBurst_Resp(:, Indx_Ch, Indx_B)), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta (z-scored)')
legend off

end
% saveFig(['Figure_3-', BandLabels{Indx_B}], Paths.PaperResults, PlotProps)
end


%% raw values


PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [0 1];

Grid = [2 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

chART.sub_plot([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_microsleep, flip(sProbMicrosleep_Stim, 2), GenProbMicrosleep, ...
    Range, flip(TallyLabels), 'Stimulus', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')


chART.sub_plot([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Stim(:, :, 1, :)), 2), ...
    GenProbBurst(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta (z-scored)')
legend off


chART.sub_plot([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Stim(:, :, 2, :)), 2),  ...
    GenProbBurst(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha (z-scored)')
legend off


%%% response locked


chART.sub_plot([], Grid, [2 1], [], true, PlotProps.Indexes.Letters{4}, PlotProps);
plotTimecourse(t_microsleep, flip(sProbMicrosleep_Resp, 2), GenProbMicrosleep, ...
    Range, flip(TallyLabels), 'Response', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')
legend off

chART.sub_plot([], Grid, [2 2], [], true, PlotProps.Indexes.Letters{5}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Resp(:, :, 1, :)), 2), ...
    GenProbBurst(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta (z-scored)')
legend off


chART.sub_plot([], Grid, [2 3], [], true, PlotProps.Indexes.Letters{6}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Resp(:, :, 2, :)), 2),  ...
    GenProbBurst(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha (z-scored)')
legend off


saveFig('Figure_3-1', Paths.PaperResults, PlotProps)
