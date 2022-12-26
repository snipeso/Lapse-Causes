function [zProb, zGenProb] = zscoreTimecourse(ProbAll, GenProb, PreserveDim)

Dims = size(ProbAll);

zProb = nan(Dims);
zGenProb = nan(size(GenProb));


if isempty(PreserveDim) % microsleeps
    for Indx_P = 1:Dims(1)
        Prob = ProbAll(Indx_P, :, :);
        MEAN = mean(Prob, 'all', 'omitnan');
        STD = std(Prob, 0, 'all', 'omitnan');
        zProb(Indx_P, :, :) = (Prob-MEAN)./STD;

        zGenProb(Indx_P) = (GenProb(Indx_P)-MEAN)./STD;
    end

elseif PreserveDim==3 % bursts
    for Indx_P = 1:Dims(1)
        for Indx_B = 1:Dims(3)
            Prob = ProbAll(Indx_P, :, Indx_B, :);
            MEAN = mean(Prob, 'all', 'omitnan');
            STD = std(Prob, 0, 'all', 'omitnan');
            zProb(Indx_P, :, Indx_B, :) = (Prob-MEAN)./STD;

            zGenProb(Indx_P, Indx_B) = (GenProb(Indx_P, Indx_B)-MEAN)./STD;
        end
    end
elseif PreserveDim==4 % bursts
    for Indx_P = 1:Dims(1)
        for Indx_B = 1:Dims(4)
            Prob = ProbAll(Indx_P, :, :, Indx_B, :);
            MEAN = mean(Prob, 'all', 'omitnan');
            STD = std(Prob, 0, 'all', 'omitnan');
            zProb(Indx_P, :, :, Indx_B, :) = (Prob-MEAN)./STD;

            zGenProb(Indx_P, :, Indx_B) = (GenProb(Indx_P, :, Indx_B)-MEAN)./STD;
        end
    end
end


end