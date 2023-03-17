
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



%% Gather data

Plot = false;
AllStats = struct();
xLabels = {};

% eye status (compare furthest and closest trials with EO)
ProbType = squeeze(jointTally(Trials, SD & ~Furthest, EC, Lapses, Participants, ...
    Sessions, SessionGroups, true));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Eyes closed');

% radius
ProbType = squeeze(jointTally(Trials, EO & (Furthest | Closest), Furthest==1, Lapses, Participants, ...
    Sessions, SessionGroups, true));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Distance');


% sleep deprivation
ProbType = squeeze(jointTally(Trials, ~Furthest, SD, Lapses, Participants, ...
    Sessions, SessionGroups, true));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Sleep Dep');


% visual hemifield
ProbType = squeeze(jointTally(Trials, SD & Furthest, Trials.isRight==1, Lapses, Participants, ...
    Sessions, SessionGroups, true));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Hemifield (r, far)');

ProbType = squeeze(jointTally(Trials, SD & ~Furthest, Trials.isRight==1, Lapses, Participants, ...
    Sessions, SessionGroups, true));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Hemifield (r, close)');


% theta
ProbType = squeeze(jointTally(Trials, SD & ~Furthest & (Theta | NotTheta), Theta, Lapses, Participants, ...
    Sessions, SessionGroups, true));
AllStats = catStruct(AllStats, getProbStats(ProbType, StatsP, Plot));
xLabels = cat(1, xLabels, 'Theta');

% alpha
ProbType = squeeze(jointTally(Trials, SD & ~Furthest & (Alpha | NotAlpha), Alpha, Lapses, Participants, ...
    Sessions, SessionGroups, true));
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


function Stats = getProbStats(ProbType, StatsP, Plot)
% ProbType is a P x 3 matrix, with each column representing the proportion
% of event 1, event 2, and their combined occurances.

% assign readable variables
Prob1 = ProbType(:, 1);
Prob2 = ProbType(:, 2);
ActualJointProb = ProbType(:, 3);

% joint probability given proportions of thing1 and thing2
ExpectedJointProb = Prob1.*Prob2;

% statistically compare expected probability with actual probability
Stats = pairedttest(ExpectedJointProb, ActualJointProb, StatsP);

% quantify the difference as a percentage from the possible values, with 0%
% being entirely the expected joint probability, and 100% being completely
% dependent (and -100% completely anti-correlated)

% MinProb =  min(ProbType(:, [1 2]), [], 2);
MinProb =  ProbType(:, 1);
Prcnt = 100*(ProbType(:, 3)-ExpectedJointProb)./(MinProb-ExpectedJointProb);

Stats.prcnt = mean(Prcnt, 'omitnan');
Stats.prcntIQ = quantile(Prcnt, [.25 .75])';


if exist('Plot', 'var') && Plot
    figure
    hold on
    plot([0 1], [0 1], ':')
    scatter(ExpectedJointProb, ActualJointProb, 'filled')
    ylabel('Actual joint probability')
    xlabel('Expected joint probability')
    xlim([0 1])
    ylim([0 1])

end

end













