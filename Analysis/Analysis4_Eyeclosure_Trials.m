% gets the data showing the probability of eyesclosed over time for each
% trial outcome type.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

OnlyClosestStimuli = true; % only use closest trials


Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
TrialWindow = Parameters.Trials.Window;
SampleRate = Parameters.SampleRate;
ConfidenceThreshold = Parameters.EyeTracking.MinConfidenceThreshold;
MaxNaNProportion = Parameters.Trials.MaxNaNProportion;
MaxStimulusDistance = Parameters.Stimuli.MaxDistance;
SessionBlocks = Parameters.Sessions.Conditions;
Triggers = Parameters.Triggers;



EyetrackingPath = fullfile(Paths.Data, 'Pupils', ['Raw_', num2str(SampleRate), 'Hz'], Task);
CacheDir = fullfile(Paths.Cache, 'Trial_Information');
CacheFilename = [Task, '_TrialsTable.mat'];

SessionBlockLabels = fieldnames(SessionBlocks);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

% get trial information
load(fullfile(CacheDir, CacheFilename), 'TrialsTable')

EyetrackingQualityTable = readtable(fullfile(Paths.QualityCheck, 'EyeTracking', ...
    ['DataQuality_', Task, '_Pupils.csv']));

TrialTime = linspace(TrialWindow(1), TrialWindow(2), SampleRate*(TrialWindow(2)-TrialWindow(1))); % time vector

% specify only close trials, or all trials
TitleTag = '';
if OnlyClosestStimuli
    TitleTag = [ TitleTag, '_Close'];
    MaxStimulusDistance = quantile(TrialsTable.Radius, MaxStimulusDistance);
else
    MaxStimulusDistance = max(TrialsTable.Radius);
end


for Indx_SB = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = SessionBlocks.(SessionBlockLabels{Indx_SB});

    % initialize variables
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
            CurrentTrials = find(strcmp(TrialsTable.Participant, Participants{idxParticipant}) & ...
                strcmp(TrialsTable.Session, Sessions{idxSession}) & TrialsTable.Radius < MaxStimulusDistance);

            % load in eye data
            Eyes = load_datafile(EyetrackingPath, Participants{idxParticipant}, Sessions{idxSession}, 'Eyes');
            if isempty(Eyes); continue; end
            EEGMetadata = load_datafile(EyetrackingPath, Participants{idxParticipant}, Sessions{idxSession}, 'EEGMetadata');

            CleanEyeIndex = EyetrackingQualityTable.(Sessions{idxSession})(strcmp(EyetrackingQualityTable.Participant, Participants{idxParticipant}));
            EyeClosed = clean_eyeclosure_data(Eyes, EEGMetadata, Triggers, CleanEyeIndex, SampleRate, ConfidenceThreshold);
TrialData = chop_trials(Data, SampleRate, EEGMetadata.events, Trigger, TrialWindow);


            % cut out each trial
            [Trials_Stim, Trials_Resp] = ...
                chopTrials(EyeClosed, TrialsTable(CurrentTrials, :), TrialWindow, SampleRate);

            % pool sessions
            AllTrials_Stim = cat(1, AllTrials_Stim, Trials_Stim);
            AllTrials_Resp = cat(1, AllTrials_Resp, Trials_Resp);

            % save info
            AllTrials_Table = cat(1, AllTrials_Table, TrialsTable(CurrentTrials, :)); % important that it be in the same order!
            MicrosleepTimepoints = tallyTimepoints(MicrosleepTimepoints, EyeClosed);
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




