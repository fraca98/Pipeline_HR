function garminSessionCutter()
% This function:
% - converts the Garmin column 'timestamp' to 'time' in format
%   datetime 
% - renames column 'heart_rate' to 'rate' and 
% - cuts all the entries for which the time is outside the specified
%   session
% and save the results in the original .csv file

% dialog box to select the session file
[fileSession,pathSession] = uigetfile('session*.csv','Select you session');
if isequal(fileSession,0)
    error('garminSessionCutter: select a valid session file .csv')
end
session = readtable(fullfile(pathSession,fileSession),'VariableNamingRule','preserve'); %to preserve name of columns

% dialog box to select the garmin file
[fileGarmin,pathGarmin] = uigetfile('garmin*.csv','Select you Garmin file');
if isequal(fileGarmin,0)
    error('garminSessionCutter: select a valid Garmin file .csv')
end

garmin = readtable(fullfile(pathGarmin,fileGarmin),'VariableNamingRule','preserve'); %to preserve name of columns
garmin = renamevars(garmin,'timestamp','time');
garmin = renamevars(garmin,'heart_rate','rate');

garmin.time = datetime(datenum(1989,12,31)+(garmin.time/(24*60*60)),'ConvertFrom','datenum'); %convert to datetime from timestamp
% Warning: The FIT Profile defines the date_time type as an uint32 that represents the number of seconds since midnight on December 31, 1989 UTC
% https://developer.garmin.com/fit/cookbook/datetime/
garmin.time = garmin.time + hours(1); %to consider '+01:00' TimeZone without setting it (else set
%everywhere, also in other files the TimeZone for each datetime)

garmin = table2timetable(garmin);

idx_bet = isbetween(garmin.time,session.start, session.end); %check where values of time in Garmin are between & equal start/end of session
valid = sum(idx_bet==1); %find number of valid entries (marked as 1 if between)
if(valid==0)
    error('garminSessionCutter: no Garmin values for the session selected')
end
garmin = garmin(idx_bet,:);
writetimetable(garmin,fullfile(pathGarmin,fileGarmin));
display(strcat('Exported file:',fileGarmin));

end

