% gets the data showing the probability of eyesclosed over time for both
% lapses and other types of responses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
Sessions = P.SessionBlocks.SD;
Paths = P.Paths;
Task = P.Labels.Task;
Parameters = P.Parameters;

StartTime = Parameters.Timecourse.Start;
EndTime = Parameters.Timecourse.End;
fs = 250;
WelchWindow = 2;

ConfidenceThreshold = 0.5;
minTrials = Parameters.MinTypes;
MinNaN = 0.5;

Pool = fullfile(Paths.Pool, 'Eyes'); % place to save matrices so they can be plotted in next script

MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', 'AllTrials.mat'), 'Trials')
Q = quantile(Trials.Radius, 0.5);

TrialTypeLabels = [1 2 3];
Filenames = getContent(MicrosleepPath);
t = linspace(StartTime, EndTime, fs*(EndTime-StartTime));

ProbMicrosleep = nan(numel(Participants), numel(TrialTypeLabels), numel(t));
GenProbMicrosleep = nan(numel(Participants), 1);
ProbType = nan(numel(Participants), 3, 2); % proportion of trials resulting in lapse, split by whether there was eyes closed or not

for Indx_P = 1:numel(Participants)

    AllTrials_EC = [];
    AllTrials_Table = table();

    for Indx_S = 1:numel(Sessions)

        % trial info for current recording
        CurrentTrials = find(strcmp(Trials.Participant, Participants{Indx_P}) & ...
            strcmp(Trials.Session, Sessions{Indx_S}));
        nTrials = nnz(CurrentTrials);

        % load in eye data
        Filename = Filenames(contains(Filenames, Participants{Indx_P}) & ...
            contains(Filenames, Sessions{Indx_S}));

        if isempty(Filename)
            warning(['No data in ', Participants{Indx_P},  Sessions{Indx_S} ])
            continue
        elseif ~exist(fullfile(MicrosleepPath, Filename), 'file')
            warning(['No data in ', Filename])
            continue
        end
        load(fullfile(MicrosleepPath, Filename), 'Eyes')

        if isnan(Eyes.DQ) || Eyes.DQ == 0 || Eyes.DQ < 1
            warning(['Bad data in ', char(Filename)])
            continue
        end

        Eye = round(Eyes.DQ); % which eye

        % get 1s and 0s of whether eyes were open
        [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), fs, ConfidenceThreshold); % not using internal microsleep identifier so that I'm flexible

        % get each trial, save to field of trial type
        Trials_EC = nan(nTrials, numel(t));
        for Indx_T = 1:nTrials
            StimT = Trials.StimTime(CurrentTrials(Indx_T));
            Start = round(fs*(StimT+StartTime));
            End = round(fs*(StimT+EndTime))-1;

            Trial = EyeOpen(Start:End)==0; % just keep track of eyes closed
            Trials_EC(Indx_T, :) = Trial;
        end

        %%% pool sessions
        AllTrials_EC = cat(1, AllTrials_EC, Trials_EC);

        % save table info
        AllTrials_Table = cat(1, AllTrials_Table, Trials(CurrentTrials, :));

    end

    if isempty(AllTrials_Table)
        continue
    end


    %%% get probability of microsleep (in time) for each trial type
    for Indx_T = 1:3

        % choose trials
        Trial_Indexes = AllTrials_Table.Type==Indx_T & ...
            AllTrials_Table.Radius < Q;
        nTrials = nnz(Trial_Indexes);
        AllTrials = AllTrials_EC(Trial_Indexes, :, :);

        % check if there's enough data
        Nans = sum(isnan(AllTrials), 1);
        if isempty(AllTrials) || nTrials < minTrials || any(Nans > MinNaN) % makes sure every timepoint had at least 10 trials
            continue
        end

        % average trials
        ProbMicrosleep(Indx_P, Indx_T, :)  = sum(AllTrials, 1, 'omitnan')/nTrials;
    end

    % get general probability of eyes closed
    nTrials = size(AllTrials_EC, 1);
    GenProbMicrosleep(Indx_P) = mean(sum(AllTrials_EC, 1, 'omitnan')/nTrials, 'omitnan');


    %%% get probability of a lapse for every eyeclosure
    StimEdges = dsearchn(t', [0; .5]);
    StimWindow = StimEdges(1):StimEdges(2);


    EyeStatus = [0 1]; % eyes open, then closed
    for Indx_E = 1:2
        Prcnt = sum(AllTrials_EC(:, StimWindow)==EyeStatus(Indx_E), 3)/numel(StimWindow); % percent of stimulus window with eyes either open or closed
        Tots = nnz(Prcnt(AllTrials_Table.Radius < Q)>MinEC); % total trials to consider with eyes in that configuration
    end


    disp(['Finished ', Participants{Indx_P}])
end

% remove all data from participants missing any of the trial types
for Indx_P = 1:numel(Participants)
    if any(isnan(ProbMicrosleep(Indx_P, :, :)), 'all')
        ProbMicrosleep(Indx_P, :, :) = nan;
    end
end

%%% save
save(fullfile(Pool, 'ProbMicrosleep.mat'), 'ProbMicrosleep', 't', 'GenProbMicrosleep')
