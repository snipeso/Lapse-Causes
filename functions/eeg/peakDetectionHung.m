function Peaks = peakDetectionHung(Wave)
% finds negative peaks as min point between a down zero-crossing and an up
% zero crossing.

[DZC, UZC] = getZC(Wave);

%%% Find peaks and troughs between zero crossings
Peaks = struct();
for n = 1:length(DZC)

    % find lowest point between zero crossings in filtered wave
    [~, NegPeakID] = min(Wave(DZC(n):UZC(n)));

    % adjust negative peak index to absolute value in ref wave
    NegPeakID = NegPeakID + DZC(n) - 1;

    Peaks(n).NegPeakID = NegPeakID;
     Peaks(n).MidUpID = UZC(n);
      Peaks(n).MidDownID = DZC(n);

    % positive peak
    if n < length(DZC)
        [~, PosPeakID] = max(Wave(UZC(n):DZC(n+1)));
        PosPeakID = PosPeakID + UZC(n) - 1;
        Peaks(n).PosPeakID = PosPeakID;
    else
        Peaks(n).PosPeakID =UZC(n)+1;
    end
end


% final adjustment to positive peaks to make sure they are the largest
% point between midpoints. % TODO also for negative??
for n = 1:numel(Peaks)-1
    [~, PosPeakID] = max(Wave(Peaks(n).MidUpID:Peaks(n+1).MidDownID));
    PosPeakID = PosPeakID + Peaks(n).MidUpID - 1;
    Peaks(n).PosPeakID = PosPeakID;
    Peaks(n).NextMidDownID = Peaks(n+1).MidDownID;
    if n>1
        Peaks(n).PrevPosPeakID = Peaks(n-1).PosPeakID;
    end
end

% remove last peak if it's positive peak doesn't exist:
if Peaks(n).PosPeakID > numel(Wave)
    Peaks(end) = [];
end
