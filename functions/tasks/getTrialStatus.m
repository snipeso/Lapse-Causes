function Trials = getTrialStatus(Trials, ColumnName, CurrentTrials, Vector, fs, Window, MinWindow)
% Trials is table of all trials. Needs to have "StimTime"
% Vector is nans, 1s and 0s, and vector needs to have more than MinWindow
% to count as a 1.

nTrials = nnz(CurrentTrials);

for Indx_T = 1:nTrials
    StimT = round(fs*Trials.StimTime(CurrentTrials(Indx_T)));
    Start = StimT+Window(1)*fs;
    End = StimT+Window(2)*fs;

    Pnts = numel(Start:End); % uses both nans and 0s
    V = Vector(Start:End);

    if nnz(isnan(V))/Pnts > 0.5 % if too much nan, then ignore
        Trials.(ColumnName)(CurrentTrials(Indx_T)) = nan;

    elseif nnz(V==1)/Pnts > MinWindow
        Trials.(ColumnName)(CurrentTrials(Indx_T)) = 1;

    else
        Trials.(ColumnName)(CurrentTrials(Indx_T)) = 0;
    end
end