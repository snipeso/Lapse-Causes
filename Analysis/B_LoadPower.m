
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

Trials = loadBehavior(Participants, Sessions, Task, Paths, false);

% set to nan all trials that are beyond 50% radius and with eyes closed
Trials.FinalType = Trials.Type;

Q = quantile(Trials.Radius, 0.5);
Trials.FinalType(Trials.Radius>Q) = nan;

SessionBlocks = P.SessionBlocks;
SB_Labels = fieldnames(SessionBlocks);

AllData = [];
for Indx_B = 1:numel(SB_Labels)
    Sessions = SessionBlocks.(SB_Labels{Indx_B});
    CellTrials = tasktable2cell(Trials, Participants, Sessions, 'FinalType');
    [Data, Freqs, Chanlocs] = loadPowerPoolTrials(Source, Participants, Sessions, Task, CellTrials); % Data is P x T x Ch x F;

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


