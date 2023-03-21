function AllPeaks = getHungPeaks(EEG, Band, Keep_Points)
% relies on scripts from Matcycle

Keep_Points = find(Keep_Points);
nChan = size(EEG.data, 1);
fs = EEG.srate;

AllPeaks = struct();

for Indx_C = 1:nChan

    Chan = EEG.data(Indx_C, :);

    % find peaks
    Peaks = peakDetectionHung(Chan);
    Peaks = peakProperties(Chan, Peaks, fs);

    % identify their frequency
    Peaks = meanHungFreq(Peaks);
    Freqs = [Peaks.Frequency];
    Peaks = Peaks(Freqs<=Band(2) &Freqs>=Band(1));

    % exclude peaks inside known noise
    Peak_Points = [Peaks.NegPeakID];
    Peaks = Peaks(ismember(Peak_Points, Keep_Points));

    for Indx_P = 1:numel(Peaks)

        Peaks(Indx_P).ChannelIndx = Indx_C;
        Peaks(Indx_P).Channel = indexes2labels(Indx_C, EEG.chanlocs);
    end

    AllPeaks = catStruct(AllPeaks, Peaks);
disp(['ch' num2str(Indx_C)])
end










