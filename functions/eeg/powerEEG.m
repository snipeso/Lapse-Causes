function [Power, Freqs] = powerEEG(EEG, WelchWindow, Overlap)
% calculates power with welch function.
% WelchWindow = 8;
% Overlap = .75;

fs = EEG.srate;

nfft = 2^nextpow2(WelchWindow*fs);
noverlap = round(nfft*Overlap);
window = hanning(nfft);

[Power, Freqs] = pwelch(EEG.data', window, noverlap, nfft, fs);

Power = Power';