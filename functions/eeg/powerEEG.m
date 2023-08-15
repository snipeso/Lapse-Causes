function [Power, Freqs] = powerEEG(EEG, WelchWindow, Overlap)
% calculates power with welch function.
% WelchWindow = 8;
% Overlap = .75;

tic
fs = EEG.srate;

nfft = 2^nextpow2(WelchWindow*fs);
% nfft = WelchWindow*fs;
noverlap = round(nfft*Overlap);
window = hanning(nfft);

[Power, Freqs] = pwelch(EEG.data', window, noverlap, nfft, fs);

Power = Power';

toc