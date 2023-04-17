function Trials = getTrialStatus(Trials, ColumnName, CurrentTrials, Vector, fs, Windows, MinWindow, WindowColumns)
% Trials is table of all trials. Needs to have "StimTime"
% Vector is nans, 1s and 0s, and vector needs to have more than MinWindow
% to count as a 1.

MinNanProportion = 0.5;
nTrials = nnz(CurrentTrials);
nWindows = size(Windows, 1);

for Indx_T = 1:nTrials
    for Indx_W = 1:nWindows

        %%% assign 0, 1 or nan for whether there is an event in a given
        %%% window for each trial.
        StimT = round(fs*Trials.StimTime(CurrentTrials(Indx_T)));
        Start = StimT+Windows(Indx_W, 1)*fs;
        End = StimT+Windows(Indx_W, 2)*fs;

        Pnts = numel(Start:End); % uses both nans and 0s
        V = Vector(Start:End);

        if nnz(isnan(V))/Pnts > MinNanProportion % if too much nan, then ignore
            Trials.([ColumnName,  '_', WindowColumns{Indx_W}])(CurrentTrials(Indx_T)) = nan;

        elseif nnz(V==1)/Pnts > MinWindow
            Trials.([ColumnName, '_', WindowColumns{Indx_W}])(CurrentTrials(Indx_T)) = 1;

        else
            Trials.([ColumnName, '_', WindowColumns{Indx_W}])(CurrentTrials(Indx_T)) = 0;
        end


        %%% assign 0, 1 or nan based on whether a window of equivalent size
        %%% just before stimulus onset (excluding nans as much as possible)
        %%% has that event or not (used to determine base rate probability
        %%% of that event, given the selected window size)
        PreStim = flip(Vector(round(StimT-fs*4):StimT));
        PreStim(isnan(PreStim)) = []; % ignore all nans
        WinLength = End-Start;
        if numel(PreStim) < WinLength*MinNanProportion
            Trials.([ColumnName,  '_', WindowColumns{Indx_W}, '_BR'])(CurrentTrials(Indx_T)) = nan;
            continue
        elseif numel(PreStim) < WinLength
            WinLength = numel(PreStim); % if not the full length of the target window, but still not completely nans
        end

        % get window the same length
        PreStim = PreStim(1:WinLength);

        if nnz(PreStim==1)/numel(PreStim) > MinWindow
            Trials.([ColumnName, '_', WindowColumns{Indx_W}, '_BR'])(CurrentTrials(Indx_T)) = 1;
        else
            Trials.([ColumnName, '_', WindowColumns{Indx_W}, '_BR'])(CurrentTrials(Indx_T)) = 0;
        end

    end
end