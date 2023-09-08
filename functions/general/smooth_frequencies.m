function sData = smooth_frequencies(Data, Frequencies, FrequencyDimention, SmoothSpan)
% smooth_frequencies(Data, Freqs, FreqDim, SmoothSpan)
% function for smoothing data by "smoothSpan".
% horrible mess, to fix once I figure out how
% for Lapse-Causes

Dims = size(Data);


sData = nan(Dims);
switch FrequencyDimention
    case 'last'
        switch numel(Dims)
            case 2
                   for Indx_P = 1:Dims(1)
                            sData(Indx_P, :) = smoothF(Data(Indx_P, :), Frequencies, SmoothSpan);
                end

            case 3
                  for Indx_P = 1:Dims(1)
                    for Indx_S = 1:Dims(2)
                            sData(Indx_P, Indx_S, :) = smoothF(Data(Indx_P, Indx_S, :), Frequencies, SmoothSpan);
                        
                    end
                end
            case 4
                for Indx_P = 1:Dims(1)
                    for Indx_S = 1:Dims(2)
                        for Indx_Ch = 1:Dims(3)
                            sData(Indx_P, Indx_S, Indx_Ch, :) = smoothF(Data(Indx_P, Indx_S, Indx_Ch, :), Frequencies, SmoothSpan);
                        end
                    end
                end
                
            case 5
                for Indx_P = 1:Dims(1)
                    for Indx_S = 1:Dims(2)
                        for Indx_T = 1:Dims(3)
                            for Indx_Ch = 1:Dims(4)
                                sData(Indx_P, Indx_S, Indx_T, Indx_Ch, :) = smoothF(Data(Indx_P, Indx_S, Indx_T, Indx_Ch, :), Frequencies, SmoothSpan);
                            end
                        end
                    end
                end
            case 6
                for Indx_P = 1:Dims(1)
                    for Indx_S = 1:Dims(2)
                        for Indx_T = 1:Dims(3)
                            for Indx_Ch = 1:Dims(4)
                                for Indx_6 = 1:Dims(5)
                                    sData(Indx_P, Indx_S, Indx_T, Indx_Ch, Indx_6, :) = smoothF(Data(Indx_P, Indx_S, Indx_T, Indx_Ch, Indx_6, :), Frequencies, SmoothSpan);
                                end
                            end
                        end
                    end
                end
            otherwise
                error('dont know this dimention for smoothing')
        end
    otherwise
        error('dont know this dimention for smoothing')
end


function SmoothData = smoothF(Data, Freqs, SmoothSpan)
% function for smoothing data (so that I'm consistent in all the code).
% Data is a 1 x Freqs matrix.

FreqRes = Freqs(2)-Freqs(1);
SmoothPoints = round(SmoothSpan/FreqRes);

SmoothData = smooth_frequencies(Data, SmoothPoints, 'lowess');