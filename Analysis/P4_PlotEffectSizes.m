% retrofit microsleep/burst timecourse scripts to produce output
% This script compares the effects of:
% - distance from center (50% split)
% - eyeclosure
% - theta burst
% - alpha bursts

% P x T x 2 % T is already normalized to the number of total trials

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
% Sessions = [SessionBlocks.BL, SessionBlocks.SD]; % different representation for the tabulateTable function
% SessionGroups = {1:3, 4:6};
Sessions = [SessionBlocks.BL, SessionBlocks.SD];
SessionGroups = {1:6};

Parameters = P.Parameters;

Radius = 2/3;


load(fullfile(Paths.Pool, 'Tasks', 'AllTrials.mat'), 'Trials')

Q = quantile(Trials.Radius, [1/3 2/3]);
Closest = Trials.Radius<=Q(1);
Furthest = Trials.Radius>=Q(2);
EO = Trials.EC == 0;
EC = Trials.EC == 1;

BL = ismember(Trials.Session, SessionBlocks.BL);
SD = ismember(Trials.Session, SessionBlocks.SD);

%%

HedgesG = nan(1, 5);
HedgesGCI = nan(2, 5);
xLabels = {};

clc

% radius
ProbType = splitTally(Trials, EO & Closest & SD, EO & Furthest & SD, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 1, HedgesG, HedgesGCI, xLabels, 'Distance', StatsP);
dispStat(Stats, [1 1], 'SD distance (EO):');


% eye status
ProbType = splitTally(Trials, EO & ~Furthest & SD, EC & ~Furthest & SD, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 2, HedgesG, HedgesGCI, xLabels, 'EC', StatsP);
dispStat(Stats, [1 1], 'Eyes:');


% sleep deprivation
ProbType = splitTally(Trials, EO & ~Furthest & BL, EO & ~Furthest & SD, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 3, HedgesG, HedgesGCI, xLabels, 'SD', StatsP);
dispStat(Stats, [1 1], 'SD:');


% Theta
Theta = Trials.Theta == 1;
NotTheta = Trials.Theta == 0;
% ProbType = splitTally(Trials, EO & ~Furthest & SD & NotTheta, EO & ~Furthest & SD & Theta, Participants, ...
%     Sessions, SessionGroups, MinTots, BadParticipants);
ProbType = splitTally(Trials, EO & ~Furthest & SD & NotTheta, EO & ~Furthest & SD & Theta, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 3, HedgesG, HedgesGCI, xLabels, 'Theta', StatsP);
dispStat(Stats, [1 1], 'Theta:');



% alpha
Alpha = Trials.Alpha == 1;
NotAlpha = Trials.Alpha == 0;
ProbType = splitTally(Trials, EO & ~Furthest & SD & NotAlpha, EO & ~Furthest & SD &Alpha, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 3, HedgesG, HedgesGCI, xLabels, 'Alpha', StatsP);
dispStat(Stats, [1 1], 'Alpha:');











%%


%%% load in data

HedgesG = nan(1, 5);
HedgesGCI = nan(2, 5);
xLabels = {};

% eyes closed lapses
[HedgesG, HedgesGCI, xLabels] = loadG(1, HedgesG, HedgesGCI, xLabels, 'EC', ...
    fullfile(Paths.Pool, 'Eyes', 'ProbType_EC.mat'), StatsP);

% Sleep deprivation
[HedgesG, HedgesGCI, xLabels] = loadG(2, HedgesG, HedgesGCI, xLabels, 'SD (EO)', ...
    fullfile(Paths.Pool, 'Tasks', 'ProbType_SD.mat'), StatsP);

% Load distance lapses
[HedgesG, HedgesGCI, xLabels] = loadG(3, HedgesG,HedgesGCI, xLabels, 'Distance (EO)', ...
    fullfile(Paths.Pool, 'Tasks', 'ProbType_Radius.mat'), StatsP);

% Bursts
[HedgesG, HedgesGCI, xLabels] = loadG(4, HedgesG, HedgesGCI, xLabels, 'Alpha (EO)', fullfile(Paths.Pool, 'EEG', 'ProbType_Alpha.mat'), StatsP);
[HedgesG, HedgesGCI, xLabels] = loadG(5, HedgesG, HedgesGCI, xLabels, 'Theta (EO)', fullfile(Paths.Pool, 'EEG', 'ProbType_Theta.mat'), StatsP);


figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width*1, PlotProps.Figure.Height*.2])
Grid = [1 1];

Legend = {};
Colors = getColors(5);
Orientation = 'vertical';
PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 50;
subfigure([], Grid, [1 1], [], true, '', PlotProps);
plotUFO(HedgesG', HedgesGCI', xLabels, Legend, Colors, Orientation, PlotProps)
ylabel("Hedge's g effect on lapse probability")

saveFig(TitleTag, Paths.PaperResults, PlotProps)


function [HedgesG, HedgesGCI, Labels, Stats] = loadG(ProbType, Indx, HedgesG, HedgesGCI, Labels, Label, StatsP)

Stats = pairedttest(squeeze(ProbType(:, 1, 1)), squeeze(ProbType(:, 1, 2)), StatsP); % P x T x EovsEc

HedgesG(Indx) = Stats.hedgesg;
HedgesGCI(:, Indx) = Stats.hedgesgCI;

Labels{Indx} = Label;

end
