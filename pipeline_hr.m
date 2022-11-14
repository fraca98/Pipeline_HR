clear
close all
clc
%%
filePath = matlab.desktop.editor.getActiveFilename; % Get the filepath of the script
projectPath = fileparts(filePath); % Take directory of folder containing filePath
dataPath = fullfile(projectPath,'data');
%%
data_fd = dir(dataPath);
data_Flags = [data_fd.isdir];
% Extract only those that are directories.
users_Dirs = data_fd(data_Flags);
% Get only the folder names into a cell array.
users_DirsNames = {users_Dirs(3:end).name};
users_DirsNames = string(users_DirsNames);

%% Loop in data folder for each user folder (iterate for user)
for idx_user = 1:size(users_DirsNames,2)
    userPath = fullfile(dataPath,users_DirsNames(idx_user));
    user_fd = dir(userPath);
    user_Flags = [user_fd.isdir];
    sessions_Dirs = user_fd(user_Flags);
    sessions_DirsNames = {sessions_Dirs(3:end).name};
    sessions_DirsNames = string(sessions_DirsNames);

    %% Loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2) %i = 1 : 2
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % Get only the folder names into a cell array.
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        figure(),hold on

        tf_intervals = startsWith(csv_names, 'intervals');
        if(ismember(1,tf_intervals) == 1)
            intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)));
            for k=1:size(intervals,2)
                xline(intervals.starttimestamp(k),'HandleVisibility','off')
                xline(intervals.endtimestamp(k),'HandleVisibility','off')
            end
            for k=1:size(intervals,2)-1
                x_fill=[intervals.endtimestamp(k),intervals.endtimestamp(k),intervals.starttimestamp(k+1),intervals.starttimestamp(k+1)];
                y_fill=[0,250,250,0];
                a = fill(x_fill,y_fill,'yellow','HandleVisibility','off');
                a.FaceAlpha = 0.5;
            end
        end


        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        if(ismember(1,tf_polar) == 1)
            polar = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            plot(polar.timestamp, polar.value, Color='red', DisplayName='Polar')
        end

        tf_fitbit = startsWith(csv_names,'fitbit'); %% take fitbit file name
        if(ismember(1,tf_fitbit) == 1)
            fitbit = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_fitbit)));
            plot(fitbit.timestamp, fitbit.value, Color='blue', DisplayName='Fitbit')
        end
        tf_apple = startsWith(csv_names,'Apple'); %% take apple file name
        if(ismember(1,tf_apple) == 1)
            apple = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_apple)));
            apple.time.TimeZone = '+01:00'; %specify correct timezone
            apple_timestamp = posixtime(apple.time);
            idx_timestamp = find(apple_timestamp >= intervals.starttimestamp(1) & apple_timestamp <= intervals.endtimestamp(end));
            %apple_res = apple(idx_timestamp,:);
            plot(apple_timestamp(idx_timestamp), apple.rate(idx_timestamp), Color='black', DisplayName='Apple')
        end
        tf_withings = startsWith(csv_names,'withings'); %% take withings file name
        if(ismember(1,tf_withings) == 1)
            withings = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_withings)));
            plot(withings.timestamp, withings.value, Color='green', DisplayName='Withings')
        end

        tf_garmin = startsWith(csv_names,'garmin'); %% take garmin file name
        if(ismember(1,tf_garmin) == 1)
            garmin = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_garmin)));
            plot(garmin.timestamp, garmin.value, Color='magenta', DisplayName='Garmin')
        end
        ylim([35 200]);
        set(gca,'FontSize',13)
        legend('Location','eastoutside')
    end
end