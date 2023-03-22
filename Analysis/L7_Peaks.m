% script to get info on bursts occurance in time

clear
clc
% close all

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

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};

Pool = fullfile(Paths.Pool, 'EEG');

PeakPath = fullfile(Paths.Data, 'EEG', 'Peaks', '5_9', Task);
BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

Durations = nan(numel(Participants), numel(SB_Labels));
TimeSpent = nan(numel(Participants), numel(SB_Labels), 3); % to compare overlap in time of bursts and peaks
TotPeaks = nan(numel(Participants), numel(SB_Labels));
TotBursts =nan(numel(Participants), numel(SB_Labels)); 

for Indx_P = 1:numel(Participants)
    for Indx_SB = 1:numel(SB_Labels) % BL vs SD

        Sessions = SessionBlocks.(SB_Labels{Indx_SB});
        for Indx_S = 1:numel(Sessions)  % gather information for all the sessions in the block

            % load burst data
            Bursts = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'Bursts');
            if isempty(Bursts); continue; end

           

            % load peak data
            Peaks = loadMATFile(PeakPath, Participants{Indx_P}, Sessions{Indx_S}, 'TopPeaks');
            if isempty(Peaks); continue; end

            TotPeaks(Indx_P, Indx_SB) = numel(Peaks);

            % load in EEG data
            EEG = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');
            Pnts = EEG.pnts;
            ValidTime = EEG.valid_t; % vector of 1s of all the time in which the task was active, and there wasn't noise

            % get task duration
            Durations(Indx_P, Indx_SB) = ...
                Add(Durations(Indx_P, Indx_SB), nnz(ValidTime)/fs);


            %%% Get amount of overlap in time
            % Get times with peaks (only negative zero-crossings)
            PeakTime = peaks2time(Peaks, 'MidDownID', 'MidUpID', Pnts);
            PeakTime = PeakTime & ValidTime;

            TimeSpent(Indx_P, Indx_SB, 1) = Add(TimeSpent(Indx_P, Indx_SB, 1), nnz(PeakTime)/fs);

            % get time spent with theta bursts
            BurstFreqs = [Bursts.Frequency];
%             Band = Bands.Theta;
Band = [5 9];
            BurstTime = bursts2time(Bursts(BurstFreqs>=Band(1) & BurstFreqs<Band(2)), Pnts);
            BurstTime = BurstTime & ValidTime; % only consider bursts during task

             TotBursts(Indx_P, Indx_SB) = numel(Bursts(BurstFreqs>=Band(1) & BurstFreqs<Band(2)));
            TimeSpent(Indx_P, Indx_SB, 2) = Add(TimeSpent(Indx_P, Indx_SB, 2), nnz(BurstTime)/fs);

            % get overlap
            BothBurstTime = BurstTime & PeakTime; % when there is both theta and alpha (it gets subtracted later)
            TimeSpent(Indx_P, Indx_SB, end) = ...
                Add(TimeSpent(Indx_P, Indx_SB, end), nnz(BothBurstTime)/fs);
        end

        %%% remove overlapping bands times and normalize by total duration
        Duration = Durations(Indx_P, Indx_SB);

        TimeSpent(Indx_P, Indx_SB, :) = TimeSpent(Indx_P, Indx_SB, :)/Duration;
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
