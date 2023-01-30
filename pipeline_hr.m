clear
close all
clc

addpath(genpath("src"));
%%
% devices names
devices = {'Apple','Fitbit','Garmin','Withings'};

% color to plot devices
colors = {'black','blue','magenta','green'};

%% Set the timestep to retime heart rate data
timestep = 5;

%% Plot sessions
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
        polar = retimeHR(polar,timestep);
        %polar(isnan(polar.rate),:)=[]; %remove NaN to have a continue plot
        plot(polar.time, polar.rate,'.',Color='red', DisplayName='Polar')

        for i = 1:length(devices)
            tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
            if(ismember(1,tf) == 1)
                data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),'VariableNamingRule','preserve');
                %data = retime(data,polar.time); %retime to have same grid of Polar to have plot NAN
                data = retimeHR(data,timestep,polar.time(1),polar.time(end));
                plot(data.time, data.rate,'.', Color=colors{i}, DisplayName=devices{i})
            end
            ylim([35 200]);
            set(gca,'FontSize',13)
            legend('Location','eastoutside')
        end
    end
end

%% A) Error metrics
% - RMSE
% - COD
% - MARD
% - MAE
% - DELAY
% - XCORR

strDevices = string(['IDUser',devices]);

% creation of tables inside strcutures of errorMetrics
RMSE.all = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
COD.all = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
MARD.all = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
MAE.all = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
DELAY.all = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
XCORR.all = table('Size',[length(users_DirsNames),5],'VariableTypes',{'double','cell','cell','cell','cell'},'VariableNames',strDevices);

RMSE.all = standardizeMissing(RMSE.all,0); %to set table to NaN
COD.all = standardizeMissing(COD.all,0);
MARD.all = standardizeMissing(MARD.all,0);
MAE.all = standardizeMissing(MAE.all,0);
DELAY.all = standardizeMissing(DELAY.all,0);
XCORR.all = standardizeMissing(XCORR.all,0);


for tr = 1 : length(intervals.start)-1
    RMSE.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
    COD.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
    MARD.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
    MAE.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
    DELAY.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
    XCORR.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','cell','cell','cell','cell'},'VariableNames',strDevices);

    RMSE.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(RMSE.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    COD.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(COD.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    MARD.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(MARD.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    MAE.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(MAE.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    DELAY.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(DELAY.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    XCORR.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(XCORR.transition.(sprintf('tr%d%d',tr-1,tr)),0);
end

for hrzone = 1 : length(intervals.start)
    RMSE.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
    COD.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
    MARD.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
    MAE.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
    DELAY.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
    XCORR.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','cell','cell','cell','cell'},'VariableNames',strDevices);

    RMSE.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(RMSE.zone.(sprintf('z%d',hrzone-1)),0);
    COD.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(COD.zone.(sprintf('z%d',hrzone-1)),0);
    MARD.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(MARD.zone.(sprintf('z%d',hrzone-1)),0);
    MAE.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(MAE.zone.(sprintf('z%d',hrzone-1)),0);
    DELAY.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(DELAY.zone.(sprintf('z%d',hrzone-1)),0);
    XCORR.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(XCORR.zone.(sprintf('z%d',hrzone-1)),0);
end

RMSE.alltr = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
COD.alltr = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
MARD.alltr = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
MAE.alltr = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
DELAY.alltr = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','double','double','double','double'},'VariableNames',strDevices);
XCORR.alltr = table('Size',[length(users_DirsNames),length(strDevices)],'VariableTypes',{'double','cell','cell','cell','cell'},'VariableNames',strDevices);

RMSE.alltr = standardizeMissing(RMSE.alltr,0);
COD.alltr = standardizeMissing(COD.alltr,0);
MARD.alltr = standardizeMissing(MARD.alltr,0);
MAE.alltr = standardizeMissing(MAE.alltr,0);
DELAY.alltr = standardizeMissing(DELAY.alltr,0);
XCORR.alltr = standardizeMissing(XCORR.alltr,0);

for idx_user = 1:size(users_DirsNames,2)

    % assign the idUser in tables of structures of errorMetrics
    RMSE.all {idx_user,1} = users_DirsNames(idx_user);
    COD.all {idx_user,1} = users_DirsNames(idx_user);
    MARD.all {idx_user,1} = users_DirsNames(idx_user);
    MAE.all {idx_user,1} = users_DirsNames(idx_user);
    DELAY.all {idx_user,1} = users_DirsNames(idx_user);
    XCORR.all {idx_user,1} = users_DirsNames(idx_user);

    for tr = 1 : length(intervals.start)-1
        RMSE.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        COD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        MARD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        MAE.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        DELAY.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        XCORR.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
    end

    for hrzone = 1 : length(intervals.start)
        RMSE.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        COD.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        MARD.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        MAE.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        DELAY.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        XCORR.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
    end

    RMSE.alltr {idx_user,1} = users_DirsNames(idx_user);
    COD.alltr {idx_user,1} = users_DirsNames(idx_user);
    MARD.alltr {idx_user,1} = users_DirsNames(idx_user);
    MAE.alltr {idx_user,1} = users_DirsNames(idx_user);
    DELAY.alltr {idx_user,1} = users_DirsNames(idx_user);
    XCORR.alltr {idx_user,1} = users_DirsNames(idx_user);

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
        % shift to seconds without milliseconds (start --> at the start)
        intervals.start = dateshift(intervals.start, 'start', 'second');
        intervals.end = dateshift(intervals.end, 'start', 'second');

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)),"VariableNamingRule",'preserve');
        polar = MStoS(polar); %to S from Ms
        polar = retimeHR(polar,timestep);

        for i = 1:length(devices)
            tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
            if(ismember(1,tf) == 1)
                data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),"VariableNamingRule",'preserve');
                data = retimeHR(data,timestep,polar.time(1),polar.time(end));

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
                DELAY.all {idx_user,i+1} = timeDelay(allpolar,alldata);
                XCORR.all {idx_user,i+1} = {xcorrN(allpolar,alldata)};

                % 2) Each transition
                for tr = 1 : length(intervals.start)-1
                    trpolar = polar(isbetween(polar.time,intervals.end(tr),intervals.start(tr+1)),:);
                    trdata = data(isbetween(data.time,intervals.end(tr),intervals.start(tr+1)),:);

                    RMSE.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,i+1} = rmse(trpolar,trdata);
                    COD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,i+1} = cod(trpolar,trdata);
                    MARD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,i+1} = mard(trpolar,trdata);
                    MAE.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,i+1} = mae(trpolar,trdata);
                    DELAY.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,i+1} = timeDelay(trpolar,trdata);
                    XCORR.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,i+1} = {xcorrN(trpolar,trdata)};

                end

                % 3) Each heart rate zone (interval)
                for hrzone = 1 : length(intervals.start)
                    hrzonepolar = polar(isbetween(polar.time,intervals.start(hrzone),intervals.end(hrzone)),:);
                    hrzonedata = data(isbetween(data.time,intervals.start(hrzone),intervals.end(hrzone)),:);

                    RMSE.zone.(sprintf('z%d',hrzone-1)) {idx_user,i+1} = rmse(hrzonepolar,hrzonedata);
                    COD.zone.(sprintf('z%d',hrzone-1)) {idx_user,i+1} = cod(hrzonepolar,hrzonedata);
                    MARD.zone.(sprintf('z%d',hrzone-1)) {idx_user,i+1} = mard(hrzonepolar,hrzonedata);
                    MAE.zone.(sprintf('z%d',hrzone-1)) {idx_user,i+1} = mae(hrzonepolar,hrzonedata);
                    DELAY.zone.(sprintf('z%d',hrzone-1)) {idx_user,i+1} = timeDelay(hrzonepolar,hrzonedata);
                    XCORR.zone.(sprintf('z%d',hrzone-1)) {idx_user,i+1} = {xcorrN(hrzonepolar,hrzonedata)};

                end

                % 4) All the transitions together
                alltrpolar = [];
                alltrdata = [];
                for tr = 1 : length(intervals.start)-1
                    alltrpolar = [alltrpolar;polar(isbetween(polar.time,intervals.end(tr),intervals.start(tr+1)),:)];
                    alltrdata = [alltrdata;data(isbetween(data.time,intervals.end(tr),intervals.start(tr+1)),:)];
                end
                RMSE.alltr {idx_user,i+1} = rmse(alltrpolar,alltrdata);
                COD.alltr {idx_user,i+1} = cod(alltrpolar,alltrdata);
                MARD.alltr {idx_user,i+1} = mard(alltrpolar,alltrdata);
                MAE.alltr {idx_user,i+1} = mae(alltrpolar,alltrdata);
                DELAY.alltr {idx_user,i+1} = timeDelay(alltrpolar,alltrdata);
                XCORR.alltr {idx_user,i+1} = {xcorrN(alltrpolar,alltrdata)};
            end
        end
    end
end

%% B) Statistics
% - Mean
% - SD
% - Median
% - 25/75 boxplot

% Sessione 1

Sess1.MEAN.all = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double'},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
Sess1.MEDIAN.all = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double'},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
Sess1.SD.all = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double'},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
Sess1.p25.all = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double'},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
Sess1.p75.all = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);

Sess1.MEAN.all = standardizeMissing(Sess1.MEAN.all,0);
Sess1.MEDIAN.all = standardizeMissing(Sess1.MEDIAN.all,0);
Sess1.SD.all = standardizeMissing(Sess1.SD.all,0);
Sess1.p25.all = standardizeMissing(Sess1.p25.all,0);
Sess1.p75.all = standardizeMissing(Sess1.p75.all,0);

for tr = 1 : length(intervals.start)-1
    Sess1.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
    Sess1.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
    Sess1.SD.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
    Sess1.p25.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
    Sess1.p75.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);


    Sess1.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(Sess1.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    Sess1.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(Sess1.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    Sess1.SD.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(Sess1.SD.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    Sess1.p25.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(Sess1.p25.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    Sess1.p75.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(Sess1.p75.transition.(sprintf('tr%d%d',tr-1,tr)),0);
end

for hrzone = 1 : length(intervals.start)
    Sess1.MEAN.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
    Sess1.MEDIAN.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
    Sess1.SD.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
    Sess1.p25.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
    Sess1.p75.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);

    Sess1.MEAN.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(Sess1.MEAN.zone.(sprintf('z%d',hrzone-1)),0);
    Sess1.MEDIAN.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(Sess1.MEDIAN.zone.(sprintf('z%d',hrzone-1)),0);
    Sess1.SD.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(Sess1.SD.zone.(sprintf('z%d',hrzone-1)),0);
    Sess1.p25.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(Sess1.p25.zone.(sprintf('z%d',hrzone-1)),0);
    Sess1.p75.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(Sess1.p75.zone.(sprintf('z%d',hrzone-1)),0);
end

Sess1.MEAN.alltr = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
Sess1.MEDIAN.alltr = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
Sess1.SD.alltr = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
Sess1.p25.alltr = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);
Sess1.p75.alltr = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Fitbit","Garmin"]);

Sess1.MEAN.alltr = standardizeMissing(Sess1.MEAN.alltr,0);
Sess1.MEDIAN.alltr = standardizeMissing(Sess1.MEDIAN.alltr,0);
Sess1.SD.alltr = standardizeMissing(Sess1.SD.alltr,0);
Sess1.p25.alltr = standardizeMissing(Sess1.p25.alltr,0);
Sess1.p25.alltr = standardizeMissing(Sess1.p75.alltr,0);


for idx_user = 1:size(users_DirsNames,2)

    % assign the idUser in tables of structures of errorMetrics
    Sess1.MEAN.all {idx_user,1} = users_DirsNames(idx_user);
    Sess1.MEDIAN.all {idx_user,1} = users_DirsNames(idx_user);
    Sess1.SD.all {idx_user,1} = users_DirsNames(idx_user);
    Sess1.p25.all {idx_user,1} = users_DirsNames(idx_user);
    Sess1.p75.all {idx_user,1} = users_DirsNames(idx_user);

    for tr = 1 : length(intervals.start)-1
        Sess1.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        Sess1.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        Sess1.SD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        Sess1.p25.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        Sess1.p75.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
    end

    for hrzone = 1 : length(intervals.start)
        Sess1.MEAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        Sess1.MEDIAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        Sess1.SD.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        Sess1.p25.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        Sess1.p75.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);;
    end

    Sess1.MEAN.alltr {idx_user,1} = users_DirsNames(idx_user);
    Sess1.MEDIAN.alltr {idx_user,1} = users_DirsNames(idx_user);
    Sess1.SD.alltr {idx_user,1} = users_DirsNames(idx_user);
    Sess1.p25.alltr {idx_user,1} = users_DirsNames(idx_user);
    Sess1.p75.alltr {idx_user,1} = users_DirsNames(idx_user);

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

    % first session of the user
    idx_session = 1;
    csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
    % get only the folder names into a cell array
    csv_names = {csvs(3:end).name};
    csv_names = string(csv_names);

    tf_intervals = startsWith(csv_names, 'intervals');
    intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)),"VariableNamingRule",'preserve');
    % shift to seconds without milliseconds (start --> at the start)
    intervals.start = dateshift(intervals.start, 'start', 'second');
    intervals.end = dateshift(intervals.end, 'start', 'second');

    tf_polar = startsWith(csv_names,'polar'); %% take polar file name
    polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)),"VariableNamingRule",'preserve');
    polar = MStoS(polar); %to S from Ms
    polar = retimeHR(polar,timestep);

    k=3;

    for i = 1:length(devices)
        tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
        if(ismember(1,tf) == 1)
            data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),"VariableNamingRule",'preserve');
            data = retimeHR(data,timestep,polar.time(1),polar.time(end));

            % Now calculating the Statistics

            % 1) Entire signal (from the start of the first interval to
            % the end of the session or last interval. Transitions are
            % included)
            allpolar = polar(isbetween(polar.time,intervals.start(1),intervals.end(end)),:);
            alldata = data(isbetween(data.time,intervals.start(1),intervals.end(end)),:);

            Sess1.MEAN.all {idx_user,2} = nanmean(allpolar.rate);
            Sess1.MEDIAN.all {idx_user,2} = nanmedian(allpolar.rate);
            Sess1.SD.all {idx_user,2} = nanstd(allpolar.rate);
            Sess1.p25.all {idx_user,2} = prctile(allpolar.rate,25);
            Sess1.p75.all {idx_user,2} = prctile(allpolar.rate,75);

            Sess1.MEAN.all {idx_user,k} = nanmean(alldata.rate);
            Sess1.MEDIAN.all {idx_user,k} = nanmedian(alldata.rate);
            Sess1.SD.all {idx_user,k} = nanstd(alldata.rate);
            Sess1.p25.all {idx_user,k} = prctile(alldata.rate,25);
            Sess1.p75.all {idx_user,k} = prctile(alldata.rate,75);



            % 2) Each transition
            for tr = 1 : length(intervals.start)-1
                trpolar = polar(isbetween(polar.time,intervals.end(tr),intervals.start(tr+1)),:);
                trdata = data(isbetween(data.time,intervals.end(tr),intervals.start(tr+1)),:);


                Sess1.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,2} = nanmean(trpolar.rate);
                Sess1.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,2} = nanmedian(trpolar.rate);
                Sess1.SD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,2} = nanstd(trpolar.rate);
                Sess1.p25.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,2} = prctile(trpolar.rate,25);
                Sess1.p75.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,2} = prctile(trpolar.rate,75);

                Sess1.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,k} = nanmean(trdata.rate);
                Sess1.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,k} = nanmedian(trdata.rate);
                Sess1.SD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,k} = nanstd(trdata.rate);
                Sess1.p25.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,k} = prctile(trdata.rate,25);
                Sess1.p75.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,k} = prctile(trdata.rate,75);
            end

            % 3) Each heart rate zone (interval)
            for hrzone = 1 : length(intervals.start)
                hrzonepolar = polar(isbetween(polar.time,intervals.start(hrzone),intervals.end(hrzone)),:);
                hrzonedata = data(isbetween(data.time,intervals.start(hrzone),intervals.end(hrzone)),:);

                Sess1.MEAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,2} = nanmean(hrzonepolar.rate);
                Sess1.MEDIAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,2} = nanmedian(hrzonepolar.rate);
                Sess1.SD.zone.(sprintf('z%d',hrzone-1)) {idx_user,2} = nanstd(hrzonepolar.rate);
                Sess1.p25.zone.(sprintf('z%d',hrzone-1)) {idx_user,2} = prctile(hrzonepolar.rate,25);
                Sess1.p75.zone.(sprintf('z%d',hrzone-1)) {idx_user,2} = prctile(hrzonepolar.rate,75);

                Sess1.MEAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,k} = nanmean(hrzonedata.rate);
                Sess1.MEDIAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,k} = nanmedian(hrzonedata.rate);
                Sess1.SD.zone.(sprintf('z%d',hrzone-1)) {idx_user,k} = nanstd(hrzonedata.rate);
                Sess1.p25.zone.(sprintf('z%d',hrzone-1)) {idx_user,k} = prctile(hrzonedata.rate,25);
                Sess1.p75.zone.(sprintf('z%d',hrzone-1)) {idx_user,k} = prctile(hrzonedata.rate,75);

            end

            % 4) All the transitions together
            alltrpolar = [];
            alltrdata = [];
            for tr = 1 : length(intervals.start)-1
                alltrpolar = [alltrpolar;polar(isbetween(polar.time,intervals.end(tr),intervals.start(tr+1)),:)];
                alltrdata = [alltrdata;data(isbetween(data.time,intervals.end(tr),intervals.start(tr+1)),:)];
            end
            Sess1.MEAN.alltr {idx_user,2} = nanmean(alltrpolar.rate);
            Sess1.MEDIAN.alltr {idx_user,2} = nanmedian(alltrpolar.rate);
            Sess1.SD.alltr {idx_user,2} = nanstd(alltrpolar.rate);
            Sess1.p25.alltr {idx_user,2} = prctile(alltrpolar.rate,25);
            Sess1.p75.alltr {idx_user,2} = prctile(alltrpolar.rate,75);

            Sess1.MEAN.alltr {idx_user,k}= nanmean(alltrdata.rate);
            Sess1.MEDIAN.alltr {idx_user,k} = nanmedian(alltrdata.rate);
            Sess1.SD.zone.alltr {idx_user,k}= nanstd(alltrdata.rate);
            Sess1.p25.alltr {idx_user,k} = prctile(alltrdata.rate,25);
            Sess1.p75.alltr {idx_user,k} = prctile(alltrdata.rate,75);

            k=k+1;
        end
    end
end
%%
% Sessione 2
Sess2.MEAN.all = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double'},'VariableNames',["IDUser","Polar","Apple","Withings"]);
Sess2.MEDIAN.all = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double'},'VariableNames',["IDUser","Polar","Apple","Withings"]);
Sess2.SD.all = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double'},'VariableNames',["IDUser","Polar","Apple","Withings"]);
Sess2.p25.all = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double'},'VariableNames',["IDUser","Polar","Apple","Withings"]);
Sess2.p75.all = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);

Sess2.MEAN.all = standardizeMissing(Sess2.MEAN.all,0);
Sess2.MEDIAN.all = standardizeMissing(Sess2.MEDIAN.all,0);
Sess2.SD.all = standardizeMissing(Sess2.SD.all,0);
Sess2.p25.all = standardizeMissing(Sess2.p25.all,0);
Sess2.p75.all = standardizeMissing(Sess2.p75.all,0);

for tr = 1 : length(intervals.start)-1
    Sess2.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
    Sess2.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
    Sess2.SD.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
    Sess2.p25.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
    Sess2.p75.transition.(sprintf('tr%d%d',tr-1,tr)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);


    Sess2.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(Sess2.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    Sess2.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(Sess2.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    Sess2.SD.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(Sess2.SD.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    Sess2.p25.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(Sess2.p25.transition.(sprintf('tr%d%d',tr-1,tr)),0);
    Sess2.p75.transition.(sprintf('tr%d%d',tr-1,tr)) = standardizeMissing(Sess2.p75.transition.(sprintf('tr%d%d',tr-1,tr)),0);
end

for hrzone = 1 : length(intervals.start)
    Sess2.MEAN.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
    Sess2.MEDIAN.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
    Sess2.SD.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
    Sess2.p25.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
    Sess2.p75.zone.(sprintf('z%d',hrzone-1)) = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);

    Sess2.MEAN.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(Sess2.MEAN.zone.(sprintf('z%d',hrzone-1)),0);
    Sess2.MEDIAN.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(Sess2.MEDIAN.zone.(sprintf('z%d',hrzone-1)),0);
    Sess2.SD.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(Sess2.SD.zone.(sprintf('z%d',hrzone-1)),0);
    Sess2.p25.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(Sess2.p25.zone.(sprintf('z%d',hrzone-1)),0);
    Sess2.p75.zone.(sprintf('z%d',hrzone-1)) = standardizeMissing(Sess2.p75.zone.(sprintf('z%d',hrzone-1)),0);
end

Sess2.MEAN.alltr = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
Sess2.MEDIAN.alltr = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
Sess2.SD.alltr = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
Sess2.p25.alltr = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);
Sess2.p75.alltr = table('Size',[length(users_DirsNames),4],'VariableTypes',{'double','double','double','double',},'VariableNames',["IDUser","Polar","Apple","Withings"]);

Sess2.MEAN.alltr = standardizeMissing(Sess2.MEAN.alltr,0);
Sess2.MEDIAN.alltr = standardizeMissing(Sess2.MEDIAN.alltr,0);
Sess2.SD.alltr = standardizeMissing(Sess2.SD.alltr,0);
Sess2.p25.alltr = standardizeMissing(Sess2.p25.alltr,0);
Sess2.p25.alltr = standardizeMissing(Sess2.p75.alltr,0);


for idx_user = 1:size(users_DirsNames,2)

    % assign the idUser in tables of structures of errorMetrics
    Sess2.MEAN.all {idx_user,1} = users_DirsNames(idx_user);
    Sess2.MEDIAN.all {idx_user,1} = users_DirsNames(idx_user);
    Sess2.SD.all {idx_user,1} = users_DirsNames(idx_user);
    Sess2.p25.all {idx_user,1} = users_DirsNames(idx_user);
    Sess2.p75.all {idx_user,1} = users_DirsNames(idx_user);

    for tr = 1 : length(intervals.start)-1
        Sess2.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        Sess2.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        Sess2.SD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        Sess2.p25.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
        Sess2.p75.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,1} = users_DirsNames(idx_user);
    end

    for hrzone = 1 : length(intervals.start)
        Sess2.MEAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        Sess2.MEDIAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        Sess2.SD.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        Sess2.p25.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);
        Sess2.p75.zone.(sprintf('z%d',hrzone-1)) {idx_user,1} = users_DirsNames(idx_user);;
    end

    Sess2.MEAN.alltr {idx_user,1} = users_DirsNames(idx_user);
    Sess2.MEDIAN.alltr {idx_user,1} = users_DirsNames(idx_user);
    Sess2.SD.alltr {idx_user,1} = users_DirsNames(idx_user);
    Sess2.p25.alltr {idx_user,1} = users_DirsNames(idx_user);
    Sess2.p75.alltr {idx_user,1} = users_DirsNames(idx_user);

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

    % second session of the user
    idx_session = 2;
    csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
    % get only the folder names into a cell array
    csv_names = {csvs(3:end).name};
    csv_names = string(csv_names);

    tf_intervals = startsWith(csv_names, 'intervals');
    intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)),"VariableNamingRule",'preserve');
    % shift to seconds without milliseconds (start --> at the start)
    intervals.start = dateshift(intervals.start, 'start', 'second');
    intervals.end = dateshift(intervals.end, 'start', 'second');

    tf_polar = startsWith(csv_names,'polar'); %% take polar file name
    polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)),"VariableNamingRule",'preserve');
    polar = MStoS(polar); %to S from Ms
    polar = retimeHR(polar,timestep);

    k=3;
    for i = 1:length(devices)
        tf = startsWith(csv_names,devices{i},'IgnoreCase',true); %% take file name containing devices data ignoring case sensitive
        if(ismember(1,tf) == 1)
            data = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf)),"VariableNamingRule",'preserve');
            data = retimeHR(data,timestep,polar.time(1),polar.time(end));

            % Now calculating the Statistics

            % 1) Entire signal (from the start of the first interval to
            % the end of the session or last interval. Transitions are
            % included)
            allpolar = polar(isbetween(polar.time,intervals.start(1),intervals.end(end)),:);
            alldata = data(isbetween(data.time,intervals.start(1),intervals.end(end)),:);

            Sess2.MEAN.all {idx_user,2} = nanmean(allpolar.rate);
            Sess2.MEDIAN.all {idx_user,2} = nanmedian(allpolar.rate);
            Sess2.SD.all {idx_user,2} = nanstd(allpolar.rate);
            Sess2.p25.all {idx_user,2} = prctile(allpolar.rate,25);
            Sess2.p75.all {idx_user,2} = prctile(allpolar.rate,75);

            Sess2.MEAN.all {idx_user,k} = nanmean(alldata.rate);
            Sess2.MEDIAN.all {idx_user,k} = nanmedian(alldata.rate);
            Sess2.SD.all {idx_user,k} = nanstd(alldata.rate);
            Sess2.p25.all {idx_user,k} = prctile(alldata.rate,25);
            Sess2.p75.all {idx_user,k} = prctile(alldata.rate,75);



            % 2) Each transition
            for tr = 1 : length(intervals.start)-1
                trpolar = polar(isbetween(polar.time,intervals.end(tr),intervals.start(tr+1)),:);
                trdata = data(isbetween(data.time,intervals.end(tr),intervals.start(tr+1)),:);


                Sess2.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,2} = nanmean(trpolar.rate);
                Sess2.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,2} = nanmedian(trpolar.rate);
                Sess2.SD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,2} = nanstd(trpolar.rate);
                Sess2.p25.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,2} = prctile(trpolar.rate,25);
                Sess2.p75.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,2} = prctile(trpolar.rate,75);

                Sess2.MEAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,k} = nanmean(trdata.rate);
                Sess2.MEDIAN.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,k} = nanmedian(trdata.rate);
                Sess2.SD.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,k} = nanstd(trdata.rate);
                Sess2.p25.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,k} = prctile(trdata.rate,25);
                Sess2.p75.transition.(sprintf('tr%d%d',tr-1,tr)) {idx_user,k} = prctile(trdata.rate,75);
            end

            % 3) Each heart rate zone (interval)
            for hrzone = 1 : length(intervals.start)
                hrzonepolar = polar(isbetween(polar.time,intervals.start(hrzone),intervals.end(hrzone)),:);
                hrzonedata = data(isbetween(data.time,intervals.start(hrzone),intervals.end(hrzone)),:);

                Sess2.MEAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,2} = nanmean(hrzonepolar.rate);
                Sess2.MEDIAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,2} = nanmedian(hrzonepolar.rate);
                Sess2.SD.zone.(sprintf('z%d',hrzone-1)) {idx_user,2} = nanstd(hrzonepolar.rate);
                Sess2.p25.zone.(sprintf('z%d',hrzone-1)) {idx_user,2} = prctile(hrzonepolar.rate,25);
                Sess2.p75.zone.(sprintf('z%d',hrzone-1)) {idx_user,2} = prctile(hrzonepolar.rate,75);

                Sess2.MEAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,k} = nanmean(hrzonedata.rate);
                Sess2.MEDIAN.zone.(sprintf('z%d',hrzone-1)) {idx_user,k} = nanmedian(hrzonedata.rate);
                Sess2.SD.zone.(sprintf('z%d',hrzone-1)) {idx_user,k} = nanstd(hrzonedata.rate);
                Sess2.p25.zone.(sprintf('z%d',hrzone-1)) {idx_user,k} = prctile(hrzonedata.rate,25);
                Sess2.p75.zone.(sprintf('z%d',hrzone-1)) {idx_user,k} = prctile(hrzonedata.rate,75);

            end

            % 4) All the transitions together
            alltrpolar = [];
            alltrdata = [];
            for tr = 1 : length(intervals.start)-1
                alltrpolar = [alltrpolar;polar(isbetween(polar.time,intervals.end(tr),intervals.start(tr+1)),:)];
                alltrdata = [alltrdata;data(isbetween(data.time,intervals.end(tr),intervals.start(tr+1)),:)];
            end
            Sess2.MEAN.alltr {idx_user,2} = nanmean(alltrpolar.rate);
            Sess2.MEDIAN.alltr {idx_user,2} = nanmedian(alltrpolar.rate);
            Sess2.SD.alltr {idx_user,2} = nanstd(alltrpolar.rate);
            Sess2.p25.alltr {idx_user,2} = prctile(alltrpolar.rate,25);
            Sess2.p75.alltr {idx_user,2} = prctile(alltrpolar.rate,75);

            Sess2.MEAN.alltr {idx_user,k}= nanmean(alltrdata.rate);
            Sess2.MEDIAN.alltr {idx_user,k} = nanmedian(alltrdata.rate);
            Sess2.SD.zone.alltr {idx_user,k}= nanstd(alltrdata.rate);
            Sess2.p25.alltr {idx_user,k} = prctile(alltrdata.rate,25);
            Sess2.p75.alltr {idx_user,k} = prctile(alltrdata.rate,75);

            k=k+1;
        end
    end
end