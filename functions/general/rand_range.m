function Rand = rand_range(N, Min, Max)

Rand = Min + (Max - Min) .*rand(N, 1);