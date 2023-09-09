function Tally = tally_timepoints(Tally, Vector)
% Tally is a Ch x 2 array, the first column indicating the total number of
% 1s, and the second column the total number of points in Vector.

if isempty(Tally)
    Tally = zeros(size(Vector, 1), 2);
end

TotChannels = size(Vector, 1);

for Indx_Ch = 1:TotChannels
    Tally(Indx_Ch, 1) = Tally(Indx_Ch, 1) + sum(Vector(Indx_Ch, :), 'omitnan');
    Tally(Indx_Ch, 2) = Tally(Indx_Ch, 2) + nnz(~isnan(Vector(Indx_Ch, :))); % like this so it doesn't count nans
end

% TODO: make it sum values instead of count ones