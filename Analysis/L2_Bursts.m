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
fs = 250;

EyeType = [1 0]; % open, closed (later, its the other way around)
ConfidenceThreshold = 0.5; % for classifying eyes closed/open TODO: also in getECtrials, make it analysisParameters thing

Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
BandLabels = fieldnames(Bands);
ROI = fieldnames(Channels.preROI);

% LateralityThreshold = .25;

Pool = fullfile(Paths.Pool, 'EEG');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);

Filenames = getContent(Source_Bursts);

Durations = nan(numel(Participants), numel(SB_Labels));
TimeSpent = nan(numel(Participants), numel(SB_Labels), numel(BandLabels)+1); % duration of bursts individually, and overlapping

Durations_Eyes = nan(numel(Participants), numel(SB_Labels), 2);
TimeSpent_Eyes =  nan(numel(Participants), numel(SB_Labels), numel(BandLabels), 2);

for Indx_P = 1:numel(Participants)
    for Indx_SB = 1:numel(SB_Labels)

        Sessions = SessionBlocks.(SB_Labels{Indx_SB});
        for Indx_S = 1:numel(Sessions)  % gather information for all the sessions in the block

            %%% load burst data
            Filename_Bursts = Filenames(contains(Filenames, Participants{Indx_P}) & ...
                contains(Filenames, Sessions{Indx_S}));

            if isempty(Filename_Bursts)
                warning(['No data in ', Participants{Indx_P},  Sessions{Indx_S} ])
                continue
            elseif ~exist(fullfile(Source_Bursts, Filename_Bursts), 'file')
                warning(['No data in ', Filename_Bursts])
                continue
            end

            load(fullfile(Source_Bursts, Filename_Bursts), 'EEG', 'Bursts')
            fs = EEG.srate;
            Pnts = EEG.pnts;
            ValidTime = EEG.valid_t; % vector of 1s of all the time in which the task was active, and there wasn't noise


            %%% load eye-data
            Filename_Microsleeps = replace(Filename_Bursts, 'Bursts', 'Pupils');
            if ~exist(fullfile(MicrosleepPath, Filename_Microsleeps), 'file')
                warning(['No eye data in ', Filename_Microsleeps])
                continue
            end

            load(fullfile(MicrosleepPath, Filename_Microsleeps), 'Eyes')

            Eye = round(Eyes.DQ); % which eye

            if isnan(Eyes.DQ) || Eyes.DQ == 0 || Eyes.DQ < 1 % skip if bad data
                EyeOpen = nan(1, Pnts);
                warning(['Bad data in ', Filename_Microsleeps])
                continue
            end

            [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), fs, ConfidenceThreshold); % not using internal microsleep identifier so that I'm flexible

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

                % time with EC/EO
                for Indx_E = 1:numel(EyeType)
                    BurstTime_Eyes = BurstTime & EyeOpen==EyeType(Indx_E);
                    TimeSpent_Eyes(Indx_P, Indx_SB, Indx_B, Indx_E) = ...
                        Add(TimeSpent_Eyes(Indx_P, Indx_SB, Indx_B, Indx_E), ...
                        nnz(BurstTime_Eyes)/fs);

                    if Indx_B ==1 % only do it once HACK
                        Durations_Eyes(Indx_P, Indx_SB, Indx_E) = ...
                            Add(Durations_Eyes(Indx_P, Indx_SB, Indx_E), ...
                            nnz(EyeOpen==EyeType(Indx_E) & ValidTime)/fs);
                    end
                end
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

        TimeSpent(Indx_P, Indx_SB, end) = TimeSpent(Indx_P, Indx_SB, end)/Duration;

        % same for eye status
        for Indx_E = 1:2
            Duration = Durations_Eyes(Indx_P, Indx_SB, Indx_E);
            TimeSpent_Eyes(Indx_P, Indx_SB, :, Indx_E) = TimeSpent_Eyes(Indx_P, Indx_SB, :, Indx_E)./Duration;
        end
    end

    disp(['Finished ', Participants{Indx_P}])
end


%%% save to pool
save(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent', 'TimeSpent_Eyes', 'Durations_Eyes')

function z = Add(x, y)
% little function to handle default nan values that get added on
if isnan(x)
    z = y;
else
    z = x+y;
end
end
