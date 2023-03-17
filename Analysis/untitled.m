
% ProbTheta = squeeze(TimeSpent(:, 2, 1)+TimeSpent(:, 2, 3));
% ProbAlpha = squeeze(TimeSpent(:, 2, 2)+TimeSpent(:, 2, 3));
% ActualJointProb = squeeze(TimeSpent(:, 2, 3));


% % Distance vs Lapses 
%  ProbType = squeeze(jointTally(Trials, EO, Furthest==1, Trials.Type==1, Participants, ...
%     Sessions, SessionGroups, true));
% Label = 'Effect of distance';

% % EC vs Lapses 
%  ProbType = squeeze(jointTally(Trials, SD & ~Furthest, Trials.EC==1, Trials.Type==1, Participants, ...
%     Sessions, SessionGroups, true));
% Label = 'Effect of EC';


% EC vs Lapses 
%  ProbType = squeeze(jointTally(Trials, [], Trials.Theta==1, Trials.Alpha==1, Participants, ...
%     Sessions, SessionGroups, true));
% Label = 'Theta and alpha';


% Left v right
 Rand = randn(size(Trials, 1), 1)>0;
 ProbType = squeeze(jointTally(Trials, [], Trials.isRight==1, Trials.Type==1, Participants, ...
    Sessions, SessionGroups, true));
Label = 'Effect of EC';


% Band vs lapses
%  ProbType = squeeze(jointTally(Trials, EO & SD, Trials.Theta==1, Trials.Type==1, Participants, ...
%     Sessions, SessionGroups, true));
% Label = 'Effect of Theta';

% Band vs lapses
%  ProbType = squeeze(jointTally(Trials, EO, SD, Trials.Type==1, Participants, ...
%     Sessions, SessionGroups, true));
% Label = 'Effect of SD';



ProbTheta = ProbType(:, 1);
ProbAlpha = ProbType(:, 2);
ActualJointProb = ProbType(:, 3);

JointProb = ProbTheta.*ProbAlpha;

 figure
 hold on
 plot([0 1], [0 1], ':')
 scatter(JointProb, ActualJointProb, 'filled')
ylabel('Actual joint probability')
xlabel('Expected joint probability')
xlim([0 1])
ylim([0 1])


Stats = pairedttest(JointProb, ActualJointProb, StatsP)


MinProb =  min(ProbType(:, [1 2]), [], 2);
Prcnt = 100*(ProbType(:, 3)-JointProb)./(MinProb-JointProb);
dispDescriptive(Prcnt, Label, '%', 0);

