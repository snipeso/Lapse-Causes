function [Eye, T] = cleanEye(Pupil, Eye, ColumnName, fs)
% smooths, resamples and cleans up eye vector
% Pupil is the table that Pupil Core outputs
% Eye is 0 or 1
% Colunm name is parameter to use, I recommend "confidence"
% fs is new sampling rate

SmoothFactor = 10; % I just picked a number that worked

% create time vector in seconds for pupil timestamps
t_Pupil = Pupil.pupil_timestamp(Pupil.eye_id == Eye); % get timestamps of specific eye

% select data and smooth it
D = smooth(Pupil.(ColumnName)(Pupil.eye_id == Eye), SmoothFactor);

% resample to EEG rate (reduces computation time)
[Eye, T] = resample(D, t_Pupil, fs);