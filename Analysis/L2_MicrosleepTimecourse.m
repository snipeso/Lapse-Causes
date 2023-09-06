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
SampleRate = Parameters.fs;
ConfidenceThreshold = Parameters.EC_ConfidenceThreshold; % value of pupil confidence to mark eye-closures
minTrials = Parameters.MinTypes; % there needs to be at least these many trials for all trial types to include that participant.
MaxNaNProportion = Parameters.MinNanProportion; % any more nans in time than this in a given trial is grounds to exclude the trial
MaxStimulusDistance = Parameters.Radius; % only use trials that are relatively close to fixation point

nTrialTypes = 3;
OnlyClosestStimuli = true; % only use closest trials

% locations
Pool = fullfile(Paths.Pool, 'Eyes'); % place to save matrices so they can be plotted in next script
if ~exist(Pool, 'dir')
    mkdir(Pool)
end

EyetrackingPath = fullfile(Paths.Data, ['Pupils_', num2str(SampleRate)], Task);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', [Task, '_AllTrials.mat']), 'Trials')

TrialTime = linspace(TrialWindow(1), TrialWindow(2), SampleRate*(TrialWindow(2)-TrialWindow(1))); % time vector

% specify only close trials, or all trials
TitleTag = '';
if OnlyClosestStimuli
    TitleTag = [ TitleTag, '_Close'];
    MaxStimulusDistance = quantile(Trials.Radius, MaxStimulusDistance);
else
    MaxStimulusDistance = max(Trials.Radius);
end

SessionBlockLabels = fieldnames(SessionBlocks);
for Indx_SB = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = P.SessionBlocks.(SessionBlockLabels{Indx_SB});

    EyesClosedStim = nan(numel(Participants), 3, numel(TrialTime)); % P x TT x t matrix with final probabilities
    EyesClosedResp = EyesClosedStim;
    ProbabilityEyesClosed = nan(numel(Participants), 1); % get general probability of a microsleep for a given session block (to control for when z-scoring)

    for idxParticipant = 1:numel(Participants)

        AllTrials_Stim = []; % need to pool all trials across sessions in a given session block
        AllTrials_Resp = [];
        AllTrials_Table = table();
        MicrosleepTimepoints = [0 0]; % total number of points in recording that is a microsleep; total number of points, pooling sessions

        for idxSession = 1:numel(Sessions)

            % trial info for current recording
            CurrentTrials = find(strcmp(Trials.Participant, Participants{idxParticipant}) & ...
                strcmp(Trials.Session, Sessions{idxSession}) & Trials.Radius < MaxStimulusDistance);

            % load in eye data
            Eyes = load_datafile(EyetrackingPath, Participants{idxParticipant}, Sessions{idxSession}, 'Eyes');
            if isempty(Eyes); continue; end

            if isnan(Eyes.DQ) || Eyes.DQ == 0
                warning(['Bad data in ', Participants{idxParticipant}, Sessions{idxSession}])
                continue
            end

            Eye = round(Eyes.DQ); % which eye

            % get 1s and 0s of whether eyes were open
            [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), SampleRate, ConfidenceThreshold); % not using internal microsleep identifier so that I'm flexible
            EyeClosed = flip_vector_with_nans(EyeOpen);

            % cut out each trial
            [Trials_Stim, Trials_Resp] = ...
                chopTrials(EyeClosed, Trials(CurrentTrials, :), TrialWindow, SampleRate);

            % pool sessions
            AllTrials_Stim = cat(1, AllTrials_Stim, Trials_Stim);
            AllTrials_Resp = cat(1, AllTrials_Resp, Trials_Resp);

            % save info
            AllTrials_Table = cat(1, AllTrials_Table, Trials(CurrentTrials, :)); % important that it be in the same order!
            MicrosleepTimepoints = tally_timepoints(MicrosleepTimepoints, EyeClosed);
        end

        if isempty(AllTrials_Table)
            warning('empty table')
            continue
        end

        % get probability of microsleep (in time) for each trial type
        [EyesClosedStim(idxParticipant, :, :), EyesClosedResp(idxParticipant, :, :)] = ...
            getProbTrialType(AllTrials_Stim, AllTrials_Resp, AllTrials_Table, MaxNaNProportion, minTrials);


        % calculate general probability of a microsleep
        ProbabilityEyesClosed(idxParticipant) =  MicrosleepTimepoints(1)./MicrosleepTimepoints(2);
        disp(['Finished ', Participants{idxParticipant}])
    end

    %%% save
    save(fullfile(Pool, ['ProbMicrosleep_', SessionBlockLabels{Indx_SB}, TitleTag, '.mat']), 'EyesClosedStim', 'EyesClosedResp', 'TrialTime', 'ProbabilityEyesClosed')
end


