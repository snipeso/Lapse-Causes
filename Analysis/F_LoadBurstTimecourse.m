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
fs = 1000;
WelchWindow = 2;

% ConfidenceThreshold = 0.5;
minTrials = 10;
MinNaN = 0.5;

Tag =  ['s', num2str(StartTime), '_e', num2str(EndTime), '_w', num2str(WelchWindow)];
TitleTag = strjoin({'LapseCauses', 'LAT', 'Power', Tag}, '_');
TitleTag = replace(TitleTag, '.', '-');

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script

BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts_Old', Task); % Temp!


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', 'AllTrials.mat'), 'Trials')

TrialTypeLabels = [1 2 3];
Filenames = getContent(BurstPath);
t = linspace(StartTime, EndTime, fs*(EndTime-StartTime));

ProbBurst = nan(numel(Participants), numel(TrialTypeLabels), 2, numel(t)); % the 2 is theta and alpha
for Indx_P = 1:numel(Participants)

    Data = struct();
    for T = TrialTypeLabels % assign empty field for concatnation later
        Data.(['T_',num2str(T)]) = [];
    end

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
        t = EEG.times;

        Freqs = 1./[Bursts.Mean_period];
        ThetaTime = bursts2time(Bursts(Freqs>4 & Freqs<=8), t); % theta
        AlphaTime = bursts2time(Bursts(Freqs>8 & Freqs<=12), t); % alpha
        BurstTime = [ThetaTime; AlphaTime];

        % get each trial, save to field of trial type
        for Indx_T = 1:nTrials
            StimT = Trials.StimTime(CurrentTrials(Indx_T));
            Start = round(fs*(StimT+StartTime));
            End = round(fs*(StimT+EndTime))-1;
            Type = Trials.Type(CurrentTrials(Indx_T));

            Trial = permute(BurstTime(:, Start:End), [3 1 2]); % trial x band x time
            Data.(['T_', num2str(Type)]) = cat(1, Data.(['T_', num2str(Type)]), Trial);
        end
    end

    % get probabilities for each trial type
    for Indx_T = 1:numel(TrialTypeLabels) % assign empty field for concatnation later
        AllTrials = Data.(['T_',num2str(TrialTypeLabels(Indx_T))]);

        nTrials = size(AllTrials, 1);

        if isempty(AllTrials) || nTrials < minTrials
            continue
        end

        ProbBurst(Indx_P, Indx_T, :, :)  = sum(AllTrials, 1, 'omitnan')./nTrials;
    end

    disp(['Finished ', Participants{Indx_P}])
end

% remove all data from participants missing any of the trial types
for Indx_P = 1:numel(Participants)
    if any(isnan(ProbBurst(Indx_P, :, :)), 'all')
        ProbBurst(Indx_P, :, :) = nan;
    end
end

t = linspace(StartTime, EndTime, fs*(EndTime-StartTime));
save(fullfile(Pool, 'ProbBurst.mat'), 'ProbBurst', 't')
