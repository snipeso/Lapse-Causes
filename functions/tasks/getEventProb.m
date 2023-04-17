function JP = getEventProb(ProbLapse, ProbEvent, OJP)
% assemble matrix of P x 2, with col1 indicating the expected joint
% probability as a percentage of event probability, and col2 the observed
% joint probability  also as a percent of event probability.

EJP = ProbLapse.*ProbEvent;
EJP_Prcnt = (ProbEvent-EJP)./ProbEvent;

OJP = (ProbEvent-OJP)./ProbEvent;