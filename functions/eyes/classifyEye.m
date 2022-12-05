function [EyeOpen, Microsleeps] = classifyEye(Eye, fs, Threshold)
% Classifies eyes as open or closed, and if stretch longer than 1s, as a
% microsleep.
% in Lapse-Causes

MicrosleepThreshold = 1; % in seconds

Nans = isnan(Eye);

% eye event can't be shorter than 50 ms
MinEO = .05;
% Convert pupils into 1s for opne and 0s for closed.
EyeOpen = Eye > Threshold;

% find all EO < 50ms
[Starts, Ends] = data2windows(EyeOpen);
Durations = (Ends - Starts)/fs;

for Indx_D = 1:numel(Durations)
    if Durations(Indx_D) < MinEO
        EyeOpen(Starts(Indx_D):Ends(Indx_D)) = 0;
    end
end

% find all EC < 50ms
[Starts, Ends] = data2windows(not(EyeOpen));
Durations = (Ends - Starts)/fs;

for Indx_D = 1:numel(Durations)
    if Durations(Indx_D) < MinEO
        EyeOpen(Starts(Indx_D):Ends(Indx_D)) = 1;
    end
end



%%% Classify microsleeps
[Starts, Ends] = data2windows(not(EyeOpen));

Durations = (Ends - Starts)/fs;
Keep = Durations >= MicrosleepThreshold;
Durations(~Keep) = [];
Starts(~Keep) = [];
Ends(~Keep) = [];

Microsleeps = zeros(size(EyeOpen));

for Indx_S = 1:numel(Starts)
    Microsleeps(Starts(Indx_S):Ends(Indx_S)) = true;
end

Microsleeps(Nans) = nan;
EyeOpen = double(EyeOpen);
EyeOpen(Nans) = nan;