function NewBursts = getBurstProperties(Bursts)
% loop through burst properties, only keep related ones

Average = {'periodNeg', 'periodPos', 'amplitude', 'period', 'Coh_Burst_Frequency', 'Coh_Burst_amplitude'}; % variables to average
Sum = {'Coh_Burst_amplitude_sum'}; % variables to sum
Preserve = {'nPeaks', 'Band', 'Channel', 'Channel_Label', 'Sign', 'BT', ...
    'Start', 'End', 'Frequency', 'Coh_Burst_Channels', 'Coh_Burst_Channel_Labels', ...
    'Coh_Burst_Starts', 'Coh_Burst_Ends', 'Coh_Burst_Signs', 'Coh_Burst_Frequency', 'Coh_Burst_amplitude', ...
    'Coh_Burst_amplitude_sum', 'All_Start', 'All_End', 'globality_bursts'}; % variables to transfer "verbatim"



Fields = fieldnames(Bursts);
NewBursts = rmfield(Bursts, Fields(~ismember(Fields, Preserve)));


for Indx_B = 1:numel(Bursts)
    % average
    for Indx_A = 1:numel(Average)
        NewBursts(Indx_B).(['Mean_', Average{Indx_A}]) = mean(Bursts(Indx_B).(Average{Indx_A}), 'all', 'omitnan');
    end

    % sum
    for Indx_A = 1:numel(Sum)
        NewBursts(Indx_B).(['Sum_', Sum{Indx_A}]) = sum(Bursts(Indx_B).(Sum{Indx_A}), 'all', 'omitnan');
    end
end