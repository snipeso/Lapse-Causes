% gets the data showing the probability of eyesclosed over time for each
% trial outcome type.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

OnlyClosestStimuli = true; % only use closest trials
CheckEyes = true; % only used eyes-open trials

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
TrialWindow = Parameters.Trials.Window;
SampleRate = Parameters.SampleRate;
ConfidenceThreshold = Parameters.EyeTracking.MinConfidenceThreshold;
MaxNaNProportion = Parameters.Trials.MaxNaNProportion;
MaxStimulusDistance = Parameters.Stimuli.MaxDistance;
SessionBlocks = Parameters.Sessions.Conditions;
Triggers = Parameters.Triggers;
MinTrials = Parameters.Trials.MinPerSubGroupCount;
Bands = Parameters.Bands;

EyetrackingPath = fullfile(Paths.Data, 'Pupils', ['Raw_', num2str(SampleRate), 'Hz'], Task);
TrialCacheDir = fullfile(Paths.Cache, 'Trial_Information');
CacheFilename = [Task, '_TrialsTable.mat'];

EyeclosureCacheDir = fullfile(Paths.Cache, 'Data_Figures');
if ~exist(EyeclosureCacheDir, 'dir')
    mkdir(EyeclosureCacheDir)
end

SessionBlockLabels = fieldnames(SessionBlocks);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Run

% get trial information
load(fullfile(TrialCacheDir, CacheFilename), 'TrialsTable')

EyetrackingQualityTable = readtable(fullfile(Paths.QualityCheck, 'EyeTracking', ...
    ['DataQuality_', Task, '_Pupils.csv']));

TrialTime = linspace(TrialWindow(1), TrialWindow(2), SampleRate*(TrialWindow(2)-TrialWindow(1))); % time vector
TotBands = numel(fieldnames(Bands));

% specify only close trials, or all trials
TitleTag = '';

if CheckEyes
    TitleTag = [TitleTag, '_EO'];
    EyesOpenTrials = Trials.EyesClosed == 0;
else
    EyesOpenTrials = true(size(Trials, 1), 1);
end

if OnlyClosestStimuli
    TitleTag = [ TitleTag, '_Close'];
    MaxStimulusDistance = quantile(TrialsTable.Radius, MaxStimulusDistance);
else
    MaxStimulusDistance = max(TrialsTable.Radius);
end



for idxSessionBlock = 1:numel(SessionBlockLabels) % loop through BL and SD

    Sessions = P.SessionBlocks.(SessionBlockLabels{idxSessionBlock});

    % set up blanks
    ProbBurstStimLockedTopography = nan(numel(Participants), 3, TotChannels, TotBands, numel(t_window)); % P x TT x Ch x B x t matrix with final probabilities
    ProbBurstRespLockedTopography = ProbBurstStimLockedTopography;

    ProbBurstStimLocked =  nan(numel(Participants), 3, TotBands, numel(t_window));  % P x TT x B x t
    ProbBurstRespLocked = ProbBurstStimLocked;

    ProbBurstTopography = zeros(numel(Participants), TotChannels, TotBands, 2); % get general probability of a burst for a given session block (to control for when z-scoring)
    ProbBurst = zeros(numel(Participants), TotBands, 2);

    for idxParticipant = 1:numel(Participants)


    end
end

