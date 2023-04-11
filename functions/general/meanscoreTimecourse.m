function [zProb, zGenProb] = meanscoreTimecourse(ProbAll, GenProb, PreserveDim)

Dims = size(ProbAll);


zProb = nan(Dims);
zGenProb = nan(size(GenProb));

if isempty(PreserveDim) % microsleeps
    for Indx_P = 1:Dims(1)
        zProb(Indx_P, :, :) = ProbAll(Indx_P, :, :) - GenProb(Indx_P);
        zGenProb(Indx_P) = 0;
    end

elseif PreserveDim == 4 % bursts on 4th dimention
    for Indx_P = 1:Dims(1)
        for Indx_Ch = 1:Dims(3)
            for Indx_B = 1:Dims(4)
                zProb(Indx_P, :, Indx_Ch, Indx_B, :) = ...
                    ProbAll(Indx_P, :, Indx_Ch, Indx_B, :) - GenProb(Indx_P, Indx_Ch, Indx_B);
                zGenProb(Indx_P, Indx_Ch, Indx_B) = 0;
            end
        end
    end
end