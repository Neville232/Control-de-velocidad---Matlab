clear all
clc

% Definir el array respuesta_escalon en MATLAB
respuesta_escalon = [
    0, 35, 70, 105, 140, 175, 210, 245, 280, 315, ...
    350, 385, 420, 455, 490, 525, 560, 595, 630, 665, ...
    700, 735, 770, 805, 840, 875, 910, 945, 980, 1015, ...
    1050, 1085, 1120, 1155, 1190, 1225, 1260, 1295, 1330, 1365
]';

% Definir el vector de tiempo
tiempo = (0:0.256:(0.256*(length(respuesta_escalon)-1)))';

% Definir la entrada de escalón unitario de 1400 RPM
entrada = 1400 * ones(size(tiempo));

% Crear el objeto iddata con la entrada y la salida
data = iddata(respuesta_escalon, entrada, 0.256);

% Definir las opciones de estimación del modelo de proceso
opt = procestOptions('Display', 'on', 'Focus', 'stability');

% Estimar el modelo de proceso de primer orden con retardo
try
    sys = procest(data, 'P1D', opt);
catch ME
    disp('Error al estimar el modelo de proceso:');
    disp(ME.message);
    return;
end

% Mostrar el modelo estimado
disp('Modelo de proceso estimado:');
disp(sys);

% Obtener el numerador y denominador de la función de transferencia
[num, den] = tfdata(sys, 'v');

% Imprimir el numerador y denominador
disp('Numerador:');
disp(num);
disp('Denominador:');
disp(den);

% Graficar la respuesta al escalón del modelo estimado y comparar con los datos originales
figure;
step(sys); % Respuesta al escalón del modelo estimado
hold on;
plot(tiempo, respuesta_escalon, 'r--'); % Respuesta al escalón original
legend('Modelo estimado', 'Datos originales');
title('Comparación de la respuesta al escalón');
xlabel('Tiempo');
ylabel('Amplitud');