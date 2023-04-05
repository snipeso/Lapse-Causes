function Tally = tallyTimepoints(Tally, Vector)
% Tally is a 1 x 2 array, the first number indicating the total number of
% 1s, and the second number the total number of points in Vector.

Tally(1) = Tally(1) + nnz(Vector==1);
Tally(2) = Tally(2) + nnz(Vector==1 | Vector==0); % like this so it doesn't count nans