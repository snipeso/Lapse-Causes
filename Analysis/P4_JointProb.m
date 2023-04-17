% script to

clear
clc
close all

P = analysisParameters();
StatsP = P.StatsP;
Paths  = P.Paths;
Bands = P.Bands;
BandLabels = fieldnames(Bands)';
Participants = P.Participants;
TitleTag = 'ES';
MinTots = P.Parameters.MinTots; % minimum total of trials for that participant to be considered

Task = 'LAT';

Parameters = P.Parameters;

load(fullfile(Paths.Pool, 'Tasks', [Task, '_AllTrials.mat']), 'Trials')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Gather data
%%

Windows = flip({'Pre', 'Stimulus', 'Response'});
Sessions = {'BL', 'SD'};
Columns = {'EC', 'Alpha', 'Theta'};
TrialType = 1;


Plot = false;
AllStats = struct();
xLabels = {};

for Indx_S = 1:2
    for Indx_C = 1:numel(Columns)
        for Indx_W = 1:numel(Windows)

            Window = Windows{Indx_W};

            % trial subsets
            EO = Trials.EC_Stimulus == 0;
            NanEyes = isnan(Trials.EC_Stimulus); % only ignore trials with EC during stimulus
            NanEEG = isnan(Trials.(['Theta_', Window])); % ignore trials depending on window of interest
            Session = ismember(Trials.Session, SessionBlocks.(Sessions{Indx_S}));


            %%% gather data
            % eye status (compare furthest and closest trials with EO)
            if Indx_C > 1
                TrialSubset = ~NanEEG & EO & Session;
            else
                TrialSubset = ~NanEyes & Session;
            end
            ProbType = adjustedJointProportion(Trials, TrialSubset, Columns{Indx_C}, Window, ...
                TrialType, Participants, MinTots);
            AllStats = catStruct(AllStats, getProbStats(ProbType, Plot));
            xLabels = cat(1, xLabels, [Columns{Indx_C}, ' – ', Window]);
        end
    end
end


[sig, ~, ~, p_fdr] = fdr_bh([AllStats.p], StatsP.Alpha, StatsP.ttest.dep);
sig = [AllStats.p] <.05; % TODO permutations

%% plot effect sizes


Orientation = 'vertical';
PlotProps = P.Manuscript;
PlotProps.Axes.xPadding = 40;
PlotProps.Axes.yPadding = 30;


Legend = {};
Colors = [getColors([1 3], '', 'blue'); % EC
    getColors([1 3], '', 'yellow'); % alpha
    getColors([1 3], '', 'red'); % theta
    ];


WindowLabels = {'before stimulus', 'during stimulus', 'during response'};
TotLines = 9;
Starts = 1:TotLines:numel(AllStats);

figure('units', 'centimeters', 'position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.6])

for Indx_S = 1:numel(Sessions)

    Range = Starts(Indx_S):Starts(Indx_S)+TotLines-1;

    subplot(numel(Sessions), 1, Indx_S)
    plotUFO([AllStats(Range).prcnt]', [AllStats(Range).prcntIQ]', xLabels(Range), ...
        Legend, Colors, Orientation, PlotProps)

    % plot significance
    Means = [AllStats(Range).prcnt];
    Means(~sig(Range)) = nan;

    scatter(numel(Means):-1:1, Means, 'filled', 'w');
    set(gca,'YAxisLocation','right', 'XAxisLocation', 'bottom');
    ylabel(['Increased probability of a lapse due to ... during ' Sessions{Indx_S}])
    ylim([-1 1])

end

saveFig('Figure_7', Paths.PaperResults, PlotProps)


%% display statistics
% clc
%
% for Indx_S = 1:numel(AllStats)
%     dispStat(AllStats(Indx_S), [1 1], xLabels{Indx_S});
% end









