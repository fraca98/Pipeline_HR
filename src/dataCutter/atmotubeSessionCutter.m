function atmotubeSessionCutter()
% This function:
% - creates and saves a file .csv containing the values (time,rate) of
%   Garmin related to that specific session (-/+10 seconds start/end)
% - manages if the input Garmin file has .csv or .json extension

% dialog box to select the session file 
[fileSession,pathSession] = uigetfile({'session*.csv','Session'},'Select you session');
if isequal(fileSession,0)
    error('atmotubeSessionCutter: select a valid session file .csv')
end
session = readtable(fullfile(pathSession,fileSession),'VariableNamingRule','preserve'); %to preserve name of columns

% dialog box to select the atmotube(AirQuality) file
[fileAtmo,pathAtmo] = uigetfile({'*.csv;','Atmotube'},'Select you Atmotube .csv file');
if isequal(fileAtmo,0)
    error('atmotubeSessionCutter: select a valid Garmin file .csv')
end

atmo = readtimetable(fullfile(pathAtmo,fileAtmo),'VariableNamingRule','preserve'); %to preserve name of columns
    
idx_bet = isbetween(atmo.Date,session.start-seconds(10), session.end+seconds(10)); %check where values of time are between & equal start/end of session
valid = sum(idx_bet==1); %find number of valid entries (marked as 1 if between)
if(valid==0)
    error('atmotubeSessionCutter: no values for the session found')
end
atmo = atmo(idx_bet,:);
atmo = sortrows(atmo); %sorting rows
writetimetable(atmo,fullfile(pathSession,sprintf("atmotube_%d_%d.csv",session.iduser,session.id)));
display(strcat('Exported file:',sprintf("atmotube_%d_%d.csv",session.iduser,session.id)));

end

