% gets the data showing the probability of burst in time

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
SessionGroup = 'BL';
Sessions = P.SessionBlocks.(SessionGroup);
Paths = P.Paths;
Task = P.Labels.Task;
Parameters = P.Parameters;
Bands = P.Bands;
BandLabels = fieldnames(Bands);

StartTime = Parameters.Timecourse.Start; % window around triggers
EndTime = Parameters.Timecourse.End;
fs = Parameters.fs;
ConfidenceThreshold = Parameters.EC_ConfidenceThreshold;
minTrials = Parameters.MinTypes; % minimum number of trials for each category
minNanProportion = Parameters.MinNanProportion; % any more nans than this in a given trial is grounds to exclude the trial

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script
BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task);
EyePath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', [Task, '_AllTrials.mat']), 'Trials')
Max_Radius = quantile(Trials.Radius, Parameters.Radius); % only look at trials within a certain radius

t_window = linspace(StartTime, EndTime, fs*(EndTime-StartTime)); % time vector for epoched data

% blanks to fill
ProbBurst_Stim = nan(numel(Participants), 3, 2, numel(t_window));
ProbBurst_Resp = nan(numel(Participants), 3, 2, numel(t_window));
GenProbBurst = zeros(numel(Participants), numel(BandLabels), 2);

for Indx_P = 1:numel(Participants)

    AllTrials_Stim = [];
    AllTrials_Resp = [];
    AllTrials_Table = table();

    for Indx_S = 1:numel(Sessions)

        %%% Load data

        % trial info for current recording
        CurrentTrials = find(strcmp(Trials.Participant, Participants{Indx_P}) & ...
            strcmp(Trials.Session, Sessions{Indx_S}));
        nTrials = nnz(CurrentTrials);

        % load in burst data
        Bursts = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'Bursts');
        if isempty(Bursts); continue; end

        % load in EEG data
        EEG = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');
        Pnts = EEG.pnts;
        t_valid = EEG.valid_t;

        % load in eye data
        Eyes = loadMATFile(EyePath, Participants{Indx_P}, Sessions{Indx_S}, 'Eyes');
        if isempty(Eyes); continue; end

        if isnan(Eyes.DQ) || Eyes.DQ == 0
            warning(['Bad data in ', Participants{Indx_P}, Sessions{Indx_S}])
            continue
        end

        Eye = round(Eyes.DQ); % which eye

        % get 1s and 0s of whether eyes were open
        [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), fs, ConfidenceThreshold);


        %%% select data

        % exclude EC timepoints
        t_valid = t_valid & EyeOpen==1;

        % select bursts
        Freqs = [Bursts.Frequency];

        Trials_B_Stim = nan(nTrials, numel(BandLabels), numel(t_window));
        Trials_B_Resp = nan(nTrials, numel(BandLabels), numel(t_window));

        for Indx_B = 1:numel(BandLabels)

            % 0s and 1s of whether there is a burst or not, nans for noise
            Band = Bands.(BandLabels{Indx_B});
            BT = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2)), Pnts);
            BT(not(t_valid)) = nan;

            % get trial info
            [Trials_B_Stim(:, Indx_B, :), Trials_B_Resp(:, Indx_B, :)] = ...
                chopTrials(BT, Trials, CurrentTrials, StartTime, EndTime, fs);

            % get general probability of a burst
            GenProbBurst(Indx_P, Indx_B, 1) = GenProbBurst(Indx_P, Indx_B, 1) + sum(BT==1); % burst
            GenProbBurst(Indx_P, Indx_B, 2) = GenProbBurst(Indx_P, Indx_B, 2) + sum(BT==1 | BT==0); % all points
        end

        % pool sessions
        AllTrials_Stim = cat(1, AllTrials_Stim, Trials_B_Stim);
        AllTrials_Resp = cat(1, AllTrials_Resp, Trials_B_Resp);

        % save trial info
        AllTrials_Table = cat(1, AllTrials_Table, Trials(CurrentTrials, :));
    end

    if isempty(AllTrials_Table)
        warning('empty table')
        continue
    end

    %%% get probability of microsleep (in time) for each trial type
    for Indx_B = 1:numel(BandLabels)
        for Indx_TT = 1:3

            % get prob of burst in stim trial
            TT_Indexes = AllTrials_Table.Type==Indx_TT & AllTrials_Table.Radius < Max_Radius;
            nTrials = nnz(TT_Indexes);
            TypeTrials_Stim = squeeze(AllTrials_Stim(TT_Indexes, Indx_B, :));

            ProbBurst_Stim(Indx_P, Indx_TT, Indx_B, :) = ...
                probEvent(TypeTrials_Stim, minNanProportion, minTrials);


            % get prob of burst in resp trial
            if Indx_TT>1 % not lapses
                TypeTrials_Resp = squeeze(AllTrials_Resp(TT_Indexes, Indx_B, :));

                ProbBurst_Resp(Indx_P, Indx_TT, Indx_B, :)  = ...
                    probEvent(TypeTrials_Resp, minNanProportion, minTrials);
            end
        end
    end


    disp(['Finished ', Participants{Indx_P}])
end

% remove all data from participants missing any of the trial types
for Indx_P = 1:numel(Participants)
    for Indx_B = 1:numel(BandLabels)
        if any(isnan(ProbBurst_Stim(Indx_P, :, Indx_B, :)), 'all')
            ProbBurst_Stim(Indx_P, :, Indx_B, :) = nan;
        end

        if any(isnan(ProbBurst_Resp(Indx_P, 2:3, Indx_B, :)), 'all')
            ProbBurst_Resp(Indx_P, :, Indx_B, :) = nan;
        end
    end
end

% get general probability as fraction
GenProbBurst = GenProbBurst(:, :, 1)./GenProbBurst(:, :, 2);

%%% save
t = t_window;
save(fullfile(Pool, ['ProbBurst_', SessionGroup, '.mat']), 'ProbBurst_Stim', 'ProbBurst_Resp', 't', 'GenProbBurst')
