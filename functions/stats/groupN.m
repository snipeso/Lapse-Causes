function groupN(CohenD)

u = 1.96; % for alpha = 5%
v = 1.28; % for beta = 10%

N = round((2*(u+v)^2)/(CohenD)^2);

disp(['For Cohen D of ', num2str(CohenD), ', N = ', num2str(N)])
