function Trials = getTrialStatus(Trials, ColumnName, CurrentTrials, Vector, fs, Windows, MinWindow, WindowColumns)
% Trials is table of all trials. Needs to have "StimTime"
% Vector is nans, 1s and 0s, and vector needs to have more than MinWindow
% to count as a 1.

MinNanProportion = 0.5;
nTrials = nnz(CurrentTrials);
nWindows = size(Windows, 1);

for Indx_T = 1:nTrials
    for Indx_W = 1:nWindows
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
    end
end