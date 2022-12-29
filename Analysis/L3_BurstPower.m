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
Parameters = P.Parameters;  

fs = Parameters.fs;
ConfidenceThreshold = Parameters.EC_ConfidenceThreshold; % for classifying eyes closed/open

WelchWindow = 8; % duration of window to do FFT
Overlap = .75; % overlap of hanning windows for FFT

MinDur = 60; % if there's less than X seconds of data, don't save

TitleTag = strjoin({'Power', 'Burstless'}, '_');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

EEGPath = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
% Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

MicrosleepPath = fullfile(Paths.Data, ['Pupils_', num2str(fs)], Task);
BurstPath = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = fieldnames(SessionBlocks);
BandLabels = fieldnames(Bands);

Pool = fullfile(Paths.Pool, 'EEG'); % place to save matrices so they can be plotted in next script


%%% Load EEG information, splitting by session blocks
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

            % load EEG data
            EEG = loadMATFile(EEGPath, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');
            if isempty(EEG); continue; end
            Data = EEG.data;

            % load bursts
            Bursts = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'Bursts');
            if isempty(Bursts); continue; end

            % load in EEG metadata
            EEG = loadMATFile(BurstPath, Participants{Indx_P}, Sessions{Indx_S}, 'EEG');

            Pnts = EEG.pnts;
            ValidTime = EEG.valid_t; % vector of 1s of all the time in which the task was active, and there wasn't noise


            % load eye-data
            Eyes = loadMATFile(MicrosleepPath, Participants{Indx_P}, Sessions{Indx_S}, 'Eyes');
            if isempty(Eyes); continue; end

            if isnan(Eyes.DQ) || Eyes.DQ == 0 || Eyes.DQ < 1 % skip if bad data
                EyeOpen = nan(1, Pnts);
                warning('Bad eye data')
                continue
            end

            Eye = round(Eyes.DQ); % which eye
            [EyeOpen, ~] = classifyEye(Eyes.Raw(Eye, :), fs, ConfidenceThreshold); % not using internal microsleep identifier so that I'm flexible

            ValidTime = ValidTime & EyeOpen == 1;

            %%% remove bad time points
            EEG.data = Data;
            EEG.data(:, ~ValidTime) = nan;

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
            if isempty(fieldnames(ALLEEG.(AllFields{Indx_F})))
                continue
            end

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


