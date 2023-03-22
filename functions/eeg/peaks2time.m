function Time = peaks2time(Peaks, StartVariable, EndVariable, Pnts)
% turns structure of peaks into a time vector, based on variables indicated

Time = zeros(1, Pnts);

Starts = [Peaks.(StartVariable)];
Ends = [Peaks.(EndVariable)];

for Indx_P = 1:numel(Starts)
    Time(Starts(Indx_P):Ends(Indx_P)) = 1;
end