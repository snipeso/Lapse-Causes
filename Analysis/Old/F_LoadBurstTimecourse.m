% gets the data showing the probability of eyesclosed over time for both
% lapses and other types of responses

%TODO: check code for mistakes

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
Sessions = P.SessionBlocks.SD;
TallyLabels = P.Labels.Tally;
Paths = P.Paths;
Task = P.Labels.Task;
Bands = P.Bands;
Channels = P.Channels;
RefreshTrials = false;

StartTime = -2;
EndTime = 2;
fs = 250;
WelchWindow = 2;

StartStim = 0;
EndWindow = 1;
MinBurst = .5; % percentage of above window

% ConfidenceThreshold = 0.5;
minTrials = 10;
MinNaN = 0.5;

Tag =  ['s', num2str(StartTime), '_e', num2str(EndTime), '_w', num2str(WelchWindow)];
TitleTag = strjoin({'LapseCauses', 'LAT', 'Power', Tag}, '_');
TitleTag = replace(TitleTag, '.', '-');

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script

BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task); % Temp!

Bands.Theta = [4 8];
Bands.Alpha = [8 12];
BandLabels = {'Theta', 'Alpha'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', 'AllTrials.mat'), 'Trials')
Q = quantile(Trials.Radius, 0.5);

TrialTypeLabels = [1 2 3];
t_window = linspace(StartTime, EndTime, fs*(EndTime-StartTime));

ProbBurst = nan(numel(Participants), numel(TrialTypeLabels), 2, numel(t_window)); % the 2 is theta and alpha
GenProbBurst = nan(numel(Participants), 2);
ProbType = nan(numel(Participants), 3, numel(BandLabels), 2); % proportion of trials resulting in lapse, split by whether there was eyes closed or not

Filenames = getContent(BurstPath);

for Indx_P = 1:numel(Participants)


    AllTrials_EC = [];
    AllTrials_Table = table();

    for Indx_S = 1:numel(Sessions)

        % trial info for current recording
        CurrentTrials = find(strcmp(Trials.Participant, Participants{Indx_P}) & ...
            strcmp(Trials.Session, Sessions{Indx_S}));
        nTrials = nnz(CurrentTrials);

        % load in eeg data
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
        t_eeg = EEG.times;

        Freqs = 1./[Bursts.Mean_period];

        %         if numel(Freqs) < numel(Bursts) % weird bug
        %             % find missing datapoints
        %             BT = struct2table(Bursts);
        %             A = find(cellfun(@isempty, BT.Mean_period));
        %             Bursts(A) = [];
        %             Freqs = 1./[Bursts.Mean_period];
        %         end

        Trials_EC = nan(nTrials, numel(BandLabels), numel(t_window));


        for Indx_B = 1:numel(BandLabels)
            Band = Bands.(BandLabels{Indx_B});
            BurstTime = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2)), t_eeg);

            for Indx_T = 1:nTrials
                % trial info
                StimT = fs*Trials.StimTime(CurrentTrials(Indx_T));
                Start = round(StimT+fs*StartTime);

                End = Start + fs*(EndTime-StartTime) -1;

                Trials_EC(Indx_T, Indx_B, :) = BurstTime(Start:End);

            end
        end

          %%% pool sessions
        AllTrials_EC = cat(1, AllTrials_EC, Trials_EC);

        % save table info
        AllTrials_Table = cat(1, AllTrials_Table, Trials(CurrentTrials, :));
    end


    %%% get probability of burst (in time) for each trial type
    for Indx_T = 1:3

        % choose trials
        Trial_Indexes = AllTrials_Table.Type==Indx_T & ...
            AllTrials_Table.Radius < Q;
        nTrials = nnz(Trial_Indexes);
        AllTrials = AllTrials_EC(Trial_Indexes, :, :);

        % check if there's enough data       
        if isempty(AllTrials) || nTrials < minTrials
            continue
        end

        % average trials
        ProbBurst(Indx_P, Indx_T, :, :)  = sum(AllTrials, 1, 'omitnan')./nTrials;
    end

    % get general probability of bursts
    nTrials = size(AllTrials_EC, 1);
    GenProbBurst(Indx_P, :) = mean(sum(AllTrials_EC, 1, 'omitnan')./nTrials, 3, 'omitnan');


    %%% get probability of a lapse for every burst
    StimEdges = dsearchn(t_window', [StartStim; EndWindow]);
    StimWindow = StimEdges(1):StimEdges(2);

    BurstStatus = [0 1]; % not burst and burst
    for Indx_E = 1:numel(BurstStatus)
        Prcnt = sum(AllTrials_EC(:, :, StimWindow)==BurstStatus(Indx_E), 3)./numel(StimWindow); % percent of stimulus window with eyes either open or closed
        Tots = sum(Prcnt(AllTrials_Table.Radius<Q, :)>MinBurst, 'omitnan'); % total trials to consider with eyes in that configuration

         % check if there's enough data       
        if  Tots < minTrials*2
            continue
        end

        for Indx_T = 1:3 % loop through trial outcomes
            Trial_Indexes = AllTrials_Table.Type==Indx_T & ...
                AllTrials_Table.Radius<Q;

            ProbType(Indx_P, Indx_T, :, Indx_E) = sum(Prcnt(Trial_Indexes, :)>MinBurst, 'omitnan')/Tots;
        end
    end

    disp(['Finished ', Participants{Indx_P}])
end

% remove all data from participants missing any of the trial types
for Indx_P = 1:numel(Participants)
    if any(isnan(ProbBurst(Indx_P, :, :)), 'all')
        ProbBurst(Indx_P, :, :) = nan;
    end
end

t = t_window;
save(fullfile(Pool, 'ProbBurst.mat'), 'ProbBurst', 't', 'GenProbBurst')
save(fullfile(Pool, 'ProbType_Bursts.mat'), 'ProbType')

