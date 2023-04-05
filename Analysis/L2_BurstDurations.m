% script to see how much the bursts occupy EEG (to see if reasonable to
% assume they also cause the lapses)

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
Sessions = P.Sessions;
Paths = P.Paths;
Task = P.Labels.Task;
Bands = P.Bands;
Parameters = P.Parameters;

fs = Parameters.fs;
ConfidenceThreshold = Parameters.EC_ConfidenceThreshold; % for classifying eyes closed/open

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
BandLabels = fieldnames(Bands);

Pool = fullfile(Paths.Pool, 'EEG');

EyePath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);
BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

Durations = nan(numel(Participants), numel(SB_Labels));
TimeSpent = nan(numel(Participants), numel(SB_Labels), numel(BandLabels)+1); % duration of bursts individually, and overlapping

for Indx_P = 1:numel(Participants)
    for Indx_SB = 1:numel(SB_Labels) % BL vs SD

        Sessions = SessionBlocks.(SB_Labels{Indx_SB});
        for Indx_S = 1:numel(Sessions)  % gather information for all the sessions in the block

            % load burst data
            Bursts = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'Bursts');
            if isempty(Bursts); continue; end

            % load in EEG data
            EEG = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');
            Pnts = EEG.pnts;
            ValidTime = EEG.valid_t; % vector of 1s of all the time in which the task was active, and there wasn't noise

            % load eye-data
            Eyes = loadMATFile(EyePath, Participants{Indx_P}, Sessions{Indx_S}, 'Eyes');
            if isempty(Eyes); continue; end

            if isnan(Eyes.DQ) || Eyes.DQ == 0
                EyeOpen = nan(1, Pnts);
                warning('Bad data eye data')
                continue
            end

            Eye = round(Eyes.DQ); % which eye
            [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), fs, ConfidenceThreshold);

            % look only at eye-open clean data
            ValidTime = ValidTime & EyeOpen == 1;

            % get task duration
            Durations(Indx_P, Indx_SB) = ...
                Add(Durations(Indx_P, Indx_SB), nnz(ValidTime)/fs);


            %%% get time spent with each burst band
            BurstFreqs = [Bursts.Frequency];
            AllBurstTime = [];
            for Indx_B = 1:numel(BandLabels)
                Band = Bands.(BandLabels{Indx_B});
                BurstTime = bursts2time(Bursts(BurstFreqs>=Band(1) & BurstFreqs<Band(2)), Pnts);
                BurstTime = BurstTime & ValidTime; % only consider bursts during task
                AllBurstTime = cat(1, AllBurstTime, BurstTime);

                % overall time
                TimeSpent(Indx_P, Indx_SB, Indx_B) = ...
                    Add(TimeSpent(Indx_P, Indx_SB, Indx_B), nnz(BurstTime)/fs);
            end

            % get overlap
            BothBurstTime = all(AllBurstTime, 1); % when there is both theta and alpha (it gets subtracted later)
            TimeSpent(Indx_P, Indx_SB, end) = ...
                Add(TimeSpent(Indx_P, Indx_SB, end), nnz(BothBurstTime)/fs);
        end

        %%% remove overlapping bands times and normalize by total duration
        Duration = Durations(Indx_P, Indx_SB);
        for Indx_B = 1:numel(BandLabels)
            TimeSpent(Indx_P, Indx_SB, Indx_B) = (TimeSpent(Indx_P, Indx_SB, Indx_B)-...
                TimeSpent(Indx_P, Indx_SB, end))/Duration;
        end

        TimeSpent(Indx_P, Indx_SB, end) = TimeSpent(Indx_P, Indx_SB, end)/Duration;
    end

    disp(['Finished ', Participants{Indx_P}])
end

% remove participants for which either session is missing data
TimeSpent(any(any(isnan(TimeSpent), 3), 2), :, :) = nan;

%%% save to pool
save(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent', 'Durations')

function z = Add(x, y)
% little function to handle default nan values that get added on
if isnan(x)
    z = y;
else
    z = x+y;
end
end
