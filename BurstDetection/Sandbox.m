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

Task = 'PVT'; % Game or Standing
Session = 'Session2Beam';
Participant = 'P15';

Source = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task); % normal data
Filename_Source = strjoin({Participant, Task, Session, 'Clean.mat'}, '_');

load(fullfile(Source, Filename_Source), 'EEG')
SampleRate = EEG.srate;
EEG = pop_select(EEG, 'channel', 1:4:size(EEG.data, 1));


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
EEGNarrowbands = cycy.filter_eeg_narrowbands(EEG, Bands);

%%

CriteriaSets = struct();
CriteriaSets.MonotonicityInTime = .7;
CriteriaSets.MonotonicityInAmplitude = .6;
CriteriaSets.PeriodConsistency = .6;
CriteriaSets.FlankConsistency = .5;
CriteriaSets.AmplitudeConsistency = .5;
CriteriaSets.MinCyclesPerBurst = 4;

CriteriaSets(2).MonotonicityInAmplitude = .9;
CriteriaSets(2).MonotonicityInTime = .9;
CriteriaSets(2).AmplitudeConsistency = .2;
CriteriaSets(2).PeriodConsistency = .8;
CriteriaSets(2).MinCyclesPerBurst = 3;



%% Single channel
close all

Channel = labels2indexes(71, EEG.chanlocs);

Bursts = cycy.detect_bursts(EEG, Channel, EEGNarrowbands,...
    Bands, CriteriaSets);

cycy.plot.plot_all_bursts(EEG, 40, Bursts, 'Band');

%% single set

Bursts = cycy.test_criteria_set(EEG.data(Channel, :), SampleRate, Bands.Alpha, CriteriaSets(2));



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
