clear
clc
close all

% generate a random signal
SampleRate = 1000;
Duration = 10; % seconds
t = linspace(0, Duration, Duration*SampleRate);
Signal = randn(size(t));

% filter the signal in narrow range (8-12 Hz)
FilteredSignal = cycy.utils.lowpass_filter(Signal, SampleRate, 12);
FilteredSignal = cycy.utils.highpass_filter(FilteredSignal, SampleRate, 8); 

% subtract filtered signal from main signal
SignalWithoutBand = Signal-FilteredSignal;

% calculate power
Overlap = .8;
nPoints = 2*SampleRate; % 2 seconds
noverlap = round(nPoints*Overlap);
window = hanning(nPoints);
[Power, ~] = pwelch(Signal, window, noverlap, nPoints, SampleRate);
[PowerWithoutBand, Freqs] = pwelch(SignalWithoutBand, window, noverlap, ...
    nPoints, SampleRate);

figure
plot(Freqs, Power)
hold on
plot(Freqs, PowerWithoutBand)
xlabel('Frequency (Hz)')
ylabel('Power')
legend({'Intact', 'SubtractingSine'})
xlim([0 40])
