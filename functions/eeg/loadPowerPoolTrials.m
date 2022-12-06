function [AllData, Freqs, Chanlocs] = loadPowerPoolTrials(Source, Participants, Sessions, Task, TrialTypeLabels, Trials)
% load all power from main tasks, averaging by trial category
% Results in variable "AllData": P x S x T x Ch x F; and Chanlocs and Freqs
% TrialTypes is a cell array, with each cell containing a list of
% categories for each trial (one number per group). This then averages by
% group (T). Trials is a P x S array
% from Lapses-Causes.

disp('Loading power')

PowerType = 'Welch';
MinTrials = 10; % minimum number of trials before NaNing the participant


% set up new matrix
AllData = nan(numel(Participants), numel(TrialTypeLabels), 128, 1000); % bleah way of doing things, but handles if first participant is missing data

for Indx_P = 1:numel(Participants)
    Data = struct();
    for T = TrialTypeLabels % assign empty field for concatnation later
        Data.(['T_',num2str(T)]) = [];
    end

    for Indx_S = 1:numel(Sessions)

        %%% load power data
        Filename = strjoin({Participants{Indx_P}, Task, Sessions{Indx_S}, ...
            [PowerType, '.mat']}, '_');
        Path = fullfile(Source, Filename);

        if ~exist(Path, 'file')
            warning(['Missing ', Filename])
            continue
        end

        load(Path, 'Power', 'Freqs', 'Chanlocs') % Power is Ch x F x T

        if isempty(Power)
            continue
        end

        % get the correct trials
        TrialTypes = Trials{Indx_P, Indx_S};

        for T = TrialTypeLabels
            Data.(['T_',num2str(T)]) = cat(3, Data.(['T_',num2str(T)]), Power(:, :, TrialTypes==T));
        end
        clear Power
    end

    % average trials across sessions
    for Indx_T  = 1:numel(TrialTypeLabels)
        D = Data.(['T_',num2str(TrialTypeLabels(Indx_T))]);
        if size(D, 3) < MinTrials
            continue
        end

        AllData(Indx_P, Indx_T, 1:numel(Chanlocs), 1:numel(Freqs)) = mean(D, 3, 'omitnan');
    end

    disp(['Finished ', Participants{Indx_P}])
end

% remove extra padded nans
AllData(:, :, numel(Chanlocs)+1:128, :) = [];
AllData(:, :, :, numel(Freqs)+1:1000) = [];

