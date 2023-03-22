clear
clc
close all

Info = peakParameters();
Paths = Info.Paths;

Band = [4 7.5];
BandLabel = '4_7';
Task = 'LAT';
Refresh = false;

% Sessions = {'BaselineBeam', 'MainPre', 'Session1Beam', 'Session2Beam1', 'Session2Beam2', 'Session2Beam3', 'MainPost'};
Sessions = {'BaselineBeam', 'Session2Beam1'};
% Participants = {'P10'};

Participants = {'P01', 'P02', 'P03', 'P04', 'P05', 'P06', 'P07', 'P08', ...
    'P09', 'P10', 'P11', 'P12', 'P13', 'P14', 'P15', 'P16', 'P17', 'P19'};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Paths
Source = fullfile(Paths.Data, 'EEG', 'Peaks_AllChannels', BandLabel, Task);
Destination = fullfile(Paths.Data, 'EEG', 'Peaks', BandLabel, Task);

if ~exist(Destination, 'dir')
    mkdir(Destination)
end


Content = getContent(Source);
load(fullfile(Source, Content(1)), 'EEG')
Chanlocs = EEG.chanlocs;
nChan = numel(Chanlocs);
fs = EEG.srate;


for Indx_P = 1:numel(Participants)

    AllVoltageNegs = cell([1 nChan]);

    %%% Get voltage thresholds for each channel based on quantiles

    for Indx_S = 1:numel(Sessions)

        % load data
        AllPeaks = loadMATFile(Source, Participants{Indx_P}, Sessions{Indx_S}, 'AllPeaks');
        if isempty(AllPeaks)
            continue
        end

        % sort peaks by channel
        for Indx_Ch = 1:nChan
            Peaks = AllPeaks([AllPeaks.ChannelIndx]==Indx_Ch);
            AllVoltageNegs{Indx_Ch} = cat(2, AllVoltageNegs{Indx_Ch}, [Peaks.voltageNeg]);
        end
        disp(['finished gathering ', Participants{Indx_P}, Sessions{Indx_S}])
    end

    % put nan's for channels with nothing (shouldn't be any, but to be
    % safe)
    Blanks = cellfun(@isempty, AllVoltageNegs);
    AllVoltageNegs(Blanks)  = {nan};

    % get thresholds for each channel
    Quantiles = nan(1, nChan);
    for Indx_Ch = 1:nChan
    Quantiles(Indx_Ch) = quantile(AllVoltageNegs{Indx_Ch}, .2); % since it's negative voltages, then it needs to be the first 20%
    end


    %%% Select for each recording only the peaks above threshold

    for Indx_S = 1:numel(Sessions)

        % load data
        AllPeaks = loadMATFile(Source, Participants{Indx_P}, Sessions{Indx_S}, 'AllPeaks');
        if isempty(AllPeaks)
            continue
        end

        TopPeaks = struct();

        for Indx_Ch = 1:nChan
            Peaks = AllPeaks([AllPeaks.ChannelIndx]==Indx_Ch); % get only peaks from that channel
            Peaks = Peaks([Peaks.voltageNeg]<=Quantiles(Indx_Ch)); % get only peaks above that channel's threshold

            TopPeaks = catStruct(TopPeaks, Peaks); % assemble in new structure
        end

        EEG = loadMATFile(Source, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');
        save(fullfile(Destination, strjoin({Participants{Indx_P}, Task, Sessions{Indx_S}, 'TopPeaks.mat'}, '_')), 'TopPeaks', 'EEG')
        disp(['Finished ' Participants{Indx_P}, Sessions{Indx_S}])
    end


end












