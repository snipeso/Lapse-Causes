

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters
Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
TallyLabels = Parameters.Labels.TrialOutcome; % rename to outcome labels TODO
StatParameters = Parameters.Stats;
Windows = Parameters.Trials.SubWindows;
WindowTitles = {["Pre", "[-2, 0]"], ["Stimulus", "[0, 0.3]"], ["Response", "[0.3 1]"], ["Post", "[2 4]"]};
Bands = Parameters.Bands;
BandLabels = fieldnames(Bands);

CacheDir = fullfile(Paths.Cache, 'Data_Figures');

CheckEyes = true; % check if person had eyes open or closed
Closest = false; % only use closest trials


TitleTag = SessionGroup;
if CheckEyes
    TitleTag = [TitleTag, '_EO'];
end

if Closest
    TitleTag = [ TitleTag, '_Close'];
end


load(fullfile(CacheDir, ['Bursts_', TitleTag, '.mat']), 'Chanlocs','TrialTime', ...
    'ProbBurstRespLockedTopography', 'ProbBurstStimLockedTopography', 'ProbabilityBurstTopography')







