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

% Last Modified by GUIDE v2.5 01-Mar-2025 20:56:17

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


% --- Executes just before UI is made visible.
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
handles.tiempo = [];
handles.magnitudes = [];
handles.tiemposTranscurridos = [];

% Set the CloseRequestFcn
set(handles.figure1, 'CloseRequestFcn', {@UI_CloseRequestFcn, handles});
set(handles.button_connet, 'BackgroundColor', [0.5, 1, 0.5]);
% Actualizar el popupmenu con los puertos COM disponibles
actualizarMenuCOM(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes UI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Executes when user attempts to close UI.
function UI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Actualizar handles
handles = guidata(hObject);

% Desconectar el puerto serial si esta conectado
if isfield(handles, 's') && isvalid(handles.s)
    fclose(handles.s);
    delete(handles.s);
    handles = rmfield(handles, 's');
    disp('Puerto serial desconectado.');
end

% Guardar los cambios en handles
guidata(hObject, handles);

% Hint: delete(hObject) closes the figure
delete(hObject);

% --- Outputs from this function are returned to the command line.
function varargout = UI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in boton_iniciar.
function button_start_Callback(hObject, eventdata, handles)
% hObject    handle to boton_iniciar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.label_rpm, 'String', 'Motor encendido');
if isfield(handles, 's') && isvalid(handles.s)
    fwrite(handles.s, 101, 'uint8'); % Enviar 101 en binario
    disp('Comando de inicio enviado.');
    set(handles.button_stop, 'BackgroundColor', [0.5, 1, 0.5]);
    set(handles.button_start, 'BackgroundColor', [0.94, 0.94, 0.94]);
end

% --- Executes on button press in boton_detener.
function button_stop_Callback(hObject, eventdata, handles)
% hObject    handle to boton_detener (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 's') && isvalid(handles.s)
    fwrite(handles.s, 102, 'uint8'); % Enviar 102 en binario
    disp('Comando de parada enviado.');
    set(handles.button_start, 'BackgroundColor', [0.5, 1, 0.5]);
    set(handles.button_stop, 'BackgroundColor', [0.94, 0.94, 0.94]);
end

% --- Executes on button press in boton_conectar.
function button_connet_Callback(hObject, eventdata, handles)
% hObject    handle to boton_conectar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Verificar si ya esta conectado al puerto serial
if isfield(handles, 's') && isvalid(handles.s) && strcmp(handles.s.Status, 'open')
    return;
end

% Obtener el puerto serial seleccionado del popupmenu
puertosCOM = get(handles.menuCOM, 'String');
indiceSeleccionado = get(handles.menuCOM, 'Value');
puertoSerial = puertosCOM{indiceSeleccionado};

% Configuracion del puerto serial
velocidadBaudios = 9600; % Configura la velocidad en baudios

% Crear objeto serial
handles.s = serial(puertoSerial, 'BaudRate', velocidadBaudios, 'Terminator', '-'); % Usar '-' como terminador

% Configurar la funcion de callback para leer datos cuando esten disponibles
handles.s.BytesAvailableFcnMode = 'terminator';
handles.s.BytesAvailableFcn = {@serialCallback, hObject};

% Abrir el puerto serial
fopen(handles.s);
disp(['Puerto serial ', puertoSerial, ' conectado.']);

%Cambia de color el boton de iniciar
set(handles.button_start, 'BackgroundColor', [0.5, 1, 0.5]);
set(handles.button_connet, 'BackgroundColor', [0.94, 0.94, 0.94]);
set(handles.button_disconnet, 'BackgroundColor', [1, 0.5, 0.5]);

% Guardar los cambios en handles
guidata(hObject, handles);

% --- Executes on button press in boton_desconectar.
function button_disconnet_Callback(hObject, eventdata, handles)
% hObject    handle to boton_desconectar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 's') && isvalid(handles.s)
    fclose(handles.s);
    delete(handles.s);
    handles = rmfield(handles, 's');
    disp('Puerto serial desconectado.');
    set(handles.button_start, 'BackgroundColor', [0.94, 0.94, 0.94]);
    set(handles.button_stop, 'BackgroundColor', [0.94, 0.94, 0.94]);
    set(handles.button_connet, 'BackgroundColor', [0.5, 1, 0.5]);
    set(handles.button_disconnet, 'BackgroundColor', [0.94, 0.94, 0.94]);


end

% Guardar los cambios en handles
guidata(hObject, handles);

function serialCallback(obj, event, hObject)
% obj    handle to the serial object
% event  structure with event data
% hObject handle to the figure

% Obtener handles actualizados
handles = guidata(hObject);

% Leer los datos disponibles
dato = fscanf(obj);

% Verificar si se recibieron datos
if isempty(dato)
    disp('No se recibieron datos.');
    return;
end

% Eliminar el terminador '-' del dato recibido
dato = strrep(dato, '-', '');

% Convertir el dato a numero
dato = str2double(dato);
disp(['Dato recibido: ', num2str(dato)]);

% Obtener el tiempo actual
tiempoActual = now;

% Si es el primer dato, almacenar el tiempo inicial
if isempty(handles.tiemposTranscurridos)
    handles.tiempoInicio = tiempoActual;
end

% Calcular el tiempo en segundos desde el primer dato
tiempoTranscurrido = (tiempoActual - handles.tiempoInicio) * 24 * 3600; % Convertir dias a segundos

% Almacenar los valores de magnitud y tiempo transcurrido
handles.magnitudes = [handles.magnitudes, dato];
handles.tiemposTranscurridos = [handles.tiemposTranscurridos, tiempoTranscurrido];

% Verificar la variacion de las muestras en el intervalo de tiempo de 3 segundos
intervalo = 2; % Intervalo de tiempo en segundos
umbralVariacion = 0.02; % Variacion maxima permitida (2%)

% Encontrar las muestras dentro del intervalo de tiempo
indicesRecientes = find(handles.tiemposTranscurridos >= (tiempoTranscurrido - intervalo));

if ~isempty(indicesRecientes)
    magnitudesRecientes = handles.magnitudes(indicesRecientes);
    magnitudMaxima = max(magnitudesRecientes);
    magnitudMinima = min(magnitudesRecientes);
    variacion = (magnitudMaxima - magnitudMinima) / magnitudMaxima;

    if variacion <= umbralVariacion
        % disp('La variacion de las muestras en los ultimos 3 segundos es menor o igual al 2%.');
        disp('Se ha alcanzado el establecimiento del sistema.');
        fwrite(handles.s, 102, 'uint8'); % Enviar 102 en binario para detener el proceso
        set(handles.button_stop, 'BackgroundColor', [0.94, 0.94, 0.94]);
        valorFinalPromedio = mean(magnitudesRecientes);
        disp(['Valor final promedio: ', num2str(valorFinalPromedio)]);
        valor63 = 0.63 * valorFinalPromedio;
        
        % Encontrar el tiempo en el que la magnitud alcanza el 63% del valor final
        indice63 = find(handles.magnitudes == valor63, 1);
        
        if ~isempty(indice63)
            constanteTiempo = handles.tiemposTranscurridos(indice63);
            disp(['Tiempo en el que la magnitud alcanza el 63%: ', num2str(constanteTiempo)]);
            disp(['Magnitud en el 63%: ', num2str(handles.magnitudes(indice63))]);
            disp('Sin interpolar');
        else
            % Si no se encuentra el valor, realizar interpolacion lineal
            indiceInferior = find(handles.magnitudes < valor63, 1, 'last');
            indiceSuperior = find(handles.magnitudes > valor63, 1, 'first');
            
            if ~isempty(indiceInferior) && ~isempty(indiceSuperior)
                % Interpolacion lineal
                x1 = handles.tiemposTranscurridos(indiceInferior);
                y1 = handles.magnitudes(indiceInferior);
                x2 = handles.tiemposTranscurridos(indiceSuperior);
                y2 = handles.magnitudes(indiceSuperior);
                constanteTiempo = x1 + (valor63 - y1) * (x2 - x1) / (y2 - y1);
                disp(['Tiempo mas cercano inferior: ', num2str(x1)]);
                disp(['Magnitud mas cercana inferior: ', num2str(y1)]);
                disp(['Tiempo mas cercano superior: ', num2str(x2)]);
                disp(['Magnitud mas cercana superior: ', num2str(y2)]);
            else
                constanteTiempo = NaN; % Si no se puede interpolar, asignar NaN
            end
        end
        
        if ~isnan(constanteTiempo)
            a = 1/constanteTiempo; % El tiempo en el que la magnitud alcanza el 63% del valor final
            K = valorFinalPromedio  * a;
            disp(['K: ', num2str(K)]);
            disp(['a: ', num2str(a)]);
            disp(['t: ', num2str(constanteTiempo)]);
            disp(['T establecimiento: ', num2str(4*constanteTiempo)])
            disp(['ymax: ', num2str(valorFinalPromedio)]);
            disp(['y63: ', num2str(valor63)]);

            set(handles.label_k, 'String', num2str(K, '%.2f'));
            set(handles.label_a, 'String', ['s + ', num2str(a, '%.2f')]);

            num = [K];
            den = [1 a];
            sys = tf(num, den);
            step(sys);
            obj = stepinfo(sys);
            ts = obj.SettlingTime;
            mp = obj.Overshoot*100;
            disp(['Tiempo de establecimiento: ', num2str(ts)]);
            disp(['Sobre impulso: ', num2str(mp)]);

            set(handles.label_settlingtime, 'String', ['Ts: ', num2str(ts, '%.2f'), ' s']);
            set(handles.label_overshoot, 'String', ['Mp: ', num2str(mp, '%.2f'), '%']);

        else
            disp('No se pudo determinar el tiempo en el que la magnitud alcanza el 63% del valor final.');
        end
    else
        % disp('La variacion de las muestras en los ultimos 3 segundos es mayor al 2%.');
    end
end

% Actualizar la grafica en el axes con el tag grafica_1
axes(handles.graph_1);
plot(handles.graph_1, handles.tiemposTranscurridos, handles.magnitudes);
xlabel(handles.graph_1, 'Tiempo (s)');
ylabel(handles.graph_1, 'RPM');
title(handles.graph_1, 'Grafica de RPM vs Tiempo');
set(handles.label_rpm, 'String', [num2str(dato), ' RPM']);
% Guardar los cambios en handles
guidata(hObject, handles);


function input_setpoint_Callback(hObject, eventdata, handles)
% hObject    handle to entrada_setpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of entrada_setpoint as text
%        str2double(get(hObject,'String')) returns contents of entrada_setpoint as a double


% --- Executes during object creation, after setting all properties.
function input_setpoint_CreateFcn(hObject, eventdata, handles)
% hObject    handle to entrada_setpoint (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in boton_enviar.
function button_send_Callback(hObject, eventdata, handles)
% hObject    handle to boton_enviar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Obtener el valor del edit_text con el tag entrada_setpoint
setpointStr = get(handles.entrada_setpoint, 'String');

% Verificar si el edit_text tiene contenido
if ~isempty(setpointStr)
    % Convertir el valor a numero
    setpointValue = str2double(setpointStr);
    
    % Verificar si la conversion fue exitosa y si esta en el rango 0-100
    if ~isnan(setpointValue) && setpointValue >= 0 && setpointValue <= 100 && mod(setpointValue, 1) == 0
        % Convertir el valor a binario
        setpointBinario = uint8(setpointValue);
        
        % Enviar el valor binario por el puerto serial
        fwrite(handles.s, setpointBinario, 'uint8');
        
        % Obtener el tiempo actual
        tiempoActual = now;
        
        % Si es el primer dato, almacenar el tiempo inicial
        if isempty(handles.tiemposTranscurridos)
            handles.tiempoInicio = tiempoActual;
        end
        
        % Calcular el tiempo en segundos desde el primer dato
        tiempoTranscurrido = (tiempoActual - handles.tiempoInicio) * 24 * 3600; % Convertir dias a segundos
        
        % Almacenar los valores de magnitud y tiempo transcurrido
        handles.magnitudes = [handles.magnitudes, setpointValue];
        handles.tiemposTranscurridos = [handles.tiemposTranscurridos, tiempoTranscurrido];
        
        % Mostrar mensaje de confirmacion
        disp(['Valor enviado: ', num2str(setpointValue)]);
    else
        % Mostrar mensaje de error si la conversion fallo o el valor no esta en el rango
        disp('Error: El valor ingresado no es un numero entero valido entre 0 y 100.');
    end
else
    % Mostrar mensaje de error si el edit_text esta vacio
    disp('Error: No se ingreso ningun valor.');
end

% Guardar los cambios en handles
guidata(hObject, handles);

function actualizarMenuCOM(handles)
% Obtener la lista de puertos COM disponibles
info = instrhwinfo('serial');
puertosCOM = info.SerialPorts;

% Actualizar el popupmenu con los puertos COM disponibles
set(handles.menuCOM, 'String', puertosCOM);

% Guardar los cambios en handles
guidata(handles.figure1, handles);


% --- Executes on selection change in menuCOM.
function menuCOM_Callback(hObject, eventdata, handles)
% hObject    handle to menuCOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns menuCOM contents as cell array
%        contents{get(hObject,'Value')} returns selected item from menuCOM


% --- Executes during object creation, after setting all properties.
function menuCOM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to menuCOM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in calcular_controlador.
function calcular_controlador_Callback(hObject, eventdata, handles)
% hObject    handle to calcular_controlador (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
