% plot the timecourses showing relationship of bursts with lapses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters


SmoothFactor = 0.3; % in seconds, smooth signal to be visually pleasing
CheckEyes = true; % check if person had eyes open or closed
Closest = true; % only use closest trials
SessionGroup = 'BL';
SmoothSignal = true;

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;

TitleTag = SessionGroup;
if CheckEyes
    TitleTag = [TitleTag, '_EO'];
end

if Closest
    TitleTag = [TitleTag, '_Close'];
    MicrosleepTag = '_Close';
else
    MicrosleepTag = '';
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data

%%% microsleep data
load(fullfile(Paths.Pool, 'Eyes', ['ProbMicrosleep_', SessionGroup, MicrosleepTag, '.mat']), ...
    'ProbMicrosleep_Stim', 'ProbMicrosleep_Resp', 't_window', 'GenProbMicrosleep')
t_microsleep = t_window;

% smooth and z-score data
sProbMicrosleep_Stim = smooth_frequencies(ProbMicrosleep_Stim, t_microsleep, 'last', SmoothFactor);

sProbMicrosleep_Resp = smooth_frequencies(ProbMicrosleep_Resp, t_microsleep, 'last', SmoothFactor);

















