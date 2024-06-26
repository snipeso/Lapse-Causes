function FlippedVector = flip_vector_with_nans(Vector)
% turns 0s to 1s and 1s to 0s, leaving NaNs intact.

FlippedVector = double(Vector==0);
FlippedVector(isnan(Vector)) = nan;