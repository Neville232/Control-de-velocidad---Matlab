
% Parámetros del sistema
K = 1400;  % Ganancia
tau = 2.5; % Constante de tiempo
delay = 0.7; % Retardo

% Definición del tiempo
t = 0:0.01:10; % Vector de tiempo de 0 a 10 segundos con incrementos de 0.01 segundos

% Entrada del sistema (escalón unitario)
u = ones(size(t));

% Salida del sistema de primer orden con retardo
y = K * (1 - exp(-(t-delay)/tau)) .* (t >= delay);

% Graficar los resultados
figure;
subplot(2,1,1);
plot(t, u, 'b', 'LineWidth', 1.5);
title('Entrada del Sistema');
xlabel('Tiempo (s)');
ylabel('Amplitud');
grid on;

subplot(2,1,2);
plot(t, y, 'r', 'LineWidth', 1.5);
title('Salida del Sistema de Primer Orden con Retardo');
xlabel('Tiempo (s)');
ylabel('Amplitud');
grid on;