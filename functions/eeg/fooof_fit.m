function [Slope, Intercept] = fooof_fit(X, Y, Range, Plot)

if ~exist("Plot", 'var')
    Plot = false;
end

Results = fooof(X, Y, Range, struct(), Plot);

Slope = -Results.aperiodic_params(2);
Intercept = Results.aperiodic_params(1);

if Plot
    fooof_plot(Results)
end