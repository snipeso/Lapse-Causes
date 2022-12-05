
clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
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

TitleTag = strjoin({'Bursts', 'LAT', 'Power', 'Hemifield', SessionBlock}, '_');
Tag =  ['s', num2str(StartTime), '_e', num2str(EndTime), '_w', num2str(WelchWindow)];

Results = fullfile(Paths.Results, 'LAT_Power', 'Hemifield');
if ~exist(Results, 'dir')
    mkdir(Results)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

SessionBlocks = P.SessionBlocks;

Source =  fullfile(P.Paths.Data, 'EEG', 'Locked', Task, Tag);
 [AllData, Freqs, Chanlocs, AllTrials] = loadSessionBlockData(P, Source, SessionBlocks);


% z-score it
zData = zScoreData(AllData, 'last');

% average frequencies into bands
bData = bandData(zData, Freqs, Bands, 'last');




