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
%%

Windows = {'Pre', 'Stimulus', 'Response'};

Plot = false;
AllStats = struct();
xLabels = {};

for Indx_W = 2%1:numel(Windows)

    Window = Windows{Indx_W};

    % trial indexing
    Q = quantile(Trials.Radius, [1/3 2/3]);
    Closest = Trials.Radius<=Q(1);
    Furthest = Trials.Radius>=Q(2);

    EC = Trials.(['EC_', Window]) == 1;

    BL = ismember(Trials.Session, SessionBlocks.BL);
    SD = ismember(Trials.Session, SessionBlocks.SD);

    Theta = Trials.(['Theta_', Window]) == 1;
    NotTheta = Trials.(['Theta_', Window]) == 0;
    Alpha = Trials.(['Alpha_', Window]) == 1;
    NotAlpha = Trials.(['Alpha_', Window]) == 0;

%     Lapses = Trials.Type==1;
 Lapses = Trials.Type==3;

    NanEyes = isnan(Trials.EC_Stimulus); % only ignore trials with EC during stimulus
    NanEEG = isnan(Trials.(['Theta_', Window])); % ignore trials depending on window of interest


    %%% gather data

    % eye status (compare furthest and closest trials with EO)
    ProbType = squeeze(jointTally(Trials, ~NanEyes & SD, EC, Lapses, Participants, ...
        Sessions, SessionGroups));
    JP = getEventProb(ProbType);
    AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
    xLabels = cat(1, xLabels, 'Eyes closed – SD');

    ProbType = squeeze(jointTally(Trials, ~NanEyes & BL, EC, Lapses, Participants, ...
        Sessions, SessionGroups));
    AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
    xLabels = cat(1, xLabels, 'Eyes closed – BL');


    % alpha
    ProbType = squeeze(jointTally(Trials, SD & (Alpha | NotAlpha) & ~NanEEG & ~EC, Alpha, Lapses, Participants, ...
        Sessions, SessionGroups));
    AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
    xLabels = cat(1, xLabels, 'Alpha burst – SD');

    ProbType = squeeze(jointTally(Trials, BL & (Alpha | NotAlpha) & ~NanEEG & ~EC, Alpha, Lapses, Participants, ...
        Sessions, SessionGroups));
    AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
    xLabels = cat(1, xLabels, 'Alpha burst – BL');


    % theta
    ProbType = squeeze(jointTally(Trials, SD & (Theta | NotTheta) & ~NanEEG & ~EC, Theta, Lapses, Participants, ...
        Sessions, SessionGroups));
    AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
    xLabels = cat(1, xLabels, 'Theta burst – SD');

    ProbType = squeeze(jointTally(Trials, BL & (Theta | NotTheta) & ~NanEEG & ~EC, Theta, Lapses, Participants, ...
        Sessions, SessionGroups));
    AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
    xLabels = cat(1, xLabels, 'Theta burst – BL');

end


[sig, ~, ~, p_fdr] = fdr_bh([AllStats.p], StatsP.Alpha, StatsP.ttest.dep);
sig = [AllStats.p] <.05;

%% plot effect sizes


Orientation = 'vertical';
PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 40;
PlotProps.Axes.yPadding = 30;


Legend = {};
Colors = [getColors([1 2], '', 'blue'); % EC
    getColors([1 2], '', 'yellow'); % alpha
    getColors([1 2], '', 'red'); % theta
    ];


WindowLabels = {'BEFORE stimulus', 'DURING stimulus', 'DURING response'};
TotLines = 6;
Starts = 1:TotLines:numel(AllStats);

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.6])

for Indx_W = 1:numel(Windows)

    Range = Starts(Indx_W):Starts(Indx_W)+TotLines-1;


    subplot(numel(Windows), 1, Indx_W)
    plotUFO([AllStats(Range).prcnt]', [AllStats(Range).prcntIQ]', xLabels(Range), ...
        Legend, Colors, Orientation, PlotProps)

    % plot significance
    Means = [AllStats(Range).prcnt];
    Means(~sig(Range)) = nan;

    scatter(numel(Means):-1:1, Means, 'filled', 'w');
    set(gca,'YAxisLocation','right', 'XAxisLocation', 'bottom');
    ylabel(['Increased probability of a lapse due to ... ', WindowLabels{Indx_W}])
    ylim([-.1 1])

end

saveFig('Figure_5', Paths.PaperResults, PlotProps)


%% display statistics
% clc
% 
% for Indx_S = 1:numel(AllStats)
%     dispStat(AllStats(Indx_S), [1 1], xLabels{Indx_S});
% end









