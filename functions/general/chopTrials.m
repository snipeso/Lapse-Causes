function [Trials_Stim, Trials_Resp] = chopTrials(Timecourse, Trials, CurrentTrials, StartTime, EndTime, fs)

Pnts = numel((StartTime*fs):(EndTime*fs-1));
nTrials = numel(CurrentTrials);

Trials_Stim = nan(nTrials, Pnts);
Trials_Resp = nan(nTrials, Pnts);

for Indx_T = 1:nTrials

    % stimulus locked
    StimT = round(fs*Trials.StimTime(CurrentTrials(Indx_T)));
    Start = StimT+StartTime*fs;
    End = StimT+EndTime*fs-1;

    Trial = Timecourse(Start:End);
    Trials_Stim(Indx_T, :) = Trial;


    % response locked
    RespT = round(fs*Trials.RespTime(CurrentTrials(Indx_T)));

    if isnan(RespT)
        continue
    end

    Start = RespT+StartTime*fs;
    End = RespT+EndTime*fs-1;

    Trial = Timecourse(Start:End);
    Trials_Resp(Indx_T, :) = Trial;
end










