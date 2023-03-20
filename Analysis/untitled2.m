
% 
% % Generate example data
% V_1 = rand(20, 1);
% V_2 = rand(20, 1);
% V_1_2 = rand(20, 1) < V_1 .* V_2;

V_1 = ProbType(:, 1);
V_2 = ProbType(:, 2);
V_1_2 = ProbType(:, 3);

% Compute confidence intervals using 1000 bootstrap iterations
[CI_lower, CI_upper] = bootstrap_freq_diff2(V_1, V_2, V_1_2, 1000);

disp([num2str(CI_lower), '-', num2str(CI_upper)])