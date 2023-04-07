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

SmoothFactor = 0.3; % in seconds, smooth signal to be visually pleasing
CheckEyes = true; % check if person had eyes open or closed
Closest = true; % only use closest trials
ZScore = true; % best only z-scored; when raw, it's the average prob for each individual channel 
SessionGroup = 'SD';

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
load(fullfile(Paths.Pool, 'Eyes', ['ProbMicrosleep_', SessionGroup, MicrosleepTag, '.mat']), 'ProbMicrosleep_Stim', 'ProbMicrosleep_Resp', 't_window', 'GenProbMicrosleep')
t_microsleep = t_window;

% remove all data from participants missing any of the trial types
[ProbMicrosleep_Stim, ProbMicrosleep_Resp] = removeBlankParticipants(ProbMicrosleep_Stim, ProbMicrosleep_Resp);

% smooth and z-score data
sProbMicrosleep_Stim = smoothFreqs(ProbMicrosleep_Stim, t_microsleep, 'last', SmoothFactor);

sProbMicrosleep_Resp = smoothFreqs(ProbMicrosleep_Resp, t_microsleep, 'last', SmoothFactor);

%%% burst data
load(fullfile(Paths.Pool, 'EEG', ['ProbBurst_', TitleTag, '.mat']), 'ProbBurst_Stim', ...
    'ProbBurst_Resp', 't_window',  'GenProbBurst', 'Chanlocs')
t_burst = t_window;
TotChannels = size(GenProbBurst, 2);

% remove all data from participants missing any of the trial types
for Indx_B = 1:2
    for Indx_Ch = 1:TotChannels
        [ProbBurst_Stim(:, :, Indx_Ch, Indx_B, :), ProbBurst_Resp(:, :, Indx_Ch, Indx_B, :)] = ...
            removeBlankParticipants(squeeze(ProbBurst_Stim(:, :, Indx_Ch, Indx_B, :)), ...
            squeeze(ProbBurst_Resp(:, :, Indx_Ch, Indx_B, :)));
    end
end

%  z-score
if ZScore

    % z-score microsleep data
    [zProbMicrosleep_Stim, zGenProbMicrosleep] = ...
        zscoreTimecourse(sProbMicrosleep_Stim, GenProbMicrosleep, []);
    [zProbMicrosleep_Resp, ~] = ...
        zscoreTimecourse(sProbMicrosleep_Resp, GenProbMicrosleep, []);

    % z-score burst data
    [zProbBurst_Stim, zGenProbBurst] = ...
        zscoreTimecourse(ProbBurst_Stim, GenProbBurst, 4);
    [zProbBurst_Resp, ~] = ...
        zscoreTimecourse(ProbBurst_Resp, GenProbBurst, 4);

    TitleTag = [TitleTag, '_z-score'];
    zTag = ' (z-scored)';
    EC_Range = [-2 5.5];
    Range = [-2 1.5];
else
    % microsleep data
    zProbMicrosleep_Stim = sProbMicrosleep_Stim;
    zProbMicrosleep_Resp = sProbMicrosleep_Resp;
    zGenProbMicrosleep = GenProbMicrosleep;

    % burst data
    zProbBurst_Stim = ProbBurst_Stim;
    zProbBurst_Resp = ProbBurst_Resp;
    zGenProbBurst = GenProbBurst;
     TitleTag = [TitleTag, '_raw'];
     zTag = '';
         EC_Range = [0 1];
    Range = [0 1];
end

% average channels
zProbBurst_Stim = squeeze(mean(zProbBurst_Stim, 3, 'omitnan'));
zProbBurst_Resp = squeeze(mean(zProbBurst_Resp, 3, 'omitnan'));


% smooth signals
zProbBurst_Stim = smoothFreqs(zProbBurst_Stim, t_burst, 'last', SmoothFactor);
zProbBurst_Resp = smoothFreqs(zProbBurst_Resp, t_burst, 'last', SmoothFactor);






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots and stats


%% Figure 1

clc

PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 25;


Grid = [2 3];

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*1.2, PlotProps.Figure.Height*.5])

%%% stimulus locked

% eyeclosure

subfigure([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
Stats = plotTimecourse(t_microsleep, flip(zProbMicrosleep_Stim, 2), zGenProbMicrosleep, ...
    EC_Range, flip(TallyLabels), 'Stimulus', getColors(3), StatsP, PlotProps);
ylim(EC_Range)
ylabel(['Probability of EC', zTag])

disp(['A: N=', num2str(mode(Stats.df(:))+1)])

% theta
subfigure([], Grid, [1 2], [], true, PlotProps.Indexes.Letters{2}, PlotProps);
Stats = plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 1, :)), 2), ...
    zGenProbBurst(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(Range)
ylabel(['Probability of theta', zTag])
legend off

disp(['B: N=',  num2str(mode(Stats.df(:))+1)])

% alpha
subfigure([], Grid, [1 3], [], true, PlotProps.Indexes.Letters{3}, PlotProps);
Stats = plotTimecourse(t_burst, flip(squeeze(zProbBurst_Stim(:, :, 2, :)), 2),  ...
    zGenProbBurst(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(Range)
ylabel(['Probability of alpha', zTag])
legend off

disp(['C: N=', num2str(mode(Stats.df(:))+1)])


%%% response locked

% eyeclosure
subfigure([], Grid, [2 1], [], true, PlotProps.Indexes.Letters{4}, PlotProps);
Stats = plotTimecourse(t_microsleep, flip(zProbMicrosleep_Resp, 2), zGenProbMicrosleep, ...
    EC_Range, flip(TallyLabels), 'Response', getColors(3), StatsP, PlotProps);
ylim(EC_Range)
ylabel(['Probability of EC', zTag])
legend off

disp(['D: N=', num2str(mode(Stats.df(:))+1)])

% theta
subfigure([], Grid, [2 2], [], true, PlotProps.Indexes.Letters{5}, PlotProps);
Stats = plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 1, :)), 2), ...
    zGenProbBurst(:, 1), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(Range)
ylabel(['Probability of theta', zTag])
legend off

disp(['E: N=', num2str(mode(Stats.df(:))+1)])


% alpha
subfigure([], Grid, [2 3], [], true, PlotProps.Indexes.Letters{6}, PlotProps);
Stats = plotTimecourse(t_burst, flip(squeeze(zProbBurst_Resp(:, :, 2, :)), 2),  ...
    zGenProbBurst(:, 2), Range, flip(TallyLabels), '', getColors(3), StatsP, PlotProps);
ylim(Range)
ylabel(['Probability of alpha', zTag])
legend off

disp(['F: N=', num2str(mode(Stats.df(:))+1)])


saveFig(['Figure_3_', TitleTag], Paths.PaperResults, PlotProps)



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Stats

%% EC probabilities in little windows

clc

% probability of EC before stim
disp('---EC---')
preWindow = [-2 0];
Window = dsearchn(t_microsleep', preWindow');

Prob = squeeze(mean(zProbMicrosleep_Stim(:, :, Window(1):Window(2)), 3, 'omitnan')); % P x TT

Stats = pairedttest(zGenProbMicrosleep, Prob(:, 1), StatsP);
dispStat(Stats, [1 1], 'Pre Lapse probability:');


% during stim
stimWindow = [0 0.3];
Window = dsearchn(t_microsleep', stimWindow');

Prob = squeeze(mean(zProbMicrosleep_Stim(:, :, Window(1):Window(2)), 3, 'omitnan')); % P x TT

Stats = pairedttest(zGenProbMicrosleep, Prob(:, 1), StatsP);
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

    Stats = pairedttest(zGenProbBurst(:, Indx_B), Prob(:, 1), StatsP);
    dispStat(Stats, [1 1], 'Pre Lapse probability:');

    Stats = pairedttest(zGenProbBurst(:, Indx_B), Prob(:, 3), StatsP);
    dispStat(Stats, [1 1], 'Pre Correct probability:');

        % prob JUST before stim
    Window = dsearchn(t_burst', [-.5 0]');
    Prob = squeeze(mean(zProbBurst_Stim(:, :, Indx_B, Window(1):Window(2)), 4, 'omitnan')); % P x TT

    Stats = pairedttest(zGenProbBurst(:, Indx_B), Prob(:, 1), StatsP);
    dispStat(Stats, [1 1], 'Narrow Pre Lapse probability:');

    Stats = pairedttest(zGenProbBurst(:, Indx_B), Prob(:, 3), StatsP);
    dispStat(Stats, [1 1], 'Narrow Pre Correct probability:');


    % during stim
    Window = dsearchn(t_burst', stimWindow');

    Prob = squeeze(mean(zProbBurst_Stim(:, :, Indx_B, Window(1):Window(2)), 4, 'omitnan')); % P x TT

    Stats = pairedttest(zGenProbBurst(:, Indx_B), Prob(:, 1), StatsP);
    dispStat(Stats, [1 1], 'Stim Lapse probability:');

    % lapse well afte rresponse
      Window = dsearchn(t_burst', [2 4]');

    Prob = squeeze(mean(zProbBurst_Stim(:, :, Indx_B, Window(1):Window(2)), 4, 'omitnan')); % P x TT

    Stats = pairedttest(zGenProbBurst(:, Indx_B), Prob(:, 1), StatsP);
    dispStat(Stats, [1 1], 'Post stim Lapse probability:');

        Stats = pairedttest(zGenProbBurst(:, Indx_B), Prob(:, 3), StatsP);
    dispStat(Stats, [1 1], 'Post stim correct probability:');


    % correct after response
    Window = [0 1];
    Window = dsearchn(t_burst', Window');

    Prob = squeeze(mean(zProbBurst_Resp(:, :, Indx_B, Window(1):Window(2)), 4, 'omitnan')); % P x TT

    Stats = pairedttest(GenProbBurst(:,Indx_B), Prob(:, 3), StatsP);
    dispStat(Stats, [1 1], 'Post resp correct:');

        Stats = pairedttest(GenProbBurst(:,Indx_B), Prob(:, 2), StatsP);
    dispStat(Stats, [1 1], 'Post resp late:');


    disp('____________')
end


