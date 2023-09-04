% plot outcome of tasks, to compare PVT and LAT


clear
clc
close all


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% parameters

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
Participants = Parameters.Participants;
MinTrialCount = Parameters.Trials.MinTotalCount;
SessionBlocks = Parameters.Sessions.Conditions;
SessionBlockLabels = fieldnames(SessionBlocks);
Sessions = Parameters.Sessions;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Load trial data

CacheDir = fullfile(Paths.Cache, "C_Assemble_Trial_Information/");


%%% Get PVT trial data
load(fullfile(CacheDir, 'PVT_TrialsTable.mat'), 'TrialsTable') % from script Load_Trials
TrialsTablePVT = TrialsTable;
OldType = Trials_PVT.Type; % TODO: remove

[RTStructPVT, ~, ~] = assemble_reaction_times(TrialsTablePVT, Participants, Sessions.PVT, SessionBlockLabels);







