clear
clc
close all

Info = burstParameters();
Paths = Info.Paths;
Bands = Info.Bands;
BandLabels = fieldnames(Bands);

% place to try different parameters for burst detection

% Task = 'Game'; % Game or Standing
% Session = 'Session2';
% Participant = 'P10';

Task = 'Fixation'; % Game or Standing
Session = 'Main4';
Participant = 'P03';

Source = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task); % normal data
Filename_Source = strjoin({Participant, Task, Session, 'Clean.mat'}, '_');

load(fullfile(Source, Filename_Source), 'EEG')
SampleRate = EEG.srate;



%% Filter

%
tic
EEGNarrowbands = cycy.filter_eeg_narrowbands(EEG, Bands);
toc

%%

% irregular shaped bursts
Idx = 1;
CriteriaSets = struct();
CriteriaSets(Idx).PeriodConsistency = .6;
CriteriaSets(Idx).MonotonicityInAmplitude = .6;
CriteriaSets(Idx).FlankConsistency = 0.6;
CriteriaSets(Idx).AmplitudeConsistency = 0.6;
CriteriaSets(Idx).MinCyclesPerBurst = 4;
% % without periodneg, to capture bursts that accelerate/decelerate

% short bursts
Idx = 2;
CriteriaSets(Idx).PeriodConsistency = .7;
CriteriaSets(Idx).MonotonicityInAmplitude = .9;
CriteriaSets(Idx).PeriodNeg = true;
CriteriaSets(Idx).FlankConsistency = 0.3;
CriteriaSets(Idx).MinCyclesPerBurst = 3;

% dirty bursts
Idx = 3; 
CriteriaSets(Idx).PeriodConsistency = .5;
CriteriaSets(Idx).MonotonicityInTime = .4;
CriteriaSets(Idx).MonotonicityInAmplitude = .4;
CriteriaSets(Idx).ReversalRatio = 0.6;
CriteriaSets(Idx).ShapeConsistency = .2;
CriteriaSets(Idx).FlankConsistency = .5;
CriteriaSets(Idx).MinCyclesPerBurst = 3;
CriteriaSets(Idx).AmplitudeConsistency = .4;
CriteriaSets(Idx).MinCyclesPerBurst = 4;
CriteriaSets(Idx).PeriodNeg = true;

%% Single channel
close all

Channel = labels2indexes(99, EEG.chanlocs);
%
% profile on
Bursts = cycy.detect_bursts(EEG, Channel, EEGNarrowbands,...
    Bands, CriteriaSets);
% profile viewer
% % %
cycy.plot.plot_all_bursts(EEG, 15, Bursts, 'CriteriaSetIndex');
% 
figure
cycy.plot.power_without_bursts(EEG.data(Channel, :), SampleRate, Bursts);

cycy.plot.burst_criteriaset_diagnostics(Bursts);
%% single set

Channel = labels2indexes(99, EEG.chanlocs);
BurstsSingle = cycy.test_criteria_set(EEG.data(Channel, :), SampleRate, ...
    Bands.Alpha, CriteriaSets(3));


%% All channels
% detect bursts
RunParallel = true; % if there's a lot of data, channels can be run in parallel
Bursts = cycy.detect_bursts_all_channels(EEG, EEGNarrowbands, Bands, ...
    CriteriaSets, RunParallel); 


%%
MinFrequencyRange = 1;

% aggregate bursts across channels
BurstClusters = cycy.aggregate_bursts_into_clusters(Bursts, EEG, MinFrequencyRange);

%%
cycy.plot.plot_all_bursts(EEG, 10, BurstClusters, 'Band');

%%
cycy.plot.burst_criteriaset_diagnostics(BurstClusters)
