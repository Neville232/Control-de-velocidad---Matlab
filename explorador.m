function varargout = explorador(varargin)
% EXPLORADOR MATLAB code for explorador.fig
%      EXPLORADOR, by itself, creates a new EXPLORADOR or raises the existing
%      singleton*.
%
%      H = EXPLORADOR returns the handle to a new EXPLORADOR or the handle to
%      the existing singleton*.
%
%      EXPLORADOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EXPLORADOR.M with the given input arguments.
%
%      EXPLORADOR('Property','Value',...) creates a new EXPLORADOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before explorador_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to explorador_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help explorador

% Last Modified by GUIDE v2.5 30-Mar-2024 17:51:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @explorador_OpeningFcn, ...
                   'gui_OutputFcn',  @explorador_OutputFcn, ...
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


% --- Executes just before explorador is made visible.
function explorador_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to explorador (see VARARGIN)

% Choose default command line output for explorador
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes explorador wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = explorador_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in boton_exp.
function boton_exp_Callback(hObject, eventdata, handles)
% hObject    handle to boton_exp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ruta = uigetdir('', 'Elige una carpeta');

if ruta ~= 0
    set(handles.label_ruta, 'String', ruta);
else
    set(handles.label_ruta, 'String', 'No se ha seleccionado ninguna carpeta')
end
