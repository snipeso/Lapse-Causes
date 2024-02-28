load('D:\Data\LSM\Preprocessed\Clean\Waves\LAT\P01_LAT_BaselineBeam_Clean.mat')

freqs = 1:20;

[Power, ~, TF.times] = wavetransform(EEG.data(68, :), EEG.srate, freqs, 3, 15);

Power = squeeze(Power);
EEGw = EEG;
EEGw.data = Power;
EEGwe = pop_epoch(EEGw, {'S  3'}, [-2 4]);

t= linspace(-2, 4, 1500);

%%

close all

Mean = mean(Power, 2);
STD  = std(Power, [], 2);

Data = EEGwe.data;
zData = (Data-Mean)./STD;
mData = Data - Mean;
mlData = log(Data) - log(Mean);

figure
contourf(t, freqs, mean(zData, 3), 30,  'linecolor','none')
colorbar
colormap(jet)
clim([-.5 .5])


figure
contourf(t, freqs,  log(mean(Data, 3)), 30,  'linecolor','none')
colorbar

figure
contourf(t, freqs,  mean(mData, 3), 30,  'linecolor','none')
colorbar

figure
contourf(t, freqs,  mean(mlData, 3), 30,  'linecolor','none')
colorbar