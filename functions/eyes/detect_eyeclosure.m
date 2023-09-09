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

for idxGap = 1:numel(Durations)
    if Durations(idxGap) < MinEO
        EyeOpen(Starts(idxGap):Ends(idxGap)) = 0;
    end
end

% find all EC < 50ms
[Starts, Ends] = data2windows(not(EyeOpen));
Durations = (Ends - Starts)/SampleRate;

for idxGap = 1:numel(Durations)
    if Durations(idxGap) < MinEO
        EyeOpen(Starts(idxGap):Ends(idxGap)) = 1;
    end
end

EyeOpen = double(EyeOpen);
EyeOpen(Nans) = nan;
EyeClosed = flip_vector_with_nans(EyeOpen);