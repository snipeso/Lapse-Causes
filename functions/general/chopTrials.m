function [Trials_Stim, Trials_Resp] = chopTrials(Timecourse, Trials, TrialWindow, fs)
% function to chop a given Timecourse (1 x t_all) into trials locked to the
% stimulus onset and response onset. Trial information is inside the table
% Trials (column names StimTime and RespTime). TrialWindow is a [1 x 2]
% array with start and end time, in seconds. fs is the sampling rate.
% Output is a nTrial x t_window array. 

Pnts = numel((TrialWindow(1)*fs):(TrialWindow(2)*fs-1));
nTrials = size(Trials, 1);

Trials_Stim = nan(nTrials, Pnts);
Trials_Resp = nan(nTrials, Pnts);

for Indx_T = 1:nTrials

    % stimulus locked
    StimT = round(fs*Trials.StimTime(Indx_T));
    Start = StimT+TrialWindow(1)*fs;
    End = StimT+TrialWindow(2)*fs-1;

    Trial = Timecourse(Start:End);
    Trials_Stim(Indx_T, :) = Trial;


    % response locked
    RespT = round(fs*Trials.RespTime(Indx_T));

    if isnan(RespT)
        continue
    end

    Start = RespT+TrialWindow(1)*fs;
    End = RespT+TrialWindow(2)*fs-1;

    Trial = Timecourse(Start:End);
    Trials_Resp(Indx_T, :) = Trial;
end










