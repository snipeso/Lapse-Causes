function Stats = pairedWilcoxon(Data1, Data2)

Diff = Data2-Data1;



[p,sig, stats] = signrank(Diff);

try
Stats.zval = stats.zval;
catch
    warning('something weird with z-values again')
    Stats.zval = stats;
end
Stats.p = p;
Stats.sig = sig;
Stats.df = numel(Diff) - nnz(isnan(Diff)) - 1;
Stats.N = Stats.df + 1;
Stats.mean_diff = mean(Diff, 'omitnan');
Stats.std_diff = std(Diff, 'omitnan');
Stats.mean1 = mean(Data1, 'omitnan');
Stats.mean2 = mean(Data2, 'omitnan');

PooledSTD = sqrt((std(Data1, 'omitnan')^2 + std(Data2, 'omitnan')^2)/2);

Stats.RequiredN =  sampsizepwr('z', [Stats.mean1, PooledSTD], [Stats.mean2], .8, []);