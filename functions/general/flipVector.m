function FlippedVector = flipVector(Vector)
% turns 0s to 1s and 1s to 0s, leaving NaNs intact.

Ones = Vector == 1;
Zeros = Vector == 0;

FlippedVector = Vector;
FlippedVector(Ones) = 0;
FlippedVector(Zeros) = 1;