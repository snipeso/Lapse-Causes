clear
clc
close all
Parameters = analysisParameters();
Paths = Parameters.Paths;
Participants = Parameters.Participants;

SessionBlocks = Parameters.Sessions.Conditions;
SessionBlockLabels = fieldnames(SessionBlocks);
Bands = Parameters.Bands;

BurstsCacheDir = fullfile(Paths.Cache, 'Data_Figures');

load(fullfile(BurstsCacheDir, CacheFilename), 'TrialsTable', 'AllBurstsTable')



%%
PlotProps = Parameters.PlotProps.Manuscript;
MinTrials = Parameters.Trials.MinPerSubGroupCount;

Grid = [2 2];


figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.4])

ColumnNames = {'AmplitudeTheta','AmplitudeAlpha'};
for idxColumn = 1:numel(ColumnNames)
    [Amplitudes, TotTrials] = average_amplitudes(TrialsTable, Participants, ColumnNames{idxColumn}, SessionBlocks, MinTrials);

    Space = chART.sub_figure([1, 2], [1 idxColumn], [], PlotProps.Indexes.Letters{idxColumn}, PlotProps);
    for idxSession = 1:2
        chART.sub_plot(Space, Grid, [1 idxSession], [], true, '', PlotProps);
        Data = squeeze(Amplitudes(:, idxSession, :));
        Stats = paired_ttest(Data, [], Parameters.Stats);
        chART.plot.individual_rows(Data, Stats, {'Lapses', 'Late', 'Fast'}, [], PlotProps, PlotProps.Color.Participants);
        title(SessionBlockLabels{idxSession})
        ylim([10 35])
        ylabel('Amplitude')

        chART.sub_plot(Space, Grid, [2 idxSession], [], true, '', PlotProps);
        Data = squeeze(TotTrials(:, idxSession, :));
        Stats = paired_ttest(Data, [], Parameters.Stats);
        chART.plot.individual_rows(Data, Stats, {'Lapses', 'Late', 'Fast'}, [], PlotProps, PlotProps.Color.Participants);
              ylim([0 1.1])
        ylabel('Trials with a burst')
              

    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions


function [Amplitudes, TotTrials] = average_amplitudes(TrialsTable, Participants, ColumnName, SessionBlocks, MinTrials)

SessionBlockLabels = fieldnames(SessionBlocks);

Amplitudes = nan(numel(Participants), numel(SessionBlockLabels), 3);
TotTrials = Amplitudes;

for idxParticipant = 1:numel(Participants)
    for idxSessions = 1:numel(SessionBlockLabels)
        for idxTrial = 1:3
            Indexes = strcmp(TrialsTable.Participant, Participants{idxParticipant}) & ...
                contains(TrialsTable.Session, SessionBlocks.(SessionBlockLabels{idxSessions})) & ...
                TrialsTable.Type == idxTrial;
            NonNanValues = nnz(~isnan(TrialsTable.(ColumnName)(Indexes)));
            TotTrials(idxParticipant, idxSessions, idxTrial) = NonNanValues/nnz(Indexes);


            if NonNanValues < MinTrials
                continue
            end
            Amplitudes(idxParticipant, idxSessions, idxTrial) = mean(TrialsTable.(ColumnName)(Indexes), 'omitnan');
        end
    end
end
end