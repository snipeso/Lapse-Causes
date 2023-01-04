function plotChangeProb(EventProb, LapseProb, Legend, PlotProps)
% Plots the relationship between the probability of a lapse during an event
% with the proportion of lapses due to that event, taking into account the
% probability of that event.
% EventProb is a P x E matrix with values from 0 to 1
% LapseProb is a P x E matrix
% Legend is a 1 x E cell aray

Dims = size(EventProb);


hold on

%%% plot individuals

% plot event line
for Indx_P = 1:Dims(1)



end


%%% plot averages



setAxisProperties(PlotProps)