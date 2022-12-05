
clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
Sessions = P.Sessions;
StatsP = P.StatsP;
TallyLabels = P.Labels.Tally;
Format = P.Format;
Paths = P.Paths;
Task = P.Labels.Task;
Bands = P.Bands;
Channels = P.Channels;
RefreshTrials = false;

Refresh = false;
StartTime = -.5;
EndTime = 1.5;
WelchWindow = 2;

TitleTag = strjoin({'LapseCauses', 'LAT', 'Power'}, '_');
Tag =  ['s', num2str(StartTime), '_e', num2str(EndTime), '_w', num2str(WelchWindow)];

Pool = fullfile(Paths.Pool, 'Power'); % place to save matrices so they can be plotted in next script
if ~exist(Pool, 'dir')
    mkdir(Pool)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

Source =  fullfile(P.Paths.Data, 'EEG', 'Locked', Task, Tag);

if ~RefreshTrials || ~exist(fullfile(Pool, 'AllTrials.mat'), 'file')

    %%% get trial information
    Trials = loadBehavior(Participants, Sessions, Task, Paths, false);

    % get time of stim and response trigger
    EEGPath = fullfile(Paths.Preprocessed, 'Waves', 'MAT', Task); % use Waves, since has an fs of 1000
    Trials = getTrialLatencies(Trials, EEGPath, P.Triggers);

    % get eyes-closed info
    MicrosleepPath = fullfile(Paths.Data, 'Pupils_1000', Task); % also 1000 fs
    Trials = getECtrials(Trials, MicrosleepPath, 1000);

    % set to nan all trials that are beyond 50% radius and with eyes closed
    Trials.FinalType = Trials.Type;

    Q = quantile(Trials.Radius, 0.5);
    Trials.FinalType(Trials.Radius>Q) = nan;

    Trials.FinalType(isnan(Trials.EC)|logical(Trials.EC)) = nan;

    save(fullfile(Pool, 'AllTrials.mat'), 'Trials')
else
    load(fullfile(Pool, 'AllTrials.mat'), 'Trials')
end

%%
%%% Load EEG information, splitting by session blocks
SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};

AllData = [];
for Indx_B = 1:numel(SB_Labels)
    Sessions = SessionBlocks.(SB_Labels{Indx_B});
    CellTrials = tasktable2cell(Trials, Participants, Sessions, 'Type');
    [Data, Freqs, Chanlocs] = loadPowerPoolTrials(Source, Participants, Sessions, Task, 1:3, CellTrials); % Data is P x T x Ch x F;

    AllData = cat(5, AllData, Data); % P x T x Ch x F x S
end
AllData = permute(AllData, [1 5 2 3 4]); % P x S x T x Ch x F


% z-score it
zData = zScoreData(AllData, 'last');

% average frequencies into bands
bData = bandData(zData, Freqs, Bands, 'last');

% save
Data = bData;
SessionLabels = SB_Labels;
save(fullfile(Pool, strjoin({'Power', 'Band', 'Topography', 'Close', 'EO', 'TrialType.mat'}, '_')), 'Data', 'Chanlocs', 'Bands', 'SessionLabels')


