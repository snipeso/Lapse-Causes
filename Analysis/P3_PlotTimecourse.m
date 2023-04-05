% plot the timecourses showing relationship of bursts with lapses

clear
clc
% close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants_sdTheta; % only look at participants with substantial sdTheta
Participants = ones(1, 18);
Sessions = P.Sessions;
TallyLabels = P.Labels.Tally;
Paths = P.Paths;
Task = P.Labels.Task;
Channels = P.Channels;
StatsP = P.StatsP;

SmoothFactor = 0.3; % in seconds, smooth signal to be visually pleasing

SessionGroup = 'BL';
TitleTag = strjoin({'Timecourse', SessionGroup}, '_');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data

%%% microsleep data
load(fullfile(Paths.Pool, 'Eyes', ['ProbMicrosleep_', SessionGroup, '.mat']), 'ProbMicrosleep_Stim', 'ProbMicrosleep_Resp', 't', 'GenProbMicrosleep')
t_microsleep = t;

% remove low sdTheta participants for fairness of comparison
ProbMicrosleep_Stim(~Participants, :, :) = nan;
ProbMicrosleep_Resp(~Participants, :, :) = nan;

% smooth and z-score data
sProbMicrosleep_Stim = smoothFreqs(ProbMicrosleep_Stim, t_microsleep, 'last', SmoothFactor);
[zProbMicrosleep_Stim, zGenProbMicrosleep_Stim] = ...
    zscoreTimecourse(sProbMicrosleep_Stim, GenProbMicrosleep, []);

sProbMicrosleep_Resp = smoothFreqs(ProbMicrosleep_Resp, t_microsleep, 'last', SmoothFactor);
[zProbMicrosleep_Resp, zGenProbMicrosleep_Resp] = ...
    zscoreTimecourse(sProbMicrosleep_Resp, GenProbMicrosleep, []);


%%% burst data
load(fullfile(Paths.Pool, 'EEG', ['ProbBurst_', SessionGroup, '.mat']), 'ProbBurst_Stim', 'ProbBurst_Resp', 't',  'GenProbBurst')
t_burst = t;

% remove low sdTheta participants for obvious reasons
ProbBurst_Stim(~Participants, :, :) = nan;
ProbBurst_Resp(~Participants, :, :) = nan;

% smooth and z-score
sProbBurst_Stim = smoothFreqs(ProbBurst_Stim, t_burst, 'last', SmoothFactor);
[zProbBurst_Stim, zGenProbBurst_Stim] = ...
    zscoreTimecourse(sProbBurst_Stim, GenProbBurst, 3);

sProbBurst_Resp = smoothFreqs(ProbBurst_Resp, t_burst, 'last', SmoothFactor);
[zProbBurst_Resp, zGenProbBurst_Resp] = ...
    zscoreTimecourse(sProbBurst_Resp, GenProbBurst, 3);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots and stats


%% Figure 1

clc

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [-3.5 5.5];

Grid = [2 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

%%% stimulus locked

% eyeclosure
subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_microsleep, flip(zProbMicrosleep_Stim, 2), zGenProbMicrosleep_Stim, ...
    Range, flip(TallyLabels), 'Stimulus', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')

disp(['A: N=', num2str(nnz(~any(any(isnan(zProbMicrosleep_Stim), 3),2)))])

% theta
subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 1, :)), 2), ...
    zGenProbBurst_Stim(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta (z-scored)')
legend off

disp(['B: N=',  num2str(nnz(~any(any(isnan(squeeze(zProbBurst_Stim(:, :, 1, :))), 3),2)))])

% alpha
subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 2, :)), 2),  ...
    zGenProbBurst_Stim(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha (z-scored)')
legend off

disp(['C: N=', num2str(nnz(~any(any(isnan(squeeze(zProbBurst_Stim(:, :, 2, :))), 3),2)))])


%%% response locked

% eyeclosure
subfigure([], Grid, [2 1], [], true, PlotProps.Indexes.Letters{4}, PlotProps);
plotTimecourse(t_microsleep, flip(zProbMicrosleep_Resp, 2), zGenProbMicrosleep_Stim, ...
    Range, flip(TallyLabels), 'Response', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')
legend off

disp(['D: N=', num2str(nnz(~any(any(isnan(zProbMicrosleep_Resp(:, [2, 3], :)), 3),2)))])

% theta
subfigure([], Grid, [2 2], [], true, PlotProps.Indexes.Letters{5}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 1, :)), 2), ...
    zGenProbBurst_Resp(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta (z-scored)')
legend off

disp(['E: N=', num2str(nnz(~any(any(isnan(squeeze(zProbBurst_Resp(:, [2 3], 1, :))), 3),2)))])


% alpha
subfigure([], Grid, [2 3], [], true, PlotProps.Indexes.Letters{6}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 2, :)), 2),  ...
    zGenProbBurst_Resp(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha (z-scored)')
legend off

disp(['F: N=', num2str(nnz(~any(any(isnan(squeeze(zProbBurst_Resp(:, [2 3], 2, :))), 3),2)))])


saveFig('Figure_3', Paths.PaperResults, PlotProps)



%% raw values


PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;
Range = [0 1];

Grid = [2 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.5])

%%% stimulus locked
subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
plotTimecourse(t_microsleep, flip(sProbMicrosleep_Stim, 2), GenProbMicrosleep, ...
    Range, flip(TallyLabels), 'Stimulus', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')


subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Stim(:, :, 1, :)), 2), ...
    GenProbBurst(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta (z-scored)')
legend off


subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Stim(:, :, 2, :)), 2),  ...
    GenProbBurst(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha (z-scored)')
legend off


%%% response locked


subfigure([], Grid, [2 1], [], true, PlotProps.Indexes.Letters{4}, PlotProps);
plotTimecourse(t_microsleep, flip(sProbMicrosleep_Resp, 2), GenProbMicrosleep, ...
    Range, flip(TallyLabels), 'Response', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of EC (z-scored)')
legend off

subfigure([], Grid, [2 2], [], true, PlotProps.Indexes.Letters{5}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Resp(:, :, 1, :)), 2), ...
    GenProbBurst(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of theta (z-scored)')
legend off


subfigure([], Grid, [2 3], [], true, PlotProps.Indexes.Letters{6}, PlotProps);
plotTimecourse(t_burst, flip(squeeze(sProbBurst_Resp(:, :, 2, :)), 2),  ...
    GenProbBurst(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps)
ylim(Range)
ylabel('Probability of alpha (z-scored)')
legend off


saveFig('Figure_3-1', Paths.PaperResults, PlotProps)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Stats

%% EC probabilities in little windows

clc

% probability of EC before stim
preWindow = [-2 0];
Window = dsearchn(t_microsleep', preWindow');

Prob = squeeze(mean(zProbMicrosleep_Stim(:, :, Window(1):Window(2)), 3, 'omitnan')); % P x TT

Stats = pairedttest(zGenProbMicrosleep_Stim, Prob(:, 1), StatsP);
dispStat(Stats, [1 1], 'Pre Lapse probability:');


% during stim
stimWindow = [0 0.25];
Window = dsearchn(t_microsleep', stimWindow');

Prob = squeeze(mean(zProbMicrosleep_Stim(:, :, Window(1):Window(2)), 3, 'omitnan')); % P x TT

Stats = pairedttest(zGenProbMicrosleep_Stim, Prob(:, 1), StatsP);
dispStat(Stats, [1 1], 'Stim lapse probability:');

disp('*')

% mean values
Prob = squeeze(mean(ProbMicrosleep_Stim(:, :, Window(1):Window(2)), 3, 'omitnan')); % P x TT
dispDescriptive(100*Prob(:, 3), 'Correct EC probability', '%', 0);
dispDescriptive(100*Prob(:, 2), 'late EC probability', '%', 0);
dispDescriptive(100*Prob(:, 1), 'lapse EC probability', '%', 0);

disp('*')

% late v correct
Point = 0;
Point = dsearchn(t_microsleep', Point);

Prob = squeeze(mean(zProbMicrosleep_Stim(:, [2 3], Point), 3, 'omitnan')); % P x TT

Stats = pairedttest(Prob(:, 2), Prob(:, 1), StatsP);
dispStat(Stats, [1 1], 'Stim late vs correct probability:');


%% burst probability
clc
BandLabels = {'Theta', 'Alpha'};

for Indx_B = 1:2

    disp(BandLabels{Indx_B})

    % prob before stim
    Window = dsearchn(t_burst', preWindow');

    Prob = squeeze(mean(zProbBurst_Stim(:, :, Indx_B, Window(1):Window(2)), 4, 'omitnan')); % P x TT

    Stats = pairedttest(zGenProbBurst_Stim(:, Indx_B), Prob(:, 1), StatsP);
    dispStat(Stats, [1 1], 'Pre Lapse probability:');

    Stats = pairedttest(zGenProbBurst_Stim(:, Indx_B), Prob(:, 3), StatsP);
    dispStat(Stats, [1 1], 'Pre Correct probability:');


    % during stim
    Window = dsearchn(t_burst', stimWindow');

    Prob = squeeze(mean(zProbBurst_Stim(:, :, Indx_B, Window(1):Window(2)), 4, 'omitnan')); % P x TT

    Stats = pairedttest(zGenProbBurst_Stim(:, Indx_B), Prob(:, 1), StatsP);
    dispStat(Stats, [1 1], 'Stim Lapse probability:');


        % diff with correct
    Window = [.5 1.5];
    Window = dsearchn(t_burst', Window');

    Prob = squeeze(mean(zProbBurst_Stim(:, :, Indx_B, Window(1):Window(2)), 4, 'omitnan')); % P x TT

    Stats = pairedttest(Prob(:, 3), Prob(:, 1), StatsP);
    dispStat(Stats, [1 1], 'Post resp probability lapse v correct stim locked:');

    % correct after response
    Window = [0 1];
    Window = dsearchn(t_burst', Window');

    Prob = squeeze(mean(zProbBurst_Resp(:, :, Indx_B, Window(1):Window(2)), 4, 'omitnan')); % P x TT

    Stats = pairedttest(GenProbBurst(:,Indx_B), Prob(:, 3), StatsP);
    dispStat(Stats, [1 1], 'Post resp:');


    disp('____________')
end


