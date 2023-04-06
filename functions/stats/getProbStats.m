function Stats = getProbStats(ProbType, Plot)
% ProbType is a P x 3 matrix, with each column representing the proportion
% of event 1, event 2, and their combined occurances.

% assign readable variables
Prob1 = ProbType(:, 1);
Prob2 = ProbType(:, 2);
ActualJointProb = ProbType(:, 3);

% joint probability given proportions of thing1 and thing2
ExpectedJointProb = Prob1.*Prob2;

% statistically compare expected probability with actual probability
% Stats = pairedttest(ExpectedJointProb, ActualJointProb, StatsP);
Stats = pairedWilcoxon(ExpectedJointProb, ActualJointProb);

% quantify the difference as a percentage from the possible values, with 0
% being entirely the expected joint probability, and 1 being completely
% dependent (and -1 completely anti-correlated)

% MinProb =  min(ProbType(:, [1 2]), [], 2);
MinProb =  ProbType(:, 1);
Prcnt = (ProbType(:, 3)-ExpectedJointProb)./(MinProb-ExpectedJointProb);

Stats.prcnt = mean(Prcnt, 'omitnan');
Stats.prcntIQ = quantile(Prcnt, [.25 .75])';


if exist('Plot', 'var') && Plot
    figure
    hold on
    plot([0 1], [0 1], ':')
    scatter(ExpectedJointProb, ActualJointProb, 'filled')
    ylabel('Actual joint probability')
    xlabel('Expected joint probability')
    xlim([0 1])
    ylim([0 1])

end

end




