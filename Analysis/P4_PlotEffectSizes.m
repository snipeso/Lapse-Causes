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


load(fullfile(Paths.Pool, 'Tasks', 'AllTrials.mat'), 'Trials')



%%

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

HedgesG = nan(1, 5);
HedgesGCI = nan(2, 5);
xLabels = {};

clc

% eye status
[ProbType, ProbEvent(:, :, 1)] = splitTally(Trials, EO & ~Furthest & SD, EC & ~Furthest & SD, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

LapseProb(:, 1) = squeeze(ProbType(:, 1, 2));

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 1, HedgesG, HedgesGCI, xLabels, 'EC', StatsP);
dispStat(Stats, [1 1], 'Eyes:');



% radius
ProbType = splitTally(Trials, EO & Closest & SD, EO & Furthest & SD, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 2, HedgesG, HedgesGCI, xLabels, 'Distance', StatsP);
dispStat(Stats, [1 1], 'SD distance:');


% sleep deprivation
ProbType = splitTally(Trials, EO & ~Furthest & BL, EO & ~Furthest & SD, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 3, HedgesG, HedgesGCI, xLabels, 'SD', StatsP);
dispStat(Stats, [1 1], 'SD:');


% Theta
[ProbType, ProbEvent(:, :, 2)] = splitTally(Trials, EO & ~Furthest & SD & NotTheta, EO & ~Furthest & SD & Theta, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);
LapseProb(:, 2) = squeeze(ProbType(:, 1, 2));

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 4, HedgesG, HedgesGCI, xLabels, 'Theta', StatsP);
dispStat(Stats, [1 1], 'Theta:');


% alpha
[ProbType, ProbEvent(:, :, 3)] = splitTally(Trials, EO & ~Furthest & SD & NotAlpha, EO & ~Furthest & SD &Alpha, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);
LapseProb(:, 3) = squeeze(ProbType(:, 1, 2));

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 5, HedgesG, HedgesGCI, xLabels, 'Alpha', StatsP);
dispStat(Stats, [1 1], 'Alpha:');


figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width*1, PlotProps.Figure.Height*.2])
Grid = [1 1];

Legend = {};
Colors = [getColors(1, '', 'blue');
    getColors(1, '', 'green');
    getColors(1, '', 'purple');
    getColors(1, '', 'red');
    getColors(1, '', 'yellow');
    ];
Orientation = 'vertical';
PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 50;
subfigure([], Grid, [1 1], [], true, '', PlotProps);
plotUFO(HedgesG', HedgesGCI', xLabels, Legend, Colors, Orientation, PlotProps)
ylabel("Hedge's g effect on lapse probability")

saveFig(TitleTag, Paths.PaperResults, PlotProps)



%% plot models


% calculate stats without discarding data
ProbEvent = nan(numel(Participants), 2, 3); % EC, theta, alpha
LapseProb = nan(numel(Participants), 3);

[ProbType, ProbEvent(:, :, 1)] = splitTally(Trials, ~Furthest & EO & SD, ~Furthest & EC & SD, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);
LapseProb(:, 1) = squeeze(ProbType(:, 1, 2));

[ProbType, ProbEvent(:, :, 2)] = splitTally(Trials, ~Furthest & SD & EO & NotTheta, ~Furthest & SD & EO & Theta, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);
LapseProb(:, 2) = squeeze(ProbType(:, 1, 2));

[ProbType, ProbEvent(:, :, 3)] = splitTally(Trials, ~Furthest & SD & EO & NotAlpha, ~Furthest & SD & EO & Alpha, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);
LapseProb(:, 3) = squeeze(ProbType(:, 1, 2));

ProbEvent = squeeze(ProbEvent(:, 2, :));

[Tally1, ~] = tabulateTable(Trials, ~Furthest & SD, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, true); % P x SB x TT
GenLapseProb = squeeze(Tally1(:, 1, 1))./sum(squeeze(Tally1),2, 'omitnan');

[Tally2, ~] = tabulateTable(Trials, ~Furthest & SD & EO, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, true); % P x SB x TT

GenLapseProb(:, 2:3) = repmat(squeeze(Tally2(:, 1, 1))./sum(squeeze(Tally2),2, 'omitnan'), 1, 2);

GenLapseProb(BadParticipants, :) = nan;
ProbEvent(BadParticipants, :) = nan;
LapseProb(BadParticipants, :) = nan;

%%


Legend = {'EC', 'Theta', 'Alpha'};
Colors = [getColors(1, '', 'blue');
      getColors(1, '', 'red');
    getColors(1, '', 'yellow');
];
Grid = [1, 2];

figure
plotChangeProb(ProbEvent, LapseProb, GenLapseProb, Legend, Colors, PlotProps)



%%
function [HedgesG, HedgesGCI, Labels, Stats] = loadG(ProbType, Indx, HedgesG, HedgesGCI, Labels, Label, StatsP)

Stats = pairedttest(squeeze(ProbType(:, 1, 1)), squeeze(ProbType(:, 1, 2)), StatsP); % P x T x EovsEc

HedgesG(Indx) = Stats.hedgesg;
HedgesGCI(:, Indx) = Stats.hedgesgCI;

Labels{Indx} = Label;

end
