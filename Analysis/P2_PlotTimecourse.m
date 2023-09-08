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
    'ProbEyesClosedStimLocked', 'ProbEyesClosedRespLocked', 'TrialTime', 'ProbabilityEyesClosed')
TrialTime = TrialTime;

% smooth and z-score data
ProbEyesClosedStimLockedSmooth = smooth_frequencies(ProbEyesClosedStimLocked, TrialTime, 'last', SmoothFactor);
ProbEyesClosedRespLockedSmooth = smooth_frequencies(ProbEyesClosedRespLocked, TrialTime, 'last', SmoothFactor);

%%% burst data
load(fullfile(Paths.Pool, 'EEG', ['ProbBurst_', TitleTag, '.mat']), 'ProbBurst_Stim_Pooled', ...
    'ProbBurst_Resp_Pooled', 'TrialTime',  'ProbabilityBurst', 'Chanlocs')
t_burst = TrialTime;


% smooth signals
% sProbBurst_Stim = smooth_frequencies(ProbBurst_Stim_Pooled, t_burst, 'last', SmoothFactor); % P x TT x B x t
% sProbBurst_Resp = smooth_frequencies(ProbBurst_Resp_Pooled, t_burst, 'last', SmoothFactor);

sProbBurst_Stim = ProbBurst_Stim_Pooled;
sProbBurst_Resp = ProbBurst_Resp_Pooled;

%  z-score
if ZScore

    % z-score microsleep data
    [ProbEyesClosedStimLockedSmooth, ProbabilityEyesClosed] = ...
        zscoreTimecourse(ProbEyesClosedStimLockedSmooth, ProbabilityEyesClosed, []);
    [ProbEyesClosedRespLockedSmooth, ~] = ...
        zscoreTimecourse(ProbEyesClosedRespLockedSmooth, ProbabilityEyesClosed, []);

    % z-score burst data
    [zProbBurst_Stim, zGenProbBurst] = ...
        zscoreTimecourse(sProbBurst_Stim, ProbabilityBurst, 3);
    [zProbBurst_Resp, ~] = ...
        zscoreTimecourse(sProbBurst_Resp, ProbabilityBurst, 3);

    TitleTag = [TitleTag, '_z-score'];
    zTag = ' (z-scored)';
    YLim = [-2 5.5];
    YLim = [-2 1.5];

else

    % z-score microsleep data
    [ProbEyesClosedStimLockedSmooth, ProbabilityEyesClosed] = ...
        meanscoreTimecourse(ProbEyesClosedStimLockedSmooth, ProbabilityEyesClosed, []);
    [ProbEyesClosedRespLockedSmooth, ~] = ...
        meanscoreTimecourse(ProbEyesClosedRespLockedSmooth, ProbabilityEyesClosed, []);

    % mean-shift burst data
    [zProbBurst_Stim, zGenProbBurst] = ...
        meanscoreTimecourse(sProbBurst_Stim, ProbabilityBurst, 3);
    [zProbBurst_Resp, ~] = ...
        meanscoreTimecourse(sProbBurst_Resp, ProbabilityBurst, 3);

    TitleTag = [TitleTag, '_raw'];
    zTag = '';
    %     EC_Range = [-100 300];
    %     Range = [-100 100];

    YLim = [-.35 .35];
    YLim = [-.35 .35];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots and stats

%% display general prop of things

disp_stats_descriptive(100*ProbabilityEyesClosed, 'EC gen prop', '%', 0);

disp_stats_descriptive(100*ProbabilityBurst(:, 1), 'Theta gen prop', '%', 0);
disp_stats_descriptive(100*ProbabilityBurst(:, 2), 'Alpha gen prop', '%', 0);

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
 PlotProps.Stats.disp_stats = true;
chART.sub_plot([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
Stats = plot_timecourse(TrialTime, flip(ProbEyesClosedStimLockedSmooth, 2), ProbabilityEyesClosed, ...
    YLim, flip(TallyLabels), 'Stimulus', getColors(3), StatsP, PlotProps);
ylim(YLim)
ylabel(['\Delta prop. trials with EC', zTag])

disp(['A: N=', num2str(mode(Stats.df(:))+1)])

% theta
disp('****** Theta ***********')
chART.sub_plot([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
Stats = plot_timecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 1, :)), 2), ...
    zGenProbBurst(:, 1), YLim, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(YLim)
ylabel(['\Delta prop. trials with theta burst', zTag])
legend off

disp(['B: N=',  num2str(mode(Stats.df(:))+1)])

% alpha
disp('****** alpha ***********')
chART.sub_plot([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
Stats = plot_timecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 2, :)), 2),  ...
    zGenProbBurst(:, 2), YLim, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(YLim)
ylabel(['\Delta prop. trials with alpha burst', zTag])
legend off

disp(['C: N=', num2str(mode(Stats.df(:))+1)])


%%% response locked

% eyeclosure
 PlotProps.Stats.disp_stats = false;
chART.sub_plot([], Grid, [2 1], [], true, PlotProps.Indexes.Letters{4}, PlotProps);
Stats = plot_timecourse(TrialTime, flip(ProbEyesClosedRespLockedSmooth, 2), ProbabilityEyesClosed, ...
    YLim, flip(TallyLabels), 'Response', getColors(3), StatsP, PlotProps);
ylim(YLim)
ylabel(['\Delta prop. trials with EC', zTag])
legend off

disp(['D: N=', num2str(mode(Stats.df(:))+1)])

% theta
chART.sub_plot([], Grid, [2 2], [], true, PlotProps.Indexes.Letters{5}, PlotProps);
Stats = plot_timecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 1, :)), 2), ...
    zGenProbBurst(:, 1), YLim, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(YLim)
ylabel(['\Delta prop. trials with theta burst', zTag])
legend off

disp(['E: N=', num2str(mode(Stats.df(:))+1)])


% alpha
chART.sub_plot([], Grid, [2 3], [], true, PlotProps.Indexes.Letters{6}, PlotProps);
Stats = plot_timecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 2, :)), 2),  ...
    zGenProbBurst(:, 2), YLim, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(YLim)
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
        Window = dsearchn(TrialTime', Windows(Indx_W, :)');
        Prob = squeeze(mean(ProbEyesClosedStimLockedSmooth(:, :, Window(1):Window(2)), 3, 'omitnan')); % P x TT

        Stats = paired_ttest(ProbabilityEyesClosed, Prob(:, Indx_TT), StatsP);
        disp_stats(Stats, [1 1], [WindowLabels{Indx_W}, ' ' TrialTypes{Indx_TT}]);
    end
end

% mean values
Window = dsearchn(TrialTime', Windows(2, :)'); % stim window
Prob = squeeze(mean(ProbEyesClosedStimLocked(:, :, Window(1):Window(2)), 3, 'omitnan')); % P x TT
disp_stats_descriptive(100*Prob(:, 3), 'Correct EC Proportion', '%', 0);
disp_stats_descriptive(100*Prob(:, 2), 'late EC Proportion', '%', 0);
disp_stats_descriptive(100*Prob(:, 1), 'lapse EC Proportion', '%', 0);

disp('*')

% late v correct
Point = 0;
Point = dsearchn(TrialTime', Point);

Prob = squeeze(mean(ProbEyesClosedStimLockedSmooth(:, [2 3], Point), 3, 'omitnan')); % P x TT

Stats = paired_ttest(Prob(:, 2), Prob(:, 1), StatsP);
disp_stats(Stats, [1 1], 'Stim late vs correct Proportion:');


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

            Stats = paired_ttest(zGenProbBurst(:, Indx_B), Prob(:, Indx_TT), StatsP);
            disp_stats(Stats, [1 1], [WindowLabels{Indx_W}, ' ', TrialTypes{Indx_TT}]);
        end

        disp('***')
    end
    disp('____________')
end

Window =  dsearchn(t_burst', [1 2]');
Prob = squeeze(mean(zProbBurst_Stim(:, :, 2, Window(1):Window(2)), 4, 'omitnan')); % P x TT
Stats = paired_ttest(zGenProbBurst(:, 2), Prob(:, 1), StatsP);
disp_stats(Stats, [1 1], ['Intermezzo ', TrialTypes{1}]);