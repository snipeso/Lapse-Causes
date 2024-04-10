% plot the timecourses showing relationship of bursts with lapses

clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

SmoothFactor = 0.2; % in seconds, smooth signal to be visually pleasing
CheckEyes = true; % check if person had eyes open or closed
Closest = false; % only use closest trials
SessionBlockLabels = {'BL', 'SD'}; % might need to change to EW.
SessionLabels = {'BL', 'EW'}; % because I switched the names late

Parameters = analysisParameters();
Paths = Parameters.Paths;
Task = Parameters.Task;
TallyLabels = Parameters.Labels.TrialOutcome; % rename to outcome labels TODO
StatParameters = Parameters.Stats;

CacheDir = fullfile(Paths.Cache, 'Data_Figures');


%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% plot

DispN = true;
DispStats = true;


clc
YLimEyesClosed = [-.6 1.4];
YLimAlpha = [-1 1];
YLimTheta = [-1 1];

Grid = [2 3];
PlotProps = Parameters.PlotProps.Manuscript;

figure('Units','centimeters','Position', [0 0 PlotProps.Figure.Width, PlotProps.Figure.Height*.5])
for idxSession = 1:2

    SessionBlockLabel = SessionBlockLabels{idxSession};
    disp(SessionBlockLabel)

    %%%%%%%%%%%%%%%%%
    %%% load data

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


    % eyeclosure data
    load(fullfile(CacheDir, ['Eyeclosures_', SessionBlockLabel, EyeclosureTag, '.mat']), ...
        'EyesClosedStimLocked', 'EyesClosedRespLocked', 'TrialTime', 'EyeclosureDescriptives')

    [ProbEyesClosedStimLockedDiff, ProbEyesClosedRespLockedDiff, ProbabilityEyesClosedDiff] = ...
        process_data(EyesClosedStimLocked, EyesClosedRespLocked, EyeclosureDescriptives, ...
        TrialTime, SmoothFactor, []); % smooth and z-score data

    % burst data
    load(fullfile(CacheDir, ['Bursts_', TitleTag, '.mat']), ...
        'BurstStimLocked', 'BurstRespLocked', 'BurstDescriptives')

    [ProbBurstsStimLockedDiff, ProbBurstsRespLockedDiff, ProbabilityBurstsDiff] = ...
        process_data(BurstStimLocked, BurstRespLocked, BurstDescriptives, ...
        TrialTime, SmoothFactor, 3);


    %%%%%%%%%%%%%%%%%%%%
    %%% Plot

    %%% stimulus locked
    disp('EC')
    plot_timecourse(TrialTime, flip(ProbEyesClosedStimLockedDiff, 2), ProbabilityEyesClosedDiff(:, 1), ...
        YLimEyesClosed, flip(TallyLabels), 'Stimulus', StatParameters, DispN, DispStats, PlotProps, ...
        Grid, [idxSession 1], '', 'Eye closure');
    ylabel('Porportion of trials (z-scored)')
    chART.plot.vertical_text(SessionLabels{idxSession}, .3, .5, PlotProps)

    disp('theta')
    plot_timecourse(TrialTime, flip(squeeze(ProbBurstsStimLockedDiff(:, :, 1, :)), 2), ...
        ProbabilityBurstsDiff(:, 1), YLimTheta, flip(TallyLabels), '', ...
        StatParameters, DispN, DispStats, PlotProps, Grid, [idxSession 2], '', ...
        'Theta bursts');
    ylabel('Proportion of channels (z-scored)')
    legend off

    disp('alpha')
    plot_timecourse(TrialTime, flip(squeeze(ProbBurstsStimLockedDiff(:, :, 2, :)), 2), ...
        ProbabilityBurstsDiff(:, 2), YLimAlpha, flip(TallyLabels), '', ...
        StatParameters, DispN, DispStats, PlotProps, Grid, [idxSession 3], '', ...
        'Alpha bursts');
    ylabel('Proportion of channels (z-scored)')
    legend off

    disp("++++++++++++++++++++++++++++++++++++")
    disp("++++++++++++++++++++++++++++++++++++")
    disp("++++++++++++++++++++++++++++++++++++")
end

chART.save_figure(['Figure_BurstTimecourse_',TitleTag], Paths.Results, PlotProps)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Stats


%% display general probability of things

clc

disp_stats_descriptive(100*EyeclosureDescriptives(:, 1), 'EC gen prop', '%', 0);
disp_stats_descriptive(100*BurstDescriptives(:, 1, 1), 'Theta gen prop', '%', 0);
disp_stats_descriptive(100*BurstDescriptives(:, 2, 1), 'Alpha gen prop', '%', 0);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [ProbStimProcessed, ProbRespProcessed, ProbEventProcessed] = ...
    process_data(ProbStimLocked, ProbRespLocked, ProbEvent, TrialTime, SmoothFactor, BandDimention)

% smooth data
ProbStimSmooth = smooth_frequencies(ProbStimLocked, TrialTime, 'last', SmoothFactor); % NB, the original function was intended to smooth power spectra, but it works just as well for time, since the SmoothFactor is relative to the the TrialTime vector
ProbRespSmooth = smooth_frequencies(ProbRespLocked, TrialTime, 'last', SmoothFactor);

% z-score the data
[ProbStimProcessed, ProbEventProcessed] = mean_center_timescore(ProbStimSmooth, ProbEvent, BandDimention);
[ProbRespProcessed, ~] = mean_center_timescore(ProbRespSmooth, ProbEvent, BandDimention);
end




%%%%%%%%%%%%%%
%%% plots

function Stats = plot_timecourse(TrialTime, ProbabilityByOutput, BaselineProbability, ...
    YLims, LineLabels, Time0Label, StatParameters, DispN, DispStats, PlotProps, ...
    Grid, Position, Letter, Title)
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
if Position(1)==1
    title(Title, 'FontSize', PlotProps.Text.TitleSize)
elseif Position(1)==Grid(1)
    xlabel('Time (s)')
end

if ~isempty(LineLabels) && Position(1)==1 && Position(2)==1
    legend([LineLabels, 'p<.05'])
    set(legend, 'ItemTokenSize', [10 10], 'location', 'northeast')
end


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

disp(['>>>>>>>' Letter, '<<<<<<<<<<<'])
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
    -0.5, 0;
    0, .3;
    0.3, 1.5;
    1.5 4];

for idxLine = 1:numel(LineLabels)
    disp(LineLabels{idxLine})
    for Indx_W = 1:size(Windows, 1)
        TValues = abs(Stats.t(idxLine, :));
        TValues(TrialTime<Windows(Indx_W, 1) | TrialTime>Windows(Indx_W, 2)) = nan;
        [~, IndxMaxT] = max(TValues);
        disp_stats(Stats, [idxLine, IndxMaxT], [num2str(Windows(Indx_W, 1)), ':' num2str(Windows(Indx_W, 2))...
            '  max t: ', num2str(TrialTime(IndxMaxT), '%.2f'), ' s']);
    end
    disp('_____________')
end
end
