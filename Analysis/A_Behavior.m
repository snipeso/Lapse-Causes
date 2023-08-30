% Script in Lapse-Causes that plots the first figure (and stats) related to
% the LAT task performance.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = analysisParameters();
Paths = Parameters.Paths;
StatParameters = Parameters.Stats;
Participants = Parameters.Participants;
MinTrialCount = Parameters.Trials.MinTotalCount;
Participants = Parameters.Participants;
Sessions = Parameters.Sessions;





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Assemble trial data


Trials_PVT = assemble_trials_table(Task, TaskDir, Participants, Sessions);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions