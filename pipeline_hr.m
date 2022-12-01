clear
close all
clc

%%
% devices names
devices = {'Fitbit','Apple','Withings','Garmin'};

% color to plot devices
colors = {'blue','black','green','magenta'};

%% Plot original data for user
filePath = matlab.desktop.editor.getActiveFilename; % Get the filepath of the script
projectPath = fileparts(filePath); % Take directory of folder containing filePath
dataPath = fullfile(projectPath,'data'); %path of folder data
data_fd = dir(dataPath);
data_Flags = [data_fd.isdir];
% extract only those that are directories.
users_Dirs = data_fd(data_Flags);

% get only the folder names into a cell array.
users_DirsNames = {users_Dirs(3:end).name};

users_DirsNames = string(users_DirsNames);
% remove not necessary folders
users_DirsNames(startsWith(users_DirsNames,'Test')) = [];
users_DirsNames(startsWith(users_DirsNames,'AirQuality')) = [];
users_DirsNames(startsWith(users_DirsNames,'Garmin')) = [];
users_DirsNames(startsWith(users_DirsNames,'AppleWatch')) = [];

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
    
    figure()
    sgtitle('idUser '+ users_DirsNames(idx_user))

    % loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2)
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % get only the folder names into a cell array.
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        subplot(2,1,idx_session),hold on

        tf_session = startsWith(csv_names, 'session');
        session = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_session)),"VariableNamingRule",'preserve');
        % shift to seconds without milliseconds (start)
        session.start = dateshift(session.start, 'start', 'second');
        session.end = dateshift(session.end, 'start', 'second');

        tf_intervals = startsWith(csv_names, 'intervals');
        intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)),"VariableNamingRule",'preserve');
        % shift to seconds without milliseconds (start)
        intervals.start = dateshift(intervals.start, 'start', 'second');
        intervals.end = dateshift(intervals.end, 'start', 'second');

        % color from start session to first interval
        x_fill=[session.start,session.start,intervals.start(1),intervals.start(1)];
        y_fill=[0,250,250,0];
        a = fill(x_fill,y_fill,'yellow','HandleVisibility','off');
        a.FaceAlpha = 0.5;

        % plot vertical line for end session (end last interval)
        xline(session.end,'HandleVisibility','off');

        % color each interval
        for k=1:size(intervals,2)-1
            x_fill=[intervals.end(k),intervals.end(k),intervals.start(k+1),intervals.start(k+1)];
            y_fill=[0,250,250,0];
            a = fill(x_fill,y_fill,'yellow','HandleVisibility','off');
            a.FaceAlpha = 0.5;
        end

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)),"VariableNamingRule",'preserve');
        polar = MStoS(polar);
        polar(isnan(polar.rate),:)=[]; %remove NaN to have a continue plot
        plot(polar.time, polar.rate, Color='red', DisplayName='Polar')

        for i = 1:length(devices)
            tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
            if(ismember(1,tf) == 1)
                data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),"VariableNamingRule",'preserve');
                plot(data.time, data.rate, Color=colors{i}, DisplayName=devices{i})
            end
            ylim([35 200]);
            set(gca,'FontSize',13)
            legend('Location','eastoutside')
        end
    end
end

%% A) Signal analysis
%% A.1) Metrics for entire session, all transitions together, all heart rate zones, all transitions one by one
% - RMSE
% - COD
% - MARD
% - MAD
% - MAE

Headers = {'Type','Fitbit','Apple','Withings','Garmin'};
% Create empty tables to store metrics
RMSE = cell2table(cell(0,length(Headers)),VariableNames = Headers);
COD = cell2table(cell(0,length(Headers)),VariableNames = Headers);
MARD = cell2table(cell(0,length(Headers)),VariableNames = Headers);
MAE = cell2table(cell(0,length(Headers)),VariableNames = Headers);


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
    
    % loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2)
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % get only the folder names into a cell array
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)),"VariableNamingRule",'preserve');
        polar = MStoS(polar);

        % TODO

        for i = 1:length(devices)
            tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
            if(ismember(1,tf) == 1)
                data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),"VariableNamingRule",'preserve');
            end
        end
    end
end

%% A.2) Calculation on the entire signal for
% - Delay
% - Cross-correlation
% - R^2

Headers = {'idUser','idSession','Fitbit','Apple','Withings','Garmin'};
% Create empty tables to store metrics
DELAY = cell2table(cell(0,length(Headers)),VariableNames = Headers);
CROSSCORR = cell2table(cell(0,length(Headers)),VariableNames = Headers);
R2 = cell2table(cell(0,length(Headers)),VariableNames = Headers); % already defined as COD(?)

%% B) Session analysis
% - Mean
% - SD
% - Median
% - 25/75 boxplot

Headers = {'idUser','idSession','Polar','Fitbit','Apple','Withings','Garmin'};
% Create empty tables to store metrics
SessionMean = cell2table(cell(0,length(Headers)),VariableNames = Headers);
SessionMedian = cell2table(cell(0,length(Headers)),VariableNames = Headers);
SessionSD = cell2table(cell(0,length(Headers)),VariableNames = Headers);
Session25p = cell2table(cell(0,length(Headers)),VariableNames = Headers);
Session75p = cell2table(cell(0,length(Headers)),VariableNames = Headers);


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
    
    % Loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2)
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % Get only the folder names into a cell array
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        rowMean = cell(1,length(Headers));
        rowMean(:) = {NaN(1,1)};
        rowMedian = cell(1,length(Headers));
        rowMedian(:) = {NaN(1,1)};
        rowSD = cell(1,length(Headers));
        rowSD(:) = {NaN(1,1)};
        row25p = cell(1,length(Headers));
        row25p(:) = {NaN(1,1)};
        row75p = cell(1,length(Headers));
        row75p(:) = {NaN(1,1)};

        tf_session = startsWith(csv_names, 'session');
        session = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_session)),"VariableNamingRule",'preserve');
        
        rowMean{1} = session.iduser;
        rowMean{2} = session.id;
        rowMedian{1} = session.iduser;
        rowMedian{2} = session.id;
        rowSD{1} = session.iduser;
        rowSD{2} = session.id;
        row25p{1} = session.iduser;
        row25p{2} = session.id;
        row75p{1} = session.iduser;
        row75p{2} = session.id;

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)),"VariableNamingRule",'preserve');
        polar = MStoS(polar);

        rowMean{3} = nanmean(polar.rate);
        rowMedian{3} = nanmedian(polar.rate);
        rowSD{3} = nanstd(polar.rate);
        row25p{3} = prctile(polar.rate,25);
        row75p{3} = prctile(polar.rate,75);

        for i = 1:length(devices)
            tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
            if(ismember(1,tf) == 1)
                data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),"VariableNamingRule",'preserve');

                rowMean{3+i} = nanmean(data.rate);
                rowMedian{3+i} = nanmedian(data.rate);
                rowSD{3+i} = nanstd(data.rate);
                row25p{3+i} = prctile(data.rate,25);
                row75p{3+i} = prctile(data.rate,75);
            end
        end
        SessionMean = [SessionMean;rowMean];
        SessionMedian = [SessionMedian;rowMedian];
        SessionSD = [SessionSD;rowSD];
        Session25p = [Session25p;row25p];
        Session75p = [Session75p;row75p];
    end
end

