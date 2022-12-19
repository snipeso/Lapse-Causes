function Trials = getBurstTrials(Trials, BurstPath, Bands, fs)
% using EEG and burst data with same sampling rate, identifies which
% trials had more than 50% eyes closed

BandLabels = fieldnames(Bands);

disp('Getting burst status for trials')

Participants = unique(Trials.Participant);
Sessions = unique(Trials.Session);

for Indx_B = 1:numel(BandLabels)
    Trials.(BandLabels{Indx_B}) = nan(size(Trials, 1), 1);
end

% timewindow relative to stim onset to see if eyes were open or closed
StartWindow = 0;
EndWindow = 1;

ConfidenceThreshold = 0.5;
MinBurst = 0.5; % faction of trial that needs to be EO to be considered EO
MinNaN = 0.5; % fraction of trial time to consider whether NAN

Filenames = getContent(BurstPath);

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
        t_valid = EEG.valid_t;

        Freqs = [Bursts.Frequency];

        % get timepoints for each burst
        BurstTime = nan(numel(BandLabels), Pnts);
        for Indx_B = 1:numel(BandLabels)
            Band = Bands.(BandLabels{Indx_B});
            BT = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2)), Pnts);
            BurstTime(Indx_B, :) = BT;
        end

        BurstTime(:, not(t_valid)) = nan;

        % determine based on amount of eyes closed time, whether classify
        % trial as EC
        for Indx_T = 1:nTrials
                StimT = round(fs*Trials.StimTime(CurrentTrials(Indx_T)));
                Start = StimT+StartWindow*fs;
                End = StimT+EndWindow*fs;

            for Indx_B = 1:numel(BandLabels)

                if nnz(isnan(BurstTime(Indx_B, Start:End)))/numel(Start:End) > MinNaN
                    Trials.(BandLabels{Indx_B})(CurrentTrials(Indx_T)) = nan;
                elseif nnz(BurstTime(Indx_B, Start:End))/numel(Start:End) >= MinBurst
                    Trials.(BandLabels{Indx_B})(CurrentTrials(Indx_T)) = 1;
                else
                    Trials.(BandLabels{Indx_B})(CurrentTrials(Indx_T)) = 0;
                end
            end
        end
    end
    disp(['Finished ', Participants{Indx_P}])
end