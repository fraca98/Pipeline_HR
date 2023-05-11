% Sampling frequency mode for each device: determine the most common time step
% across all sessions for each device.
% Then use the largest common time step to resample each data series.

clear
close all
clc

addpath(genpath("src"));
%%
% devices names
devices = {'Apple','Fitbit','Garmin','Withings'};

Polar = [];
Apple = [];
Fitbit = [];
Garmin = [];
Withings = [];
%% Analyze sessions
filePath = matlab.desktop.editor.getActiveFilename; % Get the filepath of the script
projectPath = fileparts(filePath); % Take directory of folder containing filePath
dataPath = fullfile(projectPath,'data'); %path of folder data
data_fd = dir(dataPath);
data_Flags = [data_fd.isdir];
% extract only those that are directories.
users_Dirs = data_fd(data_Flags);

% get only the folder names into a cell array.
users_Dirs = users_Dirs(3:end);

% remove not necessary folders
users_Dirs(startsWith({users_Dirs.name},'Test')) = [];
users_Dirs(startsWith({users_Dirs.name},'AirQuality')) = [];
users_Dirs(startsWith({users_Dirs.name},'Garmin')) = [];
users_Dirs(startsWith({users_Dirs.name},'AppleWatch')) = [];

% sort users alphabetically
[~,ind] = sort(cellfun(@(x) str2num(char(regexp(x,'\d*','match'))),{users_Dirs.name}));
users_Dirs = users_Dirs(ind);
users_DirsNames = {users_Dirs.name};

users_DirsNames = string(users_DirsNames);

% loop in data folder for each user folder (iterate for user)
for idx_user = 1:size(users_DirsNames,2)
    userPath = fullfile(dataPath,users_DirsNames(idx_user));
    user_fd = dir(userPath);
    user_Flags = [user_fd.isdir];
    sessions_Dirs = user_fd(user_Flags);
    sessions_Dirs = sessions_Dirs(3:end); % keep only valid folders

    % sort sessions alphabetically
    [~,ind] = sort(cellfun(@(x) str2num(char(regexp(x,'\d*','match'))),{sessions_Dirs.name}));
    sessions_Dirs = sessions_Dirs(ind);
    sessions_DirsNames = {sessions_Dirs.name};

    sessions_DirsNames = string(sessions_DirsNames);
    sessions_DirsNames(startsWith(sessions_DirsNames,'Questionnaires')) = []; %remove the Questionnaires folder when i iterate sessions

    csvs = dir(fullfile(userPath));
    % get only the folder names into a cell array.
    csv_names = {csvs(3:end).name};
    csv_names = string(csv_names);
    tf_user = startsWith(csv_names,'user');
    user = readtable(fullfile(userPath, csv_names(tf_user)),"VariableNamingRule",'preserve');

    % loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2)
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % get only the folder names into a cell array.
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        tf_intervals = startsWith(csv_names, 'intervals');
        intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)),"VariableNamingRule",'preserve');

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)),"VariableNamingRule",'preserve');
        idx_bet = isbetween(polar.time,intervals.start(1), intervals.end(end)); %use exact intervals
        polar = polar(idx_bet,:);
        Polar = [Polar;polar];      

        for i = 1:length(devices)
            tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
            if(ismember(1,tf) == 1)
                data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),'VariableNamingRule','preserve');
                idx_bet = isbetween(data.time,intervals.start(1), intervals.end(end)); % use exact intervals
                data = data(idx_bet,:);
                switch i
                    case 1
                        Apple = [Apple;data];
                    case 2
                        Fitbit = [Fitbit;data];
                    case 3
                        Garmin = [Garmin;data];
                    case 4
                        Withings = [Withings;data];
                end
            end
        end
    end
end

%% Compute durations and mode
durationPolar = diff(Polar.Properties.RowTimes);
modePolar = mode(durationPolar);

durationApple = diff(Apple.Properties.RowTimes);
modeApple = mode(durationApple);

durationFitbit = diff(Fitbit.Properties.RowTimes);
modeFitbit = mode(durationFitbit);

durationGarmin = diff(Garmin.Properties.RowTimes);
modeGarmin = mode(durationGarmin);

durationWithings = diff(Withings.Properties.RowTimes);
modeWithings = mode(durationWithings);

T=table({'Polar';'Apple';'Fitbit';'Garmin';'Withings'},[modePolar;modeApple;modeFitbit;modeGarmin;modeWithings],'VariableNames',{'Device','Sampling frequency mode'});

milliseconds(T.("Sampling frequency mode"))
