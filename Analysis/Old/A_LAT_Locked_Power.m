% Calculate power for the trials requested in the LAT task

clear
clc
close all


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

P = analysisParameters();

Participants = P.Participants;
StatsP = P.StatsP;
Tally = P.Labels.Tally;
Format = P.Format;
Paths = P.Paths;
Task = P.Labels.Task;
Triggers = P.Triggers;
RemoveCh = P.Channels.Remove;

Refresh = false;
StartTime = .5; % relative to stim trigger
EndTime = 1; % relative to stim trigger
WelchWindow = .5;

TitleTag = strjoin({'Bursts', 'LAT', 'Hemifield'}, '_');

% get files and paths
Source = fullfile(Paths.Preprocessed, 'Clean', 'Power', Task);
Source_Cuts = fullfile(Paths.Preprocessed, 'Cutting', 'Cuts', Task);
Destination = fullfile(Paths.Data, 'EEG', 'Locked', Task, ...
    ['s', num2str(StartTime), '_e', num2str(EndTime), '_w', num2str(WelchWindow)]);

if ~exist(Destination, 'dir')
    mkdir(Destination)
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load data

Files = deblank(cellstr(ls(Source)));
Files(~contains(Files, '.set')) = [];

for Indx_F = 1:numel(Files)
    File = Files{Indx_F};
    Filename_Core = extractBefore(File, '_Clean.set');
    Filename = [Filename_Core, '_Welch.mat'];
    
    % skip if already done
    if ~Refresh && exist(fullfile(Destination, Filename), 'file')
        disp(['**************already did ',Filename, '*************'])
        continue
    end
    
    % load EEG
    EEG = pop_loadset('filename', File, 'filepath', Source);
    
    % remove bad channels
    EEG = pop_select(EEG, 'nochannel', labels2indexes(RemoveCh, EEG.chanlocs));
    
    [Channels, Points] = size(EEG.data);
    fs = EEG.srate;
    Chanlocs = EEG.chanlocs;
    
    % set to nan all cut data
    Cuts_Filepath = fullfile(Source_Cuts, [Filename_Core, '_Cuts.mat']);
    EEG = remove_noise(EEG, Cuts_Filepath);
    
    
    %%% get epochs
    
    % get trial trigger labels
    Trigger_Labels = {EEG.event.type};
    
    StartTask = find(strcmp(Trigger_Labels, Triggers.Start));
    EndTask =  find(strcmp(Trigger_Labels, Triggers.End));
    Ignore = zeros(numel(Trigger_Labels), 1);
    Ignore([1:StartTask, EndTask:end]) = 1;
    Ignore(ismember(Trigger_Labels, Triggers.Extras)) = 1;
    Trigger_Labels = Trigger_Labels(~Ignore);
    
    Stim = find(strcmp(Trigger_Labels, Triggers.Stim));
    TrialTriggers = cell(1, numel(Stim));
    TrialTriggers(1) = {Trigger_Labels(1)};
    for Indx_S = 2:numel(Stim)
        Indx = Stim(Indx_S-1)+1:Stim(Indx_S)-1;
        TrialTriggers(Indx_S) = {Trigger_Labels(Indx)};
    end
    
    % get epoch limits
    Trigger_Labels = {EEG.event.type};
    Trigger_Times = [EEG.event.latency];
    Stim = strcmp(Trigger_Labels, Triggers.Stim);
    Starts = Trigger_Times(Stim) + StartTime*fs;
    Ends =  Trigger_Times(Stim) + EndTime*fs;
    
    [Power, Freqs] = PowerTrials(EEG, Starts, Ends, WelchWindow);
    
    %%%
    save(fullfile(Destination, Filename), 'Power', 'TrialTriggers', 'Freqs', 'Chanlocs')
    disp(['*************finished ',Filename '*************'])
end



