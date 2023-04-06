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

EO = Trials.EC == 0;
EC = Trials.EC == 1;

BL = ismember(Trials.Session, SessionBlocks.BL);
SD = ismember(Trials.Session, SessionBlocks.SD);

Theta = Trials.Theta == 1;
NotTheta = Trials.Theta == 0;
Alpha = Trials.Alpha == 1;
NotAlpha = Trials.Alpha == 0;

Lapses = Trials.Type==1;

NanEyes = isnan(Trials.EC);
NanEEG = isnan(Trials.Theta);


%% Gather data

Plot = false;
AllStats = struct();
xLabels = {};

% eye status (compare furthest and closest trials with EO)
ProbType = squeeze(jointTally(Trials, [], EC, Lapses, Participants, ...
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
ProbType = squeeze(jointTally(Trials, SD & (Alpha | NotAlpha) & ~NanEEG & ~NanEyes, Alpha, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
xLabels = cat(1, xLabels, 'Alpha burst');

% theta
ProbType = squeeze(jointTally(Trials, SD & (Theta | NotTheta) & ~NanEEG & ~NanEyes, Theta, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
xLabels = cat(1, xLabels, 'Theta burst');


[sig, ~, ~, p_fdr] = fdr_bh([AllStats.p], StatsP.Alpha, StatsP.ttest.dep);



%% plot effect sizes

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width*1.2, PlotProps.Figure.Height*.15])
Grid = [1 1];

Legend = {};
Colors = [getColors(1, '', 'blue');
    getColors(1, '', 'green');
    getColors(1, '', 'purple');  
    getColors(1, '', 'yellow');
        getColors(1, '', 'red');
    ];

Orientation = 'vertical';
PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 40;
PlotProps.Axes.yPadding = 30;
% subfigure([], Grid, [1 1], [], true, '', PlotProps);
plotUFO([AllStats.prcnt]', [AllStats.prcntIQ]', xLabels, Legend, Colors, Orientation, PlotProps)


% plot significance
Means = [AllStats.prcnt];
Means(~sig) = nan;
scatter(numel(Means):-1:1, Means, 'filled', 'w');
set(gca,'YAxisLocation','right', 'XAxisLocation', 'bottom');
ylabel("Increased probability of a lapse due to ...")
ylim([-.1 1])
saveFig('Figure_5', Paths.PaperResults, PlotProps)




% TODO:
% GET DF!!
% might be better to always make the 100% relative to the occurances of
% interest (EC, theta), rather than the smallest?





%% functions










