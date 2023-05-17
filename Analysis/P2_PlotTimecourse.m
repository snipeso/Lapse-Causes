% plot the timecourses showing relationship of bursts with lapses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();
Sessions = P.Sessions;
TallyLabels = P.Labels.Tally;
Paths = P.Paths;
Task = P.Labels.Task;
Channels = P.Channels;
StatsP = P.StatsP;
Windows = P.Parameters.Topography.Windows;


SmoothFactor = 0.3; % in seconds, smooth signal to be visually pleasing
CheckEyes = true; % check if person had eyes open or closed
Closest = false; % only use closest trials
ZScore = false; % best only z-scored; when raw, it's the average prob for each individual channel
SessionGroup = 'BL';

TitleTag = SessionGroup;
if CheckEyes
    TitleTag = [TitleTag, '_EO'];
end

if Closest
    TitleTag = [TitleTag, '_Close'];
    MicrosleepTag = '_Close';
else
    MicrosleepTag = '';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data

%%% microsleep data
load(fullfile(Paths.Pool, 'Eyes', ['ProbMicrosleep_', SessionGroup, MicrosleepTag, '.mat']), ...
    'ProbMicrosleep_Stim', 'ProbMicrosleep_Resp', 't_window', 'GenProbMicrosleep')
t_microsleep = t_window;

% smooth and z-score data
sProbMicrosleep_Stim = smoothFreqs(ProbMicrosleep_Stim, t_microsleep, 'last', SmoothFactor);

sProbMicrosleep_Resp = smoothFreqs(ProbMicrosleep_Resp, t_microsleep, 'last', SmoothFactor);

%%% burst data
load(fullfile(Paths.Pool, 'EEG', ['ProbBurst_', TitleTag, '.mat']), 'ProbBurst_Stim_Pooled', ...
    'ProbBurst_Resp_Pooled', 't_window',  'GenProbBurst_Pooled', 'Chanlocs')
t_burst = t_window;


% smooth signals
sProbBurst_Stim = smoothFreqs(ProbBurst_Stim_Pooled, t_burst, 'last', SmoothFactor); % P x TT x B x t
sProbBurst_Resp = smoothFreqs(ProbBurst_Resp_Pooled, t_burst, 'last', SmoothFactor);
%  z-score
if ZScore

    % z-score microsleep data
    [zProbMicrosleep_Stim, zGenProbMicrosleep] = ...
        zscoreTimecourse(sProbMicrosleep_Stim, GenProbMicrosleep, []);
    [zProbMicrosleep_Resp, ~] = ...
        zscoreTimecourse(sProbMicrosleep_Resp, GenProbMicrosleep, []);

    % z-score burst data
    [zProbBurst_Stim, zGenProbBurst] = ...
        zscoreTimecourse(sProbBurst_Stim, GenProbBurst_Pooled, 3);
    [zProbBurst_Resp, ~] = ...
        zscoreTimecourse(sProbBurst_Resp, GenProbBurst_Pooled, 3);

    TitleTag = [TitleTag, '_z-score'];
    zTag = ' (z-scored)';
    EC_Range = [-2 5.5];
    Range = [-2 1.5];

else

    % z-score microsleep data
    [zProbMicrosleep_Stim, zGenProbMicrosleep] = ...
        meanscoreTimecourse(sProbMicrosleep_Stim, GenProbMicrosleep, []);
    [zProbMicrosleep_Resp, ~] = ...
        meanscoreTimecourse(sProbMicrosleep_Resp, GenProbMicrosleep, []);

    % mean-shift burst data
    [zProbBurst_Stim, zGenProbBurst] = ...
        meanscoreTimecourse(sProbBurst_Stim, GenProbBurst_Pooled, 3);
    [zProbBurst_Resp, ~] = ...
        meanscoreTimecourse(sProbBurst_Resp, GenProbBurst_Pooled, 3);

    TitleTag = [TitleTag, '_raw'];
    zTag = '';
    %     EC_Range = [-100 300];
    %     Range = [-100 100];

    EC_Range = [-.35 .35];
    Range = [-.35 .35];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots and stats

%% display general prop of things

dispDescriptive(100*GenProbMicrosleep, 'EC gen prop', '%', 0);

dispDescriptive(100*GenProbBurst_Pooled(:, 1), 'Theta gen prop', '%', 0);
dispDescriptive(100*GenProbBurst_Pooled(:, 2), 'Alpha gen prop', '%', 0);

%% Figure 1

clc

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;


Grid = [2 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*1.2, PlotProps.Figure.Height*.5])

%%% stimulus locked
disp('****** EC ***********')
% eyeclosure
PlotProps.Stats.PlotN = true;
 PlotProps.Stats.DispStat = true;
subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
Stats = plotTimecourse(t_microsleep, flip(zProbMicrosleep_Stim, 2), zGenProbMicrosleep, ...
    EC_Range, flip(TallyLabels), 'Stimulus', getColors(3), StatsP, PlotProps);
ylim(EC_Range)
ylabel(['\Delta prop. trials with EC', zTag])

disp(['A: N=', num2str(mode(Stats.df(:))+1)])

% theta
disp('****** Theta ***********')
subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
Stats = plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 1, :)), 2), ...
    zGenProbBurst(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(Range)
ylabel(['\Delta prop. trials with theta burst', zTag])
legend off

disp(['B: N=',  num2str(mode(Stats.df(:))+1)])

% alpha
disp('****** alpha ***********')
subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
Stats = plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 2, :)), 2),  ...
    zGenProbBurst(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(Range)
ylabel(['\Delta prop. trials with alpha burst', zTag])
legend off

disp(['C: N=', num2str(mode(Stats.df(:))+1)])


%%% response locked

% eyeclosure
 PlotProps.Stats.DispStat = false;
subfigure([], Grid, [2 1], [], true, PlotProps.Indexes.Letters{4}, PlotProps);
Stats = plotTimecourse(t_microsleep, flip(zProbMicrosleep_Resp, 2), zGenProbMicrosleep, ...
    EC_Range, flip(TallyLabels), 'Response', getColors(3), StatsP, PlotProps);
ylim(EC_Range)
ylabel(['\Delta prop. trials with EC', zTag])
legend off

disp(['D: N=', num2str(mode(Stats.df(:))+1)])

% theta
subfigure([], Grid, [2 2], [], true, PlotProps.Indexes.Letters{5}, PlotProps);
Stats = plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 1, :)), 2), ...
    zGenProbBurst(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(Range)
ylabel(['\Delta prop. trials with theta burst', zTag])
legend off

disp(['E: N=', num2str(mode(Stats.df(:))+1)])


% alpha
subfigure([], Grid, [2 3], [], true, PlotProps.Indexes.Letters{6}, PlotProps);
Stats = plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 2, :)), 2),  ...
    zGenProbBurst(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(Range)
ylabel(['\Delta prop. trials with alpha burst', zTag])
legend off

disp(['F: N=', num2str(mode(Stats.df(:))+1)])


saveFig(['Figure_3_', TitleTag], Paths.PaperResults, PlotProps)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Stats

%% EC probabilities in little windows

clc

WindowLabels = {'Pre', 'Stimulus', 'Response', 'Post'};
TrialTypes = {'Lapses', 'Late', 'Correct'};

% Proportion of EC before stim
disp('---EC---')


for Indx_W = 1:size(Windows, 1)
    for Indx_TT = 1:numel(TrialTypes)
        Window = dsearchn(t_microsleep', Windows(Indx_W, :)');
        Prob = squeeze(mean(zProbMicrosleep_Stim(:, :, Window(1):Window(2)), 3, 'omitnan')); % P x TT

        Stats = pairedttest(zGenProbMicrosleep, Prob(:, Indx_TT), StatsP);
        dispStat(Stats, [1 1], [WindowLabels{Indx_W}, ' ' TrialTypes{Indx_TT}]);
    end
end

% mean values
Window = dsearchn(t_microsleep', Windows(2, :)'); % stim window
Prob = squeeze(mean(ProbMicrosleep_Stim(:, :, Window(1):Window(2)), 3, 'omitnan')); % P x TT
dispDescriptive(100*Prob(:, 3), 'Correct EC Proportion', '%', 0);
dispDescriptive(100*Prob(:, 2), 'late EC Proportion', '%', 0);
dispDescriptive(100*Prob(:, 1), 'lapse EC Proportion', '%', 0);

disp('*')

% late v correct
Point = 0;
Point = dsearchn(t_microsleep', Point);

Prob = squeeze(mean(zProbMicrosleep_Stim(:, [2 3], Point), 3, 'omitnan')); % P x TT

Stats = pairedttest(Prob(:, 2), Prob(:, 1), StatsP);
dispStat(Stats, [1 1], 'Stim late vs correct Proportion:');


%% burst Proportion
clc
BandLabels = {'Theta', 'Alpha'};
WindowLabels = {'Pre', 'Stimulus', 'Response', 'Post'};
TrialTypes = {'Lapses', 'Late', 'Correct'};

for Indx_B = 1:2

    disp(BandLabels{Indx_B})
    for Indx_TT = 1:3
        for Indx_W  = 1:size(Windows, 1)

            Window = dsearchn(t_burst', Windows(Indx_W, :)');
            Prob = squeeze(mean(zProbBurst_Stim(:, :, Indx_B, Window(1):Window(2)), 4, 'omitnan')); % P x TT

            Stats = pairedttest(zGenProbBurst(:, Indx_B), Prob(:, Indx_TT), StatsP);
            dispStat(Stats, [1 1], [WindowLabels{Indx_W}, ' ', TrialTypes{Indx_TT}]);
        end

        disp('***')
    end
    disp('____________')
end

Window =  dsearchn(t_burst', [1 2]');
Prob = squeeze(mean(zProbBurst_Stim(:, :, 2, Window(1):Window(2)), 4, 'omitnan')); % P x TT
Stats = pairedttest(zGenProbBurst(:, 2), Prob(:, 1), StatsP);
dispStat(Stats, [1 1], ['Intermezzo ', TrialTypes{1}]);