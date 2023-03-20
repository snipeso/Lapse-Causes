function [CI_lower, CI_upper] = bootstrap_freq_diff(V_1, V_2, V_1_2, N)
% by chatGPT v4

% Compute the expected frequency of co-occurrence
V_1_expected = mean(V_1);
V_2_expected = mean(V_2);
V_1_2_expected = V_1_expected * V_2_expected;

% Compute the observed frequency of co-occurrence
V_1_2_observed = mean(V_1_2);

% Compute the difference between observed and expected frequencies
freq_diff = V_1_2_observed - V_1_2_expected;

% Bootstrap the frequencies and compute the difference for each iteration
freq_diff_bootstrap = zeros(N, 1);
for i = 1:N
    % Sample with replacement from V_1, V_2, and V_1_2
    V_1_sampled = datasample(V_1, length(V_1));
    V_2_sampled = datasample(V_2, length(V_2));
    V_1_2_sampled = datasample(V_1_2, length(V_1_2));
    % Compute the frequency of co-occurrence for the sampled data
    V_1_2_sampled_freq = mean(V_1_sampled .* V_2_sampled == V_1_2_sampled);
    % Compute the difference between observed and expected frequencies for the sampled data
    freq_diff_bootstrap(i) = V_1_2_sampled_freq - V_1_expected * V_2_expected;
end

% Compute the confidence intervals from the bootstrap distribution
CI_lower = prctile(freq_diff_bootstrap, 2.5);
CI_upper = prctile(freq_diff_bootstrap, 97.5);

end
