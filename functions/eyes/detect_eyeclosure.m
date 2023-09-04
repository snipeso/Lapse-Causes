function EyeClosed = detect_eyeclosure(Eye, SampleRate, Threshold)
% Classifies eyes as open or closed, and if stretch longer than 1s, as a
% microsleep.
% in Lapse-Causes

Nans = isnan(Eye);

% eye event can't be shorter than 50 ms
MinEO = .05;
% Convert pupils into 1s for opne and 0s for closed.
EyeOpen = Eye > Threshold;

% find all EO < 50ms
[Starts, Ends] = data2windows(EyeOpen);
Durations = (Ends - Starts)/SampleRate;

for Indx_D = 1:numel(Durations)
    if Durations(Indx_D) < MinEO
        EyeOpen(Starts(Indx_D):Ends(Indx_D)) = 0;
    end
end

% find all EC < 50ms
[Starts, Ends] = data2windows(not(EyeOpen));
Durations = (Ends - Starts)/SampleRate;

for Indx_D = 1:numel(Durations)
    if Durations(Indx_D) < MinEO
        EyeOpen(Starts(Indx_D):Ends(Indx_D)) = 1;
    end
end

EyeOpen = double(EyeOpen);
EyeOpen(Nans) = nan;
EyeClosed = flip_vector_with_nans(EyeOpen);