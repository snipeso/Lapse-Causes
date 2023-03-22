
clear
clc
close all

Info = peakParameters();
Paths = Info.Paths;

Band = [5 9];
BandLabel = '5_9';
Task = 'LAT';


Source = fullfile(Paths.Data, 'EEG', 'Peaks', BandLabel, Task);


Content = getContent(Source);


% loop through all files
for Indx_F = 1:numel(Content)

Filename = Content{Indx_F};

load(fullfile(Source, Filename), 'TopPeaks')











end



