
clear
clc
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parameters

Parameters = analysisParameters();
Paths = Parameters.Paths;
Participants = Parameters.Participants;
TallyLabels = Parameters.Labels.TrialOutcome; % rename to outcome labels TODO
StatParameters = Parameters.Stats;
Windows = Parameters.Trials.SubWindows;
WindowTitles = {["Pre", "[-2, 0]"], ["Stimulus", "[0, 0.3]"], ["Response", "[0.3 1]"], ["Post", "[2 4]"]};
Bands = Parameters.Bands;
BandLabels = fieldnames(Bands);
CacheDir = fullfile(Paths.Cache, 'Data_Figures');
CLims = [-.18 .18];


%%% load in data
load(fullfile(CacheDir, 'Bursts_BL.mat'), 'Chanlocs','TrialTime', ...
    'BurstStimLockedTopography', 'BurstDescriptivesTopography')
BurstDescriptivesTopographyBL = BurstDescriptivesTopography;

WindowedStimBL = average_windows(BurstStimLockedTopography, TrialTime, Windows);
WindowCount = size(Windows, 1);

load(fullfile(CacheDir, 'Bursts_SD.mat'), 'TrialTime', ...
    'BurstStimLockedTopography', 'BurstDescriptivesTopography')
BurstDescriptivesTopographySD = BurstDescriptivesTopography;
WindowedStimSD = average_windows(BurstStimLockedTopography, TrialTime, Windows);


%%% plot

%% all participants

PlotProps = Parameters.PlotProps.Manuscript;


% BL
plot_all_topos(WindowedStimBL, BurstDescriptivesTopographyBL, ...
    Participants, Chanlocs, PlotProps, BandLabels, 'BL', Paths, CLims)

% SD
plot_all_topos(WindowedStimSD, BurstDescriptivesTopographySD, ...
    Participants, Chanlocs, PlotProps, BandLabels, 'SD', Paths, CLims)


%% example participants

Grid = [2, 6];
PlotProps = Parameters.PlotProps.Manuscript;
PlotProps.Axes.yPadding = 10;
PlotProps.Axes.xPadding = 10;
PlotProps.Text.AxisSize = 22;
PlotProps.Text.TitleSize = 22;
ParticipantIndexes = [1 5 8 13 16];

figure('Units','centimeters', 'Position',[0 0 PlotProps.Figure.Width*2, PlotProps.Figure.Height*.5])

for idxSession = 1:2
    for idxParticipant = 1:numel(ParticipantIndexes)

        if idxSession == 1
            WindowedStim = WindowedStimBL;
            BurstDescriptivesTopography = BurstDescriptivesTopographyBL;
        else
            WindowedStim = WindowedStimSD;
            BurstDescriptivesTopography = BurstDescriptivesTopographySD;
        end

        chART.sub_plot([], Grid, [idxSession idxParticipant], [1 1], false, '', PlotProps);
        plot_individual_topos(WindowedStim, BurstDescriptivesTopography, ...
            Participants, Chanlocs, PlotProps, ParticipantIndexes(idxParticipant), CLims)
        title('')

    end
end
        chART.sub_plot([], Grid, [2 6], [2 1], false, '', PlotProps);
chART.plot.pretty_colorbar('Divergent', CLims, 'Likelihood difference', PlotProps)

chART.save_figure('Figure_8', Paths.Results, PlotProps)


%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions


function plot_individual_topos(WindowedStim, BurstDescriptivesTopography, ...
    Participants, Chanlocs, PlotProps, idxParticipant, CLims)
idxOutcome = 3;
idxBand = 2;
idxWindow = 3;

Data = squeeze(WindowedStim(:, idxOutcome, :, idxBand, idxWindow));
Baseline = squeeze(BurstDescriptivesTopography(:, :, idxBand));
Diff = Data(idxParticipant, :) - Baseline(idxParticipant, :);
chART.plot.eeglab_topoplot(Diff, Chanlocs, [], CLims, '', 'Divergent', PlotProps)
title(Participants{idxParticipant})
end


function plot_all_topos(WindowedStim, BurstDescriptivesTopography, ...
    Participants, Chanlocs, PlotProps, BandLabels, TitleTag, Paths, CLims)

Windows = {'Pre', 'Stim', 'Resp', 'Post'};

idxWindow = 3;
idxOutcome = 3; % fast trials
idxBand = 2;
Data = squeeze(WindowedStim(:, idxOutcome, :, idxBand, idxWindow));
Baseline = squeeze(BurstDescriptivesTopography(:, :, idxBand));
plot_all_differences(Data, Baseline, Participants, Chanlocs, PlotProps, CLims)
chART.save_figure(strjoin(['IndividualTopos',TitleTag, ...
    BandLabels(idxBand), Windows(idxWindow)], '_'), Paths.Results, PlotProps)
end



function plot_all_differences(Data, Baseline, Participants, Chanlocs, PlotProps, CLims)

figure('Units','normalized', 'OuterPosition',[0 0 .4, 1])
for idxParticipant = 1:numel(Participants)
    Diff = Data(idxParticipant, :) - Baseline(idxParticipant, :);

    subplot(5, 4, idxParticipant)
    chART.plot.eeglab_topoplot(Diff, Chanlocs, [], CLims, '', 'Divergent', PlotProps)
    title(Participants{idxParticipant})
end

PlotProps.Colorbar.Location = 'south';
PlotProps.Text.AxisSize = 15;
subplot(5, 4, 19:20)
chART.plot.pretty_colorbar('Divergent', CLims, 'Likelihood difference', PlotProps)

end

