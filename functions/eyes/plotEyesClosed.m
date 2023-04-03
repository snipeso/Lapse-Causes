function plotEyesClosed(EEG, Eye)
% little function to plot EEG, shading areas marked as eyes closed

fs = EEG.srate;
Gray = [.8 .8 .8];
ConfidenceThreshold = 0.5;

[EyeOpen, ~] = classifyEye(Eye, fs, ConfidenceThreshold);
[Starts, Ends] = data2windows(EyeOpen==0);

TMPREJ = zeros(numel(Starts), size(EEG.data, 1)+5);
TMPREJ(:, 1) = Starts;
TMPREJ(:, 2) = Ends;

TMPREJ(:, 3:5) = repmat(Gray, numel(Starts), 1);

Pix = get(0,'screensize');

eegplot(EEG.data, 'srate', fs, 'spacing', 50, 'winlength', 60, ...
    'winrej', TMPREJ, 'position', [0 0 Pix(3) Pix(4)], 'events', EEG.event)