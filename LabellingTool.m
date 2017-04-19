%% GUI I/O
function varargout = LabellingTool(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @LabellingTool_OpeningFcn, ...
    'gui_OutputFcn',  @LabellingTool_OutputFcn, ...
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
end
%--------------------------------------------------------------------------

function varargout = LabellingTool_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;
end
%--------------------------------------------------------------------------

function figure1_CloseRequestFcn(hObject, eventdata, handles)
%verify the person actually wants to close
choice = questdlg('Are you sure you want to exit?', ...
    'Exit', ...
    'Yes','No','No');
switch choice
    case 'Yes'
        delete(hObject);
    case 'No'
        return;
    otherwise
        disp('Not supposed to be here');
end
end
%--------------------------------------------------------------------------

function LabellingTool_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject; clc; zoom on;

%Set cursor properties
dcm = datacursormode(hObject);
set(dcm,'DisplayStyle','datatip','Enable','off','UpdateFcn',@onDCM);
set(0,'showhiddenhandles','on');
handles.hObject = hObject;

%initialize handles properties
handles.dcm         = dcm;
handles.filename    = [];
handles.pathname    = [];
handles.dataText    = [];
handles.time        = [];
handles.serialTimes = [];
handles.markerLine1 = [];
handles.markerLine2 = [];
handles.markerNext  = [];
handles.xlimits     = [];
handles.ylimits     = [];
handles.marker1     = 0;
handles.marker2     = 0;
handles.N           = [];
handles.markerTypes = {'.','+','o','*','x','s','d','^','v','>','<','p','h'};
handles.colors      = {...
    [237/255  28/255  36/255],...%red
    [ 33/255  64/255 154/255],...%blue
    [242/255 101/255  34/255],...%orange
    [255/255 222/255  23/255],...%yellow
    [  0/255 161/255  75/255],...%green
    [127/255  63/255 152/255]};  %purple
handles.colors      = repmat(handles.colors,1,4); %can use up to 24 labels

%create list for data labels
label1List = {'Walking AD','Walking No AD','Sit2Stand','Stand2Sit','Sit','Stand','Turning','Misc','Unknown'};
label2List = {'NA','6MWT','10MWT','TUG','BBS'};
set(handles.popupmenuLabel1,'string',label1List);
set(handles.popupmenuLabel2,'string',label2List);
set(0,'showhiddenhandles','on');

%set time to be relative
handles.timeAxis = 'Relative';

%update gui
guidata(hObject, handles);
end

%% Callback Functions
function buttonLoad_Callback(hObject, eventdata, handles)

%if a file is loaded, check to see if you want new file
if ~isempty(handles.filename)
    choice = questdlg('Are you sure you want to load a new file?', ...
        'Exit', ...
        'Yes','No','No');
    switch choice
        case 'Yes'
            %continue down below;
        case 'No'
            return; %don't overwrite anything
    end
end
%choose file
[filename,pathname] = uigetfile('*');
if filename == 0
    return; %empty file
end

%progress bar
wbar = waitbar(.25,'Loading data file');

%load file
try
[N,~,~] = xlsread([pathname,filename]); cla; hold on;
catch e
    errordlg('Unable to read file');
    delete(wbar);
    return;
end
waitbar(.5,wbar,sprintf('Initializing variables'));

%initialize variables
handles.data     = [];
handles.filename = filename(1:end-4);
handles.pathname = pathname;

%show file that is loaded on screen
set(handles.textFileLoaded,'string',[handles.filename,'.csv']);

%get the timestamp
out = regexp(handles.filename,'_','split');

%check and make sure file name is in proper format for conversion
serialTimes = [];
if length(out) == 9
    dateStr  = [out{2} '-' out{3} '-' out{4} ' ' out{5} ':' out{6} ':' out{7} '.' out{8}];
    formatIn   = 'mm-dd-yyyy HH:MM:SS.FFF';
    try
        serialTimes = relativeTime2SerialTime(dateStr,N(:,1),formatIn);
        
    catch
        serialTimes = [];
    end
end

%plot our signals, assume 1st column: time, 2-4 cols: tri-axial data
waitbar(.75,wbar,sprintf('Plotting data'));
zoom out;

%manage buttons to convert times
if isempty(serialTimes)
    set(handles.radiobuttonRelativeTime,'value',1);
    set(handles.radiobuttonAbsoluteTime,'enable','off');
else
    set(handles.radiobuttonAbsoluteTime,'enable','on');
end

if get(handles.radiobuttonRelativeTime,'value')
    time = N(:,1);
    plot(handles.mainAxes,time,N(:,2:4));
elseif get(handles.radiobuttonAbsoluteTime,'value')
    plot(handles.mainAxes,serialTimes,N(:,2:4));
    axes(handles.mainAxes); datetick('x');
else
    errordlg('Not sure how you got here, error with time buttons');
end
set(handles.mainAxes,'xminortick','on');

%create some space for labels in the data matrix
col = size(N,2);
handles.label1Index = col + 1;
handles.label2Index = col + 2;
N(:,handles.label1Index) = 0;
N(:,handles.label2Index) = 0;

%get the data
handles.data = N;
handles.time = time;
handles.serialTimes = serialTimes;

%get the default limits from plotting
handles.ylimits = get(handles.mainAxes,'ylim');
handles.xlimits = get(handles.mainAxes,'xlim');

%initialize marker lines and update functions
handles.markerLine1 = [];
handles.markerLine2 = [];
set(handles.dcm,'DisplayStyle','datatip','Enable','off','UpdateFcn',@onDCM);
if get(handles.radioLabel,'value');
    set(handles.dcm,'DisplayStyle','datatip','Enable','on','UpdateFcn',@onDCM);
end
delete(wbar);
guidata(hObject,handles);
end
%--------------------------------------------------------------------------

function buttonLabel_Callback(hObject, eventdata, handles)

%apply labels to the selected range
hold on;
if handles.marker2 > handles.marker1
    m1 = handles.marker1;
    m2 = handles.marker2;
else
    m1 = handles.marker2;
    m2 = handles.marker1;
end

%get the currently selected labels
label1Select = get(handles.popupmenuLabel1,'value');
label2Select = get(handles.popupmenuLabel2,'value');

%apply the labels
handles.data(m1:m2,handles.label1Index) = label1Select;
handles.data(m1:m2,handles.label2Index) = label2Select;

%check whether we need x axis in relative or clock time
if get(handles.radiobuttonRelativeTime,'value')
    x = handles.time(m1:m2);
elseif get(handles.radiobuttonAbsoluteTime,'value')
    x = handles.serialTimes(m1:m2);
else
   errordlg('plotting should not be here applying labels'); 
   return;
end
xlim = get(handles.mainAxes,'xlim');
ylim = get(handles.mainAxes,'ylim');

%plot over current plot with a solid color indicating it is labelled
plot(handles.mainAxes,x,handles.data(m1:m2,2:4),'color',handles.colors{label1Select})
%     'marker',handles.markerTypes{label2Select},'MarkerSize',1);
set(handles.mainAxes,'xlim',xlim,'ylim',ylim);
set(handles.mainAxes,'xminortick','on');
guidata(hObject,handles);
end
%--------------------------------------------------------------------------


function buttonExport_Callback(hObject, eventdata, handles)

%filename for exported file
file = [handles.pathname,handles.filename,'_labelled.xlsx'];

%retrieve label lists and form a matrix to store data to write
label1List = get(handles.popupmenuLabel1,'string');
label2List = get(handles.popupmenuLabel2,'string');
dataMatrix    = cell(size(handles.data,1),size(handles.data,2)+4);
unlabeledNotice = 0;

%fill in the data
for i = 1:size(handles.data,1)
    %time / X / Y / Z 
    dataMatrix{i,1} = handles.data(i,1);
    dataMatrix{i,2} = handles.data(i,2);
    dataMatrix{i,3} = handles.data(i,3);
    dataMatrix{i,4} = handles.data(i,4);

    %add columns for labels, filling in 'Not labeled' for unassigned vals
    if handles.data(i,handles.label1Index) == 0
        unlabeledNotice = 1;
        dataMatrix{i,5} = 'Not labeled';
        dataMatrix{i,6} = 'Not labeled';
    else
        dataMatrix{i,5} = label1List{handles.data(i,handles.label1Index)};
        dataMatrix{i,6} = label2List{handles.data(i,handles.label2Index)};
    end
end

%write file
startRow = '1';
startCol = 'A';
[endRow, endCol] = size(handles.data);
endRow = num2str(endRow);
ABCstring = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
endCol = ABCstring(endCol);
rangeStr = [startCol startRow ':' endCol endRow];
xlswrite(file,dataMatrix,rangeStr);

%messages for user
if ~unlabeledNotice
    msgbox(['Finished exporting file: ',file],'File Exported');
else
    messageString{1} = ['Finished exporting file: ',file];
    messageString{2} = '';
    messageString{3} = ['There are unlabeled points in your file.'];
    msgbox(messageString,'File Exported','warn');
end
end
%--------------------------------------------------------------------------

function buttonFillGaps_Callback(hObject, eventdata, handles)

%cancel if no data
if handles.data == 0
    return;
end

%get data and indices
N = handles.data;
label1Index = handles.label1Index;
label2Index = handles.label2Index;
fillStart = 0;

%check whether we need x axis in relative or clock time
if get(handles.radiobuttonRelativeTime,'value')
    x = handles.time;
elseif get(handles.radiobuttonAbsoluteTime,'value')
    x = handles.serialTimes;
else
   errordlg('plotting should not be here applying labels'); 
   return;
end

%cycle through all data
for i = 1:size(N,1)
    
    %if we have unlabelled data start fill flag
    if N(1,label1Index) == 0
        fillStart = 1;
    end
    
    %we have been filling but then run into next area of labelled data
    if fillStart == 1 && N(i,label1Index) ~= 0
        N(1:i,label1Index) =  N(i,label1Index);
        N(1:i,label2Index) =  N(i,label2Index);
        
        %reset fill flag
        fillStart = 0;
        
        %store current label to label future data
        lastLabel1Value = N(i,label1Index);
        lastLabel2Value = N(i,label2Index);
        
        %update plots with new labels
        plot(handles.mainAxes,x(1:i),handles.data(1:i,2:4),'color',handles.colors{N(i,label1Index)});
%             'marker',handles.markerTypes{N(i,label2Index)},...
%             'MarkerSize',1);
        
    %start new filling if we run into unlabeled data
    elseif (N(i,label1Index) == 0 && fillStart == 0)
        
        %apply new labels to unlabelled data
        N(i,label1Index) = lastLabel1Value;
        N(i,label2Index) = lastLabel2Value;
        plot(handles.mainAxes,x(i-1:i),handles.data(i-1:i,2:4),'color',handles.colors{N(i,label1Index)});%             'marker',handles.markerTypes{N(i,label2Index)},...
%             'MarkerSize',1);

    %fill in label
    else
        lastLabel1Value = N(i,label1Index);
        lastLabel2Value = N(i,label2Index);
    end
end

%update our data store
handles.data = N;
guidata(hObject,handles);
msgbox('Finished Filling Gaps');
end
%--------------------------------------------------------------------------


function varargout = buttonMark1_Callback(hObject, eventdata, handles)
if isempty(handles.dataText)
    return;
end
pos = handles.dataText;
if get(handles.radiobuttonRelativeTime,'value')
    x = ones(2,1)*handles.time(pos(1));
elseif get(handles.radiobuttonAbsoluteTime,'value')
    x = ones(2,1)*handles.serialTimes(pos(1));
end
handles.marker1 = pos(1);
hold on
if(~isempty(handles.markerLine1))
    delete(handles.markerLine1)
end
xlim = get(handles.mainAxes,'xlim');
ylim = get(handles.mainAxes,'ylim');
handles.markerLine1 = plot(handles.mainAxes,x,handles.ylimits,'k','linewidth',3);
if get(handles.radiobuttonAbsoluteTime,'value')
    datetick('x');
end
set(handles.mainAxes,'xlim',xlim,'ylim',ylim);
set(handles.mainAxes,'xminortick','on');
varargout{1} = handles;
guidata(hObject,handles);
end
%--------------------------------------------------------------------------

function varargout = buttonMark2_Callback(hObject, eventdata, handles)
if isempty(handles.dataText)
    return;
end
pos = handles.dataText;
if get(handles.radiobuttonRelativeTime,'value')
    x = ones(2,1)*handles.time(pos(1));
elseif get(handles.radiobuttonAbsoluteTime,'value')
    x = ones(2,1)*handles.serialTimes(pos(1));
end
handles.marker2 = pos(1);
hold on
if(~isempty(handles.markerLine2))
    delete(handles.markerLine2)
end
xlim = get(handles.mainAxes,'xlim');
ylim = get(handles.mainAxes,'ylim');
handles.markerLine2 = plot(handles.mainAxes,x,handles.ylimits,'m','linewidth',3);
if get(handles.radiobuttonAbsoluteTime,'value')
    datetick('x');
end
set(handles.mainAxes,'xlim',xlim,'ylim',ylim);
set(handles.mainAxes,'xminortick','on');
varargout{1} = handles;
guidata(hObject,handles);
end
%--------------------------------------------------------------------------

function buttonMarkNext_Callback(hObject, eventdata, handles)

if isempty(handles.dataText)
    return
end

if isempty(handles.markerNext)
    handles.markerNext = 1;
elseif isempty(handles.markerLine1) && ~isempty(handles.markerLine2)
    handles.markerNext = 1;
elseif ~isempty(handles.markerLine1) && isempty(handles.markerLine2)
    handles.markerNext = 2;
end

if handles.markerNext == 1
    output = buttonMark1_Callback(handles.buttonMark1,eventdata,handles);
    handles = output;
    handles.markerNext = 2;
elseif handles.markerNext == 2
    output = buttonMark2_Callback(handles.buttonMark2,eventdata,handles);
    handles = output;
    handles.markerNext = 1;
else
    disp('Unknown "Next Marker" condition"');
end
guidata(hObject, handles);
end
%--------------------------------------------------------------------------

function panelModes_SelectionChangeFcn(hObject, eventdata, handles)
currentlySelected = eventdata.NewValue;
switch currentlySelected
    case handles.radioZoomIn
        pan off;
        set(handles.dcm,'Enable','off');
        zoom on;
    case handles.radioZoomOut
        pan off;
        set(handles.dcm,'Enable','off');
        zoom out;
        zoom off
    case handles.radioPan
        set(handles.dcm,'Enable','off');
        zoom off;
        pan on;
    case handles.radioLabel
        zoom off;
        pan off;
        set(handles.dcm,'DisplayStyle','datatip','Enable','on','UpdateFcn',@onDCM);
    otherwise
        zoom off;
        pan off;
        set(handles.dcm,'Enable','off');
end
end
%--------------------------------------------------------------------------

function output_txt = onDCM(~,eventObj)
%get the position of the cursor
pos = get(eventObj,'Position');

%get the handles from root figure
h = groot;
handles = guidata(h.CurrentFigure);

if get(handles.radiobuttonRelativeTime,'value')
    handles.dataText = find(handles.time==pos(1));
elseif get(handles.radiobuttonAbsoluteTime,'value')
    handles.dataText = find(handles.serialTimes==pos(1));
else
    errordlg('No button selected when trying to find time pos');
end

%create text to write next to cursor
output_txt{1,1} = num2str(pos(1));

%initialize counter to display additional information
count = 2;
x = handles.dataText;
if size(handles.data,2) == handles.label2Index
    
    %add label 1 if it exists
    if ~(handles.data(x,handles.label1Index) == 0)
        label1List = get(handles.popupmenuLabel1,'string');
        output_txt{count,1} = label1List{handles.data(x,handles.label1Index)};
        count = count + 1;
    end
    
    %add label 2 if it exists
    if ~(handles.data(x,handles.label2Index) == 0)
        label2List = get(handles.popupmenuLabel2,'string');
        output_txt{count,1} = label2List{handles.data(x,handles.label2Index)};
    end
end
guidata(h.CurrentFigure,handles);
end
%--------------------------------------------------------------------------

function uibuttongroupTimeAxis_SelectionChangedFcn(hObject, eventdata, handles)
handles.timeAxis = eventdata.NewValue;
if(~isempty(handles.markerLine1))
    delete(handles.markerLine1)
    handles.markerLine1 = [];
end
if(~isempty(handles.markerLine2))
    delete(handles.markerLine2)
    handles.markerLine2 = [];
end
handles.mainAxes; hold off;
switch handles.timeAxis
    case handles.radiobuttonRelativeTime
        if ~isempty(handles.time) && ~isempty(handles.data)
            plot(handles.mainAxes,handles.time,handles.data(:,2:4)); hold on;
            applyExistingLabels(hObject,handles);
            set(handles.mainAxes,'xminortick','on');
        end
    case handles.radiobuttonAbsoluteTime
        if ~isempty(handles.serialTimes) && ~isempty(handles.data)
            plot(handles.mainAxes,handles.serialTimes,handles.data(:,2:4)); hold on;
            applyExistingLabels(hObject,handles)
            axes(handles.mainAxes); datetick('x');
            set(handles.mainAxes,'xminortick','on');
        end
    otherwise
        errordlg('Error in time selection changed panel');
end
%APPLY LABEL COLORS
end
%--------------------------------------------------------------------------

%% Helper functions
function serialTime = relativeTime2SerialTime(startTimeStamp,relativeTime,formatIn)

dateNum    = datenum(startTimeStamp,formatIn);
serialTime = zeros(length(relativeTime),1);

for i = 1:length(relativeTime)
    try
        secs            = regexp(num2str(relativeTime(i)),'\.','split');
        serialTime(i,1) = addtodate(dateNum,str2double(secs{1}),'second');
        if length(secs) > 1
            if length(secs{2}) == 1
                serialTime(i,1) = addtodate(serialTime(i,1),str2double(secs{2})*100,'millisecond');
            elseif length(secs{2}) == 2
                serialTime(i,1) = addtodate(serialTime(i,1),str2double(secs{2})*10,'millisecond');
            elseif length(secs{2}) == 3
                serialTime(i,1) = addtodate(serialTime(i,1),str2double(secs{2})*1,'millisecond');
            end
        else
            serialTime(i,1) = addtodate(serialTime(i,1),str2double('000'),'millisecond');
        end
    catch
        errordlg('Error converting to serial time');
        return;
    end
end
end

function applyExistingLabels(hObject,handles)

%get data for y and x axes
N      = handles.data;
labels = N(:,handles.label1Index);
if get(handles.radiobuttonRelativeTime,'value')
    x = handles.time;
elseif get(handles.radiobuttonAbsoluteTime,'value')
    x = handles.serialTimes;
else
   errordlg('plotting should not be here applying labels'); 
   return;
end

%cycle through data and plot colored segment for each piece of data
currentLabel = labels(1);
if currentLabel ~= 0
    startInd = 1;
else
    startInd = [];
end
for i = 1:length(x)
    lastLabel = currentLabel;
    currentLabel = labels(i);
    
    if currentLabel == lastLabel
        if currentLabel ~=0 && i == length(x)
            plot(handles.mainAxes,x(startInd:end),handles.data(startInd:end,2:4),'color',handles.colors{N(i-1,handles.label1Index)});
%                 'marker',handles.markerTypes{N(i-1,handles.label2Index)},'MarkerSize',1);
        else
            continue;
        end
    else
        %last label was valid, plot it
        if lastLabel ~= 0
            plot(handles.mainAxes,x(startInd:i-1),handles.data(startInd:i-1,2:4),'color',handles.colors{N(i-1,handles.label1Index)});
%                 'marker',handles.markerTypes{N(i-1,handles.label2Index)},'MarkerSize',1);
        end
    end
    
    if currentLabel == 0
        startInd = [];
    else
        startInd = i;
    end
end
end




%% Empty functions for GUI Graphics
function mainAxes_ButtonDownFcn(hObject, eventdata, handles)
end
function editLabel1_Callback(hObject, eventdata, handles)
end
function editLabel1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function editLabel2_Callback(hObject, eventdata, handles)
end
function editLabel2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenuLabel1_Callback(hObject, eventdata, handles)
end
function popupmenuLabel1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
function popupmenuLabel2_Callback(hObject, eventdata, handles)
end
function popupmenuLabel2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end
%%
