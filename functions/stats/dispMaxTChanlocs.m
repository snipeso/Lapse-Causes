function dispMaxTChanlocs(Stats, Chanlocs, String)

if ~any(Stats.sig)
    return
end

Stats.t(~Stats.sig) = nan;
[~, Indx] = max(abs(Stats.t));

dispStat(Stats, [Indx, 1], [String, ' ', Chanlocs(Indx).labels]);
