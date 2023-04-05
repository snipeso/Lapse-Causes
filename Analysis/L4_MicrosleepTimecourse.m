% gets the data showing the probability of eyesclosed over time for each
% trial outcome type. 

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
SessionBlocks = P.SessionBlocks;
Paths = P.Paths;
Task = P.Labels.Task; % LAT
Parameters = P.Parameters;

TrialWindow = Parameters.Timecourse.Window;
fs = Parameters.fs;
ConfidenceThreshold = Parameters.EC_ConfidenceThreshold; % value of pupil confidence to mark eye-closures
minTrials = Parameters.MinTypes; % there needs to be at least these many trials for all trial types to include that participant.
minNanProportion = Parameters.MinNanProportion; % any more nans in time than this in a given trial is grounds to exclude the trial
Max_Radius_Quantile = Parameters.Radius; % only use trials that are relatively close to fixation point

nTrialTypes = 3; 

% locations
Pool = fullfile(Paths.Pool, 'Eyes'); % place to save matrices so they can be plotted in next script
MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);

SesionBlockLabels = fieldnames(SessionBlocks);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', [Task, '_AllTrials.mat']), 'Trials')
Max_Radius = quantile(Trials.Radius, Max_Radius_Quantile);

t = linspace(TrialWindow(1), TrialWindow(2), fs*(TrialWindow(2)-TrialWindow(1))); % time vector


for Indx_SB = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = P.SessionBlocks.(SesionBlockLabels{Indx_SB});

    ProbMicrosleep_Stim = nan(numel(Participants), nTrialTypes, numel(t)); % P x TT x t matrix with final probabilities
    ProbMicrosleep_Resp = ProbMicrosleep_Stim;
    GenProbMicrosleep = nan(numel(Participants), 1); % get general probability of a microsleep for a given session block (to control for when z-scoring)

    for Indx_P = 1:numel(Participants)

        AllTrials_Stim = []; % need to pool all trials across sessions in a given session block
        AllTrials_Resp = [];
        AllTrials_Table = table();
        MicrosleepTimepoints = [0 0]; % total number of points in recording that is a microsleep; total number of points, pooling sessions

        for Indx_S = 1:numel(Sessions)

            % trial info for current recording
            CurrentTrials = find(strcmp(Trials.Participant, Participants{Indx_P}) & ...
                strcmp(Trials.Session, Sessions{Indx_S}));
            nTrials = nnz(CurrentTrials);

            % load in eye data
            Eyes = loadMATFile(MicrosleepPath, Participants{Indx_P}, Sessions{Indx_S}, 'Eyes');
            if isempty(Eyes); continue; end

            if isnan(Eyes.DQ) || Eyes.DQ == 0
                warning(['Bad data in ', Participants{Indx_P}, Sessions{Indx_S}])
                continue
            end

            Eye = round(Eyes.DQ); % which eye

            % get 1s and 0s of whether eyes were open
            [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), fs, ConfidenceThreshold); % not using internal microsleep identifier so that I'm flexible
            EyeClosed = double(EyeOpen == 0); % just keep track of eyes closed
            EyeClosed(isnan(EyeOpen)) = nan;

            % cut out each trial, pool together
            [Trials_Stim, Trials_Resp] = ...
                chopTrials(EyeClosed, Trials(CurrentTrials, :), TrialWindow, fs);

            % pool sessions
            AllTrials_Stim = cat(1, AllTrials_Stim, Trials_Stim);
            AllTrials_Resp = cat(1, AllTrials_Resp, Trials_Resp);

            % save info
            AllTrials_Table = cat(1, AllTrials_Table, Trials(CurrentTrials, :));

            MicrosleepTimepoints = tallyTimepoints(MicrosleepTimepoints, EyeClosed);
        end

        if isempty(AllTrials_Table)
            warning('empty table')
            continue
        end

        %%% get probability of microsleep (in time) for each trial type
        for Indx_TT = 1:3

            % choose trials
            Trial_Indexes = AllTrials_Table.Type==Indx_TT & AllTrials_Table.Radius < Max_Radius; % & Closest;
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

        % calculate general probability of a microsleep
GenProbMicrosleep(Indx_P) = Tally(1)./Tally(2);
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

    %%% save
    save(fullfile(Pool, ['ProbMicrosleep_', SesionBlockLabels{Indx_SB}, '.mat']), 'ProbMicrosleep_Stim', 'ProbMicrosleep_Resp', 't', 'GenProbMicrosleep')
end