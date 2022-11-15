clear
close all
clc
%%
filePath = matlab.desktop.editor.getActiveFilename; % Get the filepath of the script
projectPath = fileparts(filePath); % Take directory of folder containing filePath
dataPath = fullfile(projectPath,'data');
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

    figure()
    sgtitle('ID '+ users_DirsNames(idx_user))

    % Loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2) %i = 1 : 2
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % Get only the folder names into a cell array.
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        subplot(2,1,idx_session),hold on

        tf_intervals = startsWith(csv_names, 'intervals');
        intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)));
        for k=1:size(intervals,2)
            xline(datetime(intervals.starttimestamp(k),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'),'HandleVisibility','off')
            xline(datetime(intervals.endtimestamp(k),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'),'HandleVisibility','off')
        end
        for k=1:size(intervals,2)-1
            x_fill=[datetime(intervals.endtimestamp(k),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'),datetime(intervals.endtimestamp(k),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'),datetime(intervals.starttimestamp(k+1),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'),datetime(intervals.starttimestamp(k+1),'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00')];
            y_fill=[0,250,250,0];
            a = fill(x_fill,y_fill,'yellow','HandleVisibility','off');
            a.FaceAlpha = 0.5;
        end


        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        polar = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
        polar.Time = datetime(polar.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
        polar = table2timetable(polar);
        polar = renamevars(polar,"value","rate");
        a = timeFix(polar.timestamp);
        polar = retimeHR(polar,1); %retime polar with 1 sec to solve duplicates values for same timestamp/Time
        plot(polar.Time, polar.rate, Color='red', DisplayName='Polar')

        tf_fitbit = startsWith(csv_names,'fitbit'); %% take fitbit file name
        if(ismember(1,tf_fitbit) == 1)
            fitbit = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_fitbit)));
            fitbit.Time = datetime(fitbit.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            fitbit = table2timetable(fitbit);
            fitbit = renamevars(fitbit,"value","rate");
            plot(fitbit.Time, fitbit.rate, Color='blue', DisplayName='Fitbit')
        end
        tf_apple = startsWith(csv_names,'Apple'); %% take apple file name
        if(ismember(1,tf_apple) == 1)
            apple = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_apple)));
            apple.time.TimeZone = '+01:00'; %specify correct timezone
            apple_timestamp = posixtime(apple.time);
            idx_timestamp = find(apple_timestamp >= intervals.starttimestamp(1) & apple_timestamp <= intervals.endtimestamp(end));
            apple = apple(idx_timestamp,:);
            apple = renamevars(apple,"time","Time");
            apple = table2timetable(apple);
            plot(apple.Time, apple.rate, Color='black', DisplayName='Apple')
        end
        tf_withings = startsWith(csv_names,'withings'); %% take withings file name
        if(ismember(1,tf_withings) == 1)
            withings = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_withings)));
            withings.Time = datetime(withings.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            withings = table2timetable(withings);
            withings = renamevars(withings,"value","rate");
            plot(withings.Time, withings.rate, Color='green', DisplayName='Withings')
        end

        tf_garmin = startsWith(csv_names,'garmin'); %% take garmin file name
        if(ismember(1,tf_garmin) == 1)
            garmin = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_garmin)));
            % TODO:
        end
        ylim([35 200]);
        set(gca,'FontSize',13)
        legend('Location','eastoutside')
    end
end

%% Creation TimeTable and retiming
for idx_user = 1:size(users_DirsNames,2)
    userPath = fullfile(dataPath,users_DirsNames(idx_user));
    user_fd = dir(userPath);
    user_Flags = [user_fd.isdir];
    sessions_Dirs = user_fd(user_Flags);
    sessions_DirsNames = {sessions_Dirs(3:end).name};
    sessions_DirsNames = string(sessions_DirsNames);

    figure() % a figure for each user
    sgtitle('ID '+ users_DirsNames(idx_user))

    % Loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2) %i = 1 : 2
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % Get only the folder names into a cell array.
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        tf_fitbit = startsWith(csv_names,'fitbit'); %% take fitbit file name
        if(ismember(1,tf_fitbit) == 1)
            fitbit = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_fitbit)));
            fitbit.Time = datetime(fitbit.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            fitbit = table2timetable(fitbit);
            fitbit = renamevars(fitbit,"value","rate");

            polar = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar.Time = datetime(polar.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            polar = table2timetable(polar);
            polar = renamevars(polar,"value","rate");
            polar = retimeHR(polar,1); %retime polar with 1 sec to solve duplicates values for same timestamp/Time

            maxT = max([polar.Time(1), fitbit.Time(1)]); %take the max of date of the first value and use it as 0 on x-grid
            polar.sec0Grid = etime(datevec(datenum(polar.Time)),datevec(datenum(maxT)));
            fitbit.sec0Grid = etime(datevec(datenum(fitbit.Time)),datevec(datenum(maxT)));
            polar(polar.sec0Grid<0,:)=[];
            polar(fitbit.sec0Grid<0,:)=[];

            subplot(221), hold on
            plot(polar.sec0Grid, polar.rate,Color='red', DisplayName='Polar')
            plot(fitbit.sec0Grid, fitbit.rate,Color='blue', DisplayName='Fitbit')
            legend('Location','northwest')
        end

        tf_apple = startsWith(csv_names,'Apple'); %% take apple file name
        if(ismember(1,tf_apple) == 1)
            apple = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_apple)));
            apple.time.TimeZone = '+01:00'; %specify correct timezone
            apple_timestamp = posixtime(apple.time);
            tf_intervals = startsWith(csv_names, 'intervals');
            intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)));
            idx_timestamp = find(apple_timestamp >= intervals.starttimestamp(1) & apple_timestamp <= intervals.endtimestamp(end));
            apple = apple(idx_timestamp,:);
            apple = renamevars(apple,"time","Time");
            apple = table2timetable(apple);

            polar = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar.Time = datetime(polar.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            polar = table2timetable(polar);
            polar = renamevars(polar,"value","rate");
            polar = retimeHR(polar,1); %retime polar with 1 sec to solve duplicates values for same timestamp/Time

            maxT = max([polar.Time(1), apple.Time(1)]); %take the max of date of the first value and use it as 0 on x-grid
            polar.sec0Grid = etime(datevec(datenum(polar.Time)),datevec(datenum(maxT)));
            apple.sec0Grid = etime(datevec(datenum(apple.Time)),datevec(datenum(maxT)));
            polar(polar.sec0Grid<0,:)=[];
            polar(apple.sec0Grid<0,:)=[];

            subplot(222),hold on
            plot(polar.sec0Grid, polar.rate,'Color','red','DisplayName','Polar')
            plot(apple.sec0Grid, apple.rate,'Color','black','DisplayName','Apple')
            legend('Location','northwest')

        end
        tf_withings = startsWith(csv_names,'withings'); %% take withings file name
        if(ismember(1,tf_withings) == 1)
            withings = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_withings)));
            withings.Time = datetime(withings.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            withings = table2timetable(withings);
            withings = renamevars(withings,"value","rate");

            polar = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar.Time = datetime(polar.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            polar = table2timetable(polar);
            polar = renamevars(polar,"value","rate");
            polar = retimeHR(polar,1); %retime polar with 1 sec to solve duplicates values for same timestamp/Time

            maxT = max([polar.Time(1), fitbit.Time(1)]); %take the max of date of the first value and use it as 0 on x-grid
            polar.sec0Grid = etime(datevec(datenum(polar.Time)),datevec(datenum(maxT)));
            withings.sec0Grid = etime(datevec(datenum(withings.Time)),datevec(datenum(maxT)));
            polar(polar.sec0Grid<0,:)=[];
            polar(withings.sec0Grid<0,:)=[];

            subplot(223),hold on
            plot(polar.sec0Grid, polar.rate,Color='red', DisplayName='Polar')
            plot(withings.sec0Grid, withings.rate,Color='green', DisplayName='Withings')
            legend('Location','northwest')

        end


        tf_garmin = startsWith(csv_names,'garmin'); %% take garmin file name
        if(ismember(1,tf_garmin) == 1)

            % TODO: Garmin


            polar = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar.Time = datetime(polar.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            polar = table2timetable(polar);
            polar = renamevars(polar,"value","rate");
            polar = retimeHR(polar,1); %retime polar with 1 sec to solve duplicates values for same timestamp/Time

            subplot(224),hold on
            plot(polar.Time, polar.rate, Color='red', DisplayName='Polar')
            %plot(garmin.Time, garmin.rate, Color='magenta', DisplayName='Garmin')
            legend('Location','northwest')

        end

    end
end

%% Calculate differences and RMSE
RMSEmat = [];

for idx_user = 1:size(users_DirsNames,2)
    userPath = fullfile(dataPath,users_DirsNames(idx_user));
    user_fd = dir(userPath);
    user_Flags = [user_fd.isdir];
    sessions_Dirs = user_fd(user_Flags);
    sessions_DirsNames = {sessions_Dirs(3:end).name};
    sessions_DirsNames = string(sessions_DirsNames);

    RMSEmat(idx_user,1) = users_DirsNames(idx_user);

    figure() % a figure for each user
    sgtitle('ID '+ users_DirsNames(idx_user))

    % Loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2) %i = 1 : 2
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % Get only the folder names into a cell array.
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        tf_fitbit = startsWith(csv_names,'fitbit'); %% take fitbit file name
        if(ismember(1,tf_fitbit) == 1)
            fitbit = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_fitbit)));
            fitbit.Time = datetime(fitbit.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            fitbit = table2timetable(fitbit);
            fitbit = renamevars(fitbit,"value","rate");

            polar = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar.Time = datetime(polar.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            polar = table2timetable(polar);
            polar = renamevars(polar,"value","rate");
            polar = retimeHR(polar,1); %retime polar with 1 sec to solve duplicates values for same timestamp/Time

            maxT = max([polar.Time(1), fitbit.Time(1)]); %take the max of date of the first value and use it as 0 on x-grid
            polar.sec0Grid = etime(datevec(datenum(polar.Time)),datevec(datenum(maxT)));
            fitbit.sec0Grid = etime(datevec(datenum(fitbit.Time)),datevec(datenum(maxT)));
            polar(polar.sec0Grid<0,:)=[];
            fitbit(fitbit.sec0Grid<0,:)=[];

            idCorresp = ismember(polar.sec0Grid,fitbit.sec0Grid);
            polar = polar(idCorresp,:);
            res = fitbit.rate - polar.rate; %how much fitbit is lower/higher than polar
            subplot(221), hold on
            plot(polar.sec0Grid,res,Color='blue');
            yline(0,'--')
            title('Fitbit - Polar')

            idxNaNPolar = isnan(polar.rate);
            idxNaNFitbit = isnan(fitbit.rate);
            polar(idxNaNPolar,:)=[];
            polar(idxNaNFitbit,:)=[];
            fitbit(idxNaNPolar,:)=[];
            fitbit(idxNaNFitbit,:)=[];
            RMSEmat(idx_user,2) = sqrt(immse(polar.rate, fitbit.rate)); %RMSE (root mean square error)



        end

        tf_apple = startsWith(csv_names,'Apple'); %% take apple file name
        if(ismember(1,tf_apple) == 1)
            apple = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_apple)));
            apple.time.TimeZone = '+01:00'; %specify correct timezone
            apple_timestamp = posixtime(apple.time);
            tf_intervals = startsWith(csv_names, 'intervals');
            intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)));
            idx_timestamp = find(apple_timestamp >= intervals.starttimestamp(1) & apple_timestamp <= intervals.endtimestamp(end));
            apple = apple(idx_timestamp,:);
            apple = renamevars(apple,"time","Time");
            apple = table2timetable(apple);

            polar = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar.Time = datetime(polar.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            polar = table2timetable(polar);
            polar = renamevars(polar,"value","rate");
            polar = retimeHR(polar,1); %retime polar with 1 sec to solve duplicates values for same timestamp/Time

            maxT = max([polar.Time(1), apple.Time(1)]); %take the max of date of the first value and use it as 0 on x-grid
            polar.sec0Grid = etime(datevec(datenum(polar.Time)),datevec(datenum(maxT)));
            apple.sec0Grid = etime(datevec(datenum(apple.Time)),datevec(datenum(maxT)));
            polar(polar.sec0Grid<0,:)=[];
            apple(apple.sec0Grid<0,:)=[];

            idCorresp = ismember(polar.sec0Grid,apple.sec0Grid);
            polar = polar(idCorresp,:);
            res = apple.rate - polar.rate; %how much apple is lower/higher than polar

            subplot(222),hold on
            plot(polar.sec0Grid,res,Color='black');
            yline(0,'--')
            title('Apple - Polar')

            idxNaNPolar = isnan(polar.rate);
            idxNaNApple = isnan(apple.rate);
            polar(idxNaNPolar,:)=[];
            polar(idxNaNApple,:)=[];
            apple(idxNaNPolar,:)=[];
            apple(idxNaNApple,:)=[];
            RMSEmat(idx_user,3) = sqrt(immse(polar.rate, apple.rate)); %RMSE (root mean square error)

        end
        tf_withings = startsWith(csv_names,'withings'); %% take withings file name
        if(ismember(1,tf_withings) == 1)
            withings = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_withings)));
            withings.Time = datetime(withings.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            withings = table2timetable(withings);
            withings = renamevars(withings,"value","rate");

            polar = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar.Time = datetime(polar.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            polar = table2timetable(polar);
            polar = renamevars(polar,"value","rate");
            polar = retimeHR(polar,1); %retime polar with 1 sec to solve duplicates values for same timestamp/Time

            maxT = max([polar.Time(1), withings.Time(1)]); %take the max of date of the first value and use it as 0 on x-grid
            polar.sec0Grid = etime(datevec(datenum(polar.Time)),datevec(datenum(maxT)));
            withings.sec0Grid = etime(datevec(datenum(withings.Time)),datevec(datenum(maxT)));
            polar(polar.sec0Grid<0,:)=[];
            withings(withings.sec0Grid<0,:)=[];

            idCorresp = ismember(polar.sec0Grid,withings.sec0Grid);
            polar = polar(idCorresp,:);
            res = withings.rate - polar.rate; %how much withings is lower/higher than polar

            subplot(223),hold on
            plot(polar.sec0Grid,res,Color='green');
            yline(0,'--')
            title('Fitbit - Withings')

            idxNaNPolar = isnan(polar.rate);
            idxNaNWithings = isnan(withings.rate);
            polar(idxNaNPolar,:)=[];
            polar(idxNaNWithings,:)=[];
            withings(idxNaNPolar,:)=[];
            withings(idxNaNWithings,:)=[];
            RMSEmat(idx_user,4) = sqrt(immse(polar.rate, withings.rate)); %RMSE (root mean square error)
        end


        tf_garmin = startsWith(csv_names,'garmin'); %% take garmin file name
        if(ismember(1,tf_garmin) == 1)

            % TODO: Garmin
            polar = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar.Time = datetime(polar.timestamp,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'); %convert to Date from Timestamp
            polar = table2timetable(polar);
            polar = renamevars(polar,"value","rate");
            polar = retimeHR(polar,1); %retime polar with 1 sec to solve duplicates values for same timestamp/Time

            subplot(224),hold on
            plot(polar.Time, polar.rate, Color='red', DisplayName='Polar')
            %plot(garmin.Time, garmin.rate, Color='magenta', DisplayName='Garmin')
            legend('Location','northwest')

        end

    end
end

%%
figure, boxplot(RMSEmat(:,2:end),'Labels',{'Fitbit','Apple','Withings'});
ylabel('RMSE')
RMSE = array2table(RMSEmat);
RMSE.Properties.VariableNames(1:4) = {'ID','Fitbit','Apple','Withings'};



