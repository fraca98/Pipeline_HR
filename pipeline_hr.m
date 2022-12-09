clear
close all
clc

addpath(genpath("src"));
%%
% devices names
devices = {'Fitbit','Apple','Withings','Garmin'};

% color to plot devices
colors = {'blue','black','green','magenta'};

%% Set the timestep to retime heart rate data
timestemp = 5;

%% Plot sessions adjusting polar data to Seconds (No more considering Ms)
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

        % plot Y-lines to identify heart rate zones
        for z = 1:length(intervals.start)
            if z~=length(intervals.start)
                line([intervals.start(z) intervals.end(z)],[(0.5 + 0.1*(z-1))*(220-(session.start.Year-user.birthYear)) (0.5 + 0.1*(z-1))*(220-(session.start.Year-user.birthYear))],'HandleVisibility','off','LineStyle','--')
            end
            if z~=1
                line([intervals.start(z) intervals.end(z)],[(0.5 + 0.1*(z-2))*(220-(session.start.Year-user.birthYear)) (0.5 + 0.1*(z-2))*(220-(session.start.Year-user.birthYear))],'HandleVisibility','off','LineStyle','--')
            end
        end

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
                data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),'VariableNamingRule','preserve');
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
% ? MAD : one for each
% - MAE

% creation of tables inside strcutures of errorMetrics
RMSE.all = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
COD.all = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
MARD.all = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
MAE.all = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);

RMSE.all = standardizeMissing(RMSE.all,0); %to set table to NaN
COD.all = standardizeMissing(COD.all,0);
MARD.all = standardizeMissing(MARD.all,0);
MAE.all = standardizeMissing(MAE.all,0);

for tr = 1 : length(intervals.start)-1
    RMSE.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
    COD.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
    MARD.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
    MAE.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);

    RMSE.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(RMSE.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    COD.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(COD.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    MARD.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(MARD.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    MAE.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(MAE.transition.(sprintf('tr%d%d',tr-1,tr)),0);
end

for hrzone = 1 : length(intervals.start)
    RMSE.zone.(sprintf('z%d',hrzone)) = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
    COD.zone.(sprintf('z%d',hrzone)) = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
    MARD.zone.(sprintf('z%d',hrzone)) = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
    MAE.zone.(sprintf('z%d',hrzone)) = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);

    RMSE.zone.(sprintf('z%d',hrzone)) = standardizeMissing(RMSE.zone.(sprintf('z%d',hrzone)),0);
    COD.zone.(sprintf('z%d',hrzone)) = standardizeMissing(COD.zone.(sprintf('z%d',hrzone)),0);
    MARD.zone.(sprintf('z%d',hrzone)) = standardizeMissing(MARD.zone.(sprintf('z%d',hrzone)),0);
    MAE.zone.(sprintf('z%d',hrzone)) = standardizeMissing(MAE.zone.(sprintf('z%d',hrzone)),0);
end

RMSE.alltr = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
COD.alltr = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
MARD.alltr = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
MAE.alltr = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);


for idx_user = 1:size(users_DirsNames,2)

    % assign the idUser in tables of structures of errorMetrics
    RMSE.all {idx_user,1} = users_DirsNames(idx_user);
    COD.all {idx_user,1} = users_DirsNames(idx_user);
    MARD.all {idx_user,1} = users_DirsNames(idx_user);
    MAE.all {idx_user,1} = users_DirsNames(idx_user);

    for tr = 1 : length(intervals.start)-1
        RMSE.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        COD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        MARD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        MAE.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
    end

    for hrzone = 1 : length(intervals.start)
        RMSE.zone.(sprintf('z%d',hrzone)) {idx_user,1} = users_DirsNames(idx_user);
        COD.zone.(sprintf('z%d',hrzone)) {idx_user,1} = users_DirsNames(idx_user);
        MARD.zone.(sprintf('z%d',hrzone)) {idx_user,1} = users_DirsNames(idx_user);
        MAE.zone.(sprintf('z%d',hrzone)) {idx_user,1} = users_DirsNames(idx_user);
    end

    RMSE.alltr {idx_user,1} = users_DirsNames(idx_user);
    COD.alltr {idx_user,1} = users_DirsNames(idx_user);
    MARD.alltr {idx_user,1} = users_DirsNames(idx_user);
    MAE.alltr {idx_user,1} = users_DirsNames(idx_user);

    % access the sessions of each user
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

        tf_intervals = startsWith(csv_names, 'intervals');
        intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)),"VariableNamingRule",'preserve');
        % shift to seconds without milliseconds (start)
        intervals.start = dateshift(intervals.start, 'start', 'second');
        intervals.end = dateshift(intervals.end, 'start', 'second');

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)),"VariableNamingRule",'preserve');
        polar = MStoS(polar);
        polar = retimeHR(polar,timestemp);

        for i = 1:length(devices)
            tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
            if(ismember(1,tf) == 1)
                data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),"VariableNamingRule",'preserve');
                data = retimeHR(data,timestemp,polar.time(1),polar.time(end));

                % Now calculating the errorMetrics

                % 1) Entire signal (from the start of the first interval to
                % the end of the session or last interval. Transitions are
                % included)
                allpolar = polar(isbetween(polar.time,intervals.start(1),intervals.end(end)),:);
                alldata = data(isbetween(data.time,intervals.start(1),intervals.end(end)),:);

                RMSE.all {idx_user,i+1} = rmse(allpolar,alldata);
                COD.all {idx_user,i+1} = cod(allpolar,alldata);
                MARD.all {idx_user,i+1} = mard(allpolar,alldata);
                MAE.all {idx_user,i+1} = mae(allpolar,alldata);

                % 2) Each transition
                for tr = 1 : length(intervals.start)-1
                    trpolar = polar(isbetween(polar.time,intervals.end(tr),intervals.start(tr+1)),:);
                    trdata = data(isbetween(data.time,intervals.end(tr),intervals.start(tr+1)),:);

                    RMSE.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,i+1} = rmse(allpolar,alldata);
                    COD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,i+1} = cod(allpolar,alldata);
                    MARD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,i+1} = mard(allpolar,alldata);
                    MAE.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,i+1} = mae(allpolar,alldata);

                end

                % 3) Each heart rate zone (interval)
                for hrzone = 1 : length(intervals.start)
                    hrzonepolar = polar(isbetween(polar.time,intervals.start(hrzone),intervals.end(hrzone)),:);
                    hrzonedata = data(isbetween(data.time,intervals.start(hrzone),intervals.end(hrzone)),:);

                    RMSE.zone.(sprintf('z%d',hrzone)) {idx_user,i+1} = rmse(allpolar,alldata);
                    COD.zone.(sprintf('z%d',hrzone)) {idx_user,i+1} = cod(allpolar,alldata);
                    MARD.zone.(sprintf('z%d',hrzone)) {idx_user,i+1} = mard(allpolar,alldata);
                    MAE.zone.(sprintf('z%d',hrzone)) {idx_user,i+1} = mae(allpolar,alldata);

                end

                % 4) All the transitions together
                alltrpolar = [];
                alltrdata = [];
                for tr = 1 : length(intervals.start)-1
                    alltrpolar = [alltrpolar;polar(isbetween(polar.time,intervals.end(tr),intervals.start(tr+1)),:)];
                    alltrdata = [alltrdata;data(isbetween(data.time,intervals.end(tr),intervals.start(tr+1)),:)];
                end
                %TODO: ask why same timestep

            end
        end
    end
end

%% A.2) Calculation on the entire signal for
% - Delay
% - Cross-correlation
% - R^2: already defined as COD(?)

DELAY = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);
XCORR = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','cell','cell','cell','cell'},'VariableNames',["idUser","Fitbit","Apple","Withings","Garmin"]);

DELAY = standardizeMissing(DELAY,0);
XCORR = standardizeMissing(XCORR,0);


for idx_user = 1:size(users_DirsNames,2)

    DELAY{idx_user,1} = users_DirsNames(idx_user);
    XCORR{idx_user,1} = users_DirsNames(idx_user);

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

        tf_intervals = startsWith(csv_names, 'intervals');
        intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)),"VariableNamingRule",'preserve');
        % shift to seconds without milliseconds (start)
        intervals.start = dateshift(intervals.start, 'start', 'second');
        intervals.end = dateshift(intervals.end, 'start', 'second');

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)),"VariableNamingRule",'preserve');
        polar = MStoS(polar);
        polar = retimeHR(polar,timestemp);

        for i = 1:length(devices)
            tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
            if(ismember(1,tf) == 1)
                data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),"VariableNamingRule",'preserve');
                data = retimeHR(data,timestemp,polar.time(1),polar.time(end));

                % get the entire signal (from the start of the first interval to
                % the end of the session or last interval. Transitions are
                % included)
                allpolar = polar(isbetween(polar.time,intervals.start(1),intervals.end(end)),:);
                alldata = data(isbetween(data.time,intervals.start(1),intervals.end(end)),:);

                DELAY{idx_user,1+i} = timeDelay(allpolar,alldata);
                XCORR{idx_user,1+i} = {xcorr(allpolar.rate,alldata.rate)};

            end
        end
    end
end

%% B) Session analysis (Metrics calculated on the entire session)
% - Mean
% - SD
% - Median
% - 25/75 boxplot

SessionMEAN = table('Size',[length(users_DirsNames),7],'VariableTypes',{'double','double','double','double','double','double','double'},'VariableNames',["idUser","idSession","Polar","Fitbit","Apple","Withings","Garmin"]);
SessionMEDIAN = table('Size',[length(users_DirsNames),7],'VariableTypes',{'double','double','double','double','double','double','double'},'VariableNames',["idUser","idSession","Polar","Fitbit","Apple","Withings","Garmin"]);
SessionSD = table('Size',[length(users_DirsNames),7],'VariableTypes',{'double','double','double','double','double','double','double'},'VariableNames',["idUser","idSession","Polar","Fitbit","Apple","Withings","Garmin"]);
Session25P = table('Size',[length(users_DirsNames),7],'VariableTypes',{'double','double','double','double','double','double','double'},'VariableNames',["idUser","idSession","Polar","Fitbit","Apple","Withings","Garmin"]);
Session75P = table('Size',[length(users_DirsNames),7],'VariableTypes',{'double','double','double','double','double','double','double'},'VariableNames',["idUser","idSession","Polar","Fitbit","Apple","Withings","Garmin"]);

SessionMEAN = standardizeMissing(SessionMEAN,0);
SessionMEDIAN = standardizeMissing(SessionMEDIAN,0);
SessionSD = standardizeMissing(SessionSD,0);
Session25P = standardizeMissing(Session25P,0);
Session75P = standardizeMissing(Session75P,0);

for idx_user = 1:size(users_DirsNames,2)
    SessionMEAN{idx_user,1}=users_DirsNames(idx_user);
    SessionMEDIAN{idx_user,1}=users_DirsNames(idx_user);
    SessionSD{idx_user,1}=users_DirsNames(idx_user);
    Session25P{idx_user,1}=users_DirsNames(idx_user);
    Session75P{idx_user,1}=users_DirsNames(idx_user);

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

        tf_session = startsWith(csv_names, 'session');
        session = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_session)),"VariableNamingRule",'preserve');
        SessionMEAN{idx_user,2}=session.id;
        SessionMEDIAN{idx_user,2}=session.id;
        SessionSD{idx_user,2}=session.id;
        Session25P{idx_user,2}=session.id;
        Session75P{idx_user,2}=session.id;


        tf_intervals = startsWith(csv_names, 'intervals');
        intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)),"VariableNamingRule",'preserve');
        % shift to seconds without milliseconds (start)
        intervals.start = dateshift(intervals.start, 'start', 'second');
        intervals.end = dateshift(intervals.end, 'start', 'second');

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)),"VariableNamingRule",'preserve');
        polar = MStoS(polar);
        polar = retimeHR(polar,timestemp);
        allpolar = polar(isbetween(polar.time,intervals.start(1),intervals.end(end)),:);

        SessionMEAN{idx_user,3} = nanmean(allpolar.rate);
        SessionMEDIAN{idx_user,3} = nanmedian(allpolar.rate);
        SessionSD{idx_user,3} = nanstd(allpolar.rate);
        Session25P{idx_user,3} = prctile(allpolar.rate,25);
        Session75P{idx_user,3} = prctile(allpolar.rate,75);

        for i = 1:length(devices)
            tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
            if(ismember(1,tf) == 1)
                data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),"VariableNamingRule",'preserve');
                data = retimeHR(data,timestemp,polar.time(1),polar.time(end));

                alldata = data(isbetween(data.time,intervals.start(1),intervals.end(end)),:);

                SessionMEAN{idx_user,3+i} = nanmean(alldata.rate);
                SessionMEDIAN{idx_user,3+i} = nanmedian(alldata.rate);
                SessionSD{idx_user,3+i} = nanstd(alldata.rate);
                Session25P{idx_user,3+i} = prctile(alldata.rate,25);
                Session75P{idx_user,3+i} = prctile(alldata.rate,75);
            end
        end
    end
end