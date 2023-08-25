% Gather a table of all the trials

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters



P = analysisParameters();
Participants = P.Participants;
Paths = P.Paths;
Triggers = P.Triggers;
SampleRate = P.SampleRate;
Task = P.Task;
TrialInfo = P.Trials;
Labels = P.Labels;

% Trial parameters
Windows = TrialInfo.SubWindows(1:3); % window in which to see if there is an event or not
WindowColumns = Labels.TrialSubWindows(1:3);
MinWindow = TrialInfo.MinEventProportion; % minimum proportion of window needed to have event to count
