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
Q = quantile(Trials.Radius, 0.5);


TrialTypeLabels = [1 2 3];
Filenames = getContent(BurstPath);
t = linspace(StartTime, EndTime, fs*(EndTime-StartTime));

ProbBurst = nan(numel(Participants), numel(TrialTypeLabels), 2, numel(t)); % the 2 is theta and alpha
% ProbBurstHemifield = nan(numel(Participants), numel(TrialTypeLabels), numel(t)); % just for alpha
ProbBurstHemifield = nan(numel(Participants), 2, numel(t)); % just for alpha
GenProbBurst = nan(numel(Participants), 2);
HemiProbBurst = nan(numel(Participants), 1);

for Indx_P = 1:numel(Participants)

    Data = struct();
    for T = TrialTypeLabels % assign empty field for concatnation later
        Data.(['T_',num2str(T)]) = [];
    end
    HemiData = Data;
    %     HemiData.Left = []; % visual field of stim
    %     HemiData.Right = [];

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

        if numel(Freqs) < numel(Bursts) % weird bug
            % find missing datapoints
            BT = struct2table(Bursts);
            A = find(cellfun(@isempty, BT.Mean_period));
            Bursts(A) = [];
            Freqs = 1./[Bursts.Mean_period];
        end

        ThetaTime = bursts2time(Bursts(Freqs>4 & Freqs<=8), t); % theta
        AlphaTime = bursts2time(Bursts(Freqs>8 & Freqs<=12), t); % alpha
        BurstTime = [ThetaTime; AlphaTime];

        % just for alpha hemifield
        MainChannels = [Bursts.Channel_Label];
        isRight = ismember(MainChannels, P.Channel_s.Right);
        AlphaRight = bursts2time(Bursts(Freqs>8 & Freqs<=12 & isRight), t);

        isLeft = ismember(MainChannels, P.Channels.Left);
        AlphaLeft = bursts2time(Bursts(Freqs>8 & Freqs<=12 & isLeft), t); % flip left, so negative values indicate left burst

        % get each trial, save to field of trial type
        for Indx_T = 1:nTrials
            StimT = Trials.StimTime(CurrentTrials(Indx_T));
            Start = round(fs*(StimT+StartTime));
            End = round(fs*(StimT+EndTime))-1;
            Type = Trials.Type(CurrentTrials(Indx_T));

            %             % skip if far stimulus
            %             Radius = Trials.Radius(CurrentTrials(Indx_T));
            %             if Radius > Q
            %                 continue
            %             end

            Trial = permute(BurstTime(:, Start:End), [3 1 2]); % trial x band x time
            Data.(['T_', num2str(Type)]) = cat(1, Data.(['T_', num2str(Type)]), Trial);

            isRightStim = Trials.isRight(CurrentTrials(Indx_T));
            %             Trial = AlphaRight(Start:End)-AlphaLeft(Start:End);
            if isRightStim
                Trial = AlphaRight(Start:End)-AlphaLeft(Start:End); % sum, so that simultaneous left-right bursts are cancelled out
                HemiData.(['T_', num2str(Type)]) = cat(1, HemiData.(['T_', num2str(Type)]), Trial);
                %             else
                %                                 Trial = AlphaLeft(Start:End)-AlphaRight(Start:End); % sum, so that simultaneous left-right bursts are cancelled out
                %                 HemiData.Left = cat(1, HemiData.Left, Trial);
            end

            %             HemiData.(['T_', num2str(Type)]) = cat(1, HemiData.(['T_', num2str(Type)]), Trial);
        end
    end

    % get probabilities for each trial type
    PooledTrials = [];
    for Indx_T = 1:numel(TrialTypeLabels) % assign empty field for concatnation later

        % main bursts
        AllTrials = Data.(['T_',num2str(TrialTypeLabels(Indx_T))]);
        PooledTrials = cat(1, PooledTrials, AllTrials);

        nTrials = size(AllTrials, 1);

        if isempty(AllTrials) || nTrials < minTrials
            continue
        end

        ProbBurst(Indx_P, Indx_T, :, :)  = sum(AllTrials, 1, 'omitnan')./nTrials;
    end


    PooledHemiTrials = [];
    Sides  = {'Left', 'Right'};
    for Indx_T = 1:numel(TrialTypeLabels) % assign empty field for concatnation later
        %     for Indx_T = 1:numel(Sides)
        % hemifield bursts
        AllTrials = HemiData.(['T_',num2str(TrialTypeLabels(Indx_T))]);
        %         AllTrials = HemiData.(Sides{Indx_T});
        PooledHemiTrials = cat(1, PooledHemiTrials, AllTrials);

        nTrials = size(AllTrials, 1);

        if isempty(AllTrials) || nTrials < minTrials
            continue
        end

        ProbBurstHemifield(Indx_P, Indx_T, :)  = sum(AllTrials, 1, 'omitnan')./nTrials;
    end

    % get general probability of burst
    nTrials = size(PooledTrials, 1);
    GenProbBurst(Indx_P, :) = mean(sum(PooledTrials, 1, 'omitnan')/nTrials, 3, 'omitnan');

    nTrials = size(PooledHemiTrials, 1);
    HemiProbBurst(Indx_P) = mean(sum(PooledHemiTrials, 1, 'omitnan')/nTrials, 'omitnan');

    disp(['Finished ', Participants{Indx_P}])
end

% remove all data from participants missing any of the trial types
for Indx_P = 1:numel(Participants)
    if any(isnan(ProbBurst(Indx_P, :, :)), 'all')
        ProbBurst(Indx_P, :, :) = nan;
    end

    if any(isnan(HemiProbBurst(Indx_P, :)), 'all')
        HemiProbBurst(Indx_P, :, :) = nan;
    end
end

t = linspace(StartTime, EndTime, fs*(EndTime-StartTime));
save(fullfile(Pool, 'ProbBurst.mat'), 'ProbBurst', 't', 'GenProbBurst', 'HemiProbBurst', 'ProbBurstHemifield')
