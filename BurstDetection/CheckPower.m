Freqs = 1./[Bursts.Mean_period];
% histogram(Freqs)

WelchWindow = 8; % duration of window to do FFT
Overlap = .75; % overlap of hanning windows for FFT

BurstBand = Freqs>=8 & Freqs <=12;
% BurstBand = Freqs>=4 & Freqs <=8;
% BurstBand = Freqs
EEG2 = EEG;
EEG2.data(:, ~EEG.valid_t) = nan;
EEG1 = pop_select(EEG, 'nopoint', [[Bursts(BurstBand).Start]', [Bursts(BurstBand).End]']);
EEG3 = pop_select(EEG, 'point', [[Bursts(BurstBand).Start]', [Bursts(BurstBand).End]']);

EEG2 = rmNaN(EEG2);
EEG1 = rmNaN(EEG1);
EEG3 = rmNaN(EEG3);

 [Power, Freqs] = powerEEG(EEG2, WelchWindow, Overlap);
 [Power1, ~] = powerEEG(EEG1, WelchWindow, Overlap);
  [Power3, ~] = powerEEG(EEG3, WelchWindow, Overlap);

 %

figure('units', 'normalized', 'Position', [0 0 .5 .5])
subplot(1, 4, 1)
plot(log(Freqs), log(Power)', 'Color', [.5 .5 .5 .2], 'LineWidth', 1)
title('Original Data')
xlim(log([1 40]))

subplot(1, 4, 2)
plot(log(Freqs), log(Power1)', 'Color', [.5 .5 .5 .2], 'LineWidth', 1)
title('Burstless Data')
xlim(log([1 40]))

subplot(1, 4, 3)
plot(log(Freqs), log(Power3)', 'Color', [.5 .5 .5 .2], 'LineWidth', 1)
title('Burst Data')
xlim(log([1 40]))


subplot(1, 4, 4)
hold on
plot(log(Freqs), log(mean(Power, 1)), 'LineWidth',2)
plot(log(Freqs), log(mean(Power1, 1)), 'LineWidth',2)
legend({'original', 'burstless'})
xlim(log([1 40]))