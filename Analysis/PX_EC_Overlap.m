clear
clc
close all


P = analysisParameters();
Paths = P.Paths;
Pool = fullfile(Paths.Pool, 'EEG');
SessionLabel = {'BL', 'SD'};
BandLabels = fieldnames(P.Bands);


load(fullfile(Pool, 'BurstDurations.mat'), 'TimeSpent', 'Durations')


%%

clc
close all

Plot = true;

for Indx_SB = 1:2
    for Indx_B = 1:2
        ProbType = squeeze(TimeSpent(:, Indx_SB, [3, Indx_B, Indx_B+3]));
        Stats = getProbStats(ProbType, Plot);
        Title = [BandLabels{Indx_B}, ' ', SessionLabel{Indx_SB}];
        title(Title)

        disp([Title, ' p=', num2str(Stats.p), '; prcnt: ', num2str(round(Stats.prcnt)),'%'])
    end
end