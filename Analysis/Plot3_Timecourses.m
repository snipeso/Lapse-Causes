% plot the timecourses showing relationship of bursts with lapses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters


SmoothFactor = 0.2; % in seconds, smooth signal to be visually pleasing
CheckEyes = true; % check if person had eyes open or closed
Closest = false; % only use closest trials
SessionBlockLabel = 'SD';

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


% eyeclosure data
load(fullfile(CacheDir, ['Eyeclosures_', SessionBlockLabel, EyeclosureTag, '.mat']), ...
    'ProbEyesClosedStimLocked', 'ProbEyesClosedRespLocked', 'TrialTime', 'ProbabilityEyesClosed')

[ProbEyesClosedStimLockedDiff, ProbEyesClosedRespLockedDiff, ProbabilityEyesClosedDiff] = ...
    process_data(ProbEyesClosedStimLocked, ProbEyesClosedRespLocked, ProbabilityEyesClosed, ...
    TrialTime, SmoothFactor, []);


% burst data
load(fullfile(CacheDir, ['Bursts_', TitleTag, '.mat']), ...
    'ProbBurstStimLocked', 'ProbBurstRespLocked', 'ProbabilityBurst')

[ProbBurstsStimLockedDiff, ProbBurstsRespLockedDiff, ProbabilityBurstsDiff] = ...
    process_data(ProbBurstStimLocked, ProbBurstRespLocked, ProbabilityBurst, ...
    TrialTime, SmoothFactor, 3);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot

%%
clc
YLimEyesClosed = [-.35 .35];
YLimAlpha = [-1 1];
YLimTheta = [-1 1];

Grid = [2 3];
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.xPadding = 25;

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width*1.2, PlotProps.Figure.Height*.5])

%%% stimulus locked
DispN = true;
DispStats = true;

% eyeclosure
plot_timecourse(TrialTime, flip(ProbEyesClosedStimLockedDiff, 2), ProbabilityEyesClosedDiff, ...
    YLimEyesClosed, flip(TallyLabels), 'Stimulus', StatParameters, DispN, DispStats, PlotProps, ...
    Grid, [1 1], PlotProps.Indexes.Letters{1});
ylabel('\Delta likelihood eyeclosure')

% theta
plot_timecourse(TrialTime, flip(squeeze(ProbBurstsStimLockedDiff(:, :, 1, :)), 2), ...
    ProbabilityBurstsDiff(:, 1), YLimTheta, flip(TallyLabels), '', ...
    StatParameters, DispN, DispStats, PlotProps, Grid, [1 2], PlotProps.Indexes.Letters{2});
ylabel('\Delta likelihood theta burst')

% alpha
plot_timecourse(TrialTime, flip(squeeze(ProbBurstsStimLockedDiff(:, :, 2, :)), 2), ...
    ProbabilityBurstsDiff(:, 2), YLimAlpha, flip(TallyLabels), '', ...
    StatParameters, DispN, DispStats, PlotProps, Grid, [1 3], PlotProps.Indexes.Letters{3});
ylabel('\Delta likelihood alpha burst')


%%% response locked
DispStats = false;

% eyeclosure
plot_timecourse(TrialTime, flip(ProbEyesClosedRespLockedDiff, 2), ProbabilityEyesClosedDiff, ...
    YLimEyesClosed, flip(TallyLabels), 'Response', StatParameters, DispN, DispStats, PlotProps, ...
    Grid, [2 1], PlotProps.Indexes.Letters{4});
ylabel('\Delta likelihood eyeclosure')
legend off

% theta
plot_timecourse(TrialTime, flip(squeeze(ProbBurstsRespLockedDiff(:, :, 1, :)), 2), ...
    ProbabilityBurstsDiff(:, 1), YLimTheta, flip(TallyLabels), '', ...
    StatParameters, DispN, DispStats, PlotProps, Grid, [2 2], PlotProps.Indexes.Letters{2});
ylabel('\Delta likelihood theta burst')

% alpha
plot_timecourse(TrialTime, flip(squeeze(ProbBurstsRespLockedDiff(:, :, 2, :)), 2), ...
    ProbabilityBurstsDiff(:, 2), YLimAlpha, flip(TallyLabels), '', ...
    StatParameters, DispN, DispStats, PlotProps, Grid, [2 3], PlotProps.Indexes.Letters{3});
ylabel('\Delta likelihood alpha burst')

chART.save_figure(['Figure_',TitleTag], Paths.Results, PlotProps)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Stats


%% display general prop of things

disp_stats_descriptive(100*ProbabilityEyesClosedDiff, 'EC gen prop', '%', 0);

disp_stats_descriptive(100*ProbabilityBurst(:, 1), 'Theta gen prop', '%', 0);
disp_stats_descriptive(100*ProbabilityBurst(:, 2), 'Alpha gen prop', '%', 0);



%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [ProbStimProcessed, ProbRespProcessed, ProbEventProcessed] = ...
    process_data(ProbStimLocked, ProbRespLocked, ProbEvent, TrialTime, SmoothFactor, BandDimention)

% smooth data
ProbStimSmooth = smooth_frequencies(ProbStimLocked, TrialTime, 'last', SmoothFactor);
ProbRespSmooth = smooth_frequencies(ProbRespLocked, TrialTime, 'last', SmoothFactor);

% center data to recording average
[ProbStimProcessed, ProbEventProcessed] = mean_center_timescore(ProbStimSmooth, ProbEvent, BandDimention);
[ProbRespProcessed, ~] = mean_center_timescore(ProbRespSmooth, ProbEvent, BandDimention);
end




%%%%%%%%%%%%%%
%%% plots

function Stats = plot_timecourse(TrialTime, ProbabilityByOutput, BaselineProbability, ...
    YLims, LineLabels, Time0Label, StatParameters, DispN, DispStats, PlotProps, ...
    Grid, Position, Letter)
% plots the timecourse locked to stimulus onset.
% ProbabilityByOutput is a P x TrialOutput x t matrix

Colors = chART.color_picker(3);
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

chART.sub_plot([], Grid, Position, [], true, Letter, PlotProps);

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

% labels
if ~isempty(LineLabels)
    legend([LineLabels, 'p<.05'])
    set(legend, 'ItemTokenSize', [10 10], 'location', 'northeast')
end

xlabel('Time (s)')

% indicate what the plot is timelocked to
YShift = .05*diff(Range);
if ~isempty(Time0Label)
    text(.1, Range(2)-YShift, Time0Label, 'FontName', PlotProps.Text.FontName, 'FontSize', PlotProps.Text.LegendSize)
end

if ~isempty(YLims)
    ylim(YLims)
end

if DispN
    plot_samplesize(Stats, TrialTime, PlotProps, Colors, Range, YShift)
end

if DispStats
    disp_stats_timecourses(Stats, LineLabels, TrialTime)
end
end


function plot_samplesize(Stats, TrialTime, PlotProps, Colors, Range, YShift)
% in corner of plot, indicate sample size per trial outcome

for indxTrialOutcome = 1:size(Colors, 1)
    N = num2str(Stats.N(indxTrialOutcome, 1));
    if N=='0'
        continue
    end
    text(min(TrialTime)+(max(TrialTime)-min(TrialTime))*.01, ...
        Range(2)-YShift*indxTrialOutcome, ['N=', N], ...
        'FontName', PlotProps.Text.FontName, 'FontSize', PlotProps.Text.LegendSize,...
        'Color',Colors(indxTrialOutcome, :))
end
end


function disp_stats_timecourses(Stats, LineLabels, TrialTime)
% print in command window the most significant values

% from these windows, find largest values
Windows = [-2 -0.5;
    -0.5 .3;
    0.3, 1.5;
    1.5 4];

for idxLine = 1:numel(LineLabels)
    disp(LineLabels{idxLine})
    for Indx_W = 1:size(Windows, 1)
        TValues = abs(Stats.t(idxLine, :));
        TValues(TrialTime<Windows(Indx_W, 1) | TrialTime>Windows(Indx_W, 2)) = nan;
        [~, IndxMaxT] = max(TValues);
        disp_stats(Stats, [idxLine, IndxMaxT], [num2str(Windows(Indx_W, 1)), ':' num2str(Windows(Indx_W, 2))...
            'max t: ', num2str(TrialTime(IndxMaxT), '%.1f'), ' s']);
    end
    disp('_____________')
end
end
