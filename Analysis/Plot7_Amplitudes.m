clear
clc
close all
Parameters = analysisParameters();
Paths = Parameters.Paths;
Participants = Parameters.Participants;

SessionBlocks = Parameters.Sessions.Conditions;
SessionBlockLabels = fieldnames(SessionBlocks);
TallyLabels = Parameters.Labels.TrialOutcome;
Bands = Parameters.Bands;
BandLabels = fieldnames(Bands);
WindowLabels = Parameters.Labels.TrialSubWindows;

BurstsCacheDir = fullfile(Paths.Cache, 'Data_Figures');

load(fullfile(BurstsCacheDir, CacheFilename), 'TrialsTable', 'AllBurstsTable')



%% Plot amplitudes

PlotProps = Parameters.PlotProps.Manuscript;
MinTrials = Parameters.Trials.MinPerSubGroupCount;
PlotProps.Axes.yPadding = 2;
PlotProps.Figure.Padding = 20;

Grid = [3 2];
Types = [3 2 1]; % fast,

[Amplitudes, TotTrials] = average_amplitudes(TrialsTable, Participants, BandLabels, WindowLabels, SessionBlocks, MinTrials);

zAmplitudes = zScoreData(permute(Amplitudes, [1 2 3 5 4]), 'last');
zAmplitudes = permute(zAmplitudes, [1 2 3 5 4]);

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.4])

for idxBand = 1:numel(BandLabels)

    Space = chART.sub_figure([1, 2], [1 idxBand], [], PlotProps.Indexes.Letters{idxBand}, PlotProps); % theta and alpha

    for idxSession = 1:2
        for idxOutcome = 1:3
            chART.sub_plot(Space, Grid, [idxOutcome idxSession], [], true, '', PlotProps);
            Data = squeeze(zAmplitudes(:, idxSession, Types(idxOutcome), idxBand, :));
            Stats = paired_ttest(Data, [], Parameters.Stats);
            chART.plot.individual_rows(Data, Stats, WindowLabels, [], PlotProps, PlotProps.Color.Participants);

            if idxOutcome == 1
                title([SessionBlockLabels{idxSession}, ' ', BandLabels{idxBand}])

            end
            if idxOutcome ~= 3
                xticklabels('')
            end

            ylim([-2 4.5])
            if idxSession==1
                ylabel([TallyLabels{Types(idxOutcome)}, ' amplitude'])
            end
        end
    end
end

chART.save_figure('SupplFigure_Amplitudes_byWindow', Paths.Results, PlotProps)


%% Plot amplitudes

PlotProps = Parameters.PlotProps.Manuscript;
MinTrials = Parameters.Trials.MinPerSubGroupCount;
PlotProps.Axes.yPadding = 2;
PlotProps.Figure.Padding = 20;

Grid = [numel(WindowLabels) 2];
Types = [3 2 1]; % fast,
YLims = [0 1.5; .5 1.2];

[~, TotTrials] = average_amplitudes(TrialsTable, Participants, BandLabels, WindowLabels, SessionBlocks, MinTrials);

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*.8, PlotProps.Figure.Height*.6])

for idxBand = 1:numel(BandLabels)

    Space = chART.sub_figure([1, 2], [1 idxBand], [], PlotProps.Indexes.Letters{idxBand}, PlotProps); % theta and alpha

    for idxSession = 1:2
        for idxWindow = 1:numel(WindowLabels)
            chART.sub_plot(Space, Grid, [idxWindow idxSession], [], true, '', PlotProps);
            Data = squeeze(TotTrials(:, idxSession, :, idxBand, idxWindow));
            Stats = paired_ttest(Data, [], Parameters.Stats);
            chART.plot.individual_rows(Data, Stats, TallyLabels, [], PlotProps, PlotProps.Color.Participants);

            if idxWindow == 1
                title([SessionBlockLabels{idxSession}, ' ', BandLabels{idxBand}])

            end
            if idxWindow ~= numel(WindowLabels)
                xticklabels('')
            end

            % ylim([-2 4.5])
            if idxSession==1
                ylabel([WindowLabels{idxWindow}, ' amplitude'])
            end
        end
    end
end

chART.save_figure('SupplFigure_Quantities', Paths.Results, PlotProps)


%% Plot amplitudes comparing outcome

PlotProps = Parameters.PlotProps.Manuscript;
MinTrials = Parameters.Trials.MinPerSubGroupCount;
PlotProps.Axes.yPadding = 2;
PlotProps.Figure.Padding = 20;

Grid = [numel(WindowLabels) 2];
Types = [3 2 1]; % fast,

[Amplitudes, TotTrials] = average_amplitudes(TrialsTable, Participants, BandLabels, WindowLabels, SessionBlocks, MinTrials);

zAmplitudes = zScoreData(permute(Amplitudes, [1 2 3 5 4]), 'last');
zAmplitudes = permute(zAmplitudes, [1 2 3 5 4]);

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*.8, PlotProps.Figure.Height*.6])

for idxBand = 1:numel(BandLabels)

    Space = chART.sub_figure([1, 2], [1 idxBand], [], PlotProps.Indexes.Letters{idxBand}, PlotProps); % theta and alpha

    for idxSession = 1:2
        for idxWindow = 1:numel(WindowLabels)
            chART.sub_plot(Space, Grid, [idxWindow idxSession], [], true, '', PlotProps);
            Data = squeeze(zAmplitudes(:, idxSession, :, idxBand, idxWindow));
            Stats = paired_ttest(Data, [], Parameters.Stats);
            chART.plot.individual_rows(Data, Stats, TallyLabels, [], PlotProps, PlotProps.Color.Participants);

            if idxWindow == 1
                title([SessionBlockLabels{idxSession}, ' ', BandLabels{idxBand}])

            end
            if idxWindow ~= numel(WindowLabels)
                xticklabels('')
            end

            ylim([-2 4.5])
            if idxSession==1
                ylabel([WindowLabels{idxWindow}, ' amplitude'])
            end
        end
    end
end

chART.save_figure('SupplFigure_Amplitudes_byTrialType', Paths.Results, PlotProps)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions


function [Amplitudes, TotTrials] = average_amplitudes(TrialsTable, Participants, BandLabels, WindowLabels, SessionBlocks, MinTrials)

SessionBlockLabels = fieldnames(SessionBlocks);

Amplitudes = nan(numel(Participants), numel(SessionBlockLabels), 3, numel(BandLabels), numel(WindowLabels));
TotTrials = Amplitudes;

for idxParticipant = 1:numel(Participants)
    for idxSessions = 1:numel(SessionBlockLabels)
        for idxTrial = 1:3
            for idxWindow = 1:numel(WindowLabels)
                for idxBand = 1:numel(BandLabels)

                    % select trials and columns
                    Indexes = strcmp(TrialsTable.Participant, Participants{idxParticipant}) & ...
                        contains(TrialsTable.Session, SessionBlocks.(SessionBlockLabels{idxSessions})) & ...
                        TrialsTable.Type == idxTrial;
                    ColumnName = ['Amp', WindowLabels{idxWindow}, BandLabels{idxBand}];

                    % find out how many trials have at least 1 burst
                    NonNanValues = nnz(~isnan(TrialsTable.(ColumnName)(Indexes)));
                    TotTrials(idxParticipant, idxSessions, idxTrial, idxBand, idxWindow) = NonNanValues/nnz(Indexes);

                    if NonNanValues < MinTrials % skip if below minimum
                        continue
                    end

                    % average trials
                    Amplitudes(idxParticipant, idxSessions, idxTrial, idxBand, idxWindow) = ...
                        mean(TrialsTable.(ColumnName)(Indexes), 'omitnan');
                end
            end
        end
    end
end
end