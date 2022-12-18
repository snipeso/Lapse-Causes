function Time = bursts2time(Bursts, Pnts)
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
    Time(Starts(Indx_B):Ends(Indx_B)) = 1;
end