
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
RefreshTrials = false;

Refresh = false;
StartTime = -.5;
EndTime = 1.5;
WelchWindow = 2;

StartTime = -1;
EndTime = 0;
WelchWindow = 1;

% temp
BandLabels = fieldnames(Bands);
PlotProps = P.Manuscript;
StatsP = P.StatsP;


Tag =  ['s', num2str(StartTime), '_e', num2str(EndTime), '_w', num2str(WelchWindow)];
TitleTag = strjoin({'LapseCauses', 'LAT', 'Power', Tag}, '_');

Pool = fullfile(Paths.Pool, 'Power'); % place to save matrices so they can be plotted in next script
if ~exist(Pool, 'dir')
    mkdir(Pool)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

Source =  fullfile(P.Paths.Data, 'EEG', 'Locked', Task, Tag);

if RefreshTrials || ~exist(fullfile(Pool, 'AllTrials.mat'), 'file')

    disp('refreshing trials')

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

    Trials.FinalType(isnan(Trials.EC)|Trials.EC==1) = nan;

    Trials.isRight = double(Trials.isRight);

    save(fullfile(Pool, 'AllTrials.mat'), 'Trials')
else
    disp('loading trials')
    load(fullfile(Pool, 'AllTrials.mat'), 'Trials')
end

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};

%%% lapse vs correct

%%% Load EEG information, splitting by session blocks

Trials.FinalType = Trials.Type;

Q = quantile(Trials.Radius, 0.5);
Trials.FinalType(Trials.Radius>Q) = nan;
Trials.FinalType(isnan(Trials.EC)|Trials.EC==1) = nan;

Trials.isRight = double(Trials.isRight);

AllData = [];
for Indx_B = 1:numel(SB_Labels)
    Sessions = SessionBlocks.(SB_Labels{Indx_B});
    CellTrials = tasktable2cell(Trials, Participants, Sessions, 'FinalType');
    %     CellTrials = tasktable2cell(Trials, Participants, Sessions, 'Type');
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
save(fullfile(Pool, strjoin({TitleTag, 'Power', 'Band', 'Topography', 'Close', 'EO', 'TrialType.mat'}, '_')), 'Data', 'Chanlocs', 'Bands', 'SessionLabels')


%% left vs right block


AllData = [];

for Indx_B = 1:numel(SB_Labels)
    Sessions = SessionBlocks.(SB_Labels{Indx_B});
    CellTrials = tasktable2cell(Trials, Participants, Sessions, 'isRight');
    [Data, Freqs, Chanlocs] = loadPowerPoolTrials(Source, Participants, Sessions, Task, [0 1], CellTrials); % Data is P x T x Ch x F;

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
save(fullfile(Pool, strjoin({TitleTag, 'Power', 'Band', 'Topography', 'Hemifield.mat'}, '_')), 'Data', 'Chanlocs', 'Bands', 'SessionLabels')


%% eo vs ec

AllData = [];

for Indx_B = 1:numel(SB_Labels)
    Sessions = SessionBlocks.(SB_Labels{Indx_B});
    CellTrials = tasktable2cell(Trials, Participants, Sessions, 'EC');
    [Data, Freqs, Chanlocs] = loadPowerPoolTrials(Source, Participants, Sessions, Task, [0 1], CellTrials); % Data is P x T x Ch x F;

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
save(fullfile(Pool, strjoin({TitleTag, 'Power', 'Band', 'Topography', 'EC.mat'}, '_')), 'Data', 'Chanlocs', 'Bands', 'SessionLabels')




