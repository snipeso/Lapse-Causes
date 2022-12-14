function AllBursts = removeChopped(AllBursts)
% remove bursts that were previously chopped (mistake)

RM = zeros(1, numel(AllBursts));

for Indx_B = 1:numel(AllBursts)
    if AllBursts(Indx_B).nPeaks ~= numel(AllBursts(Indx_B).PeakIDs)
           RM(Indx_B) = 1;
    end
end


AllBursts(logical(RM)) = [];