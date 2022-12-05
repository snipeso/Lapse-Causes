
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

Results = fullfile(Paths.Results, 'LAT_Power', 'Hemifield');
if ~exist(Results, 'dir')
    mkdir(Results)
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

for Indx_B = 1:numel(SB_Labels)
    Sessions = SessionBlocks.(SB_Labels{Indx_B});
CellTrials = tasktable2cell(Trials, Participants, Sessions, 'FinalType');
[Data, Freqs, Chanlocs] = loadAllPower(P, Source, Trials, Sessions); % Data is P x S x T x Ch x F;
end


% z-score it
zData = zScoreData(AllData, 'last');

% average frequencies into bands
bData = bandData(zData, Freqs, Bands, 'last');




