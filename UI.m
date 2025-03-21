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

% Last Modified by GUIDE v2.5 17-Mar-2025 19:19:00

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

% Si se pasa una posición como argumento, establecerla
if ~isempty(varargin)
    set(hObject, 'Position', varargin{1});
end

% Inicializar variables para almacenar datos y tiempo
handles.datos = [];

addpath('libreria');

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

% Declarar variables globales para los colores
global color_default
global color_activo
global color_inactivo

global global_intervalo 
global global_umbralVariacion 

% PARAMETRIZAR
global_RPMmax = 1500;           % RPM maximo
global_constM = 17.067;         % Pendiente de la recta
global_constC = 118.33;         % Desplazamiento
global_alpha = 0.2;             % Filtro
global_beta = 0.9855;           % Filtro
global_intervalo = 5            % Intervalo de tiempo en segundos
global_umbralVariacion = 0.02   % Variacion maxima permitida

color_default   = [0.94, 0.94, 0.94];
color_activo    = [0.5, 1, 0.5];
color_inactivo  = [1, 0.5, 0.5];

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


% Set the CloseRequestFcn
set(handles.figure1, 'CloseRequestFcn', {@UI_CloseRequestFcn, handles});
set(handles.button_connet, 'BackgroundColor', color_activo);
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
global global_setpointPorcentaje
global global_motorState

global_controlando = 0;

% Detener el motor
if ~isempty(global_s) && isvalid(global_s)
    global_setpointPorcentaje = 0; % Detener el motor
    trama = [255, global_setpointPorcentaje, 1]; % Crear la trama de datos
    disp(['Enviando trama: ', num2str(trama)]); % Mensaje de depuración
    fwrite(global_s, trama, 'uint8'); % Enviar la trama de datos
    pause(1);
    global_motorState = 0;
    trama = [255, 0, global_motorState]; % Crear la trama de datos
    disp(['Enviando trama: ', num2str(trama)]); % Mensaje de depuración
    fwrite(global_s, trama, 'uint8'); % Enviar la trama de datos
    disp('Comando de parada enviado.');
end

% Desconectar el puerto serial si esta conectado
if ~isempty(global_s) && isvalid(global_s)
    fclose(global_s);
    delete(global_s);
    global_s = [];
    disp('Puerto serial desconectado.');
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
global global_estado
global global_thau
global global_K
global global_L
global global_Kc
global global_ti
global global_q0
global global_q1
global global_setpointRPM
global global_rpm_anterior
global global_u_anterior
global global_error_anterior

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
global color_default
global color_activo
global color_inactivo

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
set(handles.button_send, 'BackgroundColor', color_activo);
set(handles.button_connet, 'BackgroundColor', color_default);
set(handles.button_disconnet, 'BackgroundColor', color_inactivo);

% Guardar los cambios en handles
guidata(hObject, handles);


%% ===========================================================================================


function button_disconnet_Callback(hObject, eventdata, handles)
% hObject    handle to boton_desconectar (see GCBO)
% Variables globales necesarias:
global global_s
global color_default
global color_activo
global color_inactivo

if ~isempty(global_s) && isvalid(global_s)
    fclose(global_s);
    delete(global_s);
    global_s = [];
    disp('Puerto serial desconectado.');
    set(handles.button_start, 'BackgroundColor', color_default);
    set(handles.button_stop, 'BackgroundColor', color_default);
    set(handles.button_connet, 'BackgroundColor', color_activo);
    set(handles.button_disconnet, 'BackgroundColor', color_default);
end

% Guardar los cambios en handles
guidata(hObject, handles);


%% ===========================================================================================


function button_send_Callback(hObject, eventdata, handles)
global global_SCADA

% Obtener el valor del edit_text con el tag input_setpoint
setpointStr = get(handles.input_setpoint, 'String');

if global_SCADA == 0
    % Llamar a la función send_setpoint
    send_setpoint(handles, setpointStr);
else
    disp('Se esta estableciendo control desde el SCADA');
end


%% ===========================================================================================


function send_setpoint(handles, setpointStr)
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
global global_constM
global global_constC

global color_default
global color_activo
global color_inactivo

% Verificar si el edit_text tiene contenido
if ~isempty(setpointStr)
    % Convertir el valor a numero
    setpointValue = str2double(setpointStr);
    
    % Verificar si la conversion fue exitosa y si esta en el rango 735-1500
    if ~isnan(setpointValue) && setpointValue >= 735 && setpointValue <= 1500 && mod(setpointValue, 1) == 0
        % Convertir el valor de RPM a porcentaje usando la razón de cambio proporcionada
        global_setpointPorcentaje = (setpointValue + global_constC) / global_constM; % Actualizar el valor del setpoint
        
        % Almacenar el setpoint en RPM para el cálculo de K
        global_setpointRPM = setpointValue;
        
        % Crear la trama de datos
        trama = [255, round(global_setpointPorcentaje), global_motorState];
        
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
        disp('Error: El valor ingresado no es un número entero válido entre 735 y 1500.');
    end
else
    % Mostrar mensaje de error si el edit_text está vacío
    disp('Error: No se ingresó ningún valor.');
end

set(handles.button_start, 'BackgroundColor', color_activo);

% Guardar los cambios en handles
guidata(handles.figure1, handles);


%% ===========================================================================================


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
global global_setpointPorcentaje

global color_default
global color_activo
global color_inactivo

setpoint = global_setpointPorcentaje;

disp(['Setpoint start: ', num2str(setpoint)]);

set(handles.label_rpm, 'String', 'Motor encendido');
if ~isempty(global_s) && isvalid(global_s)
    global_motorState = 1; % Iniciar el motor
    trama = [255, setpoint, global_motorState]; % Crear la trama de datos
    disp(['Enviando trama: ', num2str(trama)]); % Mensaje de depuración
    fwrite(global_s, trama, 'uint8'); % Enviar la trama de datos
    disp('Comando de inicio enviado.');
    set(handles.button_stop, 'BackgroundColor', color_inactivo);
    set(handles.button_start, 'BackgroundColor', color_default);
    
    % Reiniciar la gráfica
    global_graficar = true;
    global_tiempoInicio = now; % Almacenar el tiempo de inicio
    global_tiemposTranscurridos = [0]; % Reiniciar tiempos transcurridos
    global_magnitudes = [0]; % Reiniciar magnitudes
    global_stpoints = [0]; % Reiniciar setpoints
    global_tiemposSetpoints = [0]; % Reiniciar tiempos de setpoints
    
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
global global_timerControl

global color_default
global color_activo
global color_inactivo

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
    set(handles.button_start, 'BackgroundColor', color_activo);
    set(handles.button_stop, 'BackgroundColor', color_default);
    
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
global global_setpointRPM % Nueva variable global añadida

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

% Convertir el dato a número
rpm_actual = str2double(dato);
disp(['Dato recibido: ', num2str(rpm_actual)]);

% Aplicar el filtro de media de movimiento
if ~isempty(global_rpm_anterior) && global_rpm_anterior ~= 0
    rpm = global_beta * ((global_alpha * rpm_actual + ((1 - global_alpha) * global_rpm_anterior)));
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
tiempoTranscurrido = (tiempoActual - global_tiempoInicio) * 24 * 3600; % Convertir días a segundos

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

% Actualizar la gráfica en el axes con el tag grafica_1
if global_graficar
    axes(handles.graph_1);
    plot(handles.graph_1, global_tiemposTranscurridos, global_magnitudes, 'b', ...
            global_tiemposSetpoints, global_stpoints, 'r--');
    xlabel(handles.graph_1, 'Tiempo (s)');
    ylabel(handles.graph_1, 'RPM');
    title(handles.graph_1, 'Grafica de RPM vs Tiempo');
end

% Actualizar la etiqueta de RPM
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

% Llamar a la función para actualizar el porcentaje de error
updateError(handles);

% Guardar los cambios en handles
guidata(hObject, handles);



function updateError(handles)
% Variables globales necesarias
global global_magnitudes
global global_setpointRPM

% Verificar si hay datos disponibles
if ~isempty(global_magnitudes) && ~isempty(global_setpointRPM) && global_setpointRPM ~= 0
    % Obtener el último valor de RPM
    rpm_actual = global_magnitudes(end);
    
    % Calcular el porcentaje de error
    porcentaje_error = abs((global_setpointRPM - rpm_actual) / global_setpointRPM) * 100;
    
    % Mostrar el porcentaje de error en el tag label_error
    set(handles.label_error, 'String', [num2str(porcentaje_error, '%.2f'), '%']);
else
    % Si no hay datos, mostrar "N/A"
    set(handles.label_error, 'String', 'N/A');
end


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
global global_setpointRPM

global color_default
global color_activo
global color_inactivo

global global_s
global global_timer

% Verificar la variación de las muestras en el intervalo de tiempo de 3 segundos
global global_intervalo % Intervalo de tiempo en segundos
global global_umbralVariacion % Variación máxima permitida

% Encontrar las muestras dentro del intervalo de tiempo
indicesRecientes = find(global_tiemposTranscurridos >= (tiempoTranscurrido - global_intervalo));

if ~isempty(indicesRecientes)
    magnitudesRecientes = global_magnitudes(indicesRecientes);
    magnitudMaxima = max(magnitudesRecientes);
    magnitudMinima = min(magnitudesRecientes);
    variacion = (magnitudMaxima - magnitudMinima) / magnitudMaxima;

    if variacion <= global_umbralVariacion
        disp('Se ha alcanzado el establecimiento del sistema.');
        set(handles.button_stop, 'BackgroundColor', color_default);
        valorFinalPromedio = mean(magnitudesRecientes);
        disp(['Valor final promedio: ', num2str(valorFinalPromedio)]);
        valor63 = 0.63 * valorFinalPromedio;
        valor283 = 0.283 * valorFinalPromedio;

        % Detener el motor y la gráfica
        global_stpointValue = 0; % Inicializar el valor del setpoint
        global_motorState = 0; % Inicializar el estado del motor (0: detenido, 1: iniciado)
        global_graficar = false;
        trama = [255, 0, 1]; % Trama de datos específica FF 00 00 en hexadecimal
        fwrite(global_s, trama, 'uint8'); 
        pause(1);
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
            set(handles.label_thau, 'String', [num2str(thau, '%.2f'), 's + 1']);
            
            set(handles.label_k, 'String', num2str(K, '%.2f'));
            set(handles.label_L, 'String', ['-', num2str(L, '%.2f'), 's']);
        
            num = [K];
            den = [thau 1];
            sys = tf(num, den, 'InputDelay', L); % Incluir el retardo L en la función de transferencia
            
            % Obtener los datos de la respuesta al escalón
            [y, t] = step(sys);
            
            % Seleccionar el axes con el tag transfer
            axes(handles.transfer); % Seleccionar el axes
            cla(handles.transfer, 'reset'); % Limpiar el contenido del axes
            
            % Graficar la respuesta al escalón
            plot(handles.transfer, t, y, 'b', 'LineWidth', 1.5); % Graficar la respuesta al escalón
            xlabel(handles.transfer, 'Tiempo (s)');
            ylabel(handles.transfer, 'Salida');
            title(handles.transfer, 'Respuesta al Escalon');
            grid(handles.transfer, 'on'); % Agregar una cuadrícula al gráfico

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
            
            % Detener y eliminar el temporizador global_timer si existe
            if ~isempty(global_timer) && isvalid(global_timer)
                stop(global_timer);
                delete(global_timer);
                global_timer = [];
                disp('Temporizador global_timer detenido y eliminado.');
            end
            
            % Cambiar el estado a 2 (control)
            global_estado = 2;
            set(handles.calcular_controlador, 'BackgroundColor', color_activo);
        
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

global color_default
global color_activo
global color_inactivo

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

global color_default
global color_activo
global color_inactivo

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
        set(handles.label_ti, 'String', [num2str(ti, '%.2f'), 's']);

        set(handles.controlar, 'BackgroundColor', color_activo);
        set(handles.calcular_controlador, 'BackgroundColor', color_default);

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
global global_tiemposTranscurridos
global global_magnitudes
global global_rpm_anterior
global global_graficar

global color_default
global color_activo
global color_inactivo

% Asegurarse de que los valores de thau, K y L estén disponibles
if ~isempty(global_thau) && ~isempty(global_K) && ~isempty(global_L)
    % Reiniciar las variables relacionadas con la gráfica
    global_tiemposTranscurridos = [0]; % Reiniciar tiempos transcurridos
    global_magnitudes = [0]; % Reiniciar magnitudes
    global_rpm_anterior = 0; % Reiniciar RPM anterior
    global_graficar = true; % Habilitar la gráfica

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
    set(handles.controlar, 'BackgroundColor', color_inactivo);
    
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

% Asegurarse de que u_actual esté en el rango permitido (735-1500 RPM)
u_actual = max(735, min(1500, u_actual));

% Calcular la carga PWM correspondiente usando la razón de cambio proporcionada
cargaPWM = (u_actual + global_constC) / global_constM;

% Asegurarse de que cargaPWM esté en el rango permitido (0-100)
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
    disp(['Carga PWM: ', num2str(round(cargaPWM))]); % Imprimir la trama en la consola
    fwrite(global_s, trama, 'uint8');
else
    disp('Error: El puerto serial no está abierto.');
end

% Guardar los cambios en handles
guidata(hObject, handles);


%% ===========================================================================================


function ruta_tx_Callback(hObject, eventdata, handles)
global global_ruta_tx

global_ruta_tx = uigetdir('', 'Elige la carpeta que contiene el archivo TX.JSON');

if global_ruta_tx ~= 0
    [~, folderName, ~] = fileparts(global_ruta_tx);
    set(handles.label_tx, 'String', [folderName, '/TX.JSON']);
else
    set(handles.label_tx, 'String', 'No se ha seleccionado ninguna carpeta');
end


%% ===========================================================================================


% --- Executes on button press in ruta_rx.
function ruta_rx_Callback(hObject, eventdata, handles)
global global_ruta_rx

global_ruta_rx = uigetdir('', 'Elige la carpeta que contiene el archivo RX.JSON');

if global_ruta_rx ~= 0
    [~, folderName, ~] = fileparts(global_ruta_rx);
    set(handles.label_rx, 'String', [folderName, '/RX.JSON']);
else
    set(handles.label_rx, 'String', 'No se ha seleccionado ninguna carpeta');
end


%% ===========================================================================================


function scada_on_Callback(hObject, eventdata, handles)
global global_timerJSON

% Crear un objeto timer que ejecute tanto la lectura como la escritura
global_timerJSON = timer('ExecutionMode', 'fixedRate', 'Period', 0.25, ...
    'TimerFcn', {@scadaReadWrite, handles});

% Iniciar el timer
start(global_timerJSON);
disp('Temporizador SCADA iniciado (lectura y escritura).');


%% ===========================================================================================


function scada_off_Callback(hObject, eventdata, handles)
global global_timerJSON
global color_default

% Detener y eliminar el temporizador global_timerJSON si existe
if ~isempty(global_timerJSON) && isvalid(global_timerJSON)
    stop(global_timerJSON);
    delete(global_timerJSON);
    global_timerJSON = [];
    set(handles.label_SCADA, 'BackgroundColor', color_default);
    disp('Temporizador SCADA detenido y eliminado.');
end


%% ===========================================================================================


function scadaReadWrite(~, ~, handles)
% Esta función ejecuta tanto la lectura como la escritura en JSON
readAndDisplayJSON([], [], handles); % Llamar a la función de lectura
writeToJSON(handles);               % Llamar a la función de escritura


%% ===========================================================================================


function readAndDisplayJSON(~, ~, handles)
global global_ruta_rx
global global_SCADA
global color_activo
global color_default

% Verificar si la ruta del archivo JSON está definida
if isempty(global_ruta_rx) || isequal(global_ruta_rx, 0)
    disp('No se ha seleccionado ninguna carpeta.');
    return;
end

% Construir la ruta completa del archivo JSON
jsonFilePath = fullfile(global_ruta_rx, 'rx.JSON');

% Verificar si el archivo JSON existe
if exist(jsonFilePath, 'file') ~= 2
    disp('El archivo rx.JSON no existe en la ruta especificada.');
    return;
end

% Intentar abrir y leer el archivo JSON
try
    inputjson = loadjson(jsonFilePath);
catch ME
    disp(['Error al leer el archivo JSON: ', ME.message]);
    return;
end

% Mostrar el contenido del archivo JSON
disp(['Setpoint: ', num2str(inputjson.setpoint)]);
disp(['Estado del motor: ', num2str(inputjson.estado_motor)]);
disp(['Emergencia: ', num2str(inputjson.emergencia)]);
disp(['SCADA: ', num2str(inputjson.SCADA)]);

% Actualizar las etiquetas en la interfaz gráfica
set(handles.label_setpoint_SCADA, 'String', num2str(inputjson.setpoint));

if inputjson.estado_motor == 1
    set(handles.label_motor_SCADA, 'String', 'On');
else
    set(handles.label_motor_SCADA, 'String', 'Off');
end

if inputjson.emergencia == 1
    set(handles.label_emergencia_SCADA, 'String', 'On');
else
    set(handles.label_emergencia_SCADA, 'String', 'Off');
end

% Actualizar el valor de global_SCADA
global_SCADA = inputjson.SCADA;

% Cambiar el color del tag label_SCADA según el valor de global_SCADA
if global_SCADA == 1
    set(handles.label_SCADA, 'BackgroundColor', color_activo);
else
    set(handles.label_SCADA, 'BackgroundColor', color_default);
end

% Si SCADA está activo, enviar el setpoint
if global_SCADA == 1
    send_setpoint(handles, num2str(inputjson.setpoint));
end


%% ===========================================================================================


function writeToJSON(handles)
% Variables globales necesarias
global global_ruta_tx
global global_magnitudes
global global_K
global global_thau
global global_L

% Verificar si la ruta del archivo JSON está definida
if isempty(global_ruta_tx) || isequal(global_ruta_tx, 0)
    disp('No se ha seleccionado ninguna carpeta para guardar el archivo JSON.');
    return;
end

% Construir la ruta completa del archivo JSON
jsonFilePath = fullfile(global_ruta_tx, 'tx.JSON');

% Obtener el último valor de RPM
if ~isempty(global_magnitudes)
    rpm_actual = global_magnitudes(end);
else
    rpm_actual = 0; % Si no hay datos, establecer RPM en 0
end

% Crear una estructura de datos para guardar en el JSON
data.RPM = rpm_actual;
data.K = global_K;
data.thau = global_thau;
data.L = global_L;

% Guardar la estructura en un archivo JSON
try
    savejson('', data, jsonFilePath);
    disp(['Archivo JSON guardado en: ', jsonFilePath]);
catch ME
    disp(['Error al guardar el archivo JSON: ', ME.message]);
end


%% ===========================================================================================






% --- Executes on button press in maxima.
function maxima_Callback(hObject, eventdata, handles)
% hObject    handle to maxima (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Establecer el valor máximo permitido en el input_setpoint
set(handles.input_setpoint, 'String', '1500'); % Valor máximo de RPM


% --- Executes on button press in media.
function media_Callback(hObject, eventdata, handles)
% hObject    handle to media (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Establecer el valor medio permitido en el input_setpoint
set(handles.input_setpoint, 'String', '1120'); % Valor medio de RPM (aproximado)


% --- Executes on button press in minima.
function minima_Callback(hObject, eventdata, handles)
% hObject    handle to minima (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Establecer el valor mínimo permitido en el input_setpoint
set(handles.input_setpoint, 'String', '740'); % Valor mínimo de RPM