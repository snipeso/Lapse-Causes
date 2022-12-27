function String = dispStat(Stats, P, Label)
% displays as string a statistic of interest
% From Lapse-causes


Fieldnames = fieldnames(Stats);

if any(strcmp(Fieldnames, 't')) % paired t-test
    pValue = num2str(Stats.p(P(1), P(2)), '%.3f');
    disp(Label)
    String = ['N = ', num2str(Stats.N), ...
        ', t = ', num2str(Stats.t(P(1), P(2)), '%.2f'), ...
        ', p = .', extractAfter(pValue, '.'), ', g = ', num2str(Stats.hedgesg(P(1), P(2)), '%.2f')];

    disp(String)
    
elseif any(strcmp(Fieldnames, 'ranovatbl')) % 2 way rmANOVA
    Positions = [3, 5, 7]; % Session, Task, Interaction

    disp('Interpreting eta: .01 is small; .06 is medium; .14 is large')
    disp('*')
    disp(Label)
    for Indx = 1:3
        p = num2str(Stats.ranovatbl.pValueGG(Positions(Indx)),  '%.3f');
        DF1 = Stats.ranovatbl.DF(Positions(Indx));
        DF2 = Stats.ranovatbl.DF(Positions(Indx)+1);
        F = Stats.ranovatbl.F(Positions(Indx));
        eta = num2str(Stats.effects.eta2(Indx), '%.3f');


        String = [P{Indx}, ': ' ...
            '(F(', num2str(DF1), ', ', num2str(DF2), ') = ', num2str(F, '%.2f'), ...
            ', p = .', extractAfter(p, '.'), ', eta2 = .', extractAfter(eta, '.'), ')'];
        disp(String)
        disp('*')
    end

end


