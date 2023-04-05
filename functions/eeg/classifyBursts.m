function BurstTimes = classifyBursts(Bursts, Bands, TotChannels, t_valid)
% BurstTimes is a Ch x B x t matrix of 1s, zeros, and nans for when there
% are bursts.

Freqs = [Bursts.Frequency];
Channels = [Bursts.Channel];
Pnts = numel(t_valid);

BandLabels = fieldnames(Bands);
BurstTimes = zeros(TotChannels, numel(BandLabels), Pnts);

for Indx_B = 1:numel(BandLabels)
    for Indx_Ch = 1:TotChannels
        Band = Bands.(BandLabels{Indx_B});
        BT = bursts2time(Bursts(Freqs>=Band(1) & Freqs<Band(2) & ...
            Channels==Indx_Ch), Pnts);
        BT(not(t_valid)) = nan;
        BurstTimes(Indx_Ch, Indx_B, :) = BT;
    end
end