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
Triggers = P.Triggers;
Channels = P.Channels;

Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
Bands.Theta = [4 8];
Bands.Alpha = [8 15];
BandLabels = {'Theta', 'Alpha'};
ROI = fieldnames(Channels.preROI);

% LateralityThreshold = .25;

Pool = fullfile(Paths.Pool, 'EEG');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

Filenames = getContent(Source_Bursts);

Durations = nan(numel(Participants), numel(SB_Labels));
TimeSpent = nan(numel(Participants), numel(SB_Labels), numel(BandLabels)+1); % duration of bursts individually, and overlapping
TimeSpent_Eyes =  nan(numel(Participants), numel(SB_Labels), numel(BandLabels), 2);

for Indx_P = 1:numel(Participants)
    for Indx_SB = 1:numel(SB_Labels)
              
        Sessions = SessionBlocks.(SB_Labels{Indx_SB});
        for Indx_S = 1:numel(Sessions)  % gather information for all the sessions in the block


            %%% load burst data
            Filename = Filenames(contains(Filenames, Participants{Indx_P}) & ...
                contains(Filenames, Sessions{Indx_S}));

            if isempty(Filename)
                warning(['No data in ', Participants{Indx_P},  Sessions{Indx_S} ])
                continue
            elseif ~exist(fullfile(Source_Bursts, Filename), 'file')
                warning(['No data in ', Filename])
                continue
            end

            load(fullfile(Source_Bursts, Filename), 'EEG', 'Bursts')
            fs = EEG.srate;
            Pnts = size(EEG.data, 2);
            ValidTime = EEG.valid_t; % vector of 1s of all the time in which the task was active, and there wasn't noise

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

                TimeSpent(Indx_P, Indx_SB, Indx_B) = ...
                    Add(TimeSpent(Indx_P, Indx_SB, Indx_B), nnz(BurstTime)/fs);
            end

            % get overlap
            BothBurstTime = all(AllBurstTime, 1);
            TimeSpent(Indx_P, Indx_SB, end) = ...
                Add(TimeSpent(Indx_P, Indx_SB, end), nnz(BothBurstTime)/fs);
        end

        %%% remove overlapping bands times and normalize by total duration
        Duration = Durations(Indx_P, Indx_SB);
        for Indx_B = 1:numel(BandLabels)
            TimeSpent(Indx_P, Indx_SB, Indx_B) = (TimeSpent(Indx_P, Indx_SB, Indx_B)-...
                TimeSpent(Indx_P, Indx_SB, end))/Duration;
        end

        TimeSpent(Indx_P, Indx_SB, end) =TimeSpent(Indx_P, Indx_SB, end)/Duration;
    end

    disp(['Finished ', Participants{Indx_P}])
end


%%% save to pool
save(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent')

function z = Add(x, y)
% little function to handle default nan values that get added on
if isnan(x)
    z = y;
else
    z = x+y;
end
end
