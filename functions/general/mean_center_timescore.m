function [zProb, zGenProb] = mean_center_timescore(ProbAll, GenProb, PreserveDim)

Dims = size(ProbAll);
zProb = nan(Dims);
zGenProb = nan(size(GenProb));

if isempty(PreserveDim) % microsleeps
    for idxParticipant = 1:Dims(1)
        zProb(idxParticipant, :, :) = (ProbAll(idxParticipant, :, :) - GenProb(idxParticipant, 1))./GenProb(idxParticipant, 2);
        zGenProb(idxParticipant) = 0;
    end

elseif PreserveDim == 3 % bursts on 3rd dimention
    for idxParticipant = 1:Dims(1)
        for idxBand = 1:Dims(3)
            zProb(idxParticipant, :, idxBand, :) = ...
                ((ProbAll(idxParticipant, :, idxBand, :) - GenProb(idxParticipant, idxBand, 1)))./GenProb(idxParticipant, idxBand, 2);

            zGenProb(idxParticipant, idxBand) = 0;
        end
    end
end