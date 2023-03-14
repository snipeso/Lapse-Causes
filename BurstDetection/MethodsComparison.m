% Previous methods used either fixed thresholds or standard-deviation based
% thresholds to determine theta events. This is not ok when there's a
% highly variable amount of that oscillation in the signal.
clear
clc
close all

P = burstParameters();

XLim = [140 160];

Signals = [];
Titles = {};

% load high-theta signal
load('E:\Data\Preprocessed\Clean\Waves\Game\P10_Game_Session2_Clean.mat')
Signals = cat(1, Signals, EEG.data(11, 60:240*EEG.srate));
Titles = cat(1, Titles, 'HighTheta');

% load low-theta signal
load('E:\Data\Preprocessed\Clean\Waves\Game\P06_Game_Baseline_Clean.mat')
Signals = cat(1, Signals, EEG.data(11,  60:240*EEG.srate));
Titles = cat(1, Titles, 'LowTheta');

% load no-theta signal
load('E:\Data\Preprocessed\Clean\Waves\Fixation\P03_Fixation_MainPre_Clean.mat')
Signals = cat(1, Signals, EEG.data(labels2indexes(60, EEG.chanlocs), 60:240*EEG.srate));
Titles = cat(1, Titles, 'NoTheta');

% load alpha signal
load('E:\Data\Preprocessed\Clean\Waves\Fixation\P09_Fixation_BaselinePost_Clean.mat')
Signals = cat(1, Signals, EEG.data(labels2indexes(72, EEG.chanlocs),  60:240*EEG.srate));
Titles = cat(1, Titles, 'Alpha');
fs = EEG.srate;


[Power, Freqs] = quickPower(Signals, fs, 4, .5);
lPower = logPower(Power);

Dims = size(Signals);


t = linspace(0, Dims(2)/fs, Dims(2));
%% Plot power

Colors = getColors(Dims(1));
figure
hold on
for Indx_S = 1:Dims(1)
    plot(log(Freqs), lPower(Indx_S, :), 'Color', Colors(Indx_S, :), 'LineWidth', 2);
end
legend(Titles)
xlim(log([2 40])); xticks(log([2 4 8 16 32])); xticklabels([2 4 8 16 32])




%% Bernardi method

hpSignals = hpfilt(Signals, fs, 2.5);

figure('Units','normalized','OuterPosition',[0 0 1 1])
for Indx_S  = 1:Dims(1)
    Df = hpSignals(Indx_S, :);
    D = Signals(Indx_S, :);

    % detect negative peaks
    Peaks = peakDetection(Df, Df);
    Peaks = peakProperties(Df, Peaks, fs);
    Peaks = meanFreq(Peaks);

    Freqs = [Peaks.Frequency];
    thetaPeaks = Peaks(Freqs<8 &Freqs>=4);
    topThetaPeaks = thetaPeaks([thetaPeaks.amplitude]> quantile([thetaPeaks.amplitude], .8));


    subplot(Dims(1), 1, Indx_S)
    hold on
    plot(t, D)
    scatter(t([thetaPeaks.NegPeakID]), D([thetaPeaks.NegPeakID]))
    scatter(t([topThetaPeaks.NegPeakID]), D([topThetaPeaks.NegPeakID]), 'r', 'filled')
    title([Titles{Indx_S}, ' Ntot=', num2str(numel(thetaPeaks)), '; Ntop=', num2str(numel(topThetaPeaks))])
    xlim(XLim)
end

setLims(Dims(1), 1, 'y');

%% Fattinger method

figure('Units','normalized','OuterPosition',[0 0 1 1])
for Indx_S  = 1:Dims(1)
    Df = hpSignals(Indx_S, :);
    D = Signals(Indx_S, :);


    % detect negative peaks
    Peaks = peakDetection(Df, Df);
    Peaks = peakProperties(Df, Peaks, fs);
    Peaks = meanFreq(Peaks);

    Freqs = [Peaks.Frequency];
    thetaPeaks = Peaks(Freqs<8 &Freqs>=4);
    topThetaPeaks = thetaPeaks(abs([thetaPeaks.voltageNeg])> std(Df));


    subplot(Dims(1), 1, Indx_S)
    hold on
    plot(t, D)
    scatter(t([thetaPeaks.NegPeakID]), D([thetaPeaks.NegPeakID]))
    scatter(t([topThetaPeaks.NegPeakID]), D([topThetaPeaks.NegPeakID]), 'r', 'filled')
    title([Titles{Indx_S}, ' Ntot=', num2str(numel(thetaPeaks)), '; Ntop=', num2str(numel(topThetaPeaks))])
    xlim(XLim)
end

setLims(Dims(1), 1, 'y');

%% Snipes method

AllEEG = EEG;
AllEEG.data = Signals;

Bands = P.Bands;
BandNames = fieldnames(Bands);

AllfEEG = struct();
% Filter signal
for Indx_B = 1:numel(BandNames)
    fSignals = nan(size(Signals));
    for Indx_S = 1:Dims(1)

        Filt = Signals(Indx_S, :);
        Filt = hpfilt(Filt, fs, Bands.(BandNames{Indx_B})(1));
        Filt = lpfilt(Filt, fs, Bands.(BandNames{Indx_B})(2));
        fSignals(Indx_S, :) = Filt;
    end

    fEEG = AllEEG;
    fEEG.data = fSignals;
    AllfEEG = catStruct(AllfEEG, fEEG);
end


Min_Peaks = 4;
Keep_Points = ones(size(t));
FinalBursts = getAllBursts(AllEEG, AllfEEG, P.BurstThresholds, Min_Peaks, P.Bands, Keep_Points);
FinalBursts = meanFreq(FinalBursts);

BurstFreqs = [FinalBursts.Frequency];
ThetaBursts = BurstFreqs>=4 & BurstFreqs <=8;

%% plot

figure('Units','normalized','OuterPosition',[0 0 1 1])
for Indx_S  = 1:Dims(1)
    D = Signals(Indx_S, :);
    Df = AllfEEG(2).data(Indx_S, :);

    % detect negative peaks

    topThetaPeaks = FinalBursts([FinalBursts.Channel]==Indx_S & ThetaBursts);

    Peaks = peakDetection(D, Df);
    Peaks = peakProperties(D, Peaks, fs);
    Peaks = meanFreq(Peaks);
    thetaPeaks = Peaks([Peaks.Frequency]>=4 & [Peaks.Frequency]<=8);

    subplot(Dims(1), 1, Indx_S)
    hold on
    plot(t, D)
    scatter(t([thetaPeaks.NegPeakID]), D([thetaPeaks.NegPeakID]))
    scatter(t([topThetaPeaks.NegPeakID]), D([topThetaPeaks.NegPeakID]), 'r', 'filled')
    title([Titles{Indx_S}, ' Ntot=', num2str(numel(thetaPeaks)), '; Ntop=', num2str(numel([topThetaPeaks.NegPeakID]))])
    xlim(XLim)
end

setLims(Dims(1), 1, 'y');





%%

Indx_S = 2;
D = Signals(Indx_S, :);
Df = AllfEEG(2).data(Indx_S, :);

Peaks = peakDetection(D, Df);
Peaks = peakProperties(D, Peaks, fs);
Peaks = meanFreq(Peaks);

BT = P.BurstThresholds(3);
BT.period = 1./[4 8];
BT = removeEmptyFields(BT);
[Bursts, BurstPeakIDs, Diagnostics] = findBursts(Peaks, BT, Min_Peaks, Keep_Points);
plotBursts(D, fs, Peaks, BurstPeakIDs, BT)
xlim(XLim)