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
Triggers = P.Triggers;
Channels = P.Channels;

Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);

SessionBlocks = P.SessionBlocks;
SB_Labels = {'BL', 'SD'};
Bands.Theta = [4 8];
Bands.Alpha = [8 12];
BandLabels = {'Theta', 'Alpha'};
ROI = fieldnames(Channels.preROI);

Pool = fullfile(Paths.Pool, 'EEG');


load(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent', 'TimeSpent_ROI', 'LateralitySum', 'Laterality')



%% plot time spent with bursts

Legend = {BandLabels, }

%%% stacked bar plot for time spent



%%% scatter plot for time spent by ROI