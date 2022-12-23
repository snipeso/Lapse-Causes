function Time = burstAmps2time(Bursts, Pnts, fs)
% converts a struct of bursts data into an array of 0s and 1s for 1 if
% theres a burst.
% t is in datapoints, and will be the same length as Time

if isfield(Bursts, 'All_Start')
    Starts = [Bursts.All_Start];
    Ends = [Bursts.All_End];
else
    Starts = [Bursts.Start];
    Ends = [Bursts.End];
end

Time = zeros(1, Pnts);

for Indx_B = 1:numel(Starts)
    Duration = Bursts(Indx_B).All_End - Bursts(Indx_B).All_Start;
    nPeaks = (Duration/fs)*Bursts(Indx_B).Frequency;
    Amp = Bursts(Indx_B).Sum_Coh_Burst_amplitude_sum/(nPeaks);
    Time(Starts(Indx_B):Ends(Indx_B)) = Amp;
end