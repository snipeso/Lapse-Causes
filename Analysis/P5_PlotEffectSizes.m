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


%%% gather effect sizes
HedgesG = nan(1, 5);
HedgesGCI = nan(2, 5);
xLabels = {};

clc

% eye status
ProbType = splitTally(Trials, EO & ~Furthest & SD, EC & ~Furthest & SD, Participants, ...
    Sessions, SessionGroups, MinTots, zeros(numel(Participants), 1));

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 1, HedgesG, HedgesGCI, xLabels, 'EC', StatsP);
dispStat(Stats, [1 1], 'Eyes:');


% radius
ProbType = splitTally(Trials, EO & Closest & SD, EO & Furthest & SD, Participants, ...
    Sessions, SessionGroups, MinTots, zeros(numel(Participants), 1));

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 2, HedgesG, HedgesGCI, xLabels, 'Distance', StatsP);
dispStat(Stats, [1 1], 'Distance:');


% sleep deprivation
ProbType = splitTally(Trials, EO & ~Furthest & BL, EO & ~Furthest & SD, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 3, HedgesG, HedgesGCI, xLabels, 'SD', StatsP);
dispStat(Stats, [1 1], 'SD:');


% Theta
ProbType = splitTally(Trials, EO & ~Furthest & SD & NotTheta, EO & ~Furthest & SD & Theta, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 4, HedgesG, HedgesGCI, xLabels, 'Theta', StatsP);
dispStat(Stats, [1 1], 'Theta:');


% alpha
ProbType = splitTally(Trials, EO & ~Furthest & SD & NotAlpha, EO & ~Furthest & SD &Alpha, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);

[HedgesG, HedgesGCI, xLabels, Stats] = ...
    loadG(ProbType, 5, HedgesG, HedgesGCI, xLabels, 'Alpha', StatsP);
dispStat(Stats, [1 1], 'Alpha:');



%%% get info for model of how many lapses theoretically possible

% calculate stats without discarding data
EventProb = nan(numel(Participants), 2, 3); % EC, theta, alpha
LapseProb = nan(numel(Participants), 3, 2);

[ProbType, EventProb(:, :, 1)] = splitTally(Trials, ~Furthest & EO & SD, ~Furthest & EC & SD, Participants, ...
    Sessions, SessionGroups, MinTots, zeros(numel(Participants), 1));
LapseProb(:, 1, :) = squeeze(ProbType(:, 1, :));

[ProbType, EventProb(:, :, 2)] = splitTally(Trials, ~Furthest & SD & EO & NotTheta, ~Furthest & SD & EO & Theta, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);
LapseProb(:, 2, :) = squeeze(ProbType(:, 1, :));

[ProbType, EventProb(:, :, 3)] = splitTally(Trials, ~Furthest & SD & EO & NotAlpha, ~Furthest & SD & EO & Alpha, Participants, ...
    Sessions, SessionGroups, MinTots, BadParticipants);
LapseProb(:, 3, :) = squeeze(ProbType(:, 1, :));

LapseProbNot = squeeze(LapseProb(:, :, 1));
LapseProb = squeeze(LapseProb(:, :, 2));

EventProb = squeeze(EventProb(:, 2, :));

[Tally1, ~] = tabulateTable(Trials, ~Furthest & SD, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, true); % P x SB x TT
GenLapseProb = squeeze(Tally1(:, 1, 1))./sum(squeeze(Tally1),2, 'omitnan');

[Tally2, ~] = tabulateTable(Trials, ~Furthest & SD & EO, 'Type', 'tabulate', ...
    Participants, Sessions, SessionGroups, true); % P x SB x TT

GenLapseProb(:, 2:3) = repmat(squeeze(Tally2(:, 1, 1))./sum(squeeze(Tally2),2, 'omitnan'), 1, 2);

GenLapseProb(BadParticipants, [2 3]) = nan;
EventProb(BadParticipants, [2 3]) = nan;
LapseProb(BadParticipants, [ 2 3]) = nan;
LapseProbNot(BadParticipants, [ 2 3]) = nan;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Plots & stats

%% plot effect sizes

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
PlotProps.Axes.xPadding = 60;
subfigure([], Grid, [1 1], [], true, '', PlotProps);
plotUFO(HedgesG', HedgesGCI', xLabels, Legend, Colors, Orientation, PlotProps)
ylabel("Hedge's g effect on lapse probability")

saveFig('Figure_5', Paths.PaperResults, PlotProps)




%% plot model

Legend = {'EC', 'Theta', 'Alpha'};
Colors = [getColors(1, '', 'blue');
    getColors(1, '', 'red');
    getColors(1, '', 'yellow');
    ];
Grid = [1, 2];

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width*.5, PlotProps.Figure.Height*.3])
plotChangeProb(EventProb, LapseProb, LapseProbNot, GenLapseProb, Legend, Colors, PlotProps)

saveFig('Figure_6', Paths.PaperResults, PlotProps)



%% proportions of data

clc

%%% general probabilities
for Indx = 1:numel(Legend)
    dispDescriptive(100*EventProb(:, Indx), ['SD lapse probability during ' Legend{Indx}], '%', 0);
end

disp('*')

%%% max % trials resulting in lapse during X
for Indx = 1:numel(Legend)
NewX = GenLapseProb(:, Indx)./EventProb(:, Indx);

dispDescriptive(100*NewX, [ Legend{Indx}, ' max % lapses'], '%', 0);
dispDescriptive(100*LapseProbNot(:, Indx), ['Not ' Legend{Indx}, ' % lapses'], '%', 0);
Mean1 = mean(LapseProbNot(:, Indx), 'omitnan');
Mean2 = mean(NewX, 'omitnan'); 

STD1 = std(LapseProbNot(:, Indx),0, 'omitnan');
STD2 = std(NewX,0, 'omitnan');
pooledSTD = sqrt((STD1^2+STD2^2)/2);

% N needed to find that difference from "non event" data
N  = sampsizepwr('t', [Mean1, pooledSTD], Mean2, .8, []);
disp([Legend{Indx}, ' sample needed to find max lapse chance: N=', num2str(N, '%.0f')])

% max proportion detectable with current sample size
N = nnz(~isnan(LapseProbNot(:, Indx)));
M2  = sampsizepwr('t', [Mean1, STD1], [], .8, N);
disp([Legend{Indx}, ' max ES = ', num2str(100*M2, '%.0f'), '%; N=', num2str(N)])

disp(['Min max % of trials caused by theta bursts'])

disp('  ')
end

dispDescriptive(100*GenLapseProb(:, 2), 'Gen lapse prob', '%', 0);

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions


function [HedgesG, HedgesGCI, Labels, Stats] = loadG(ProbType, Indx, HedgesG, HedgesGCI, Labels, Label, StatsP)
%%% little function to get stats for all the different comparisons

Stats = pairedttest(squeeze(ProbType(:, 1, 1)), squeeze(ProbType(:, 1, 2)), StatsP); % P x T x EovsEc

HedgesG(Indx) = Stats.hedgesg;
HedgesGCI(:, Indx) = Stats.hedgesgCI;

Labels{Indx} = [Label, ' (N=',num2str(Stats.N), ')'];

end
