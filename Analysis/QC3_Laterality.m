% Script to get left vs right topography of theta and alpha

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
SessionBlocks = P.SessionBlocks;
Paths = P.Paths;
Task = P.Labels.Task; % LAT
Bands = P.Bands;
Triggers = P.Triggers;
Parameters = P.Parameters;

fs = Parameters.fs;
TotChannels = 123;
TotBands = 2;

% locations
Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script
if ~exist(Pool, 'dir')
    mkdir(Pool)
end

BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts_AllChannels', Task);
WholeBurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task); % needed for valid t

SessionBlockLabels = fieldnames(SessionBlocks);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% get data

for Indx_SB = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = P.SessionBlocks.(SessionBlockLabels{Indx_SB});

    % set up blanks
    ProbBurst = zeros(numel(Participants), 2, TotChannels, TotBands, 2); % P x H x Ch x B x 2 matrix with final probabilities

    for Indx_P = 1:numel(Participants)
        for Indx_S = 1:numel(Sessions)

            %%% load in burst data
            Bursts = load_datafile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'AllBursts');
            if isempty(Bursts); continue; end

            EEG = load_datafile(WholeBurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');
            Pnts = EEG.pnts;
            t_valid = EEG.valid_t;
            Chanlocs = EEG.chanlocs;

            % create vector of left-right laterality
            isLeft = hemifieldTime(EEG.event, Triggers, t_valid);

            % remove bursts that were chopped
            Bursts = removeChopped(Bursts);

            % get frequency of each burst
            Bursts = meanFreq(Bursts);
            Channels = [Bursts.Channel];

            % get matrix of when there are bursts for each channel
            BurstTimes = bursts2timeChannels(Bursts, Bands, TotChannels, t_valid); % Ch x B x t

            for Indx_B = 1:TotBands
                for Indx_H = 1:2
                    if Indx_H == 1 % left
                        HemiPoints = isLeft==1;
                    else
                        HemiPoints = isLeft==0;
                    end

                    BT = squeeze(BurstTimes(:, Indx_B, :)); % Ch x t
                    BT(:, ~HemiPoints) = nan; % nan other hemifield, so isn't included in count

                    ProbBurst(Indx_P, Indx_H, :, Indx_B, :) = ...
                        tallyTimepoints(squeeze(ProbBurst(Indx_P, Indx_H, :, Indx_B, :)), BT);
                end
            end
        end

        disp(['Finished ', Participants{Indx_P}])
    end

    % calculate general probabilities
    ProbBurst = ProbBurst(:, :, :, :, 1)./ProbBurst(:, :, :, :, 2); % P x Ch x B x t

    %%% save
    save(fullfile(Pool, ['Laterality_', SessionBlockLabels{Indx_SB}, '.mat']), ...
        'ProbBurst', 'Chanlocs')
end



