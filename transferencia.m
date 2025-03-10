% filepath: /c:/Users/Nelvinson/Documents/1- UNIVERSIDAD/8 - LABORATORIO DE CONTROL/0 - Repositorio Lab. Control/transferencia.m

% Parámetros de la función de transferencia
K = 1400; % Ganancia
ts = 10; % Tiempo de establecimiento en segundos
tau = ts / 4; % Constante de tiempo (aproximadamente ts/4 para un sistema de primer orden)

% Crear la función de transferencia de primer orden
sys = tf(K, [tau 1]);

% Tiempo de simulación
t_final = 10; % Segundos
t = 0:0.256:t_final; % Vector de tiempo con pasos de 256 ms

% Respuesta al escalón
[y, t] = step(sys, t);

% Generar el array de magnitudes
magnitudes = y';

% Mostrar el array de magnitudes
disp('Array de magnitudes:');
disp(magnitudes);

% Graficar la respuesta al escalón
figure;
plot(t, y, '-o');
xlabel('Tiempo (s)');
ylabel('Magnitud (RPM)');
title('Respuesta al escalón de una función de transferencia de primer orden');
grid on;