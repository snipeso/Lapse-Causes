% plot spectrum with and without theta and alpha bursts to show success of
% algorithm
% use average of all channels

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
Sessions = P.Sessions;
Paths = P.Paths;
Task = P.Labels.Task;
Bands = P.Bands;
Channels = P.Channels;

WelchWindow = 8; % duration of window to do FFT
Overlap = .75; % overlap of hanning windows for FFT

MinDur = 60; % if there's less than X seconds of data, don't save

TitleTag = strjoin({'Power', 'Burstless'}, '_');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = fieldnames(SessionBlocks);
BandLabels = fieldnames(Bands);

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script


%%% Load EEG information, splitting by session blocks
AllFiles_EEG = getContent(Source_EEG);
AllFiles_Bursts = getContent(Source_Bursts);
AllData = nan(numel(Participants), numel(SB_Labels), numel(BandLabels)+1, 123, 1025);

for Indx_P = 1:numel(Participants)
    for Indx_SB = 1:numel(SB_Labels)
        Sessions = SessionBlocks.(SB_Labels{Indx_SB});

        % prepare EEG structures to pool sessions
        ALLEEG = struct(); % concatenate EEGs separately by bursts removed
        for Indx_B = 1:numel(BandLabels)
            ALLEEG.(BandLabels{Indx_B}) = struct();
        end
        ALLEEG.Whole = struct(); % concatenate EEGs with all bursts

        for Indx_S = 1:numel(Sessions)

            %%% load data

            % load EEG
            Filename_EEG = AllFiles_EEG(contains(AllFiles_EEG, Participants{Indx_P})& ...
                contains(AllFiles_EEG, Sessions{Indx_S}));

            if isempty(Filename_EEG)
                warning(['Missing ', Participants{Indx_P} Sessions{Indx_S}])
                continue
            end

            load(fullfile(Source_EEG, Filename_EEG), 'EEG')
            Data = EEG.data;
            fs = EEG.srate;

            % load bursts
            Filename_Bursts = AllFiles_Bursts(contains(AllFiles_Bursts, Participants{Indx_P})& ...
                contains(AllFiles_Bursts, Sessions{Indx_S}));

            if isempty(Filename_Bursts)
                warning(['Missing bursts ', Participants{Indx_P} Sessions{Indx_S}])
                continue
            end

            load(fullfile(Source_Bursts, Filename_Bursts), 'Bursts', 'EEG')
            EEG.data = Data;
            EEG.data(:, ~EEG.valid_t) = nan;

            ALLEEG.Whole = catStruct(ALLEEG.Whole,  rmNaN(EEG));
            Chanlocs = EEG.chanlocs;


            %%% get EEG with and without bursts

            BurstFreqs = [Bursts.Frequency];

            for Indx_B = 1:numel(BandLabels)

                % select bursts by band
                Band = Bands.(BandLabels{Indx_B});
                BurstBand = BurstFreqs > Band(1) & BurstFreqs <= Band(2);

                % remove bursts
                EEG1 = pop_select(EEG, 'nopoint', [[Bursts(BurstBand).Start]', [Bursts(BurstBand).End]']);
                ALLEEG.(BandLabels{Indx_B}) = catStruct(ALLEEG.(BandLabels{Indx_B}), rmNaN(EEG1));
            end
        end

        %%% get power for each type of EEG
        AllFields = fieldnames(ALLEEG);

        for Indx_F = 1:numel(AllFields)

            CatEEG = pop_mergeset(ALLEEG.(AllFields{Indx_F}), 1:numel(ALLEEG.(AllFields{Indx_F})));

            % skip if not enough data
            if size(CatEEG.data, 2)/fs < MinDur
                continue
            end

            % get power of EEG with and without bursts
            [Power, Freqs] = powerEEG(CatEEG, WelchWindow, Overlap);
            AllData(Indx_P, Indx_SB, Indx_F, :, :) = Power;
        end
    end
    clc
    disp(['Finished ', Participants{Indx_P}])
end

sData = smoothFreqs(AllData, Freqs, 'last', 2);
ChData =  meanChData(sData, Chanlocs, Channels.preROI, 4);

save(fullfile(Pool, strjoin({TitleTag, 'bChData.mat'}, '_')), 'ChData', 'sData', 'AllFields', 'Chanlocs', 'Freqs')


