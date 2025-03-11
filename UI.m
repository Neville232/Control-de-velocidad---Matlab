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
    
    
    function UI_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    clc;
    % Choose default command line output for UI
    handles.output = hObject;
    global thau_global K_global L_global q0_global q1_global;
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
    handles.estado = 1;
    ylim(handles.graph_1, [0 1500]);
    
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
            handles.motorState = 1; % Iniciar el motor
            trama = [255, handles.setpointValue, handles.motorState]; % Crear la trama de datos
            disp(['Enviando trama: ', num2str(trama)]); % Mensaje de depuración
            fwrite(handles.s, trama, 'uint8'); % Enviar la trama de datos
            disp('Comando de inicio enviado.');
            set(handles.button_stop, 'BackgroundColor', [0.5, 1, 0.5]);
            set(handles.button_start, 'BackgroundColor', [0.94, 0.94, 0.94]);
            
            % Reiniciar la gráfica
            handles.graficar = true;
            handles.tiempoInicio = now; % Almacenar el tiempo de inicio
            handles.tiemposTranscurridos = []; % Reiniciar tiempos transcurridos
            handles.magnitudes = []; % Reiniciar magnitudes
            handles.setpoints = []; % Reiniciar setpoints
            handles.tiemposSetpoints = []; % Reiniciar tiempos de setpoints
            
            % Almacenar el tiempo de inicio del motor
            handles.tiempoInicioMotor = now;
            
            % Iniciar un temporizador para actualizar la gráfica del setpoint cada 0.256 segundos
            handles.timer = timer('ExecutionMode', 'fixedRate', 'Period', 0.256, ...
                                  'TimerFcn', {@updateSetpointGraph, hObject});
            start(handles.timer);
        end
        
        % Guardar los cambios en handles
        guidata(hObject, handles);
    


function updateSetpointGraph(~, ~, hObject)
    % Obtener handles actualizados
    handles = guidata(hObject);
    
    % Obtener el tiempo actual
    tiempoActual = now;
    
    % Calcular el tiempo en segundos desde el inicio
    tiempoTranscurrido = (tiempoActual - handles.tiempoInicio) * 24 * 3600; % Convertir días a segundos
    
    % Almacenar los valores de setpoint y tiempo transcurrido
    if isempty(handles.setpoints)
        handles.setpoints = [0, handles.setpointRPM]; % Iniciar desde 0 si no había un setpoint anterior
        handles.tiemposSetpoints = [0, tiempoTranscurrido];
    else
        handles.setpoints = [handles.setpoints, handles.setpointRPM]; % Usar el setpoint en RPM
        handles.tiemposSetpoints = [handles.tiemposSetpoints, tiempoTranscurrido];
    end
    
    % Actualizar la gráfica en el axes con el tag grafica_1
    axes(handles.graph_1);
    plot(handles.graph_1, handles.tiemposTranscurridos, handles.magnitudes, 'b', ...
         handles.tiemposSetpoints, handles.setpoints, 'r--');
    xlabel(handles.graph_1, 'Tiempo (s)');
    ylabel(handles.graph_1, 'RPM');
    title(handles.graph_1, 'Grafica de RPM vs Tiempo');
    
    
    % Guardar los cambios en handles
    guidata(hObject, handles);


        
    % --- Executes on button press in boton_detener.
    function button_stop_Callback(hObject, eventdata, handles)
    % hObject    handle to boton_detener (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    if isfield(handles, 's') && isvalid(handles.s)
        handles.motorState = 0; % Detener el motor
        trama = [255, handles.setpointValue, handles.motorState]; % Crear la trama de datos
        disp(['Enviando trama: ', num2str(trama)]); % Mensaje de depuración
        fwrite(handles.s, trama, 'uint8'); % Enviar la trama de datos
        disp('Comando de parada enviado.');
        set(handles.button_start, 'BackgroundColor', [0.5, 1, 0.5]);
        set(handles.button_stop, 'BackgroundColor', [0.94, 0.94, 0.94]);
        
        % Detener el temporizador
        if isfield(handles, 'timer') && isvalid(handles.timer)
            stop(handles.timer);
            delete(handles.timer);
        end
    end
    
    % Guardar los cambios en handles
    guidata(hObject, handles);

    
    % --- Executes on button press in boton_conectar.
        function button_connet_Callback(hObject, eventdata, handles)
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
        
        % Cambia de color el boton de iniciar
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
    rpm_actual = str2double(dato);
    disp(['Dato recibido: ', num2str(rpm_actual)]);
    
    % Parámetros del filtro
    alpha = 0.6; % Ajusta este valor según sea necesario
    beta = 0; % Ajusta este valor según sea necesario beta es 0 
    
    % Aplicar el filtro de media de movimiento
    if isfield(handles, 'rpm_anterior') && handles.rpm_anterior ~= 0
        rpm = (beta + 1) * (alpha * rpm_actual + ((1 - alpha) * handles.rpm_anterior));
    else
        rpm = rpm_actual;
    end
    handles.rpm_anterior = rpm; % Actualiza rpm_anterior
    
    % Obtener el tiempo actual
    tiempoActual = now;
    
    % Si es el primer dato, almacenar el tiempo inicial
    if isempty(handles.tiemposTranscurridos)
        handles.tiempoInicio = tiempoActual;
    end
    
    % Calcular el tiempo en segundos desde el primer dato
    tiempoTranscurrido = (tiempoActual - handles.tiempoInicio) * 24 * 3600; % Convertir dias a segundos
    
    % Almacenar los valores de magnitud y tiempo transcurrido
    handles.magnitudes = [handles.magnitudes, rpm];
    handles.tiemposTranscurridos = [handles.tiemposTranscurridos, tiempoTranscurrido];
    
    % Verificar el estado
    if handles.estado == 1
        % Identificación del sistema
        identificarSistema(handles, tiempoTranscurrido, rpm);
    elseif handles.estado == 2
        % Control del sistema
        controlarSistema(handles, tiempoTranscurrido, rpm);
    end
    
    % Actualizar la grafica en el axes con el tag grafica_1
    if handles.graficar
        axes(handles.graph_1);
        plot(handles.graph_1, handles.tiemposTranscurridos, handles.magnitudes, 'b', ...
                handles.tiemposSetpoints, handles.setpoints, 'r--');
        xlabel(handles.graph_1, 'Tiempo (s)');
        ylabel(handles.graph_1, 'RPM');
        title(handles.graph_1, 'Grafica de RPM vs Tiempo');
    end
    set(handles.label_rpm, 'String', [num2str(rpm), ' RPM']);
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
                handles.setpointPorcentaje = porcentaje; % Actualizar el valor del setpoint
                
                % Almacenar el setpoint en RPM para el cálculo de K
                handles.setpointRPM = setpointValue;
                
                % Crear la trama de datos
                trama = [255, handles.setpointPorcentaje, handles.motorState];
                
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
                tiempoTranscurrido = (tiempoActual - handles.tiempoInicio) * 24 * 3600; % Convertir días a segundos
                
                % Almacenar los valores de setpoint y tiempo transcurrido
                if isempty(handles.setpoints)
                    handles.setpoints = [0, setpointValue];
                    handles.tiemposSetpoints = [0, tiempoTranscurrido];
                else
                    handles.setpoints = [handles.setpoints, setpointValue];
                    handles.tiemposSetpoints = [handles.tiemposSetpoints, tiempoTranscurrido];
                end
                
                % Mostrar mensaje de confirmación
                disp(['Valor enviado: ', num2str(setpointValue)]);
                
                % Actualizar la gráfica en el axes con el tag grafica_1
                if handles.graficar
                    axes(handles.graph_1);
                    plot(handles.graph_1, handles.tiemposTranscurridos, handles.magnitudes, 'b', ...
                         handles.tiemposSetpoints, handles.setpoints, 'r--');
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

function identificarSistema(handles, tiempoTranscurrido, rpm)
    global thau_global K_global L_global;
    % Verificar la variacion de las muestras en el intervalo de tiempo de 3 segundos
    intervalo = 10; % Intervalo de tiempo en segundos
    umbralVariacion = 0.02; % Variacion maxima permitida (2%)
    
    % Encontrar las muestras dentro del intervalo de tiempo
    indicesRecientes = find(handles.tiemposTranscurridos >= (tiempoTranscurrido - intervalo));
    
    if ~isempty(indicesRecientes)
        magnitudesRecientes = handles.magnitudes(indicesRecientes);
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
            handles.setpointValue = 0; % Inicializar el valor del setpoint
            handles.motorState = 0; % Inicializar el estado del motor (0: detenido, 1: iniciado)
            handles.graficar = false;
            trama = [255, 0, 0]; % Trama de datos específica FF 00 00 en hexadecimal
            fwrite(handles.s, trama, 'uint8');
            disp('Motor detenido y gráfica detenida.');
            
            x = handles.tiemposTranscurridos;
            y = handles.magnitudes;
            constanteTiempo63 = csapi(y, x, valor63);
            disp(['Tiempo interpolado para 63%: ', num2str(constanteTiempo63)]);
            
            % Si no se encuentra el valor, realizar interpolacion con csapi
            x = handles.tiemposTranscurridos;
            y = handles.magnitudes;
            constanteTiempo283 = csapi(y, x, valor283);
            disp(['Tiempo interpolado para 28.3%: ', num2str(constanteTiempo283)]);
            
            if ~isnan(constanteTiempo63) && ~isnan(constanteTiempo283)
                t63 = constanteTiempo63; % El tiempo en el que la magnitud alcanza el 63% del valor final
                t283 = constanteTiempo283; % El tiempo en el que la magnitud alcanza el 28.3% del valor final
                K = valorFinalPromedio / handles.setpointRPM; % Usar el setpoint almacenado en RPM como K
                disp(['K: ', num2str(K)]);
                disp(['t63: ', num2str(t63)]);
                disp(['t283: ', num2str(t283)]);
                
                % Calcular thau y L
                thau = 1.5 * (t63 - t283);
                L = t63 - thau;
                
                % Guardar los valores en las variables globales
                thau_global = thau;
                K_global = K;
                L_global = L;
                
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
                handles.estado = 2;
                
                % Guardar los cambios en handles
                guidata(handles.figure1, handles);
            
            else
                disp('No se pudo determinar el tiempo en el que la magnitud alcanza el 63% o el 28.3% del valor final.');
            end
        else
            % disp('La variacion de las muestras en los ultimos 3 segundos es mayor al 2%.');
        end
    end


function controlarSistema(handles, tiempoTranscurrido, rpm)
    % Aquí puedes implementar la lógica para el control del sistema
    % Por ejemplo, actualizar la gráfica con los datos de control
    disp('Controlando el sistema...');
    % Actualizar la gráfica en el axes con el tag grafica_1
    if handles.graficar
        axes(handles.graph_1);
        plot(handles.graph_1, handles.tiemposTranscurridos, handles.magnitudes, 'b', ...
             handles.tiemposSetpoints, handles.setpoints, 'r--');
        xlabel(handles.graph_1, 'Tiempo (s)');
        ylabel(handles.graph_1, 'RPM');
        title(handles.graph_1, 'Grafica de RPM vs Tiempo controlada');
    end

    
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
            global thau_global K_global L_global q0_global q1_global;
            
            % Asegurarse de que los valores de thau, K y L estén disponibles
            if ~isempty(thau_global) && ~isempty(K_global) && ~isempty(L_global)
                thau = thau_global;
                K = K_global;
                L = L_global;
                muestreo = 0.256;
        
                % Calcular los parámetros del controlador
                Kc = 0.9 * thau / (K * L);
                ti = 3.33 * L;
        
                % Asegurarse de que ti es un escalar
                if isscalar(ti)
                    q0_global = Kc * (1 + (muestreo / (2 * ti)));
                    q1_global = -Kc * (1 - (muestreo / (2 * ti)));
                    q0 = q0_global;
                    q1 = q1_global;
        
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
        



function controlar_Callback(hObject, eventdata, handles)
    global thau_global K_global L_global q0_global q1_global;
    
    % Asegurarse de que los valores de thau, K y L estén disponibles
    if ~isempty(thau_global) && ~isempty(K_global) && ~isempty(L_global)
        % Definir el tiempo de muestreo en segundos
        tiempoMuestreo = 0.256; % Ajusta este valor según sea necesario
        
        u_anterior = 0;
        error_anterior = handles.setpointRPM;

        % Crear el temporizador
        handles.timerControl = timer('ExecutionMode', 'fixedRate', 'Period', tiempoMuestreo, ...
                                     'TimerFcn', {@ejecutarControl, hObject});
        
        % Iniciar el temporizador
        start(handles.timerControl);
        
        % Cambiar el color del botón para indicar que está activo
        set(handles.controlar, 'BackgroundColor', [0.5, 1, 0.5]);
        
        % Guardar los cambios en handles
        guidata(hObject, handles);
    else
        disp('Error: Los valores de thau, K y L no están disponibles.');
    end



function ejecutarControl(~, ~, hObject)
    global q0_global q1_global;
    
    % Obtener handles actualizados
    handles = guidata(hObject);
    
    % Obtener el último valor de magnitudes
    if ~isempty(handles.magnitudes)
        rpm_actual = handles.magnitudes(end);
    else
        rpm_actual = 0;
    end
    
    % Obtener el último valor de setpointRPM
    if ~isempty(handles.setpointRPM)
        setpoint_actual = handles.setpointRPM(end);
    else
        setpoint_actual = 0;
    end
    
    % Obtener los valores anteriores de error y control
    if isfield(handles, 'error_anterior')
        error_anterior = handles.error_anterior;
    else
        error_anterior = 0;
    end
    
    if isfield(handles, 'u_anterior')
        u_anterior = handles.u_anterior;
    else
        u_anterior = 0;
    end
    
    % Calcular el error actual
    error_actual = setpoint_actual - rpm_actual;
    
    % Obtener los valores de q0 y q1
    q0 = q0_global;
    q1 = q1_global;
    
    % Calcular el control actual
    u_actual = u_anterior + (q0 * error_actual) + (q1 * error_anterior);
    
    % Asegurarse de que u_actual esté en el rango permitido (0-100%)
    u_actual = max(0, min(100, u_actual));
    
    % Actualizar los valores anteriores
    handles.u_anterior = u_actual;
    handles.error_anterior = error_actual;
    
    % Enviar el valor de control al motor
    trama = [255, round(u_actual), handles.motorState];
    fwrite(handles.s, trama, 'uint8');
    
    % Guardar los cambios en handles
    guidata(hObject, handles);

