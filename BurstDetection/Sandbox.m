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
Session = 'Main8';
Participant = 'P15';

Source = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task); % normal data
Filename_Source = strjoin({Participant, Task, Session, 'Clean.mat'}, '_');

load(fullfile(Source, Filename_Source), 'EEG')
SampleRate = EEG.srate;
% EEG = pop_select(EEG, 'channel', 1:6:size(EEG.data, 1));


%% select data and plot spectrum

Channel = 50;

% select data
DataBroadband = EEG.data(labels2indexes(Channel, EEG.chanlocs), :);

[Power, Frequencies] = cycy.utils.compute_power(DataBroadband, SampleRate);

figure
cycy.plot.power_spectrum(Power, Frequencies, true, true)

%% filter data




%% Single channel
close all

CriteriaSets = struct();
CriteriaSets.MonotonicityInTime = .7;
CriteriaSets.MonotonicityInAmplitude = .6;
CriteriaSets.PeriodConsistency = .5;
CriteriaSets.FlankConsistency = .5;
CriteriaSets.AmplitudeConsistency = .5;
CriteriaSets.MinCyclesPerBurst = 4;

NarrowbandRange = [8 12];


% CriteriaSets = struct();
% CriteriaSets.PeriodConsistency = .85;
% CriteriaSets.MonotonicityInAmplitude = .3;
% % CriteriaSets.FlankConsistency = .6;
% CriteriaSets.AmplitudeConsistency = .6;
% CriteriaSets.MinCyclesPerBurst = 5;


Bursts = cycy.test_criteria_set(DataBroadband, SampleRate, NarrowbandRange, CriteriaSets);
% cycy.plot.properties_distributions(AugmentedCycles)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% Everything


%
tic
EEGNarrowbands = cycy.filter_eeg_narrowbands(EEG, Bands);
toc

%%

% long bursts
Idx = 1;
CriteriaSets = struct();
% CriteriaSets.PeriodConsistency = .6;
% CriteriaSets.MonotonicityInAmplitude = .6;
% CriteriaSets.FlankConsistency = 0.6;
% CriteriaSets.AmplitudeConsistency = 0.6;
% CriteriaSets.MinCyclesPerBurst = 4;
% % without periodneg, to capture bursts that accelerate/decelerate

% short bursts
% Idx = 2;
% CriteriaSets(2).PeriodConsistency = .7;
% CriteriaSets(2).MonotonicityInAmplitude = .9;
% CriteriaSets(2).MonotonicityInTime = .9;
% CriteriaSets(2).PeriodNeg = true;
% CriteriaSets(2).ShapeConsistency = .3;
% CriteriaSets(2).FlankConsistency = 0.3;
% CriteriaSets(2).MinCyclesPerBurst = 3;

% dirty bursts
% Idx = 3; 
CriteriaSets(Idx).PeriodConsistency = .5;
CriteriaSets(Idx).MonotonicityInTime = .4;
CriteriaSets(Idx).MonotonicityInAmplitude = .4;
CriteriaSets(Idx).ReversalRatio = 0.6;
CriteriaSets(Idx).ShapeConsistency = .1;
CriteriaSets(Idx).FlankConsistency = .5;
CriteriaSets(Idx).MinCyclesPerBurst = 3;
CriteriaSets(Idx).AmplitudeConsistency = .4;
CriteriaSets(Idx).MinCyclesPerBurst = 3;
CriteriaSets(Idx).PeriodNeg = true;

%% Single channel
close all

Channel = labels2indexes(1, EEG.chanlocs);
%
% profile on
Bursts = cycy.detect_bursts(EEG, Channel, EEGNarrowbands,...
    Bands, CriteriaSets);
% profile viewer
% % %
cycy.plot.plot_all_bursts(EEG, 15, Bursts, 'Band');
% 
figure
cycy.plot.power_without_bursts(EEG.data(Channel, :), SampleRate, Bursts);

cycy.plot.burst_criteriaset_diagnostics(Bursts);
%% single set

tic
BurstsSingle = cycy.test_criteria_set(EEG.data(Channel, :), SampleRate, ...
    Bands.Alpha, CriteriaSets(3));
toc

%% All channels
% detect bursts
RunParallel = false; % if there's a lot of data, channels can be run in parallel
Bursts = cycy.detect_bursts_all_channels(EEG, EEGNarrowbands, Bands, ...
    CriteriaSets, RunParallel); 


%%
MinFrequencyRange = 1;

% aggregate bursts across channels
BurstClusters = cycy.aggregate_bursts_into_clusters(Bursts, EEG, MinFrequencyRange);

%%
cycy.plot.plot_all_bursts(EEG, 20, BurstClusters, 'Band');

%%
cycy.plot.burst_criteriaset_diagnostics(BurstClusters)
