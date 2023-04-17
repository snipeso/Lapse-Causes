function Trials = getBurstTrials(Trials, BurstPath, Bands, fs, Windows, MinWindow, WindowColumns)
% using EEG and burst data with same sampling rate, identifies which
% trials had more than MinWindow eyes closed.
% Trials is table of trials.
% BurstPath is folder location with mat files containing structure Bursts
% (output from C_BurstProperties.m).
% Window is a 1 x 2 array in seconds of start and stop relative to
% stimulus.
% MinWindow is a fraction of the window to consider the trial having eyes
% closed.
% Bands is a structure, with fieldnames the band labels, and values the
% frequency ranges.

disp('Getting burst status for trials')

Participants = unique(Trials.Participant);
Sessions = unique(Trials.Session);
BandLabels = fieldnames(Bands);

for Indx_B = 1:numel(BandLabels)
    for Indx_W = 1:size(Windows, 1)
        Trials.([BandLabels{Indx_B},  '_', WindowColumns{Indx_W}]) = nan(size(Trials, 1), 1);
         Trials.([BandLabels{Indx_B},  '_', WindowColumns{Indx_W}, '_BR']) = nan(size(Trials, 1), 1);
    end
end

for Indx_P = 1:numel(Participants)
    for Indx_S = 1:numel(Sessions)

        % trial info for current recording
        CurrentTrials = find(strcmp(Trials.Participant, Participants{Indx_P}) & ...
            strcmp(Trials.Session, Sessions{Indx_S}));
        nTrials = nnz(CurrentTrials);

        % load in burst data
        Bursts = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'Bursts');
        if isempty(Bursts); continue; end

        EEG = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');
        Pnts = EEG.pnts;
        t_valid = EEG.valid_t; % has info of what timepoints were noise

        Freqs = [Bursts.Frequency];

        % get timepoints for each burst
        BurstTime = nan(numel(BandLabels), Pnts);
        for Indx_B = 1:numel(BandLabels)
            Band = Bands.(BandLabels{Indx_B});
            BT = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2)), Pnts);
            BurstTime(Indx_B, :) = BT;
        end

        % ignore noise timepoints
        BurstTime(:, not(t_valid)) = nan;

        % determine based on amount of eyes closed time, whether classify
        % trial as EC
        for Indx_B = 1:numel(BandLabels)
            Trials = getTrialStatus(Trials, BandLabels{Indx_B}, CurrentTrials,  ...
                BurstTime(Indx_B, :), fs, Windows, MinWindow, WindowColumns);
        end
    end
    disp(['Finished ', Participants{Indx_P}])
end