% check the burst detection for a specific file

clear
clc
close all

Info = analysisParameters();
Paths = Info.Paths;


%%%% Choose a file
%%%%
%%%%
Task = 'LAT'; % Game, Standing, Fixation
Session = 'Session2Beam1';
Participant = 'P04'; % P03 has almost no oscillations, P15 has tons
%%%%
%%%%
%%%%

Source_EEG = fullfile(Paths.Data, 'Clean', 'Waves', Task); % normal data
Source_Bursts = fullfile(Paths.AnalyzedData, 'EEG', 'Bursts_Lapse-Causes', Task);

EEG = load_datafile(Source_EEG, Participant, Session, 'EEG');
SampleRate = EEG.srate;

BurstClusters = load_datafile(Source_Bursts, Participant, Session, 'BurstClusters');

EEGMetadata = load_datafile(Source_Bursts, Participant, Session, 'EEGMetadata');

%%

cycy.plot.plot_all_bursts(EEG, 15, BurstClusters, 'CriteriaSetIndex');


%%
figure
Channel = labels2indexes(3, EEG.chanlocs);
BurstSubset = BurstClusters([BurstClusters.ChannelIndex]==Channel);
cycy.plot.power_without_bursts(EEG.data(Channel, :), SampleRate, BurstSubset, EEGMetadata.CleanTaskTimepoints);