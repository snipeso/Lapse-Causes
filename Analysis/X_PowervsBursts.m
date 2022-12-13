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
TallyLabels = P.Labels.Tally;
Paths = P.Paths;
Task = P.Labels.Task;
Bands = P.Bands;
Channels = P.Channels;

WelchWindow = 8; % duration of window to do FFT
Overlap = .75; % overlap of hanning windows for FFT


TitleTag = strjoin({'LapseCauses', 'LAT', 'Power', 'Burstless'}, '_');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
Bands.Theta = [4 8];
Bands.Alpha = [8 12];
BandLabels = {'Theta', 'Alpha'};

Pool = fullfile(Paths.Pool, 'Power'); % place to save matrices so they can be plotted in next script

%%% Load EEG information, splitting by session blocks
AllFiles_EEG = getContent(Source_EEG);
AllFiles_Bursts = getContent(Source_Bursts);
AllData = nan(numel(Participants), numel(SB_Labels), numel(BandLabels)+2, 123, 502); % TODO, get right number of channels and freqs

for Indx_SB = 1:numel(SB_Labels)
    Sessions = SessionBlocks.(SB_Labels{Indx_SB});

    % prepare EEG structures to pool sessions
    ALLEEG = struct(); % concatenate EEGs separately by bursts removed
    for Indx_B = 1:numel(BandLabels)
        ALLEEG.(BandLabels{Indx_B}) = struct();
    end
    ALLEEG.Whole = struct(); % concatenate EEGs with all bursts
    ALLEEG.Burstless = struct();

    for Indx_S = 1:numel(Sessions)

        %%% load data

        % load EEG
        Filename_EEG = AllFiles_EEG(contains(AllFiles_EEG, Participants{Indx_P})& ...
            contains(AllFiles_EEG, Sessions{Indx_S}));

        if isempty(Filename_EEG)
            warning(['Missing ', Filename_EEG])
            continue
        end

        load(fullfile(Source_EEG, Filename_EEG), 'EEG')
        ALLEEG.Whole = cat(1, ALLEEG.Whole, EEG);
        Chanlocs = EEG.chanlocs;

        % load bursts
        Filename_Bursts = AllFiles_Bursts(contains(AllFiles_Bursts, Participants{Indx_P})& ...
            contains(AllFiles_Bursts, Sessions{Indx_S}));
        load(fullfile(Source_Bursts, Filename_Bursts), 'Bursts')

        %%% get EEG with and without bursts

        BurstFreqs = 1./[Bursts.Mean_period];

        for Indx_B = 1:numel(BandLabels)

            % select bursts by band
            Band = Bands.(BandLabls{Indx_B});
            BurstBand = BurstFreqs > Band(1) & BurstFreqs <= Band(2);

            % remove bursts
            EEG1 = pop_select(EEG, 'nopoint', [[Bursts(BurstBand).Start]', [Bursts(BurstBand).End]']);
            ALLEEG.(BandLabels{Indx_B}) = cat(1,  ALLEEG.(BandLabels{Indx_B}), EEG1);
        end

        % remove all bursts
        EEG1 = pop_select(EEG, 'nopoint', [[Bursts.Start]', [Bursts.End]']);
        ALLEEG.Burstless = cat(1,  ALLEEG.Burstless, EEG1);
    end

    %%% get power for each type of EEG
    AllFields = fieldnames(ALLEEG);

    for Indx_F = 1:numel(AllFields)

        CatEEG = pop_mergeset(ALLEEG.(AllFields{Indx_F}));

        % get power of EEG with and without bursts
        [Power, Freqs] = powerEEG(CatEEG, WelchWindow, Overlap);
        AllData(Indx_P, Indx_SB, Indx_F, :, :) = Power;
    end
end


% z-score it
zData = zScoreData(AllData, 'last');

% average frequencies into bands
bData = bandData(zData, Freqs, Bands, 'last');
save(fullfile(Pool, strjoin({TitleTag, 'bData.mat'}, '_')), 'bData', 'AllFields', 'Chanlocs', 'Freqs')

bChData =  meanChData(zData, Chanlocs, Channels.(ROI), 4);
save(fullfile(Pool, strjoin({TitleTag, 'bChData.mat'}, '_')), 'bChData', 'AllFields', 'Chanlocs', 'Freqs')


