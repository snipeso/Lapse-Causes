function Stats = pairedWilcoxon(Data1, Data2)

Diff = Data2-Data1;



[p,sig, stats] = signrank(Diff);

Stats.zval = stats.zval;
Stats.p = p;
Stats.sig = sig;
Stats.df = numel(Diff) - nnz(isnan(Diff)) - 1;
Stats.N = Stats.df + 1;
Stats.mean_diff = mean(Diff, 'omitnan');
Stats.std_diff = std(Diff, 'omitnan');
Stats.mean1 = mean(Data1, 'omitnan');
Stats.mean2 = mean(Data2, 'omitnan');