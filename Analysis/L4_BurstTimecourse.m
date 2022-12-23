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

minTrials = Parameters.MinTypes;
minNanProportion = Parameters.MinNanProportion; % any more nans than this in a given trial is grounds to exclude the trial

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
        Globality = [Bursts.globality_bursts];

        Trials_B_Stim = nan(nTrials, numel(BandLabels), numel(t_window));
        Trials_B_Resp = nan(nTrials, numel(BandLabels), numel(t_window));

        for Indx_B = 1:numel(BandLabels)

            % 0s and 1s of whether there is a burst or not, nans for noise
            Band = Bands.(BandLabels{Indx_B});
%             BT = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2)), Pnts);
BT = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2) & Globality>.5), Pnts);
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
            TT_Indexes = AllTrials_Table.Type==Indx_TT;
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
save(fullfile(Pool, 'ProbBurst.mat'), 'ProbBurst_Stim', 'ProbBurst_Resp', 't', 'GenProbBurst')
