
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
BadParticipants = not(P.Participants_sdTheta)';
TitleTag = 'ES';
MinTots = P.Parameters.MinTots; % minimum total of trials for that participant to be considered

SessionBlocks = P.SessionBlocks;
Sessions = [SessionBlocks.BL, SessionBlocks.SD];
SessionGroups = {1:6};

Parameters = P.Parameters;

load(fullfile(Paths.Pool, 'Tasks', 'AllTrials.mat'), 'Trials')

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
ProbType = squeeze(jointTally(Trials, SD & ~Furthest & ~NanEyes, EC, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Eyes closed');

% radius
ProbType = squeeze(jointTally(Trials, EO & (Furthest | Closest) & ~NanEyes, Furthest==1, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Distance');


% sleep deprivation
ProbType = squeeze(jointTally(Trials, [], SD, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Sleep Dep');

ProbType = squeeze(jointTally(Trials, ~Furthest & EO & ~NanEyes, SD, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Sleep Dep (EO, close)');


% visual hemifield
ProbType = squeeze(jointTally(Trials, SD & Furthest & EO & ~NanEyes, Trials.isRight==1, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'R Hemifield (EO, far)');

ProbType = squeeze(jointTally(Trials, SD, Trials.isRight==1, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'R Hemifield');


% theta
ProbType = squeeze(jointTally(Trials, SD & ~Furthest & (Theta | NotTheta) & EO & ~NanEEG & ~NanEyes, Theta, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Theta');

% alpha
ProbType = squeeze(jointTally(Trials, SD & ~Furthest & (Alpha | NotAlpha) & EO & ~NanEEG & ~NanEyes, Alpha, Lapses, Participants, ...
    Sessions, SessionGroups));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Alpha');



[sig, ~, ~, p_fdr] = fdr_bh([AllStats.p], StatsP.Alpha, StatsP.ttest.dep);



%% plot effect sizes

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width*1.2, PlotProps.Figure.Height*.2])
Grid = [1 1];

Legend = {};
Colors = [getColors(1, '', 'blue');
    getColors(1, '', 'green');
    getColors(1, '', 'purple');  
     getColors(1, '', 'pink');  
    .4, .4, .4;
    .8 .8 .8;
    getColors(1, '', 'red');
    getColors(1, '', 'yellow');
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
ylim([-40 100])
saveFig('Figure_5', Paths.PaperResults, PlotProps)




% TODO:
% GET DF!!
% might be better to always make the 100% relative to the occurances of
% interest (EC, theta), rather than the smallest?





%% functions










