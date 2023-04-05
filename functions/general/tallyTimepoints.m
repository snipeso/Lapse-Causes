function Tally = tallyTimepoints(Tally, Vector)
% Tally is a Ch x 2 array, the first column indicating the total number of
% 1s, and the second column the total number of points in Vector.

TotChannels = size(Vector, 1);

for Indx_Ch = 1:TotChannels
    Tally(Indx_Ch, 1) = Tally(Indx_Ch, 1) + nnz(Vector(Indx_Ch, :)==1);
    Tally(Indx_Ch, 2) = Tally(Indx_Ch, 2) + nnz(Vector(Indx_Ch, :)==1 | ...
        Vector(Indx_Ch, :)==0); % like this so it doesn't count nans
end