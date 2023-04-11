function NewData = closeGaps(Data, MaxSize)
% in an array with nan's, provides interpolated values for smaller gaps

[Starts, Ends] = data2windows(isnan(Data));

Gaps = (Ends-Starts);



% fill edges with last result to avoid any edge artefacts
if Starts(1)==1
    Data(1:Ends(1)) = Data(Ends(1)+1);
end

if Ends(end) == numel(Data)
    Data(Starts(end):Ends(end)) = Data(Starts(end)-1);
end

    % keep list of only larger gaps
SmallGaps = Gaps<MaxSize;
    Starts(SmallGaps) = [];
Ends(SmallGaps) = [];

% interpolate all missing data
NewData = fillmissing(Data, 'linear');

% restore nans for the larger gaps
for Indx_G = 1:numel(Starts)
    NewData(Starts(Indx_G):Ends(Indx_G)) = nan;
end