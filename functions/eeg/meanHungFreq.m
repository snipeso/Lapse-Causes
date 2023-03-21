function AllBursts = meanHungFreq(AllBursts)
% loops through all bursts, gets mean frequency based on period
% (zero-crossings around negative peak)

for Indx_B = 1:numel(AllBursts)
    AllBursts(Indx_B).Frequency = 1/mean(AllBursts(Indx_B).periodNeg);
end