function varargout = UI(varargin)
% UI MATLAB code for UI.fig
%      UI, by itself, creates a new UI or raises the existing
%      singleton*.
%
%      H = UI returns the handle to a new UI or the handle to
%      the existing singleton*.
%
%      UI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UI.M with the given input arguments.
%
%      UI('Property','Value',...) creates a new UI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before UI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to UI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help UI

% Last Modified by GUIDE v2.5 28-Feb-2025 00:20:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                    'gui_Singleton',  gui_Singleton, ...
                    'gui_OpeningFcn', @UI_OpeningFcn, ...
                    'gui_OutputFcn',  @UI_OutputFcn, ...
                    'gui_LayoutFcn',  [] , ...
                    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


%% ===========================================================================================


function UI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clc;
% Choose default command line output for UI
handles.output = hObject;

% Inicializar variables para almacenar datos y tiempo
handles.datos = [];

global global_tiempo
global global_magnitudes
global global_tiemposTranscurridos
global global_stpoints
global global_tiemposSetpoints
global global_graficar
global global_tiempoInicio
global global_stpointValue
global global_motorState
global global_estado
global global_controlando

% Declarar variables globales para los parámetros de identificación del sistema y del controlador
global global_thau
global global_K
global global_L
global global_Kc
global global_ti
global global_q0
global global_q1

% Declarar variables globales adicionales
global global_setpointPorcentaje
global global_setpointRPM
global global_timer
global global_rpm_anterior
global global_u_anterior
global global_error_anterior
global global_timerControl
global global_s

global global_RPMmax
global global_constM
global global_constC
global global_alpha
global global_beta

% PARAMETRIZAR
global_RPMmax = 1400;       % RPM maximo
global_constM = 1;          % Pendiente de la recta
global_constC = 0;          % Desplazamiento
global_alpha = 0.6;         % Filtro
global_beta = 0;            % Filtro

global_tiempo = [];
global_magnitudes = [];
global_tiemposTranscurridos = [];
global_stpoints = [];
global_tiemposSetpoints = [];
global_graficar = false;    % Variable para controlar el inicio de la gráfica
global_tiempoInicio = [];   % Inicializar tiempoInicio
global_stpointValue = 0;    % Inicializar el valor del setpoint
global_motorState = 0;      % Inicializar el estado del motor (0: detenido, 1: iniciado)
global_estado = 1;
global_controlando = 0;

ylim(handles.graph_1, [0 1500]);

% Set the CloseRequestFcn
set(handles.figure1, 'CloseRequestFcn', {@UI_CloseRequestFcn, handles});
set(handles.button_connet, 'BackgroundColor', [0.5, 1, 0.5]);
% Actualizar el popupmenu con los puertos COM disponibles
actualizarMenuCOM(handles);

% Update handles structure
guidata(hObject, handles);


%% ===========================================================================================


function UI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Variables globales necesarias:
global global_s
global global_timer
global global_timerControl
global global_controlando

global_controlando = 0;

% Desconectar el puerto serial si esta conectado
if ~isempty(global_s) && isvalid(global_s)
    fclose(global_s);
    delete(global_s);
    global_s = [];
    disp('Puerto serial desconectado.');
end

% Detener el motor
if ~isempty(global_s) && isvalid(global_s)
    global_setpointValue = 0; % Detener el motor
    trama = [255, global_setpointValue, 1]; % Crear la trama de datos
    disp(['Enviando trama: ', num2str(trama)]); % Mensaje de depuración
    fwrite(global_s, trama, 'uint8'); % Enviar la trama de datos
    pause(1);
    global_motorState = 0;
    trama = [255, 0, global_motorState]; % Crear la trama de datos
    disp(['Enviando trama: ', num2str(trama)]); % Mensaje de depuración
    fwrite(global_s, trama, 'uint8'); % Enviar la trama de datos
    disp('Comando de parada enviado.');
end

% Detener y eliminar el temporizador global_timer si existe
if ~isempty(global_timer) && isvalid(global_timer)
    stop(global_timer);
    delete(global_timer);
    global_timer = [];
    disp('Temporizador global_timer detenido y eliminado.');
end

% Detener y eliminar el temporizador global_timerControl si existe
if ~isempty(global_timerControl) && isvalid(global_timerControl)
    stop(global_timerControl);
    delete(global_timerControl);
    global_timerControl = [];
    disp('Temporizador global_timerControl detenido y eliminado.');
end

% Eliminar todos los temporizadores existentes
timers = timerfindall;
if ~isempty(timers)
    stop(timers);
    delete(timers);
    disp('Todos los temporizadores han sido detenidos y eliminados.');
end

% Resetear todas las variables globales
global global_tiempo
global global_magnitudes
global global_tiemposTranscurridos
global global_stpoints
global global_tiemposSetpoints
global global_graficar
global global_tiempoInicio
global global_stpointValue
global global_motorState
global global_estado
global global_thau
global global_K
global global_L
global global_Kc
global global_ti
global global_q0
global global_q1
global global_setpointPorcentaje
global global_setpointRPM
global global_rpm_anterior
global global_u_anterior
global global_error_anterior
global global_s

global_tiempo = [];
global_magnitudes = [];
global_tiemposTranscurridos = [];
global_stpoints = [];
global_tiemposSetpoints = [];
global_graficar = false;
global_tiempoInicio = [];
global_stpointValue = 0;
global_motorState = 0;
global_estado = 1;
global_thau = [];
global_K = [];
global_L = [];
global_Kc = [];
global_ti = [];
global_q0 = [];
global_q1 = [];
global_setpointPorcentaje = [];
global_setpointRPM = [];
global_rpm_anterior = [];
global_u_anterior = [];
global_error_anterior = [];
global_s = [];

% Guardar los cambios en handles
guidata(hObject, handles);

% Hint: delete(hObject) closes the figure
delete(hObject);


%% ===========================================================================================


function varargout = UI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%% ===========================================================================================


function actualizarMenuCOM(handles)
% Obtener la lista de puertos COM disponibles
info = instrhwinfo('serial');
puertosCOM = info.SerialPorts;

% Actualizar el popupmenu con los puertos COM disponibles
set(handles.menuCOM, 'String', puertosCOM);

% Seleccionar el último puerto de la lista por defecto
if ~isempty(puertosCOM)
    set(handles.menuCOM, 'Value', length(puertosCOM));
end

% Guardar los cambios en handles
guidata(handles.figure1, handles);


function menuCOM_Callback(hObject, eventdata, handles)
% hObject    handle to menuCOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menuCOM contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menuCOM


function menuCOM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menuCOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% ===========================================================================================


function button_connet_Callback(hObject, eventdata, handles)
% Verificar si ya esta conectado al puerto serial
global global_s
if ~isempty(global_s) && isvalid(global_s) && strcmp(global_s.Status, 'open')
    return;
end

% Obtener el puerto serial seleccionado del popupmenu
puertosCOM = get(handles.menuCOM, 'String');
indiceSeleccionado = get(handles.menuCOM, 'Value');
puertoSerial = puertosCOM{indiceSeleccionado};

% Configuracion del puerto serial
velocidadBaudios = 9600; % Configura la velocidad en baudios

% Crear objeto serial
global_s = serial(puertoSerial, 'BaudRate', velocidadBaudios, 'Terminator', '-'); % Usar '-' como terminador

% Configurar la funcion de callback para leer datos cuando esten disponibles
global_s.BytesAvailableFcnMode = 'terminator';
global_s.BytesAvailableFcn = {@serialCallback, hObject};

% Abrir el puerto serial
fopen(global_s);
disp(['Puerto serial ', puertoSerial, ' conectado.']);

% Cambia de color el boton de iniciar
set(handles.button_start, 'BackgroundColor', [0.5, 1, 0.5]);
set(handles.button_connet, 'BackgroundColor', [0.94, 0.94, 0.94]);
set(handles.button_disconnet, 'BackgroundColor', [1, 0.5, 0.5]);

% Guardar los cambios en handles
guidata(hObject, handles);


%% ===========================================================================================


function button_disconnet_Callback(hObject, eventdata, handles)
% hObject    handle to boton_desconectar (see GCBO)
% Variables globales necesarias:
global global_s
if ~isempty(global_s) && isvalid(global_s)
    fclose(global_s);
    delete(global_s);
    global_s = [];
    disp('Puerto serial desconectado.');
    set(handles.button_start, 'BackgroundColor', [0.94, 0.94, 0.94]);
    set(handles.button_stop, 'BackgroundColor', [0.94, 0.94, 0.94]);
    set(handles.button_connet, 'BackgroundColor', [0.5, 1, 0.5]);
    set(handles.button_disconnet, 'BackgroundColor', [0.94, 0.94, 0.94]);
end

% Guardar los cambios en handles
guidata(hObject, handles);


%% ===========================================================================================


function button_send_Callback(hObject, eventdata, handles)
% hObject    handle to boton_enviar (see GCBO)
% Variables globales necesarias:
global global_motorState
global global_tiempoInicio
global global_stpoints
global global_tiemposSetpoints
global global_graficar
global global_tiemposTranscurridos
global global_magnitudes
global global_setpointPorcentaje
global global_setpointRPM
global global_s

% Obtener el valor del edit_text con el tag input_setpoint
setpointStr = get(handles.input_setpoint, 'String');

% Verificar si el edit_text tiene contenido
if ~isempty(setpointStr)
    % Convertir el valor a numero
    setpointValue = str2double(setpointStr);
    
    % Verificar si la conversion fue exitosa y si esta en el rango 700-1400
    if ~isnan(setpointValue) && setpointValue >= 700 && setpointValue <= 1400 && mod(setpointValue, 1) == 0
        % Convertir el valor de RPM a porcentaje entero
        porcentaje = round(setpointValue / 14);
        global_setpointPorcentaje = porcentaje; % Actualizar el valor del setpoint
        
        % Almacenar el setpoint en RPM para el cálculo de K
        global_setpointRPM = setpointValue;
        
        % Crear la trama de datos
        trama = [255, global_setpointPorcentaje, global_motorState];
        
        % Mostrar mensaje de depuración
        disp(['Enviando trama: ', num2str(trama)]);
        
        % Enviar la trama de datos por el puerto serial
        fwrite(global_s, trama, 'uint8');
        
        % Obtener el tiempo actual
        tiempoActual = now;
        
        % Verificar si tiempoInicio está inicializado
        if isempty(global_tiempoInicio)
            global_tiempoInicio = tiempoActual;
        end
        
        % Calcular el tiempo en segundos desde el primer dato
        tiempoTranscurrido = (tiempoActual - global_tiempoInicio) * 24 * 3600; % Convertir días a segundos
        
        % Almacenar los valores de setpoint y tiempo transcurrido
        if isempty(global_stpoints)
            global_stpoints = [0, setpointValue];
            global_tiemposSetpoints = [0, tiempoTranscurrido];
        else
            global_stpoints = [global_stpoints, setpointValue];
            global_tiemposSetpoints = [global_tiemposSetpoints, tiempoTranscurrido];
        end
        
        % Mostrar mensaje de confirmación
        disp(['Valor enviado: ', num2str(setpointValue)]);
        
        % Actualizar la gráfica en el axes con el tag grafica_1
        if global_graficar
            axes(handles.graph_1);
            plot(handles.graph_1, global_tiemposTranscurridos, global_magnitudes, 'b', ...
                    global_tiemposSetpoints, global_stpoints, 'r--');
            xlabel(handles.graph_1, 'Tiempo (s)');
            ylabel(handles.graph_1, 'RPM');
            title(handles.graph_1, 'Grafica de RPM vs Tiempo');
        end
    else
        % Mostrar mensaje de error si la conversión falló o el valor no está en el rango
        disp('Error: El valor ingresado no es un número entero válido entre 700 y 1400.');
    end
else
    % Mostrar mensaje de error si el edit_text está vacío
    disp('Error: No se ingresó ningún valor.');
end

% Guardar los cambios en handles
guidata(hObject, handles);


function input_setpoint_Callback(hObject, eventdata, handles)
% hObject    handle to entrada_setpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of entrada_setpoint as text
%        str2double(get(hObject,'String')) returns contents of entrada_setpoint as a double


function input_setpoint_CreateFcn(hObject, eventdata, handles)
% hObject    handle to entrada_setpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% ===========================================================================================


function button_start_Callback(hObject, eventdata, handles)
% hObject    handle to boton_iniciar (see GCBO)
% Variables globales necesarias:
global global_motorState
global global_stpointValue
global global_graficar
global global_tiempoInicio
global global_tiemposTranscurridos
global global_magnitudes
global global_stpoints
global global_tiemposSetpoints
global global_tiempoInicioMotor
global global_timer
global global_s
global global_controlando
global global_timerControl

set(handles.label_rpm, 'String', 'Motor encendido');
if ~isempty(global_s) && isvalid(global_s)
    global_motorState = 1; % Iniciar el motor
    trama = [255, global_stpointValue, global_motorState]; % Crear la trama de datos
    disp(['Enviando trama: ', num2str(trama)]); % Mensaje de depuración
    fwrite(global_s, trama, 'uint8'); % Enviar la trama de datos
    disp('Comando de inicio enviado.');
    set(handles.button_stop, 'BackgroundColor', [0.5, 1, 0.5]);
    set(handles.button_start, 'BackgroundColor', [0.94, 0.94, 0.94]);
    
    % Reiniciar la gráfica
    global_graficar = true;
    global_tiempoInicio = now; % Almacenar el tiempo de inicio
    global_tiemposTranscurridos = []; % Reiniciar tiempos transcurridos
    global_magnitudes = []; % Reiniciar magnitudes
    global_stpoints = []; % Reiniciar setpoints
    global_tiemposSetpoints = []; % Reiniciar tiempos de setpoints
    
    % Almacenar el tiempo de inicio del motor
    global_tiempoInicioMotor = now;
    
    % Iniciar un temporizador para actualizar la gráfica del setpoint cada 0.256 segundos
    global_timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.256, ...
                            'TimerFcn', {@updateSetpointGraph, hObject});
    start(global_timer);

    if global_controlando == 1
        % Definir el tiempo de muestreo en segundos
        tiempoMuestreo = 0.256; % Ajusta este valor según sea necesario

        % Crear el temporizador
        global_timerControl = timer('ExecutionMode', 'fixedRate', 'Period', tiempoMuestreo, ...
            'TimerFcn', {@ejecutarControl, hObject});

        % Iniciar el temporizador
        start(global_timerControl);
    end

end

% Guardar los cambios en handles
guidata(hObject, handles);


%% ===========================================================================================


function button_stop_Callback(hObject, eventdata, handles)
% hObject    handle to boton_detener (see GCBO)
% Variables globales necesarias:
global global_motorState
global global_stpointValue
global global_timer
global global_s

if ~isempty(global_s) && isvalid(global_s)
    global_setpointValue = 0; % Detener el motor
    trama = [255, global_setpointValue, 1]; % Crear la trama de datos
    disp(['Enviando trama: ', num2str(trama)]); % Mensaje de depuración
    fwrite(global_s, trama, 'uint8'); % Enviar la trama de datos
    pause(1);
    global_motorState = 0;
    trama = [255, 0, global_motorState]; % Crear la trama de datos
    disp(['Enviando trama: ', num2str(trama)]); % Mensaje de depuración
    fwrite(global_s, trama, 'uint8'); % Enviar la trama de datos
    disp('Comando de parada enviado.');
    set(handles.button_start, 'BackgroundColor', [0.5, 1, 0.5]);
    set(handles.button_stop, 'BackgroundColor', [0.94, 0.94, 0.94]);
    
    % Detener y eliminar el temporizador global_timer si existe
    if ~isempty(global_timer) && isvalid(global_timer)
        stop(global_timer);
        delete(global_timer);
        global_timer = [];
        disp('Temporizador global_timer detenido y eliminado.');
    end
end

% Guardar los cambios en handles
guidata(hObject, handles);


%% ===========================================================================================


function serialCallback(obj, event, hObject)
% obj    handle to the serial object
% event  structure with event data
% hObject handle to the figure
% Variables globales necesarias:
global global_tiemposTranscurridos
global global_tiempoInicio
global global_magnitudes
global global_estado
global global_graficar
global global_stpoints
global global_tiemposSetpoints
global global_rpm_anterior
global global_s
global global_alpha
global global_beta

% Obtener handles actualizados
handles = guidata(hObject);

% Leer los datos disponibles
dato = fscanf(global_s);

% Verificar si se recibieron datos
if isempty(dato)
    disp('No se recibieron datos.');
    return;
end

% Eliminar el terminador '-' del dato recibido
dato = strrep(dato, '-', '');

% Convertir el dato a numero
rpm_actual = str2double(dato);
disp(['Dato recibido: ', num2str(rpm_actual)]);


% Aplicar el filtro de media de movimiento
if ~isempty(global_rpm_anterior) && global_rpm_anterior ~= 0
    rpm = (global_beta + 1) * (global_alpha * rpm_actual + ((1 - global_alpha) * global_rpm_anterior));
else
    rpm = rpm_actual;
end
global_rpm_anterior = rpm; % Actualiza rpm_anterior

% Obtener el tiempo actual
tiempoActual = now;

% Si es el primer dato, almacenar el tiempo inicial
if isempty(global_tiemposTranscurridos)
    global_tiempoInicio = tiempoActual;
end

% Calcular el tiempo en segundos desde el primer dato
tiempoTranscurrido = (tiempoActual - global_tiempoInicio) * 24 * 3600; % Convertir dias a segundos

% Almacenar los valores de magnitud y tiempo transcurrido
global_magnitudes = [global_magnitudes, rpm];
global_tiemposTranscurridos = [global_tiemposTranscurridos, tiempoTranscurrido];

% Verificar el estado
if global_estado == 1
    % Identificación del sistema
    identificarSistema(handles, tiempoTranscurrido, rpm);
elseif global_estado == 2
    % Control del sistema
    controlarSistema(handles, tiempoTranscurrido, rpm);
end

% Actualizar la grafica en el axes con el tag grafica_1
if global_graficar
    axes(handles.graph_1);
    plot(handles.graph_1, global_tiemposTranscurridos, global_magnitudes, 'b', ...
            global_tiemposSetpoints, global_stpoints, 'r--');
    xlabel(handles.graph_1, 'Tiempo (s)');
    ylabel(handles.graph_1, 'RPM');
    title(handles.graph_1, 'Grafica de RPM vs Tiempo');
end
set(handles.label_rpm, 'String', [num2str(rpm), ' RPM']);
% Guardar los cambios en handles
guidata(hObject, handles);


%% ===========================================================================================


function updateSetpointGraph(~, ~, hObject)
% Variables globales necesarias:
global global_tiempoInicio
global global_stpoints
global global_tiemposSetpoints
global global_tiemposTranscurridos
global global_magnitudes
global global_setpointRPM

% Obtener handles actualizados
handles = guidata(hObject);

% Obtener el tiempo actual
tiempoActual = now;

% Calcular el tiempo en segundos desde el inicio
tiempoTranscurrido = (tiempoActual - global_tiempoInicio) * 24 * 3600; % Convertir días a segundos

% Almacenar los valores de setpoint y tiempo transcurrido
if isempty(global_stpoints)
    global_stpoints = [0, global_setpointRPM]; % Iniciar desde 0 si no había un setpoint anterior
    global_tiemposSetpoints = [0, tiempoTranscurrido];
else
    global_stpoints = [global_stpoints, global_setpointRPM]; % Usar el setpoint en RPM
    global_tiemposSetpoints = [global_tiemposSetpoints, tiempoTranscurrido];
end

% Actualizar la gráfica en el axes con el tag grafica_1
axes(handles.graph_1);
plot(handles.graph_1, global_tiemposTranscurridos, global_magnitudes, 'b', ...
        global_tiemposSetpoints, global_stpoints, 'r--');
xlabel(handles.graph_1, 'Tiempo (s)');
ylabel(handles.graph_1, 'RPM');
title(handles.graph_1, 'Grafica de RPM vs Tiempo');

% Guardar los cambios en handles
guidata(hObject, handles);


%% ===========================================================================================


function identificarSistema(handles, tiempoTranscurrido, rpm)
% Variables globales necesarias:
global global_tiemposTranscurridos
global global_magnitudes
global global_stpointValue
global global_motorState
global global_graficar
global global_estado
global global_thau
global global_K
global global_L
global global_s
global global_setpointRPM

% Verificar la variacion de las muestras en el intervalo de tiempo de 3 segundos
intervalo = 10; % Intervalo de tiempo en segundos
umbralVariacion = 0.02; % Variacion maxima permitida (2%)

% Encontrar las muestras dentro del intervalo de tiempo
indicesRecientes = find(global_tiemposTranscurridos >= (tiempoTranscurrido - intervalo));

if ~isempty(indicesRecientes)
    magnitudesRecientes = global_magnitudes(indicesRecientes);
    magnitudMaxima = max(magnitudesRecientes);
    magnitudMinima = min(magnitudesRecientes);
    variacion = (magnitudMaxima - magnitudMinima) / magnitudMaxima;

    if variacion <= umbralVariacion
        disp('Se ha alcanzado el establecimiento del sistema.');
        set(handles.button_stop, 'BackgroundColor', [0.94, 0.94, 0.94]);
        valorFinalPromedio = mean(magnitudesRecientes);
        disp(['Valor final promedio: ', num2str(valorFinalPromedio)]);
        valor63 = 0.63 * valorFinalPromedio;
        valor283 = 0.283 * valorFinalPromedio;

        % Detener el motor y la gráfica
        global_stpointValue = 0; % Inicializar el valor del setpoint
        global_motorState = 0; % Inicializar el estado del motor (0: detenido, 1: iniciado)
        global_graficar = false;
        trama = [255, 0, 0]; % Trama de datos específica FF 00 00 en hexadecimal
        fwrite(global_s, trama, 'uint8');        
        disp('Motor detenido y gráfica detenida.');
        x = global_tiemposTranscurridos;
        y = global_magnitudes;

        if length(x) >= 2 && length(y) >= 2
            constanteTiempo63 = csapi(y, x, valor63);
            disp(['Tiempo interpolado para 63%: ', num2str(constanteTiempo63)]);
            
            constanteTiempo283 = csapi(y, x, valor283);
            disp(['Tiempo interpolado para 28.3%: ', num2str(constanteTiempo283)]);
        else
            disp('No hay suficientes datos para realizar la interpolación.');
            constanteTiempo63 = NaN;
            constanteTiempo283 = NaN;
        end
        
        if ~isnan(constanteTiempo63) && ~isnan(constanteTiempo283)
            t63 = constanteTiempo63; % El tiempo en el que la magnitud alcanza el 63% del valor final
            t283 = constanteTiempo283; % El tiempo en el que la magnitud alcanza el 28.3% del valor final
            K = valorFinalPromedio / global_setpointRPM; % Usar el setpoint almacenado en RPM como K
            disp(['K: ', num2str(K)]);
            disp(['t63: ', num2str(t63)]);
            disp(['t283: ', num2str(t283)]);
            
            % Calcular thau y L
            thau = 1.5 * (t63 - t283);
            L = t63 - thau;
            
            global_K = K;
            global_thau = thau;
            global_L = L;
            
            disp(['thau: ', num2str(thau)]);
            disp(['L: ', num2str(L)]);
            
            % Actualizar el static text con el tag label_thau
            set(handles.label_thau, 'String', [num2str(thau, '%.2f'), ' + s']);
            
            set(handles.label_k, 'String', num2str(K, '%.2f'));
            set(handles.label_L, 'String', ['-', num2str(L, '%.2f'), 's']);
        
            num = [K];
            den = [thau 1];
            sys = tf(num, den, 'InputDelay', L); % Incluir el retardo L en la función de transferencia
            step(sys);
            obj = stepinfo(sys);
            ts = obj.SettlingTime;
            mp = obj.Overshoot * 100;
            disp(['Tiempo de establecimiento: ', num2str(ts)]);
            disp(['Sobre impulso: ', num2str(mp)]);
        
            set(handles.label_settlingtime, 'String', ['Ts: ', num2str(ts, '%.2f'), ' s']);
            set(handles.label_overshoot, 'String', ['Mp: ', num2str(mp, '%.2f'), '%']);
            
            if isfield(handles, 'timer') && isvalid(handles.timer)
                stop(handles.timer);
                delete(handles.timer);
            end
            
            % Cambiar el estado a 2 (control)
            global_estado = 2;
        
        else
            disp('No se pudo determinar el tiempo en el que la magnitud alcanza el 63% o el 28.3% del valor final.');
        end
    else
        % disp('La variacion de las muestras en los ultimos 3 segundos es mayor al 2%.');
    end
end


%% ===========================================================================================


function controlarSistema(handles, tiempoTranscurrido, rpm)


% Variables globales necesarias:
global global_graficar
global global_tiemposTranscurridos
global global_magnitudes
global global_stpoints
global global_tiemposSetpoints

disp('Controlando el sistema...');
% Actualizar la gráfica en el axes con el tag grafica_1
if global_graficar
    axes(handles.graph_1);
    plot(handles.graph_1, global_tiemposTranscurridos, global_magnitudes, 'b', ...
            global_tiemposSetpoints, global_stpoints, 'r--');
    xlabel(handles.graph_1, 'Tiempo (s)');
    ylabel(handles.graph_1, 'RPM');
    title(handles.graph_1, 'Grafica de RPM vs Tiempo controlada');
end


%% ===========================================================================================


function calcular_controlador_Callback(hObject, eventdata, handles)
% Variables globales necesarias:
global global_thau
global global_K
global global_L
global global_q0
global global_q1

% Asegurarse de que los valores de thau, K y L estén disponibles
if ~isempty(global_thau) && ~isempty(global_K) && ~isempty(global_L)
    thau = global_thau;
    K = global_K;
    L = global_L;
    muestreo = 0.256;

    % Calcular los parámetros del controlador
    Kc = 0.9 * thau / (K * L);
    ti = 3.33 * L;

    % Asegurarse de que ti es un escalar
    if isscalar(ti)
        global_q0 = Kc * (1 + (muestreo / (2 * ti)));
        global_q1 = -Kc * (1 - (muestreo / (2 * ti)));
        q0 = global_q0;
        q1 = global_q1;

        disp(['thau: ', num2str(thau, '%.2f')])
        disp(['K: ', num2str(K, '%.2f')])
        disp(['L: ', num2str(L, '%.2f')])
        disp(['Kc: ', num2str(Kc, '%.2f')])
        disp(['q0: ', num2str(q0, '%.2f')])
        disp(['q1: ', num2str(q1, '%.2f')])

        % Actualizar los static text con los tag label_Kc y label_ti
        set(handles.label_Kc, 'String', num2str(Kc, '%.2f'));
        set(handles.label_ti, 'String', num2str(ti, '%.2f'));
    else
        disp('Error: ti no es un escalar.');
    end
else
    disp('Error: Los valores de thau, K y L no están disponibles.');
end

% Guardar los cambios en handles
guidata(hObject, handles);


%% ===========================================================================================

function controlar_Callback(hObject, eventdata, handles)
% hObject    handle to controlar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Variables globales necesarias:
global global_thau
global global_K
global global_L
global global_timerControl
global global_setpointRPM
global global_controlando

% Asegurarse de que los valores de thau, K y L estén disponibles
if ~isempty(global_thau) && ~isempty(global_K) && ~isempty(global_L)
    % Definir el tiempo de muestreo en segundos
    tiempoMuestreo = 0.256; % Ajusta este valor según sea necesario
    
    global_u_anterior = 0;
    global_error_anterior = global_setpointRPM;

    global_controlando = 1;
    
    % Cambiar el color del botón para indicar que está activo
    set(handles.controlar, 'BackgroundColor', [0.5, 1, 0.5]);
    
    % Guardar los cambios en handles
    guidata(hObject, handles);
else
    disp('Error: Los valores de thau, K y L no están disponibles.');
end


%% ===========================================================================================


function controlar_Callback(hObject, eventdata, handles)
% hObject    handle to controlar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Variables globales necesarias:
global global_thau
global global_K
global global_L
global global_timerControl
global global_setpointRPM

% Asegurarse de que los valores de thau, K y L estén disponibles
if ~isempty(global_thau) && ~isempty(global_K) && ~isempty(global_L)
    % Definir el tiempo de muestreo en segundos
    tiempoMuestreo = 0.256; % Ajusta este valor según sea necesario
    
    global_u_anterior = 0;
    global_error_anterior = global_setpointRPM;

    % Crear el temporizador
    global_timerControl = timer('ExecutionMode', 'fixedRate', 'Period', tiempoMuestreo, ...
                                    'TimerFcn', {@ejecutarControl, hObject});
    
    % Iniciar el temporizador
    start(global_timerControl);
    
    % Cambiar el color del botón para indicar que está activo
    set(handles.controlar, 'BackgroundColor', [0.5, 1, 0.5]);
    
    % Guardar los cambios en handles
    guidata(hObject, handles);
else
    disp('Error: Los valores de thau, K y L no están disponibles.');
end


%% ===========================================================================================


function ejecutarControl(~, ~, hObject)
% Variables globales necesarias:
global global_magnitudes
global global_motorState
global global_q0
global global_q1
global global_u_anterior
global global_error_anterior
global global_setpointRPM
global global_s
global global_RPMmax
global global_constM
global global_constC

% Obtener handles actualizados
handles = guidata(hObject);

% Verificar si hObject es un handle válido
if isempty(handles)
    disp('Error: hObject no es un handle válido.');
    return;
end

% Obtener el último valor de magnitudes
if ~isempty(global_magnitudes)
    rpm_actual = global_magnitudes(end);
else
    rpm_actual = 0;
end

% Obtener el último valor de setpointRPM
setpoint_actual = global_setpointRPM;

% Obtener los valores anteriores de error y control
if isempty(global_error_anterior)
    error_anterior = 0;
else
    error_anterior = global_error_anterior;
end

if isempty(global_u_anterior)
    u_anterior = 0;
else
    u_anterior = global_u_anterior;
end

% Calcular el error actual
error_actual = setpoint_actual - rpm_actual;

% Obtener los valores de q0 y q1
q0 = global_q0;
q1 = global_q1;

% Calcular el control actual
u_actual = u_anterior + (q0 * error_actual) + (q1 * error_anterior);

% Asegurarse de que u_actual esté en el rango permitido (0-100%)
cargaPWM = ((u_actual/global_RPMmax) * 100 * global_consM) + global_consC;

cargaPWM = max(0, min(100, cargaPWM));

% Actualizar los valores anteriores
global_u_anterior = u_actual;
global_error_anterior = error_actual;

% Verificar si el puerto serial está abierto antes de escribir en él
if ~isempty(global_s) && isvalid(global_s) && strcmp(global_s.Status, 'open')
    % Enviar el valor de control al motor
    trama = [255, round(cargaPWM), global_motorState];
    disp(['RPM actual: ', num2str(rpm_actual)]); % Mensaje de depuración
    disp(['Setpoint actual: ', num2str(setpoint_actual)]); % Mensaje de depuración
    disp(['Error actual: ', num2str(error_actual)]); % Mensaje de depuración
    disp(['q0: ', num2str(q0)]); % Mensaje de depuración
    disp(['q1: ', num2str(q1)]); % Mensaje de depuración
    disp(['u_anterior: ', num2str(u_anterior)]); % Mensaje de depuración
    disp(['u_actual: ', num2str(u_actual)]); % Mensaje de depuración
    disp(['Salida de controlador: ', num2str(round(u_actual))]); % Imprimir la trama en la consola
    fwrite(global_s, trama, 'uint8');
else
    disp('Error: El puerto serial no está abierto.');
end

% Guardar los cambios en handles
guidata(hObject, handles);