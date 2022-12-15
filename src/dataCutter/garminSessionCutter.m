function garminSessionCutter()
% This function:
% - creates and saves a file .csv containing the values (time,rate) of
%   Garmin related to that specific session
% - manages if the input Garmin file has .csv or .json extension

% dialog box to select the session file
[fileSession,pathSession] = uigetfile({'session*.csv','Session'},'Select you session');
if isequal(fileSession,0)
    error('garminSessionCutter: select a valid session file .csv')
end
session = readtable(fullfile(pathSession,fileSession),'VariableNamingRule','preserve'); %to preserve name of columns
if(~(strcmp(session.device1{1,1},'Garmin') || strcmp(session.device2{1,1},'Garmin'))) % check if Garmin is registered for this session
    error('garminSessionCutterCsv: this session is not registered for Garmin')
end

% dialog box to select the garmin file
[fileGarmin,pathGarmin] = uigetfile({'*.csv;','csv';'*.json','Json'},'Select you Garmin file');
if isequal(fileGarmin,0)
    error('garminSessionCutter: select a valid Garmin file .csv')
end
[~,~,ext] = fileparts(fileGarmin);

if(strcmp(ext,'.json')) %Json
    garminT = jsondecode(fileread(fullfile(pathGarmin,fileGarmin)));
    %base_offset+offset to get timestamp
    garmin = [[garminT.heart_rate.data.offset] + garminT.base_date;[garminT.heart_rate.data.value]]';
    %Convert to datetime from UNIX timestamp
    time = datetime(garmin(:,1),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss');
    garmin = timetable(time,garmin(:,2),'VariableNames',{'rate'});

elseif(strcmp(ext,'.csv'))
    %csv
    garmin = readtable(fullfile(pathGarmin,fileGarmin),'VariableNamingRule','preserve'); %to preserve name of columns
    garmin = renamevars(garmin,'timestamp','time');
    garmin = renamevars(garmin,'heart_rate','rate');

    garmin.time = datetime(datenum(1989,12,31)+(garmin.time/(24*60*60)),'ConvertFrom','datenum'); %convert to datetime from timestamp
    % Warning: The FIT Profile defines the date_time type as an uint32 that represents the number of seconds since midnight on December 31, 1989 UTC
    % https://developer.garmin.com/fit/cookbook/datetime/
    garmin.time = garmin.time + hours(1); %to consider '+01:00' TimeZone without setting it (else set
    %everywhere, also in other files the TimeZone for each datetime)
    garmin = table2timetable(garmin);

else
    error('garminSessionCutter: no Garmin extension file recognized for the session selected')
end
garmin = garmin(:,{'rate'});
idx_bet = isbetween(garmin.time,session.start, session.end); %check where values of time in Garmin are between & equal start/end of session
valid = sum(idx_bet==1); %find number of valid entries (marked as 1 if between)
if(valid==0)
    error('garminSessionCutter: no Garmin values for the session selected')
end
garmin = garmin(idx_bet,:);
writetimetable(garmin,fullfile(pathSession,sprintf("garmin_%d_%d.csv",session.iduser,session.id)));
display(strcat('Exported file:',sprintf("garmin_%d_%d.csv",session.iduser,session.id)));

end
