
% plots the distribution of confidence values for each eye and each
% participant so I can chose which eye to use for each recording. Ideally,
% each histogram should show mostly 1s, and some 0s. The more uniform the
% distrinution, the worst the eye quality. In a csv, save which eye had the
% best distribution. 

clear
clc
close all

Parameters = analysisParameters();
Paths = Parameters.Paths;
Participants = Parameters.Participants;

Task = 'PVT';
Sessions = Parameters.Sessions.(Task);


for Indx_P = 1:numel(Participants)

    if mod(Indx_P-1, 5) == 0
        figure('Units', 'normalized', 'OuterPosition', [0 0 1 1])
        Indx = 0;
    end
    for Indx_S = 1:numel(Sessions)
        Indx = Indx+1;

        Path = fullfile(Paths.Data, 'Pupils', 'Raw', Task);
        Pupil = load_datafile(Path, Participants{Indx_P}, Sessions{Indx_S}, 'Pupil');
        if isempty(Pupil); continue; end

        subplot(5, numel(Sessions), Indx);
        histogram(Pupil.confidence(Pupil.eye_id==0 & strcmp(Pupil.method, '2d c++')), ...
            'BinEdges',0:.1:1, 'DisplayName', 'eye0')
        hold on
        histogram(Pupil.confidence(Pupil.eye_id==1 & strcmp(Pupil.method, '2d c++')), ...
            'BinEdges',0:.1:1, 'DisplayName', 'eye1')
        legend
        title(strjoin({Participants{Indx_P}, Sessions{Indx_S}}, ' '))
    end
end