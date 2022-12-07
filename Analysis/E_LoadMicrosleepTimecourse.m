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

ConfidenceThreshold = 0.5;
minTrials = 10;
MinNaN = 0.5;

Tag =  ['s', num2str(StartTime), '_e', num2str(EndTime), '_w', num2str(WelchWindow)];
TitleTag = strjoin({'LapseCauses', 'LAT', 'Power', Tag}, '_');
TitleTag = replace(TitleTag, '.', '-');

Pool = fullfile(Paths.Pool, 'Eyes'); % place to save matrices so they can be plotted in next script

MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

% load trial information
load(fullfile(Paths.Pool, 'Tasks', 'AllTrials.mat'), 'Trials')
Q = quantile(Trials.Radius, 0.5);

TrialTypeLabels = [1 2 3];
Filenames = getContent(MicrosleepPath);
t = linspace(StartTime, EndTime, fs*(EndTime-StartTime));

ProbMicrosleep = nan(numel(Participants), numel(TrialTypeLabels), numel(t));
GenProbMicrosleep = nan(numel(Participants), 1);
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

        % load in eye data
        Filename = Filenames(contains(Filenames, Participants{Indx_P}) & ...
            contains(Filenames, Sessions{Indx_S}));

        if isempty(Filename)
            warning(['No data in ', Participants{Indx_P},  Sessions{Indx_S} ])
            continue
        elseif ~exist(fullfile(MicrosleepPath, Filename), 'file')
            warning(['No data in ', Filename])
            continue
        end
        load(fullfile(MicrosleepPath, Filename), 'Eyes')

        if isnan(Eyes.DQ) || Eyes.DQ == 0 || Eyes.DQ < 1
            warning(['Bad data in ', char(Filename)])
            continue
        end

        Eye = round(Eyes.DQ); % which eye

        % get 1s and 0s of whether eyes were open
        [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), fs, ConfidenceThreshold); % not using internal microsleep identifier so that I'm flexible

        % get each trial, save to field of trial type
        for Indx_T = 1:nTrials
            StimT = Trials.StimTime(CurrentTrials(Indx_T));
            Start = round(fs*(StimT+StartTime));
            End = round(fs*(StimT+EndTime))-1;
            Type = Trials.Type(CurrentTrials(Indx_T));

            % skip if far stimulus
            Radius = Trials.Radius(CurrentTrials(Indx_T));
            if Radius > Q
                continue
            end

%             if nnz(isnan(EyeOpen(Start:End)))/numel(Start:End) > MinNaN
%                 continue
%             end

            Trial = EyeOpen(Start:End)==0; % just keep track of eyes closed
            Data.(['T_', num2str(Type)]) = cat(1, Data.(['T_', num2str(Type)]), Trial);
        end
    end

    % get probabilities for each trial type
    PooledTrials = [];
    for Indx_T = 1:numel(TrialTypeLabels) % assign empty field for concatnation later
        AllTrials = Data.(['T_',num2str(TrialTypeLabels(Indx_T))]);
        PooledTrials = cat(1, PooledTrials, AllTrials);

        nTrials = size(AllTrials, 1);

        Nans = sum(isnan(AllTrials), 1);

        if isempty(AllTrials) || nTrials < minTrials || any(Nans > MinNaN) % makes sure every timepoint had at least 10 trials
            continue
        end

        ProbMicrosleep(Indx_P, Indx_T, :)  = sum(AllTrials, 1, 'omitnan')/nTrials;
    end

    % get general probability of eyes closed
    nTrials = size(PooledTrials, 1);
    GenProbMicrosleep(Indx_P) = mean(sum(PooledTrials, 1, 'omitnan')/nTrials, 'omitnan');

    disp(['Finished ', Participants{Indx_P}])
end

% remove all data from participants missing any of the trial types
for Indx_P = 1:numel(Participants)
    if any(isnan(ProbMicrosleep(Indx_P, :, :)), 'all')
        ProbMicrosleep(Indx_P, :, :) = nan;
    end
end

save(fullfile(Pool, 'ProbMicrosleep.mat'), 'ProbMicrosleep', 't', 'GenProbMicrosleep')
