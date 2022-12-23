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
fs = Parameters.fs;

ConfidenceThreshold = Parameters.EC_ConfidenceThreshold;
minTrials = Parameters.MinTypes;
minNanProportion = Parameters.MinNanProportion; % any more nans than this in a given trial is grounds to exclude the trial

Pool = fullfile(Paths.Pool, 'Eyes'); % place to save matrices so they can be plotted in next script

MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', 'AllTrials.mat'), 'Trials')
Q = quantile(Trials.Radius, 0.5);

t = linspace(StartTime, EndTime, fs*(EndTime-StartTime));

ProbMicrosleep_Stim = nan(numel(Participants), 3, numel(t));
ProbMicrosleep_Resp = ProbMicrosleep_Stim;
GenProbMicrosleep = zeros(numel(Participants), 2); % point with EC, and total points
nTrials_All = nan(numel(Participants), 3);

for Indx_P = 1:numel(Participants)

    AllTrials_Stim = [];
    AllTrials_Resp = [];
    AllTrials_Table = table();

    for Indx_S = 1:numel(Sessions)

        % trial info for current recording
        CurrentTrials = find(strcmp(Trials.Participant, Participants{Indx_P}) & ...
            strcmp(Trials.Session, Sessions{Indx_S}));
        nTrials = nnz(CurrentTrials);

        % load in eye data
        Eyes = loadMATFile(MicrosleepPath, Participants{Indx_P}, Sessions{Indx_S}, 'Eyes');
        if isempty(Eyes); continue; end

        if isnan(Eyes.DQ) || Eyes.DQ == 0 || Eyes.DQ < 1
            warning(['Bad data in ', Participants{Indx_P}, Sessions{Indx_S}])
            continue
        end

        Eye = round(Eyes.DQ); % which eye

        % get 1s and 0s of whether eyes were open
        [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), fs, ConfidenceThreshold); % not using internal microsleep identifier so that I'm flexible
        EyeClosed = double(EyeOpen == 0); % just keep track of eyes closed
        EyeClosed(isnan(EyeOpen)) = nan;

        % cut put each trial, pool together
        [Trials_Stim, Trials_Resp] = ...
            chopTrials(EyeClosed, Trials, CurrentTrials, StartTime, EndTime, fs);

        % pool sessions
        AllTrials_Stim = cat(1, AllTrials_Stim, Trials_Stim);
        AllTrials_Resp = cat(1, AllTrials_Resp, Trials_Resp);

        % save info
        AllTrials_Table = cat(1, AllTrials_Table, Trials(CurrentTrials, :));
        GenProbMicrosleep(Indx_P, 1) =  GenProbMicrosleep(Indx_P, 1) + nnz(EyeClosed==1);
        GenProbMicrosleep(Indx_P, 2) =  GenProbMicrosleep(Indx_P, 2) + nnz(EyeClosed==1 | EyeClosed==0);

    end

    if isempty(AllTrials_Table)
        warning('empty table')
        continue
    end

    %%% get probability of microsleep (in time) for each trial type
    for Indx_TT = 1:3

        % choose trials
        Trial_Indexes = AllTrials_Table.Type==Indx_TT; % & Closest;
        nTrials = nnz(Trial_Indexes);
        TypeTrials_Stim = AllTrials_Stim(Trial_Indexes, :);

        ProbMicrosleep_Stim(Indx_P, Indx_TT, :) = ...
            probEvent(TypeTrials_Stim, minNanProportion, minTrials);


        % response trials
        if Indx_TT > 1
            TypeTrials_Resp = AllTrials_Resp(Trial_Indexes, :);
            ProbMicrosleep_Resp(Indx_P, Indx_TT, :) = ...
                probEvent(TypeTrials_Resp, minNanProportion, minTrials);
        end
    end

    disp(['Finished ', Participants{Indx_P}])
end

% remove all data from participants missing any of the trial types
for Indx_P = 1:numel(Participants)
    if any(isnan(ProbMicrosleep_Stim(Indx_P, :, :)), 'all')
        ProbMicrosleep_Stim(Indx_P, :, :) = nan;
    end

    if any(isnan(ProbMicrosleep_Resp(Indx_P, 2:3, :)), 'all')
        ProbMicrosleep_Resp(Indx_P, :, :) = nan;
    end
end

% get general probability as fraction
GenProbMicrosleep = GenProbMicrosleep(:, 1)./GenProbMicrosleep(:, 2);

%%% save
save(fullfile(Pool, 'ProbMicrosleep.mat'), 'ProbMicrosleep_Stim', 'ProbMicrosleep_Resp', 't', 'GenProbMicrosleep')
