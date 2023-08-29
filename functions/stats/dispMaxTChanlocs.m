function dispMaxTChanlocs(Stats, Chanlocs, String)

% if ~any(Stats.sig)
%     return
% end

t = Stats.t;
% t(~Stats.sig) = nan;
Stats.p_fdr = Stats.p_fdr(:);
Stats.N = repmat(Stats.N, numel(Stats.p_fdr), 1);
[~, Indx] = max(abs(t));

disp_stats(Stats, [Indx, 1], [String, ' ', Chanlocs(Indx).labels]);
