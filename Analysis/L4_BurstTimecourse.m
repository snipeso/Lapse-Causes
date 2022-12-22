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
minTrials = Parameters.MinTypes;
minNanProportion = 0.5; % any more nans than this in a given trial is grounds to exclude the trial

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script
BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', 'AllTrials.mat'), 'Trials')
Q = quantile(Trials.Radius, 0.5);

t_window = linspace(StartTime, EndTime, fs*(EndTime-StartTime));

ProbBurst_Stim = nan(numel(Participants), 3, 2, numel(t_window));
ProbBurst_Resp = nan(numel(Participants), 3, 2, numel(t_window));
GenProbBurst = zeros(numel(Participants), numel(BandLabels), 2);

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
        Bursts = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'Bursts');
        if isempty(Bursts); continue; end

        EEG = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');
        Pnts = EEG.pnts;
        t_valid = EEG.valid_t;

        Freqs = [Bursts.Frequency];

        % get timepoints for each burst
        BurstTime = nan(numel(BandLabels), Pnts);
        for Indx_B = 1:numel(BandLabels)
            Band = Bands.(BandLabels{Indx_B});
            BT = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2)), Pnts);
            BurstTime(Indx_B, :) = BT;
        end

        BurstTime(:, not(t_valid)) = nan;

        % cut put each trial, pool together
        Trials_B_Stim = nan(nTrials, numel(BandLabels), numel(t_window));
        Trials_B_Resp = nan(nTrials, numel(BandLabels), numel(t_window));

        for Indx_T = 1:nTrials

            % stimulus locked
            StimT = round(fs*Trials.StimTime(CurrentTrials(Indx_T)));
            Start = StimT+StartTime*fs;
            End = StimT+EndTime*fs-1;

            Trial = BurstTime(:, Start:End); % just keep track of eyes closed
            Trials_B_Stim(Indx_T, :, :) = Trial;


            % response locked
            RespT =  round(fs*Trials.RespTime(CurrentTrials(Indx_T)));

            if isnan(RespT)
                continue
            end

            Start = RespT+StartTime*fs;
            End = RespT+EndTime*fs-1;

            Trial = BurstTime(:, Start:End); % just keep track of eyes closed
            Trials_B_Resp(Indx_T, :, :) = Trial;
        end


        % pool sessions
        AllTrials_Stim = cat(1, AllTrials_Stim, Trials_B_Stim);
        AllTrials_Resp = cat(1, AllTrials_Resp, Trials_B_Resp);

        % save info
        AllTrials_Table = cat(1, AllTrials_Table, Trials(CurrentTrials, :));
        GenProbBurst(Indx_P, :, 1) =  GenProbBurst(Indx_P, :, 1)' + sum(BurstTime==1, 2);
        GenProbBurst(Indx_P, :, 2) =  GenProbBurst(Indx_P, :, 2)' + sum(BurstTime==1 | BurstTime==0, 2);

    end

    if isempty(AllTrials_Table)
        warning('empty table')
        continue
    end

    %%% get probability of microsleep (in time) for each trial type
    nTrials_Nans = 0;

    for Indx_B = 1:numel(BandLabels)
        for Indx_TT = 1:3

            % choose trials
            Trial_Indexes = AllTrials_Table.Type==Indx_TT; %% & Closest; % & AllTrials_Table.EC==0;
            nTrials = nnz(Trial_Indexes);
            TypeTrials_Stim = squeeze(AllTrials_Stim(Trial_Indexes, Indx_B, :));

            ProbBurst_Stim(Indx_P, Indx_TT, Indx_B, :)  = ...
                probEvent(TypeTrials_Stim, minNanProportion, minTrials);

        end
    end


    disp(['Finished ', Participants{Indx_P}])
end

% remove all data from participants missing any of the trial types
for Indx_P = 1:numel(Participants)
    if any(isnan(ProbBurst_Stim(Indx_P, :, :)), 'all')
        ProbBurst_Stim(Indx_P, :, :) = nan;
    end
end

% get general probability as fraction
GenProbBurst = GenProbBurst(:, :, 1)./GenProbBurst(:, :, 2);

%%% save
t = t_window;
save(fullfile(Pool, 'ProbBurst.mat'), 'ProbBurst_Stim', 't', 'GenProbBurst')
