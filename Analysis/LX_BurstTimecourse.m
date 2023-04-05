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
TotChannels = 123;

% locations
Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script
BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task);
EyePath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);

SessionBlockLabels = fieldnames(SessionBlocks);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', [Task, '_AllTrials.mat']), 'Trials')
Max_Radius = quantile(Trials.Radius, Max_Radius_Quantile);

t_window = linspace(TrialWindow(1), TrialWindow(2), fs*(TrialWindow(2)-TrialWindow(1))); % time vector



for Indx_SB = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = P.SessionBlocks.(SessionBlockLabels{Indx_SB});

    ProbMicrosleep_Stim = nan(numel(Participants), nTrialTypes, TotChannels, 2, numel(t_window)); % P x TT x Ch x B x t matrix with final probabilities
    ProbMicrosleep_Resp = ProbMicrosleep_Stim;
    GenProbBurst = zeros(numel(Participants), 123, numel(BandLabels), 2); % get general probability of a burst for a given session block (to control for when z-scoring)
    GenProbBurst_Pooled = zeros(numel(Participants), numel(BandLabels), 2); % once collapsed all channels

    for Indx_P = 1:numel(Participants)

        AllTrials_Stim = []; % need to pool all trials across sessions in a given session block
        AllTrials_Resp = [];
        AllTrials_Table = table();
        MicrosleepTimepoints = [0 0]; % total number of points in recording that is a microsleep; total number of points, pooling sessions

        for Indx_S = 1:numel(Sessions)

            % trial info for current recording
            CurrentTrials = find(strcmp(Trials.Participant, Participants{Indx_P}) & ...
                strcmp(Trials.Session, Sessions{Indx_S}) & Trials.Radius < Max_Radius);
            nTrials = nnz(CurrentTrials);


            %%% load in burst data
            Bursts = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'AllBursts');
            if isempty(Bursts); continue; end

            EEG = loadMATFile(WholeBurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');
            Pnts = EEG.pnts;
            t_valid = EEG.valid_t;

            % remove bursts that were chopped
            Bursts = removeChopped(Bursts);

            % get frequency of each burst
            Bursts = meanFreq(Bursts);

            Freqs = [Bursts.Frequency];
            Channels = [Bursts.Channel];


            %%% load in eye data
            Eyes = loadMATFile(EyePath, Participants{Indx_P}, Sessions{Indx_S}, 'Eyes');
            if isempty(Eyes); continue; end

            if isnan(Eyes.DQ) || Eyes.DQ == 0
                warning(['Bad data in ', Participants{Indx_P}, Sessions{Indx_S}])
                continue
            end

            Eye = round(Eyes.DQ); % which eye

            % get 1s and 0s of whether eyes were open
            [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), fs, ConfidenceThreshold);


            %%% Gather trials

            % exclude EC timepoints
            t_valid = t_valid & EyeOpen==1;

            % get matrix of when there are bursts for each channel
            BurstTimes = classifyBursts(Bursts, Bands, TotChannels, t_valid);

            % chop matrix into trials
            Trials_Stim = nan(TotChannels, TotBands, nnz(CurrentTrials), numel(t_window));
            Trials_Resp = Trials_Stim;

            for Indx_B = 1:TotBands
                [Trials_Stim(:, Indx_B, :, :), Trials_Resp(:, Indx_B, :, :)] = ...
                    chopTrials(squeeze(BurstTimes(:, Indx_B, :)), ...
                    Trials(CurrentTrials, :), TrialWindow, fs);
            end
        end



    end

end