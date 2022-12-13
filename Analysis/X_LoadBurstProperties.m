clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
Sessions = P.Sessions;
TallyLabels = P.Labels.Tally;
Paths = P.Paths;
Task = P.Labels.Task;
Bands = P.Bands;
Triggers = P.Triggers;
Channels = P.Channels;

Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
Bands.Theta = [4 8];
Bands.Alpha = [8 12];
BandLabels = {'Theta', 'Alpha'};
ROI = fieldnames(Channels.preROI);

Pool = fullfile(Paths.Pool, 'EEG');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data


AllFiles_Bursts = getContent(Source_Bursts);

Durations = nan(numel(Participants), numel(SB_Labels));
TimeSpent = nan(numel(Participants), numel(SB_Labels), numel(BandLabels)+1); % duration of bursts individually, and overlapping
TimeSpent_ROI = nan(numel(Participants), numel(SB_Labels), numel(ROI), numel(BandLabels));
Laterality = nan(numel(Participants), numel(SB_Labels), 2, numel(BandLabels)); %for left and right screens, number of left and right bursts
LateralitySum = Laterality;

Filename = Filenames(contains(Filenames, Participants{Indx_P}) & ...
    contains(Filenames, Sessions{Indx_S}));

for Indx_P = 1:numel(Participants)

    for Indx_SB = 1:numel(SB_Labels)
        Sessions = SessionBlocks.(SB_Labels{Indx_SB});

        for Indx_S = 1:numel(Sessions)


            %%% load burst data
            Filename = Filenames(contains(Filenames, Participants{Indx_P}) & ...
                contains(Filenames, Sessions{Indx_S}));

            if isempty(Filename)
                warning(['No data in ', Participants{Indx_P},  Sessions{Indx_S} ])
                continue
            elseif ~exist(fullfile(BurstPath, Filename), 'file')
                warning(['No data in ', Filename])
                continue
            end

            load(fullfile(BurstPath, Filename), 'EEG', 'Bursts')
            fs = EEG.srate;
            t = EEG.times;

            % make a vector of task time
            TaskTime = zeros(size(t));
            TriggerTypes = {EEG.events.type};
            TriggerTimes = [EEG.events.latency];
            StartTask = TriggerTimes(strcmp(TriggerTypes, Triggers.Start));
            EndTask = TriggerTimes(strcmp(TriggerTypes, Triggers.End));
            TaskTime(StartTask:EndTask) = 1;

            % get task duration
            Durations(Indx_P, Indx_SB) = Add(Durations(Indx_P, Indx_SB),  nnz(TaskTime)/fs);


            %%% get time spent with each burst band
            Freqs = 1./[Bursts.Mean_period];
            AllBurstTime = [];
            for Indx_B = 1:numel(BandLabels)
                Band = Bands.(BandLabels{Indx_B});
                BurstTime = burst2time(Bursts(Freqs>= Band(1) & Freqs <Band(2)));
                BurstTime = BurstTime & TaskTime; % only consider bursts during task
                AllBurstTime = cat(1, AllBurstTime, BurstTime);

                TimeSpent(Indx_P, Indx_SB, Indx_B) = Add(TimeSpent(Indx_P, Indx_SB, Indx_B), nnz(BurstTime)/fs);
            end

            % get overlap
            BothBurstTime = all(AllBurstTime, 1);
            TimeSpent(Indx_P, Indx_SB, end) = Add(TimeSpent(Indx_P, Indx_SB, end), nnz(BothBurstTime)/fs);


            %%% get time, split by ROI
            Groups = {Bursts.preROI};
            for Indx_B = 1:numel(BandLabels)

                Band = Bands.(BandLabels{Indx_B});
                for Indx_Ch = 1:numel(ROI)
                    BurstTime = burst2time(Bursts(Freqs>= Band(1) & Freqs <Band(2) & ...
                        strcmp(Groups, ROI{Indx_Ch})));
                    BurstTime = BurstTime & TaskTime; % only consider bursts during task

                    TimeSpent_ROI(Indx_P, Indx_SB, Indx_Ch, Indx_B) = ...
                        Add(TimeSpent_ROI(Indx_P, Indx_SB, Indx_Ch, Indx_B), nnz(BurstTime)/fs);
                end
            end


            %%% get laterality
            Hemifields = [-1 1]; % left, right
            BurstHemifield = [Bursts.Hemifield];
            for Indx_H = 1:numel(Hemifields)
                for Indx_B = 1:numel(BandLabels)

                    Indexes = Freqs>= Band(1) & Freqs <Band(2) & ...
                        BurstHemifield == Hemifields(Indx_H);

                    Laterality(Indx_P, Indx_SB, Indx_H, Indx_B) = ...
                        Add(Laterality(Indx_P, Indx_SB, Indx_H, Indx_B), Bursts(Indexes).Laterality);
                    LateralitySum(Indx_P, Indx_SB, Indx_H, Indx_B) = ...
                        Add(LateralitySum(Indx_P, Indx_SB, Indx_H, Indx_B), nnz(Indexes));
                end
            end
        end

        %%% remove overlapping bands times and normalize by total duration
        Duration = Durations(Indx_P, Indx_SB);
        for Indx_B = 1:numel(BandLabels)
            TimeSpent(Indx_P, Indx_SB, Indx_B) = (TimeSpent(Indx_P, Indx_SB, Indx_B)-...
                TimeSpent(Indx_P, Indx_SB, end))/Duration;

            TimeSpent_ROI(Indx_P, Indx_SB, Indx_Ch, Indx_B) = TimeSpent_ROI(Indx_P, Indx_SB, Indx_Ch, Indx_B)/Duration;
        end

        TimeSpent(Indx_P, Indx_SB, end) =TimeSpent(Indx_P, Indx_SB, end)/Duration;

        % get average of laterality values
        for Indx_H = 1:numel(Hemifields)
            for Indx_B = 1:numel(BandLabels)
                Laterality(Indx_P, Indx_SB, Indx_H, Indx_B) = ...
                    Laterality(Indx_P, Indx_SB, Indx_H, Indx_B)/LateralitySum(Indx_P, Indx_SB, Indx_H, Indx_B);
            end
        end
    end
end


%%% save to pool
save(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent', 'TimeSpent_ROI', 'LateralitySum', 'Laterality')

function z = Add(x, y)
% little function to handle default nan values that get added on
if isnan(x)
    z = y;
else
    z = x+y;
end
end
