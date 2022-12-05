function [Power, Freqs] = PowerTrials(EEG, Starts, Ends, Window)
% calculate welch power for trials
% part of Lapse-Causes

noverlap = 0;

Chanlocs = EEG.chanlocs;
fs = EEG.srate;


% p welch parameters
nfft = 2^nextpow2(Window*fs);

nFreqs = nfft/2 + 1;
Power = nan(numel(Chanlocs), nFreqs, numel(Starts));

for Indx_S = 1:numel(Starts)
    Data = EEG.data(:, round(Starts(Indx_S):Ends(Indx_S)-1));


    % remove data with nan
    nanPoints = isnan(Data(1, :));
    Data(:, nanPoints) = [];
    [Ch, Points] = size(Data);

    if nnz(nanPoints) > numel(nanPoints)*.25 % if a lot removed, skip
        continue
    elseif Points < nfft % zero pad if there's just a little missing data

        Pad = floor((nfft-Points)/2);

        pData = zeros(Ch, nfft);
        pData(:, Pad:Points+Pad-1) = Data.*hanning(Points)';


        window = nfft;
    else
        window = hanning(nfft);
        pData = Data;
    end
    [FFT, Freqs] = pwelch(pData', window, noverlap, nfft, fs);
    Power(:, :, Indx_S) = FFT';
end

Freqs = Freqs';


