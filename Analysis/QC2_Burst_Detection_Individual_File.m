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
Session = 'BaselineBeam';
Participant = 'P11'; % P03 has almost no oscillations, P15 has tons
%%%%
%%%%
%%%%

Source_EEG = fullfile(Paths.Data, 'Clean', 'Waves', Task); % normal data
Source_Bursts = fullfile(Paths.AnalyzedData, 'EEG', 'Bursts_New', Task);

EEG = load_datafile(Source_EEG, Participant, Session, 'EEG');
SampleRate = EEG.srate;

BurstClusters = load_datafile(Source_Bursts, Participant, Session, 'BurstClusters');


%%

cycy.plot.plot_all_bursts(EEG, 20, BurstClusters, 'CriteriaSetIndex');


%%
figure
Channel = labels2indexes(70, EEG.chanlocs);
cycy.plot.power_without_bursts(EEG.data(Channel, :), SampleRate, BurstClusters);