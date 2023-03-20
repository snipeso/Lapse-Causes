% gets the data showing the probability of burst

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
Bands = P.Bands;
BandLabels = fieldnames(Bands);

StartTime = Parameters.Timecourse.Start;
EndTime = Parameters.Timecourse.End;
fs = Parameters.fs;
ConfidenceThreshold = Parameters.EC_ConfidenceThreshold;

Windows_Stim = [-1.5 0;  0 0.25;  0.25 1]; % time windows to aggregate info

Windows_Resp = [-.5 0; 0 1];

minTrials = Parameters.MinTypes;
minNanProportion = Parameters.MinNanProportion; % any more nans than this in a given trial is grounds to exclude the trial

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script
BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts_AllChannels', Task);
WholeBurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task); % needed for valid t
EyePath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', 'AllTrials.mat'), 'Trials')
Q = quantile(Trials.Radius, Parameters.Radius);

t_window = linspace(StartTime, EndTime, fs*(EndTime-StartTime));

ProbBurst_Stim = nan(numel(Participants), 3, 123, 2, numel(t_window));
ProbBurst_Resp = nan(numel(Participants), 3, 123, 2,  numel(t_window));
zProbBurst_Stim = nan(numel(Participants), 3, 123, 2, size(Windows_Stim, 1));
zProbBurst_Resp = nan(numel(Participants), 3, 123, 2,  size(Windows_Resp, 1));

GenProbBurst = zeros(numel(Participants), 123, numel(BandLabels), 2);
zGenProbBurst = zeros(numel(Participants), 123, numel(BandLabels));

for Indx_P = 1:numel(Participants)

    AllTrials_Stim = [];
    AllTrials_Resp = [];
    AllTrials_Table = table();

    for Indx_S = 1:numel(Sessions)

        %%% Load in data

        % trial info for current recording
        CurrentTrials = find(strcmp(Trials.Participant, Participants{Indx_P}) & ...
            strcmp(Trials.Session, Sessions{Indx_S}));
        nTrials = nnz(CurrentTrials);

        % load in burst data
        Bursts = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'AllBursts');
        if isempty(Bursts); continue; end

        EEG = loadMATFile(WholeBurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');
        Pnts = EEG.pnts;
        t_valid = EEG.valid_t;
        Chanlocs = EEG.chanlocs;
        TotChannels = numel(Chanlocs);


        % remove bursts that were chopped
        Bursts = removeChopped(Bursts);

        % get frequency of each burst
        Bursts = meanFreq(Bursts);

        Freqs = [Bursts.Frequency];
        Channels = [Bursts.Channel];

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


        %%% select trials

        % exclude EC timepoints
        t_valid = t_valid & EyeOpen==1;

        Trials_B_Stim = nan(nTrials, TotChannels, numel(BandLabels), numel(t_window));
        Trials_B_Resp = Trials_B_Stim;

        for Indx_B = 1:numel(BandLabels)
            for Indx_Ch = 1:TotChannels

                % 0s and 1s of whether there is a burst or not, nans for noise
                Band = Bands.(BandLabels{Indx_B});
                BT = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2) & ...
                    Channels==Indx_Ch), Pnts);
                BT(not(t_valid)) = nan;

                % get trial info
                [Trials_B_Stim(:, Indx_Ch, Indx_B, :), Trials_B_Resp(:, Indx_Ch, Indx_B, :)] = ...
                    chopTrials(BT, Trials, CurrentTrials, StartTime, EndTime, fs);

                % get general probability of a burst
                GenProbBurst(Indx_P, Indx_Ch, Indx_B, 1) = GenProbBurst(Indx_P, Indx_Ch, Indx_B, 1) + sum(BT==1); % burst
                GenProbBurst(Indx_P, Indx_Ch, Indx_B, 2) = GenProbBurst(Indx_P, Indx_Ch, Indx_B, 2) + sum(BT==1 | BT==0); % all points
            end
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

    %%% get probability of event for each trial type

    for Indx_B = 1:numel(BandLabels)
        for Indx_TT = 1:3

            % get prob of burst in stim trial
            TT_Indexes = AllTrials_Table.Type==Indx_TT & AllTrials_Table.Radius <= Q;

            nTrials = nnz(TT_Indexes);

            for Indx_Ch = 1:TotChannels
                TypeTrials_Stim = squeeze(AllTrials_Stim(TT_Indexes, Indx_Ch, Indx_B, :));

                Prob = probEvent(TypeTrials_Stim, minNanProportion, minTrials);

                ProbBurst_Stim(Indx_P, Indx_TT, Indx_Ch, Indx_B, :) =  Prob;


                % get prob of burst in resp trial
                if Indx_TT>1 % not lapses
                    TypeTrials_Resp = squeeze(AllTrials_Resp(TT_Indexes, Indx_Ch, Indx_B, :));

                    Prob = probEvent(TypeTrials_Resp, minNanProportion, minTrials);

                    ProbBurst_Resp(Indx_P, Indx_TT, Indx_Ch, Indx_B, :) = Prob;
                end
            end
        end

        % z-score everything
       GP = squeeze(GenProbBurst(Indx_P, :, Indx_B, 1)./GenProbBurst(Indx_P, :, Indx_B, 2));
       Prob = squeeze(ProbBurst_Stim(Indx_P, :, :, Indx_B, :))-repmat(GP, 3, 1, 1000);
        MEAN = mean(Prob, 'all', 'omitnan');
        STD = std(Prob, 0, 'all', 'omitnan');
        zProb = (Prob-MEAN)./STD;

        for Indx_TT = 1:3
            for Indx_Ch = 1:TotChannels
                zProbBurst_Stim(Indx_P, Indx_TT, Indx_Ch, Indx_B, :) = ...
                    reduxProbEvent(zProb(Indx_TT, Indx_Ch, :), t_window, Windows_Stim);
            end
        end

        zGenProbBurst(Indx_P, :, Indx_B)  = 0;

    end

    disp(['Finished ', Participants{Indx_P}])
end

% remove all data from participants missing any of the trial types
for Indx_P = 1:numel(Participants)
    for Indx_B = 1:numel(BandLabels)
        if any(isnan(zProbBurst_Stim(Indx_P, :, :, Indx_B, :)), 'all')
            zProbBurst_Stim(Indx_P, :, :, Indx_B, :) = nan;
        end

        if any(isnan(ProbBurst_Resp(Indx_P, 2:3, :, Indx_B, :)), 'all')
            ProbBurst_Resp(Indx_P, :, :, Indx_B, :) = nan;
        end
    end
end

% get general probability as fraction
GenProbBurst = GenProbBurst(:, :, :, 1)./GenProbBurst(:, :, :, 2);

%%% save
t = t_window;
save(fullfile(Pool, 'ProbBurst_Channels_zscored.mat'), 'zProbBurst_Stim',  't', 'zGenProbBurst', 'Chanlocs', 'GenProbBurst')