Resolutions = [0.5];

Colors = getColors([1 numel(Resolutions)]);

EEG2 = EEG;
% EEG2.data = EEG.data(72, :);


figure
hold on
for Indx_R = 1:numel(Resolutions)
[Power, Freqs] = powerEEG(EEG2, Resolutions(Indx_R), 0);

plot(log(Freqs), log(Power), 'Color', Colors(Indx_R, :))

end

% xlim([2 20])
legend(string(Resolutions))
xlabel('Frequency (Hz)')
ylabel('PSD (miV^2/0.25*Hz)')