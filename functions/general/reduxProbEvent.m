function Prob = reduxProbEvent(ProbEvent, t, Windows)
% ProbEvent is a 1 x t of ones, zeros and maybe nans
% t is a time vector for the trial
% Windows is a W x 2 array of starts and stops of the windows to aggregate
% the probabilities

nWindows = size(Windows, 1);
nChannels = size(ProbEvent, 1);

Prob = nan(nChannels, nWindows);

for Indx_Ch = 1:nChannels
    for Indx_W = 1:nWindows

        % get indexes for the window edges
        Edges = dsearchn(t', Windows(Indx_W, :)');

        % get average probability for that window
        Prob(Indx_Ch, Indx_W) = mean(ProbEvent(Indx_Ch, Edges(1):Edges(2)), 'omitnan');
    end
end
