function garminSessionCutter()
% This function:
% - extracts time and heart rate info from a Garmin .Json file
% - cuts all the entries for which the time is outside the specified
%   session
% - save the results in the original .csv file

% dialog box to select the session file
[fileSession,pathSession] = uigetfile({'session*.csv','Session'},'Select you session');
if isequal(fileSession,0)
    error('garminSessionCutter: select a valid session file .csv')
end
session = readtable(fullfile(pathSession,fileSession),'VariableNamingRule','preserve'); %to preserve name of columns
if(~(strcmp(session.device1{1,1},'Garmin') || strcmp(session.device2{1,1},'Garmin'))) % check if Garmin is registered for this session
    error('garminSessionCutter: this session is not registered for an Garmin')
end

% dialog box to select the garmin file
[fileGarmin,pathGarmin] = uigetfile({'*Garmin.json','Garmin'},'Select you Garmin file');
if isequal(fileGarmin,0)
    error('garminSessionCutter: select a valid Garmin file .json')
end

garminT = jsondecode(fileread(fullfile(pathGarmin,fileGarmin)));
%base_offset+offset to get timestamp
garmin = [[garminT.heart_rate.data.offset] + garminT.base_date;[garminT.heart_rate.data.value]]';
%Convert to datetime from UNIX timestamp
time = datetime(garmin(:,1),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss');
garmin = timetable(time,garmin(:,2),'VariableNames',{'rate'});

idx_bet = isbetween(garmin.time,session.start, session.end); %check where values of time in Garmin are between & equal start/end of session
valid = sum(idx_bet==1); %find number of valid entries (marked as 1 if between)
if(valid==0)
    error('garminSessionCutter: no Garmin values for the session selected')
end
garmin = garmin(idx_bet,:);
nameCsv = strcat('garmin_',num2str(session.iduser),'_',num2str(session.id),'.csv'); %create name of csv file created
writetimetable(garmin,fullfile(pathSession,nameCsv));
display(strcat('Exported file:',nameCsv));

end


