function Array = windows2array(Starts, Ends, MaxLength)

Array = false(1, MaxLength);

for idxStart = 1:numel(Starts)
    Array(Starts(idxStart):Ends(idxStart)) = true;
end

