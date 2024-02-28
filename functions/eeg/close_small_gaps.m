function NewData = close_small_gaps(Data, MaxSize)

% identify gaps
[Starts, Ends] = data2windows(isnan(Data));
if isempty(Starts) || all(isnan(Data))
    NewData = Data;
    return
end
Gaps = (Ends-Starts);

% if any gap is too large, return only nans
if any(Gaps>MaxSize)
    NewData = nan(size(Data));
    return
end

% if starts with a gap, fill the gap with just the first value
if Starts(1)==1
    Data(1:Ends(1)) = Data(Ends(1)+1);
end

% likewise for if it ends with a gap
if Ends(end) == numel(Data)
    Data(Starts(end):Ends(end)) = Data(Starts(end)-1);
end

% interpolate all missing data
NewData = fillmissing(Data, 'linear');
end
