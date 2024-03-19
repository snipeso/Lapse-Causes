function Stats = ttest_timefrequency(Data, StatsParameters)
% runs a simple t-test on data to see which points in a P x F x t matrix
% deviates significantly from 0.

Dims = size(Data);

tValues = nan(Dims(2), Dims(3));
N = nnz(~isnan(Data(:, 1, 1)));
pValues = tValues;

for FrequencyIdx = 1:Dims(2)
    for TimeIdx = 1:Dims(3)

        [~, p, ~, stats] = ttest(squeeze(Data(:, FrequencyIdx, TimeIdx)));

        pValues(FrequencyIdx, TimeIdx) = p;
        tValues(FrequencyIdx, TimeIdx) = stats.tstat;

    end
end

[FDR, h, crit_p] = fdr_matrix(pValues, StatsParameters);

Stats.N = N;
Stats.sig = h;
Stats.t = tValues;
Stats.p = pValues;
Stats.crit_p = crit_p;

Stats.p_fdr = FDR;

end
