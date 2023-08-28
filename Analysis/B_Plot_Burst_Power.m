% Evaluates the quality of the burst detection, by plotting the change in
% spectrum of the data with and without bursts, and providing ratios
% quantifying how much power was captured by the bursts.


clear
clc
close all



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% parameters

ThetaSession = 'Session2Beam1';
AlphaSession = 'BaselineBeam';
WelchWindow = 8;
Overlap = .75;
MinDuration = 60;
Refresh = false; % if analysis has already been run, set to false if you want to use the cache

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
Channels = Parameters.Channels.PreROI;
Bands = Parameters.Bands;

Source_EEG = fullfile(Paths.Preprocessed, 'Clean', 'Waves', Task);
Source_Bursts = fullfile(Paths.Data, 'EEG', 'Bursts', Task);
CacheDir = fullfile(Paths.Cache, mfilename);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% analysis


[PowerIntact, PowerBursts, PowerBurstless, Frequencies, TimeSpent] = ...
    burst_power_by_ROI(Source_EEG, Source_Bursts, Participants, Session, Channels, ChannelFieldname, ...
    WelchWindow, Overlap, MinDuration, CacheDir, Refresh);








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions
function [PowerIntact, PowerBursts, PowerBurstless, Frequencies, TimeSpent] = ...
    burst_power_by_ROI(Source_EEG, Source_Bursts, Participants, Session, Channels, ChannelFieldname, ...
    WelchWindow, Overlap, MinDuration, CacheDir, Refresh)

%%% cache

% location of cache
CacheString = strjoin({'burst_power_by_ROI', Source_EEG, Session, ChannelFieldname, num2str(WelchWindow), ...
    num2str(Overlap), num2str(MinDuration)}, '_');
CacheString = [replace(CacheString, '.', '-'), '.mat'];
CachePath = fullfile(CacheDir, CacheString);

% load from cache
if exist(CachePath, 'file') && ~Refresh
    load(CachePath, 'PowerIntact', 'PowerBursts', 'PowerBurstless', 'Frequencies', 'TimeSpent')
    return
end

if ~exist(CacheDir, 'dir')
    mkdir(CacheDir)
end

%%% run analysis
for Participant = Participants

    % load in EEG data
EEG = load_datafile(Source_EEG, Participant{1}, Session, 'EEG');
   if isempty(EEG); continue; end
            Data = EEG.data;

            % load bursts
Bursts = load_datafile(Source_Bursts, Participant{1}, Session, 'Bursts');
   if isempty(Bursts); continue; end            

   % load EEG metadata
   Metadata = load_datafile(Source_Bursts, Participant{1}, Session, 'EEG'); % TODO, when rerun, call EEGMetadata


end
end


