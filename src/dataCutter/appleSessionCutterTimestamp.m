function appleSessionCutterTimestamp()
% This function:
% - creates and saves a file .csv containing the values (time,rate) of
%   AppleWatch related to that specific session. In this case the provided
%   datetimes in the original .csv file are defined as UNIX timestamp

% dialog box to select the session file
[fileSession,pathSession] = uigetfile({'session*.csv','Session'},'Select you session');
if isequal(fileSession,0)
    error('appleSessionCutter: select a valid session file .csv')
end
session = readtable(fullfile(pathSession,fileSession),'VariableNamingRule','preserve'); %to preserve name of columns
if(~(strcmp(session.device1{1,1},'Apple Watch') || strcmp(session.device2{1,1},'Apple Watch'))) % check if Apple is registered for this session
    error('appleSessionCutter: this session is not registered for an AppleWatch')
end

% dialog box to select the AppleWatch file to cut for the session
[fileApple,pathApple] = uigetfile({'*.csv','AppleWatch'},'Select you AppleWatch .csv');
if isequal(fileApple,0)
    error('appleSessionCutter: select a valid AppleWatch file .csv')
end

apple = readtable(fullfile(pathApple,fileApple));
apple = apple(:,{'time','rate','time_zone'});

%Convert to datetime from UNIX timestamp
apple.time = datetime(apple.time,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss');
apple.time = apple.time + hours(apple.time_zone); %adjust datetime with timezone
apple = apple(:,{'time','rate','time_zone'});
apple = table2timetable(apple);

idx_bet = isbetween(apple.time,session.start, session.end); %check where values of time in Apple are between & equal start/end of session
valid = sum(idx_bet==1); %find number of valid entries (marked as 1 if between)
if(valid==0)
    error('appleSessionCutter: no AppleWatch values for the session selected')
end

apple = apple(idx_bet,:);
nameCsv = strcat('applewatch_',num2str(session.iduser),'_',num2str(session.id),'.csv'); %create name of the new .csv file
writetimetable(apple,fullfile(pathSession,nameCsv));
display(strcat('Exported file:',nameCsv));
end

