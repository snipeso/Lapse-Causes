function plotChangeProb(EventProb, LapseProb, LapseProbNot, GenLapseProb, Legend, Colors, PlotProps)
% Plots the relationship between the probability of a lapse during an event
% with the proportion of lapses due to that event, taking into account the
% probability of that event. Plots with a dotted line from whenever the
% model surpasses the general probability of a lapse.
% EventProb is a P x E matrix with values from 0 to 1
% LapseProb is a P x E matrix
% Legend is a 1 x E cell aray

Dims = size(EventProb);


hold on

%%% plot individuals
for Indx_E = 1:Dims(2)
    Color = Colors(Indx_E, :);
    for Indx_P = 1:Dims(1)

        EndProb = EventProb(Indx_P, Indx_E);
        SwitchPoint = GenLapseProb(Indx_P, Indx_E);
        x_probnot = LapseProbNot(Indx_P, Indx_E);
        y_probnot = x_probnot*EndProb;

        if EndProb < SwitchPoint
            % plot event line
            plot([x_probnot*100, 100], [y_probnot*100, EndProb*100], 'Color', [Color, 0.2], ...
                'LineWidth', PlotProps.Line.Width/2, 'HandleVisibility', 'off')
        else
            x_switch = SwitchPoint/EndProb;

            % plot solid event line for possible values
            plot([x_probnot*100, x_switch*100], [y_probnot*100 SwitchPoint*100], 'Color', [Color, 0.2], ...
                'LineWidth', PlotProps.Line.Width/2, 'HandleVisibility', 'off')

            % plot dotted event line for impossible values
            plot([x_switch*100, 100], [SwitchPoint*100, EndProb*100], '--', 'Color', [Color, 0.2], ...
                'LineWidth', PlotProps.Line.Width/2, 'HandleVisibility', 'off')

        end

        % plot event dot
        scatter(LapseProb(Indx_P, Indx_E)*100, LapseProb(Indx_P, Indx_E)*EventProb(Indx_P, Indx_E)*100, ...
            PlotProps.Scatter.Size/4, Color, 'filled', 'MarkerFaceAlpha', .2, 'HandleVisibility', 'off')
    end
end


%%% plot averages
for Indx_E = 1:Dims(2)
    Color = Colors(Indx_E, :);

    EndProb = mean(EventProb(:, Indx_E), 'omitnan');
    SwitchPoint = mean(GenLapseProb(:, Indx_E), 'omitnan');

       x_probnot = mean(LapseProbNot(:, Indx_E), 'omitnan');
        y_probnot = x_probnot*EndProb;

    if EndProb < SwitchPoint
        % plot event line
        plot([100*x_probnot, 100], [100*y_probnot EndProb*100], ...
            'Color', Color, 'LineWidth', PlotProps.Line.Width, 'HandleVisibility','on')
    else
        x_switch = SwitchPoint/EndProb;
        
        % plot solid event line for possible values
        plot([100*x_probnot, x_switch*100], [100*y_probnot SwitchPoint*100], 'Color', Color, ...
            'LineWidth', PlotProps.Line.Width, 'HandleVisibility', 'on')

        % plot dotted event line for impossible values
        plot([x_switch*100, 100], [SwitchPoint*100, EndProb*100], '--', 'Color', Color, ...
            'LineWidth', PlotProps.Line.Width, 'HandleVisibility', 'off')
    end

    % plot event dot
    scatter(mean(LapseProb(:, Indx_E), 'omitnan')*100, ...
        mean(LapseProb(:, Indx_E), 'omitnan')*mean(EventProb(:, Indx_E), 'omitnan')*100, ...
        PlotProps.Scatter.Size*2, Color, 'filled', 'HandleVisibility', 'off')
end

if ~isempty(Legend)
    legend(Legend, 'Location', 'northwest')
end
axis square
xlim([0 100])
ylim([0 100])
xlabel('% of trials resulting in a lapse during X')
ylabel('% of trials resulting in a lapse "because" of X')

setAxisProperties(PlotProps)