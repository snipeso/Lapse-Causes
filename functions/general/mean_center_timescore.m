function [zProb, zGenProb] = mean_center_timescore(ProbAll, GenProb, PreserveDim)

Dims = size(ProbAll);
zProb = nan(Dims);
zGenProb = nan(size(GenProb));

if isempty(PreserveDim) % microsleeps
    for idxParticipant = 1:Dims(1)
        zProb(idxParticipant, :, :) = (ProbAll(idxParticipant, :, :) - GenProb(idxParticipant));
        zGenProb(idxParticipant) = 0;
    end

elseif PreserveDim == 3 % bursts on 3rd dimention
    for idxParticipant = 1:Dims(1)
        for idxBand = 1:Dims(3)
            % zProb(idxParticipant, :, idxBand, :) = ...
            %     (ProbAll(idxParticipant, :, idxBand, :) - GenProb(idxParticipant, idxBand));

            Prob = ProbAll(idxParticipant, :, idxBand, :);
            zProb(idxParticipant, :, idxBand, :) = ...
                (ProbAll(idxParticipant, :, idxBand, :) - GenProb(idxParticipant, idxBand));

            zGenProb(idxParticipant, idxBand) = 0;
        end
    end
elseif PreserveDim == 4 % bursts on 4th dimention
    for idxParticipant = 1:Dims(1)
        for idxChannel = 1:Dims(3)
            for idxBand = 1:Dims(4)
                % zProb(idxParticipant, :, idxChannel, idxBand, :) = ...
                %     100*(ProbAll(idxParticipant, :, idxChannel, idxBand, :) - ...
                %     GenProb(idxParticipant, idxChannel, idxBand))./GenProb(idxParticipant, idxChannel, idxBand);

                   zProb(idxParticipant, :, idxChannel, idxBand, :) = ...
                (ProbAll(idxParticipant, :, idxChannel, idxBand, :) - GenProb(idxParticipant, idxChannel, idxBand));
                zGenProb(idxParticipant, idxChannel, idxBand) = 0;
            end
        end
    end
end
end