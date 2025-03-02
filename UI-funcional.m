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
    
    % Last Modified by GUIDE v2.5 21-Jan-2025 18:48:43
    
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
    handles.data = [];
    handles.time = [];
    handles.magnitudes = [];
    handles.elapsedTimes = [];
    
    % Set the CloseRequestFcn
    set(handles.figure1, 'CloseRequestFcn', {@UI_CloseRequestFcn, handles});
    
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
    function varargout = UI_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    varargout{1} = handles.output;
    
    % --- Executes on button press in button_start.
    function button_start_Callback(hObject, eventdata, handles)
    % hObject    handle to button_start (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    set(handles.label_rpm, 'String', 'Nuevo contenido');
    if isfield(handles, 's') && isvalid(handles.s)
        fwrite(handles.s, 101, 'uint8'); % Enviar 101 en binario
        disp('Comando de inicio enviado.');
    end
    
    % --- Executes on button press in button_stop.
    function button_stop_Callback(hObject, eventdata, handles)
    % hObject    handle to button_stop (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    if isfield(handles, 's') && isvalid(handles.s)
        fwrite(handles.s, 102, 'uint8'); % Enviar 102 en binario
        disp('Comando de parada enviado.');
    end
    
    % --- Executes on button press in button_connet.
    function button_connet_Callback(hObject, eventdata, handles)
    % hObject    handle to button_connet (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Verificar si ya está conectado al puerto serial
    if isfield(handles, 's') && isvalid(handles.s) && strcmp(handles.s.Status, 'open')
        return;
    end
    
    % Configuración del puerto serial
    serialPort = 'COM19'; % Cambia 'COM5' por el puerto que estás utilizando
    baudRate = 9600; % Configura la velocidad en baudios
    
    % Crear objeto serial
    handles.s = serial(serialPort, 'BaudRate', baudRate, 'Terminator', '-'); % Usar '-' como terminador
    
    % Configurar la función de callback para leer datos cuando estén disponibles
    handles.s.BytesAvailableFcnMode = 'terminator';
    handles.s.BytesAvailableFcn = {@serialCallback, hObject};
    
    % Abrir el puerto serial
    fopen(handles.s);
    disp('Puerto serial conectado.');
    % Guardar los cambios en handles
    guidata(hObject, handles);
    
    % --- Executes on button press in button_disconnet.
    function button_disconnet_Callback(hObject, eventdata, handles)
    % hObject    handle to button_disconnet (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    if isfield(handles, 's') && isvalid(handles.s)
        fclose(handles.s);
        delete(handles.s);
        handles = rmfield(handles, 's');
        disp('Puerto serial desconectado.');
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
    data = fscanf(obj);
    
    % Verificar si se recibieron datos
    if isempty(data)
        disp('No se recibieron datos.');
        return;
    end
    
    % Eliminar el terminador '-' del dato recibido
    data = strrep(data, '-', '');
    
    % Convertir el dato a número
    data = str2double(data);
    disp(['Dato recibido: ', num2str(data)]);
    
    % Obtener el tiempo actual
    currentTime = now;
    
    % Si es el primer dato, almacenar el tiempo inicial
    if isempty(handles.elapsedTimes)
        handles.startTime = currentTime;
    end
    
    % Calcular el tiempo en segundos desde el primer dato
    elapsedTime = (currentTime - handles.startTime) * 24 * 3600; % Convertir días a segundos
    
    % Almacenar los valores de magnitud y tiempo transcurrido
    handles.magnitudes = [handles.magnitudes, data];
    handles.elapsedTimes = [handles.elapsedTimes, elapsedTime];
    
    % Verificar la variación de las muestras en el intervalo de tiempo de 3 segundos
    interval = 2; % Intervalo de tiempo en segundos
    variationThreshold = 0.02; % Variación máxima permitida (2%)
    
    % Encontrar las muestras dentro del intervalo de tiempo
    recentIndices = find(handles.elapsedTimes >= (elapsedTime - interval));
    
    if ~isempty(recentIndices)
        recentMagnitudes = handles.magnitudes(recentIndices);
        maxMagnitude = max(recentMagnitudes);
        minMagnitude = min(recentMagnitudes);
        variation = (maxMagnitude - minMagnitude) / maxMagnitude;
    
        if variation <= variationThreshold
            % disp('La variación de las muestras en los últimos 3 segundos es menor o igual al 2%.');
            disp('Se ha alcanzado el establecimiento del sistema.');
            fwrite(handles.s, 102, 'uint8'); % Enviar 102 en binario para detener el proceso
            valorFinalPromedio = mean(recentMagnitudes);
            disp(['Valor final promedio: ', num2str(valorFinalPromedio)]);
            valor63 = 0.63 * valorFinalPromedio;
            
                    % Encontrar el tiempo en el que la magnitud alcanza el 63% del valor final
            index63 = find(handles.magnitudes >= valor63, 1);
            
            if ~isempty(index63)
                constanteTiempo = handles.elapsedTimes(index63);
                disp(['Tiempo en el que la magnitud alcanza el 63%: ', num2str(constanteTiempo)]);
                disp(['Magnitud en el 63%: ', num2str(handles.magnitudes(index63))]);
            else
                % Si no se encuentra el valor, realizar interpolación lineal
                lowerIndex = find(handles.magnitudes < valor63, 1, 'last');
                upperIndex = find(handles.magnitudes > valor63, 1, 'first');
                
                if ~isempty(lowerIndex) && ~isempty(upperIndex)
                    % Interpolación lineal
                    x1 = handles.elapsedTimes(lowerIndex);
                    y1 = handles.magnitudes(lowerIndex);
                    x2 = handles.elapsedTimes(upperIndex);
                    y2 = handles.magnitudes(upperIndex);
                    constanteTiempo = x1 + (valor63 - y1) * (x2 - x1) / (y2 - y1);
                    disp(['Tiempo más cercano inferior: ', num2str(x1)]);
                    disp(['Magnitud más cercana inferior: ', num2str(y1)]);
                    disp(['Tiempo más cercano superior: ', num2str(x2)]);
                    disp(['Magnitud más cercana superior: ', num2str(y2)]);
                else
                    constanteTiempo = NaN; % Si no se puede interpolar, asignar NaN
                end
            end
            
            if ~isnan(constanteTiempo)
                a = 1/constanteTiempo; % El tiempo en el que la magnitud alcanza el 63% del valor final
                K = valorFinalPromedio / valor63;
                disp(['K: ', num2str(K)]);
                disp(['a: ', num2str(a)]);
                disp(['t: ', num2str(constanteTiempo)]);
                disp(['ymax: ', num2str(valorFinalPromedio)]);
                disp(['y63: ', num2str(valor63)]);
    
                set(handles.label_k, 'String', num2str(K));
                set(handles.label_a, 'String', ['s + ', num2str(a)]);
            else
                disp('No se pudo determinar el tiempo en el que la magnitud alcanza el 63% del valor final.');
            end
        else
            % disp('La variación de las muestras en los últimos 3 segundos es mayor al 2%.');
        end
    end
    
    % Actualizar la gráfica en el axes con el tag graph_1
    axes(handles.graph_1);
    plot(handles.graph_1, handles.elapsedTimes, handles.magnitudes);
    xlabel(handles.graph_1, 'Tiempo (s)');
    ylabel(handles.graph_1, 'RPM');
    title(handles.graph_1, 'Grafica de RPM vs Tiempo');
    
    % Guardar los cambios en handles
    guidata(hObject, handles);
    
    
    function input_setpoint_Callback(hObject, eventdata, handles)
    % hObject    handle to input_setpoint (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: get(hObject,'String') returns contents of input_setpoint as text
    %        str2double(get(hObject,'String')) returns contents of input_setpoint as a double
    
    
    % --- Executes during object creation, after setting all properties.
    function input_setpoint_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to input_setpoint (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
    
    % --- Executes on button press in button_send.
    function button_send_Callback(hObject, eventdata, handles)
    % hObject    handle to button_send (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Obtener el valor del edit_text con el tag input_setpoint
    setpointStr = get(handles.input_setpoint, 'String');
    
    % Verificar si el edit_text tiene contenido
    if ~isempty(setpointStr)
        % Convertir el valor a número
        setpointValue = str2double(setpointStr);
        
        % Verificar si la conversión fue exitosa y si está en el rango 0-100
        if ~isnan(setpointValue) && setpointValue >= 0 && setpointValue <= 100 && mod(setpointValue, 1) == 0
            % Convertir el valor a binario
            setpointBinary = uint8(setpointValue);
            
            % Enviar el valor binario por el puerto serial
            fwrite(handles.s, setpointBinary, 'uint8');
            
            % Obtener el tiempo actual
            currentTime = now;
            
            % Si es el primer dato, almacenar el tiempo inicial
            if isempty(handles.elapsedTimes)
                handles.startTime = currentTime;
            end
            
            % Calcular el tiempo en segundos desde el primer dato
            elapsedTime = (currentTime - handles.startTime) * 24 * 3600; % Convertir días a segundos
            
            % Almacenar los valores de magnitud y tiempo transcurrido
            handles.magnitudes = [handles.magnitudes, setpointValue];
            handles.elapsedTimes = [handles.elapsedTimes, elapsedTime];
            
            % Mostrar mensaje de confirmación
            disp(['Valor enviado: ', num2str(setpointValue)]);
        else
            % Mostrar mensaje de error si la conversión falló o el valor no está en el rango
            disp('Error: El valor ingresado no es un número entero válido entre 0 y 100.');
        end
    else
        % Mostrar mensaje de error si el edit_text está vacío
        disp('Error: No se ingresó ningún valor.');
    end
    
    % Guardar los cambios en handles
    guidata(hObject, handles);
    
    % --- Executes on button press in button_show_data.
    function button_show_data_Callback(hObject, eventdata, handles)
    % hObject    handle to button_show_data (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Mostrar los datos de magnitudes y tiempos transcurridos
    disp('Magnitudes:');
    disp(handles.magnitudes);
    
    disp('Tiempos transcurridos (s):');
    disp(handles.elapsedTimes);
    
    % Guardar los cambios en handles
    guidata(hObject, handles);
    