% This is to identify additional features of the bursts that isn't just the
% individual peaks. Also aggregates them across channels.
% Lapse-causes

clear
clc
close all

Info = burstParameters();

Paths = Info.Paths;
Bands = Info.Bands;
Tasks = Info.Tasks;
MinFreqRange = 1; % min difference in frequency from reference burst
ChannelGroups = Info.Channels.Hemifield;
Refresh = false;

for Indx_T = 1:numel(Tasks)
    Task = Tasks{Indx_T};

    Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts_AllChannels', Task);
    Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);

    Destination_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);
    if ~exist(Destination_Bursts, 'dir')
        mkdir(Destination_Bursts)
    end

    Content = getContent(Source_Bursts);
    Content(~contains(Content, 'Burst')) = [];

    % loop through all files
    for Indx_F = 1:numel(Content)

        Filename_Bursts = Content{Indx_F};
        Filename_EEG = replace(Filename_Bursts, 'Bursts.mat', 'Clean.mat');

        if exist(fullfile(Destination_Bursts, Filename_Bursts), 'file') && ~Refresh
            disp(['Skipping ', Filename_Bursts])
            continue
        else
            disp(['Loading ', Filename_Bursts])
        end

        load(fullfile(Source_EEG, Filename_EEG), 'EEG')

        fs = EEG.srate;
        [nCh, nPnts] = size(EEG.data);
        Data = EEG.data;

        % load bursts
        load(fullfile(Source_Bursts, Filename_Bursts), 'AllBursts', 'EEG')
        EEG.data = Data;

        % get frequency of each burst
        AllBursts = meanFreq(AllBursts);

        % assemble bursts
        if ~strcmp(Filename_EEG(1:3), 'P00') % skip null file, since it will not have simultaneous bursts
            Bursts = aggregateBurstsByFrequency(AllBursts, EEG, MinFreqRange);
        else
            Bursts = AllBursts;
        end

        % get properties of the main channel
        Bursts = burstPeakProperties(Bursts, EEG);
        Bursts = meanBurstPeakProperties(Bursts); % just does the mean of the main peak's properties

        % classify the burst
        Bursts = classifyBursts(Bursts);
        Bursts = localizeBursts(Bursts, ChannelGroups);

        % save
        EEG.data = [];
        save(fullfile(Destination_Bursts, Filename_Bursts), 'Bursts', 'EEG')
        disp(['Finished ', Filename_Bursts])
        clear EEG
    end
end


