function [power, phase, times, wavelets] = time_frequency(data, srate, freqs, minCycles, maxCycles, bufferZone, startTime, phaseInDegrees, resampleTo, plotFlag, numWorkers)
    arguments
        data double
        srate double
        freqs (1,:) double = single(linspace(1, 20, 39))
        minCycles (1,1) double = 3
        maxCycles (1,1) double = 5
        bufferZone (1,1) double = 3*freqs(1)
        startTime (1,1) double = 0
        phaseInDegrees (1,1) logical = true        
        resampleTo (1,1) double = srate
        plotFlag (1,1) logical = false        
        numWorkers (1,1) double = 0
    end
    fprintf('\n*** Starting wavelet transform! ***\n')

    % ---------------------------------------------------------------------
    % Wavelet transform as taught by Mike Cohen using Morlet Wavelets       
        % See also: https://mikexcohen.com/lectures.html
        % By Sven Leach and Maria Dimitriades, with minor fixes from Sophia
        % Snipes. 2024.
    % *** Input
    %
    % data:         EEG data, either as a 3D (channels x samples x trials)
    %               or 2D matrix (channels x samples).
    % srate:        Sampling rate of your EEG data.
    % freqs:        1D vector containing frequencies.
    % minCycles:    Each wavelet constitutes of a certain number of
    %               cyclces. The script spaces the number of cyclces used
    %               for a certain frequency between the minimum and maximum
    %               number of cycles provided. The minimum and maximum
    %               number of cycles are used for the lowest and highest
    %               frequency provided, respectively.
    % bufferZone:   Edge artefacts are a common problem for wavelet
    %               transforms. One technique is to add a bufferzone to
    %               your data, which is used to estimate the time period
    %               of interest yet will not be included in the output. A
    %               bufferZone of 3s means that the first and last 3s of
    %               the data will be used for power computations of the 
    %               following time periods, yet removed from the output.
    %               See also: https://www.youtube.com/watch?v=9j_FoEFJqV0
    % startTime:    The time your times vector (output) should start at (in
    %               seconds). Default: 0s
    % numWorkers:   In case you want to do parallel processing, you can
    %               specify the number of workers here. Default: 0, use all
    %               available workers on your machine.
    % plotFlag:     Plots the wavelets used in analysis.

    % *** Output
    % 
    % power:        A 4D matrix (channels x freqs x samples x trials)
    %               containing the power estimates for the frequencies
    %               provided.
    % phase:        A 4D matrix (channels x freqs x samples x trials)
    %               containing the phase estimates for the frequencies
    %               provided.
    % times:        The time vector (in seconds) taking into account the
    %               sampling rate provided. The start time can be changed
    %               by adapting startTime.
    % wavelets      The wavelets used in your analysis. In case you want to
    %               visualize or better understand the wavelets.
    % ---------------------------------------------------------------------
    

    % For parallel procesing 
    if numWorkers == 0
        mycluster = parcluster('local');
        numWorkers = mycluster.NumWorkers;      
    end
    fprintf('Working with %d CPU cores.\n', numWorkers)

    % Length of final out in seconds
    duration_buffered = size(data, 2) / srate - bufferZone*2;

    % Build the times vector
    times_buffered  = startTime : 1/resampleTo : duration_buffered  + startTime;
    pnts_buffered   = numel(times_buffered);

    % The buffer zone means that the first and last few samples will be
    % removed from the final output. Define a vector that encodes which
    % sample points to keep and which to remove.
%     keep_samples = zeros(size(data, 2), 1, 'logical');
%     keep_samples(bufferZone*srate+1 : end-bufferZone*srate) = 1;
%     fprintf('To avoid edge artefacts, the first and last %d sec of the data are considered as a buffer zone and removed from the output.\n', bufferZone)  
    pnts_resampled  = pnts_buffered + bufferZone*2*resampleTo;
    keep_samples    = zeros(pnts_resampled, 1, 'logical');
    keep_samples(bufferZone*resampleTo+1 : end-bufferZone*resampleTo) = 1;
    
    % Get dimensions of EEG data
    [nbchan, pnts, trials] = size(data);
    fprintf('Starting morlet wavelet transform on %d channels and %d frequencies, over %d samples (%d serve as a buffer and will be removed) and %d trials.\n', nbchan, numel(freqs), pnts, pnts-sum(keep_samples), trials)
    
    % Preallocate output matrices, improves speed
    power_buffered               = zeros(nbchan, length(freqs), pnts_buffered, trials, 'single');
    phase_buffered               = zeros(nbchan, length(freqs), pnts_buffered, trials, 'single');
    power_one_channel   = zeros(pnts_resampled, trials, 'single');
    phase_one_channel   = zeros(pnts_resampled, trials, 'single');


    % --- Starting to build the wavelet
    % Calculate wavelet parameters (time and width of the Gaussian)
    wavelet_times   = floor(-1/freqs(1)) : 1/srate : ceil(1/freqs(1)); % Critical here: time vector must be symmetric (i.e., -x to x), otherwise inaccurate estimate in time!
    half_wavelet    = (length(wavelet_times)-1)/2;
    wavelet_width   = logspace(log10(minCycles),log10(maxCycles),length(freqs)) ./ (2*pi*freqs); % Standard deviation of the Gaussian windows (SD = cycles/(2*pi*frequency); one for each frequency of interest; can space with log or linearly
    
    % Convolution requires zero-padding
    % This is not adding any new information, but makes it so we do not lose information on the side of the signal
    nData = pnts * trials;
    nConv = length(wavelet_times) + nData - 1; % number of time points in the signal + the number of time points in the kernel - 1 

    % Display initial message
    message = sprintf('Loop over frequencies: ... %.2f Hz (%d/%d)\r', freqs(1), 1, numel(freqs));
    message_length = numel(message);
    fprintf(message)     


    % --- Perform wavelet transform and loop over frequencies
    wavelets = []; T1 = tic;
%     for freqi = 1:numel(freqs)    
    parfor (freqi = 1:numel(freqs), numWorkers) 
        freq = freqs(freqi);

%         % Update message (normal for loop)
%         message = sprintf('Loop over frequencies: ... %.2f Hz (%d/%d)\r', freq, freqi, numel(freqs));
%         fprintf([repmat('\b', 1, message_length), message])
%         message_length = numel(message);

        % Update message (parfor loop)
        % Because parfor does not allow modifying the variable "message_length" inside the loop
        if mod(freqi, 1) == 0
            fprintf('Freq %.2f Hz %d/%d\n', freqs(freqi), freqi, numel(freqs))
        end
        
        % Make a complex morlet wavelet
        sine    = exp(2*1i*pi*freq.*wavelet_times); % make a complex sine wave
        gaus    = exp(-wavelet_times.^2./(2*wavelet_width(freqi)^2)); % make a gaussian window
        wavelet = sine.*gaus; % make a complex morlet wavelet!

        % FFT of wavelet
        fft_wavelet = fft(wavelet, nConv); % has to be the same length as the FFT of the signal, we specifiy the number of outputs!
        fft_wavelet = fft_wavelet ./ max(fft_wavelet);

        % Build wavelet
        wavelets = [wavelets fft_wavelet'];        
        
        
        % Plot wavelets
        if plotFlag

            % Plot your wavelet in the frequency domain
            % plot(abs(wavelet)) %Should resemble a gaussian
        
            % Plot what your wavelet should look like in the time domain
            sine_real = cos(2*pi*freq*wavelet_times);
            mw = sine_real.*gaus;
            
            figure(1); subplot(211); hold on
            plot(wavelet_times,sine_real,'r') % real sine wave in time
            plot(wavelet_times,gaus,'b') % gaussian in time
            plot(wavelet_times,mw,'k','LineWidth',3)
            xlabel('Time (s)'),ylabel('Amplitude')
            legend({'Sine Wave'; 'Gaussian'; 'Morlet Wavelet'})
            title('Morlet Wavelet in the Time Domain')

            points = length(wavelet_times);
            mwX = 2*abs(fft(mw)/points);
            hz = linspace(0,srate,points);

            subplot(212); hold on
            plot(hz,mwX,'k','linew',2)
            xlabel('Frequency (Hz)')
            ylabel('Amplitude') % The amplitude is symmetric! This is the case because this is a real valued morlet wavelet; the Fourier transform is symmmetric
            title('Morlet Wavelet in the Frequency Domain')
        end


        % --- Loop through channels
        for chani = 1:nbchan
    
            % Reshape and concatenate trials for the current channel
            alldata         = reshape( data(chani,:,:), 1, []);
            fft_eeg_data    = fft(alldata, nConv);
    
            % Inverse FFT of product of spectra, back to time domain
            convolution_result = ifft(fft_wavelet .* fft_eeg_data); %power time course babyyyy
    
            % Cut convolution result back to size of EEG data
            convolution_result = convolution_result(half_wavelet+1:end-half_wavelet);
    
            % Extract power and phase values 
            % And reshape convolution result back to original data dimensions
            convolution_result_resampled = resample(reshape(convolution_result, pnts, trials), resampleTo, srate);
            power_one_channel = abs(convolution_result_resampled).^2;
            phase_one_channel = angle(convolution_result_resampled);

            % Remove buffer zone
            power_buffered(chani,freqi,:,:) = power_one_channel(keep_samples, :);
            phase_buffered(chani,freqi,:,:) = phase_one_channel(keep_samples, :);
        end
    end

    % Phase values are saved in radians. Want to change them to degrees?
    % Then they go from 0 to 360°. 
    % 0° corresponds to the positive peak of the wave here.
    if phaseInDegrees
        phase_buffered           = rad2deg(phase_buffered);
        phase_buffered(phase_buffered<0)  = phase_buffered(phase_buffered<0) + 360;
    end

    % restore buffered datapoints as nans
    maxT = duration_buffered + bufferZone*2;
    times = linspace(0, maxT, maxT*resampleTo);
    power = nan(nbchan, numel(freqs), numel(times));

    Start = bufferZone*resampleTo-1;
    power(:, :, Start:Start+numel(times_buffered)-1) = power_buffered;
    phase(:, :, Start:Start+numel(times_buffered)-1) = phase_buffered;

    % Ellapsed time
    fprintf('Wavelet transform took %.2fs.\n', toc(T1))
end