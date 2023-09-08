% plot the timecourses showing relationship of bursts with lapses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters


SmoothFactor = 0.3; % in seconds, smooth signal to be visually pleasing
CheckEyes = true; % check if person had eyes open or closed
Closest = false; % only use closest trials
SessionBlockLabel = 'BL';
SmoothSignal = true;

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
TallyLabels = Parameters.Labels.TrialOutcome; % rename to outcome labels TODO
StatParameters = Parameters.Stats;


TitleTag = SessionBlockLabel;
if CheckEyes
    TitleTag = [TitleTag, '_EO'];
end

if Closest
    TitleTag = [TitleTag, '_Close'];
    EyeclosureTag = '_Close';
else
    EyeclosureTag = '';
end

CacheDir = fullfile(Paths.Cache, 'Data_Figures');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% load data

%%% microsleep data
load(fullfile(CacheDir, ['Eyeclosures_', SessionBlockLabel, EyeclosureTag, '.mat']), ...
    'ProbEyesClosedStimLocked', 'ProbEyesClosedRespLocked', 'TrialTime', 'ProbabilityEyesClosed')

% smooth data
ProbEyesClosedStimLockedSmooth = smooth_frequencies(ProbEyesClosedStimLocked, ...
    TrialTime, 'last', SmoothFactor);
ProbEyesClosedRespLockedSmooth = smooth_frequencies(ProbEyesClosedRespLocked, ...
    TrialTime, 'last', SmoothFactor);

% center data to recording average
    [ProbEyesClosedStimLockedSmooth, ProbabilityEyesClosed] = ...
        meanscoreTimecourse(ProbEyesClosedStimLockedSmooth, ProbabilityEyesClosed, []);
    [ProbEyesClosedRespLockedSmooth, ~] = ...
        meanscoreTimecourse(ProbEyesClosedRespLockedSmooth, ProbabilityEyesClosed, []);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot

%%
YLim = [-.35 .35];

Grid = [2 3];
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 25;

Colors = chART.color_picker(3);

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*1.2, PlotProps.Figure.Height*.5])

%%% stimulus locked
DispN = true;
DispStats = true;

% eyeclosure
chART.sub_plot([], Grid, [1 1], [], true, PlotProps.Indexes.Letters{1}, PlotProps);
Stats = plot_timecourse(TrialTime, flip(ProbEyesClosedStimLockedSmooth, 2), ProbabilityEyesClosed, ...
    YLim, flip(TallyLabels), 'Stimulus', Colors, StatParameters, DispN, DispStats, PlotProps);
ylabel(['\Delta likelihood eyeclosure'])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Stats


%% display general prop of things

disp_stats_descriptive(100*ProbabilityEyesClosed, 'EC gen prop', '%', 0);

disp_stats_descriptive(100*ProbabilityBurst(:, 1), 'Theta gen prop', '%', 0);
disp_stats_descriptive(100*ProbabilityBurst(:, 2), 'Alpha gen prop', '%', 0);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [zProb, zGenProb] = meanscoreTimecourse(ProbAll, GenProb, PreserveDim)

Dims = size(ProbAll);


zProb = nan(Dims);
zGenProb = nan(size(GenProb));

if isempty(PreserveDim) % microsleeps
    for Indx_P = 1:Dims(1)
%         zProb(Indx_P, :, :) = 100*(ProbAll(Indx_P, :, :) - GenProb(Indx_P))./GenProb(Indx_P);
zProb(Indx_P, :, :) = (ProbAll(Indx_P, :, :) - GenProb(Indx_P));
        zGenProb(Indx_P) = 0;
    end

elseif PreserveDim == 3 % bursts on 3rd dimention
    for Indx_P = 1:Dims(1)
            for Indx_B = 1:Dims(3)
%                 zProb(Indx_P, :, Indx_B, :) = ...
%                     100*(ProbAll(Indx_P, :, Indx_B, :) - ...
%                     GenProb(Indx_P, Indx_B))./GenProb(Indx_P, Indx_B);
                zProb(Indx_P, :, Indx_B, :) = ...
                    (ProbAll(Indx_P, :, Indx_B, :) - ...
                    GenProb(Indx_P, Indx_B));

                zGenProb(Indx_P, Indx_B) = 0;
            end
    end
elseif PreserveDim == 4 % bursts on 4th dimention
    for Indx_P = 1:Dims(1)
        for Indx_Ch = 1:Dims(3)
            for Indx_B = 1:Dims(4)
                zProb(Indx_P, :, Indx_Ch, Indx_B, :) = ...
                    100*(ProbAll(Indx_P, :, Indx_Ch, Indx_B, :) - ...
                    GenProb(Indx_P, Indx_Ch, Indx_B))./GenProb(Indx_P, Indx_Ch, Indx_B);
                zGenProb(Indx_P, Indx_Ch, Indx_B) = 0;
            end
        end
    end
end
end


%%%%%%%%%%%%%%
%%% plots

function Stats = plot_timecourse(TrialTime, ProbabilityByOutput, BaselineProbability, ...
    YLims, LineLabels, Time0Label, Colors, StatParameters, DispN, DispStats, PlotProps)
% plots the timecourse locked to stimulus onset.
% Data is a P x TT x t matrix

StatParameters.ANOVA.nBoot = 1; % to speed things up

%%% Get stats
if ~isempty(StatParameters) && ~isempty(BaselineProbability)
    Data1 = repmat(BaselineProbability, 1, size(ProbabilityByOutput, 3)); % baseline
    Data2 = ProbabilityByOutput;
    Stats = paired_ttest(Data1, Data2, StatParameters);
    Stats.timepoints = TrialTime;
    Stats.lines = LineLabels;

    Sig = Stats.p_fdr <= StatParameters.Alpha;
else
    Dims = size(ProbabilityByOutput);
    Sig = zeros(Dims(2), Dims(3));
end

if ~isempty(YLims)
    Range = YLims;
else
    Range = [min(ProbabilityByOutput(:)), max(ProbabilityByOutput(:))];
end

% plot vertical 0 line
hold on
plot([0 0], Range, 'Color', 'k', 'LineWidth',PlotProps.Line.Width/2, 'HandleVisibility', 'off')

 % plot stim patch
if ~all(isnan(ProbabilityByOutput(:, end, :)))
    rectangle('position', [0 Range(1) 0.5, diff(Range)], 'EdgeColor','none', ...
        'FaceColor', [PlotProps.Color.Generic, .15],'HandleVisibility','off')
end

% plot horizontal 0 line
plot([min(TrialTime), max(TrialTime)], [mean(BaselineProbability, 'omitnan'), mean(BaselineProbability, 'omitnan')], ...
    ':', 'Color', PlotProps.Color.Generic, 'LineWidth', PlotProps.Line.Width/2, 'HandleVisibility', 'off')

% plot data
ProbabilityMeans = squeeze(mean(ProbabilityByOutput, 1, 'omitnan'));
CI = nan(2, size(ProbabilityByOutput, 2), size(ProbabilityByOutput, 3));

PlotProps.HandleVisibility = 'off';
chART.plot.individual_rows_by_group(TrialTime, ProbabilityByOutput, Colors, [], PlotProps)
chART.plot.highlighted_segments(ProbabilityMeans, CI, TrialTime, 15, logical(Sig), Colors, PlotProps)


if ~isempty(LineLabels)
    legend([LineLabels, 'p<.05'])
    set(legend, 'ItemTokenSize', [10 10], 'location', 'northeast')
end

xlabel('Time (s)')

YShift = .05*diff(Range);
if ~isempty(Time0Label)
    text(.1, Range(2)-YShift, Time0Label, 'FontName', PlotProps.Text.FontName, 'FontSize', PlotProps.Text.LegendSize)
end

if ~isempty(YLims)
ylim(YLims)
end

if DispN

    for Indx_TT = 1:size(Colors, 1)
        N = num2str(Stats.N(Indx_TT, 1));
        if N=='0'
            continue
        end
        text(min(TrialTime)+(max(TrialTime)-min(TrialTime))*.01, Range(2)-YShift*Indx_TT, ['N=', N], ...
            'FontName', PlotProps.Text.FontName, 'FontSize', PlotProps.Text.LegendSize,...
            'Color',Colors(Indx_TT, :))
    end
end



%%% display
if DispStats
    Windows = [-2 -0.5;
        -0.5 .3;
        0.3, 1.5;
        1.5 4];

    for Indx_L = 1:numel(LineLabels)
        disp(LineLabels{Indx_L})
        for Indx_W = 1:size(Windows, 1)

            S = abs(Stats.t(Indx_L, :));
            S(TrialTime<Windows(Indx_W, 1) | TrialTime>Windows(Indx_W, 2)) = nan;
            [~, Indx] = max(S);

            % if Sig(Indx_L, Indx)
            disp_stats(Stats, [Indx_L, Indx], ['max t: ', num2str(TrialTime(Indx), '%.1f'), ' s']);
            % end

        end
        disp('_____________')
    end
end
end
