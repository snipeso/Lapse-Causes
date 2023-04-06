% script that gathers amount of time in theta, alpha and eyes closed, to
% determine whether they are related or not, and how much they occupy the
% recordings.


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
TimeSpent = nan(numel(Participants), numel(SB_Labels), 5); % Theta, Alpha, EC, Theta&EC, Alpha&EC

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
            EyeClosed = flipVector(EyeOpen);
            EyeClosed = EyeClosed==1 & ValidTime;

            % save overall EC time
            TimeSpent(Indx_P, Indx_SB, 3) = ...
                Add(TimeSpent(Indx_P, Indx_SB, 3), nnz(EyeClosed)/fs);

            % get task duration
            Durations(Indx_P, Indx_SB) = ...
                Add(Durations(Indx_P, Indx_SB), nnz(ValidTime)/fs);

            %%% get time spent with each burst band
            BurstFreqs = [Bursts.Frequency];
            for Indx_B = 1:numel(BandLabels)
                Band = Bands.(BandLabels{Indx_B});
                BurstTime = bursts2time(Bursts(BurstFreqs>=Band(1) & BurstFreqs<Band(2)), Pnts);
                BurstTime = BurstTime==1 & ValidTime; % only consider bursts during task

                % save overall burst time
                TimeSpent(Indx_P, Indx_SB, Indx_B) = ...
                    Add(TimeSpent(Indx_P, Indx_SB, Indx_B), nnz(BurstTime)/fs);


                % overlap with EC
                Overlap = BurstTime & EyeClosed;

                TimeSpent(Indx_P, Indx_SB, Indx_B+3) = ...
                    Add(TimeSpent(Indx_P, Indx_SB, Indx_B+3), nnz(Overlap)/fs);
            end
        end

        %%% remove overlapping bands times and normalize by total duration
        Duration = Durations(Indx_P, Indx_SB);
        TimeSpent(Indx_P, Indx_SB, :) = TimeSpent(Indx_P, Indx_SB, :)./Duration;
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