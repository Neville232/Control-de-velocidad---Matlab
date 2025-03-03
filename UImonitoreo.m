function varargout = UImonitoreo(varargin)
% UIMONITOREO MATLAB code for UImonitoreo.fig
%      UIMONITOREO, by itself, creates a new UIMONITOREO or raises the existing
%      singleton*.
%
%      H = UIMONITOREO returns the handle to a new UIMONITOREO or the handle to
%      the existing singleton*.
%
%      UIMONITOREO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UIMONITOREO.M with the given input arguments.
%
%      UIMONITOREO('Property','Value',...) creates a new UIMONITOREO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before UImonitoreo_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to UImonitoreo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help UImonitoreo

% Last Modified by GUIDE v2.5 03-Mar-2025 09:26:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @UImonitoreo_OpeningFcn, ...
                   'gui_OutputFcn',  @UImonitoreo_OutputFcn, ...
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

% --- Executes just before UImonitoreo is made visible.
function UImonitoreo_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to UImonitoreo (see VARARGIN)

% Choose default command line output for UImonitoreo
handles.output = hObject;

% Obtener el objeto serial de la base de datos de la aplicación
handles.s = getappdata(0, 'SerialObject');

% Configurar la función de callback para leer datos cuando estén disponibles
handles.s.BytesAvailableFcnMode = 'terminator';
handles.s.BytesAvailableFcn = {@serialCallback, hObject};

% Inicializar variables para almacenar datos y tiempo
handles.datos = [];
handles.tiempo = [];
handles.magnitudes = [];
handles.tiemposTranscurridos = [];
handles.setpoints = [];
handles.tiemposSetpoints = [];
handles.graficar = false; % Variable para controlar el inicio de la gráfica
handles.tiempoInicio = []; % Inicializar tiempoInicio
handles.setpointValue = 0; % Inicializar el valor del setpoint
handles.motorState = 0; % Inicializar el estado del motor (0: detenido, 1: iniciado)

% Set the CloseRequestFcn
set(handles.figure1, 'CloseRequestFcn', {@UImonitoreo_CloseRequestFcn, handles});

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes UImonitoreo wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% UIWAIT makes UImonitoreo wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% UIWAIT makes UImonitoreo wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Executes when user attempts to close UImonitoreo.
function UImonitoreo_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Actualizar handles
handles = guidata(hObject);

% Desconectar el puerto serial si está conectado
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
function varargout = UImonitoreo_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in button_start_monitoreo.
function button_start_monitoreo_Callback(hObject, eventdata, handles)
% hObject    handle to button_start_monitoreo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 's') && isvalid(handles.s)
    fwrite(handles.s, 101, 'uint8'); % Enviar 101 en binario
    disp('Comando de inicio enviado.');
    
    % Reiniciar la gráfica
    handles.graficar = true;
    handles.tiempoInicio = now; % Almacenar el tiempo de inicio
    handles.tiemposTranscurridos = []; % Reiniciar tiempos transcurridos
    handles.magnitudes = []; % Reiniciar magnitudes
    handles.setpoints = []; % Reiniciar setpoints
    handles.tiemposSetpoints = []; % Reiniciar tiempos de setpoints
    
    % Iniciar un temporizador para actualizar la gráfica del setpoint cada 0.256 segundos
    handles.timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.256, ...
                          'TimerFcn', {@updateSetpointGraphMonitoreo, hObject});
    start(handles.timer);
end

% Guardar los cambios en handles
guidata(hObject, handles);

% --- Executes on button press in button_stop_monitoreo.
function button_stop_monitoreo_Callback(hObject, eventdata, handles)
% hObject    handle to button_stop_monitoreo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 's') && isvalid(handles.s)
    fwrite(handles.s, 102, 'uint8'); % Enviar 102 en binario
    disp('Comando de parada enviado.');
    
    % Detener el temporizador
    if isfield(handles, 'timer') && isvalid(handles.timer)
        stop(handles.timer);
        delete(handles.timer);
    end
end

% Guardar los cambios en handles
guidata(hObject, handles);

function updateSetpointGraphMonitoreo(~, ~, hObject)
% Obtener handles actualizados
handles = guidata(hObject);

% Obtener el tiempo actual
tiempoActual = now;

% Calcular el tiempo en segundos desde el inicio
tiempoTranscurrido = (tiempoActual - handles.tiempoInicio) * 24 * 3600; % Convertir días a segundos

% Almacenar los valores de setpoint y tiempo transcurrido
handles.setpoints = [handles.setpoints, handles.setpointValue];
handles.tiemposSetpoints = [handles.tiemposSetpoints, tiempoTranscurrido];

% Actualizar la gráfica en el axes con el tag graph_2
axes(handles.graph_2);
plot(handles.graph_2, handles.tiemposTranscurridos, handles.magnitudes, 'b', ...
     handles.tiemposSetpoints, handles.setpoints, 'r--');
xlabel(handles.graph_2, 'Tiempo (s)');
ylabel(handles.graph_2, 'RPM');
title(handles.graph_2, 'Grafica de RPM vs Tiempo');

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

% Actualizar la grafica en el axes con el tag graph_2
axes(handles.graph_2);
plot(handles.graph_2, handles.tiemposTranscurridos, handles.magnitudes, 'b', ...
     handles.tiemposSetpoints, handles.setpoints, 'r--');
xlabel(handles.graph_2, 'Tiempo (s)');
ylabel(handles.graph_2, 'RPM');
title(handles.graph_2, 'Grafica de RPM vs Tiempo');

% Guardar los cambios en handles
guidata(hObject, handles);

% --- Executes on button press in button_send_monitoreo.
function button_send_monitoreo_Callback(hObject, eventdata, handles)
% hObject    handle to button_send_monitoreo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Obtener el valor del edit_text con el tag input_setpoint_monitoreo
setpointStr = get(handles.input_setpoint_monitoreo, 'String');

% Verificar si el edit_text tiene contenido
if ~isempty(setpointStr)
    % Convertir el valor a numero
    setpointValue = str2double(setpointStr);
    
    % Verificar si la conversion fue exitosa y si esta en el rango 0-100
    if ~isnan(setpointValue) && setpointValue >= 0 && setpointValue <= 100 && mod(setpointValue, 1) == 0
        handles.setpointValue = setpointValue; % Actualizar el valor del setpoint
        
        % Crear la trama de datos
        trama = [255, handles.setpointValue, handles.motorState];
        
        % Mostrar mensaje de depuración
        disp(['Enviando trama: ', num2str(trama)]);
        
        % Enviar la trama de datos por el puerto serial
        fwrite(handles.s, trama, 'uint8');
        
        % Obtener el tiempo actual
        tiempoActual = now;
        
        % Verificar si tiempoInicio está inicializado
        if isempty(handles.tiempoInicio)
            handles.tiempoInicio = tiempoActual;
        end
        
        % Calcular el tiempo en segundos desde el primer dato
        tiempoTranscurrido = (tiempoActual - handles.tiempoInicio) * 24 * 3600; % Convertir dias a segundos
        
        % Almacenar los valores de setpoint y tiempo transcurrido
        handles.setpoints = [handles.setpoints, setpointValue];
        handles.tiemposSetpoints = [handles.tiemposSetpoints, tiempoTranscurrido];
        
        % Mostrar mensaje de confirmacion
        disp(['Valor enviado: ', num2str(setpointValue)]);
        
        % Actualizar la grafica en el axes con el tag graph_2
        if handles.graficar
            axes(handles.graph_2);
            plot(handles.graph_2, handles.tiemposTranscurridos, handles.magnitudes, 'b', ...
                 handles.tiemposSetpoints, handles.setpoints, 'r--');
            xlabel(handles.graph_2, 'Tiempo (s)');
            ylabel(handles.graph_2, 'RPM');
            title(handles.graph_2, 'Grafica de RPM vs Tiempo');
        end
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


function input_setpoint_monitoreo_Callback(hObject, eventdata, handles)
% hObject    handle to input_setpoint_monitoreo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of input_setpoint_monitoreo as text
%        str2double(get(hObject,'String')) returns contents of input_setpoint_monitoreo as a double


% --- Executes during object creation, after setting all properties.
function input_setpoint_monitoreo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to input_setpoint_monitoreo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


