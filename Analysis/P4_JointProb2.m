
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
SessionBlocks = P.SessionBlocks;

Task = 'LAT';

Parameters = P.Parameters;

load(fullfile(Paths.Pool, 'Tasks', [Task, '_AllTrials.mat']), 'Trials')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Gather data
%%

Windows = {'Pre', 'Stimulus', 'Response'};
Sessions = {'BL', 'SD'};
Columns = {'EC', 'Alpha', 'Theta'};
TrialType = 1;


Plot = false;
AllStats = struct();
xLabels = {};
StatsTable = struct();
Indx = 1;
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
            Stats = getProbStats(ProbType, Plot);


            StatsTable(Indx).Session = Sessions{Indx_S};
            StatsTable(Indx).Event = Columns{Indx_C};
            StatsTable(Indx).Window = Window;
            StatsTable(Indx).Proportion = dispDescriptive(ProbType(:, 1), '', '', 2);
            StatsTable(Indx).LapseProp = dispDescriptive(ProbType(:, 2), '', '', 2);
            StatsTable(Indx).Expected = dispDescriptive(ProbType(:, 1).*ProbType(:, 2), '', '', 2);
            StatsTable(Indx).Observed = dispDescriptive(ProbType(:, 3), '', '', 2);

            StatsTable(Indx).p = Stats.p;
            StatsTable(Indx).N = Stats.N;
            if Stats.p < StatsP.Alpha
            StatsTable(Indx).RequiredN = Stats.RequiredN;
            else
                StatsTable(Indx).RequiredN = nan;
            end
            Indx = Indx+1;
        end
    end
end

StatsTable = struct2table(StatsTable);

[~, ~, ~, StatsTable.p_fdr] = fdr_bh(StatsTable.p, StatsP.Alpha, StatsP.ttest.dep);
