% retrofit microsleep/burst timecourse scripts to produce output
% This script compares the effects of:
% - distance from center (50% split)
% - eyeclosure
% - theta burst
% - alpha bursts

% P x T x 2 % T is already normalized to the number of total trials

clear
clc
close all

P = analysisParameters();
StatsP = P.StatsP;
Paths  = P.Paths;


%%% Load distance lapses
Pool = fullfile(Paths.Pool, 'Tasks');
load(fullfile(Pool, 'ProbType_Radius.mat'), 'ProbType')

Stats = pairedttest(squeeze(ProbType(:, 1, 1)), squeeze(ProbType(:, 1, 2)), StatsP);


%%% load microsleep lapses
Pool = fullfile(Paths.Pool, 'Eyes');
load(fullfile(Pool, 'ProbType_EC.mat'), 'ProbType')

Stats = pairedttest(squeeze(ProbType(:, 1, 1)), squeeze(ProbType(:, 1, 2)), StatsP);