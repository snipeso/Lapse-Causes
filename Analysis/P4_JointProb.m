% script to

clear
clc
close all

P = analysisParameters();
StatsP = P.StatsP;
Paths  = P.Paths;
Bands = P.Bands;
BandLabels = fieldnames(Bands)';
PlotProps = P.Manuscript;
Participants = P.Participants;
TitleTag = 'ES';
MinTots = P.Parameters.MinTots; % minimum total of trials for that participant to be considered

SessionBlocks = P.SessionBlocks;
Sessions = [SessionBlocks.BL, SessionBlocks.SD];
SessionGroups = {1:6};
Task = 'LAT';

Parameters = P.Parameters;

load(fullfile(Paths.Pool, 'Tasks', [Task, '_AllTrials.mat']), 'Trials')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Gather data

% trial indexing
Q = quantile(Trials.Radius, [1/3 2/3]);
Closest = Trials.Radius<=Q(1);
Furthest = Trials.Radius>=Q(2);

EC_Stim = Trials.EC_Stimulus == 1;

BL = ismember(Trials.Session, SessionBlocks.BL);
SD = ismember(Trials.Session, SessionBlocks.SD);

Theta_Stim = Trials.Theta_Stimulus == 1;
NotTheta_Stim = Trials.Theta_Stimulus == 0;
Alpha_Stim = Trials.Alpha_Stimulus == 1;
NotAlpha_Stim = Trials.Alpha_Stimulus == 0;

Lapses = Trials.Type==1;

NanEyes = isnan(Trials.EC_Stimulus);
NanEEG = isnan(Trials.Theta_Stimulus);


%% Gather data

Plot = false;
AllStats = struct();
xLabels = {};

% eye status (compare furthest and closest trials with EO)
ProbType = squeeze(jointTally(Trials, ~NanEyes, EC_Stim, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
xLabels = cat(1, xLabels, 'Eyes closed');

% radius
ProbType = squeeze(jointTally(Trials, (Furthest | Closest), Furthest==1, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
xLabels = cat(1, xLabels, 'Distance');


% sleep deprivation
ProbType = squeeze(jointTally(Trials, [], SD, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType,  Plot));
xLabels = cat(1, xLabels, 'Sleep Deprivation');



% alpha
ProbType = squeeze(jointTally(Trials, SD & (Alpha_Stim | NotAlpha_Stim) & ~NanEEG, Alpha_Stim, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
xLabels = cat(1, xLabels, 'Alpha burst (SD)');

% theta
ProbType = squeeze(jointTally(Trials, SD & (Theta_Stim | NotTheta_Stim) & ~NanEEG, Theta_Stim, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
xLabels = cat(1, xLabels, 'Theta burst (SD)');


[sig, ~, ~, p_fdr] = fdr_bh([AllStats.p], StatsP.Alpha, StatsP.ttest.dep);


%% plot effect sizes

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width*1.2, PlotProps.Figure.Height*.15])

Legend = {};
Colors = [getColors(1, '', 'blue'); % EC
    getColors(1, '', 'green'); % distance
    getColors(1, '', 'purple'); % sleep deprivation
    getColors(1, '', 'yellow'); % alpha
    getColors(1, '', 'red'); % theta
getColors([1 2], '', 'blue');
  getColors([1 2], '', 'yellow'); % alpha
    getColors([1 2], '', 'red'); % theta

    ];

RangeA = 1:5; % for figure A
RangeB = 6:11; % for Figure B

Orientation = 'vertical';
PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 40;
PlotProps.Axes.yPadding = 30;

plotUFO([AllStats(RangeA).prcnt]', [AllStats(RangeA).prcntIQ]', xLabels(RangeA), ...
    Legend, Colors(RangeA, :), Orientation, PlotProps)

% plot significance
Means = [AllStats(RangeA).prcnt];
Means(~sig(RangeA)) = nan;

scatter(numel(Means):-1:1, Means, 'filled', 'w');
set(gca,'YAxisLocation','right', 'XAxisLocation', 'bottom');
ylabel("Increased probability of a lapse due to ...")
ylim([-.1 1])


saveFig('Figure_5', Paths.PaperResults, PlotProps)


%% display statistics
clc

for Indx_S = 1:numel(AllStats)
    dispStat(AllStats(Indx_S), [1 1], xLabels{Indx_S});
    
end













