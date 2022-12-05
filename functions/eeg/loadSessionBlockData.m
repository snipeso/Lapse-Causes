function [AllData, Freqs, Chanlocs, AllTrials] = loadSessionBlockData(P, Source, SessionBlocks)
% loads in EEG data and trial data, pooling based on session blocks

SessionBlocksLabels = fieldnames(SessionBlocks);


for Indx_B = 1:numel(SessionBlocksLabels)

    Sessions = SessionBlocks.(SessionBlocksLabels{Indx_B});
    Trials = loadLATmeta(P, Sessions, false);

    [Data, Freqs, Chanlocs] = loadAllPower(P, Source, Trials, Sessions); % Data is P x S x T x Ch x F;

    % reshape data so sessions are collapsed
    Dims = size(Data);


%     shData = squeeze(reshape(Data, Dims(1), [], 1, Dims(4), Dims(5)));

    if ~exist('AllTrials', 'var')

        % set up all trials structure
        TrialVariables = fieldnames(Trials);
        AllTrials = struct();

        for Indx_V = 1:numel(TrialVariables)
            AllTrials.(TrialVariables{Indx_V}) = permute(reshape(...
                Trials.(TrialVariables{Indx_V}), Dims(1), []), [1 3 2]);
        end

        % set up all data matrix
        AllData = nan(Dims(1), numel(SessionBlocksLabels), Dims(3), Dims(4));
        AllData(:, 1, :, :) = Data;
    else

    end

end
