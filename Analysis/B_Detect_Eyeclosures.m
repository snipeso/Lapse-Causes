% Using eyetracking data, identify when participants had eyes open or
% closed.

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load in and set parameters for analysis


Tasks = {'PVT', 'LAT'};


Parameters = analysisParameters();
Paths = Parameters.Paths;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% run analysis

for Task = Tasks

    % convert raw pupil data, get Pupil and Annotations; saves to disk
import_raw_pupil_tables(Raw, Destination, Refresh)




end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions