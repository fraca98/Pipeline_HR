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
for idx_user = 1:1 %size(users_DirsNames,2)
    userPath = fullfile(dataPath,users_DirsNames(idx_user));
    user_fd = dir(userPath);
    user_Flags = [user_fd.isdir];
    sessions_Dirs = user_fd(user_Flags);
    sessions_DirsNames = {sessions_Dirs(3:end).name};
    sessions_DirsNames = string(sessions_DirsNames);
    sessions_DirsNames(startsWith(sessions_DirsNames,'Questionnaires')) = []; %remove the Questionnaires folder when i iterate sessions
    figure()
    sgtitle('idUser '+ users_DirsNames(idx_user))

    % Loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2) %i = 1 : 2
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % Get only the folder names into a cell array.
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        subplot(2,1,idx_session),hold on

        tf_session = startsWith(csv_names, 'session');
        session = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_session)),"VariableNamingRule",'preserve');
        %Shift to seconds without milliseconds (start)
        session.start = dateshift(session.start, 'start', 'second');
        session.end = dateshift(session.end, 'start', 'second');

        tf_intervals = startsWith(csv_names, 'intervals');
        intervals = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_intervals)),"VariableNamingRule",'preserve');
        %Shift to seconds without milliseconds (start)
        intervals.start = dateshift(intervals.start, 'start', 'second');
        intervals.end = dateshift(intervals.end, 'start', 'second');

        %color from start session to first interval
        x_fill=[session.start,session.start,intervals.start(1),intervals.start(1)];
        y_fill=[0,250,250,0];
        a = fill(x_fill,y_fill,'yellow','HandleVisibility','off');
        a.FaceAlpha = 0.5;

        %plot vertical line for end session (end last interval)
        xline(session.end,'HandleVisibility','off');

        %color each interval
        for k=1:size(intervals,2)-1
            x_fill=[intervals.end(k),intervals.end(k),intervals.start(k+1),intervals.start(k+1)];
            y_fill=[0,250,250,0];
            a = fill(x_fill,y_fill,'yellow','HandleVisibility','off');
            a.FaceAlpha = 0.5;
        end


        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
        polar = retimeSec(polar,1);
        polar(isnan(polar.rate),:)=[]; %remove NaN to have a continue plot
        plot(polar.time, polar.rate, Color='red', DisplayName='Polar')

        tf_fitbit = startsWith(csv_names,'fitbit'); %% take fitbit file name
        if(ismember(1,tf_fitbit) == 1)
            fitbit = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_fitbit)));
            plot(fitbit.time, fitbit.rate, Color='blue', DisplayName='Fitbit')
        end

        tf_apple = startsWith(csv_names,'apple'); %% take apple file name
        if(ismember(1,tf_apple) == 1)
            apple = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_apple)));
            plot(apple.time, apple.rate, Color='black', DisplayName='Apple')
        end

        tf_withings = startsWith(csv_names,'withings'); %% take withings file name
        if(ismember(1,tf_withings) == 1)
            withings = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_withings)));
            plot(withings.time, withings.rate, Color='green', DisplayName='Withings')
        end

        tf_garmin = and(startsWith(csv_names,'garmin'),endsWith(csv_names,'.csv')); %% take garmin file name (.csv)
        if(ismember(1,tf_garmin) == 1)
            garmin = readtable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_garmin)));
            plot(garmin.time, garmin.rate, Color='yellow', DisplayName='Garmin')
        end
        ylim([35 200]);
        set(gca,'FontSize',13)
        legend('Location','eastoutside')
    end
end

%% Creation TimeTable and retiming
for idx_user = 1:1 %size(users_DirsNames,2)
    userPath = fullfile(dataPath,users_DirsNames(idx_user));
    user_fd = dir(userPath);
    user_Flags = [user_fd.isdir];
    sessions_Dirs = user_fd(user_Flags);
    sessions_DirsNames = {sessions_Dirs(3:end).name};
    sessions_DirsNames = string(sessions_DirsNames);
    sessions_DirsNames(startsWith(sessions_DirsNames,'Questionnaires')) = []; %remove the Questionnaires folder when i iterate sessions

    figure() % a figure for each user
    sgtitle('idUser '+ users_DirsNames(idx_user))

    % Loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2) %i = 1 : 2
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % Get only the folder names into a cell array.
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        tf_fitbit = startsWith(csv_names,'fitbit'); %% take fitbit file name
        if(ismember(1,tf_fitbit) == 1)
            fitbit = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_fitbit)));
            polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar = retimeSec(polar,1);
            polar(isnan(polar.rate),:)=[]; %remove NaN to have a continue plot

            idCp = ismember(polar.time,fitbit.time);
            idCf = ismember(fitbit.time,polar.time);

            polar(idCp==0,:)=[];
            fitbit(idCf==0,:)=[];

            subplot(221), hold on
            plot(polar.time, polar.rate,'-o',Color='red', DisplayName='Polar')
            plot(fitbit.time, fitbit.rate,'-o',Color='blue', DisplayName='Fitbit')
            legend('Location','northwest')
        end

        tf_apple = startsWith(csv_names,'apple'); %% take apple file name
        if(ismember(1,tf_apple) == 1)
            apple = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_apple)));
            polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar = retimeSec(polar,1);
            polar(isnan(polar.rate),:)=[];

            idCp = ismember(polar.time,apple.time);
            idCa = ismember(apple.time,polar.time);

            polar(idCp==0,:)=[];
            apple(idCa==0,:)=[];

            subplot(222),hold on
            plot(polar.time, polar.rate,'-o','Color','red','DisplayName','Polar')
            plot(apple.time, apple.rate,'-o','Color','black','DisplayName','Apple')
            legend('Location','northwest')

        end
        tf_withings = startsWith(csv_names,'withings'); %% take withings file name
        if(ismember(1,tf_withings) == 1)
            withings = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_withings)));
            polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar = retimeSec(polar,1);
            polar(isnan(polar.rate),:)=[];

            idCp = ismember(polar.time,withings.time);
            idCw = ismember(withings.time,polar.time);

            polar(idCp==0,:)=[];
            withings(idCw==0,:)=[];


            subplot(223),hold on
            plot(polar.time, polar.rate,'-o',Color='red', DisplayName='Polar')
            plot(withings.time, withings.rate,'-o',Color='green', DisplayName='Withings')
            legend('Location','northwest')

        end


        tf_garmin = and(startsWith(csv_names,'garmin'), endsWith(csv_names,'.csv')); %% take garmin file name csv
        if(ismember(1,tf_garmin) == 1)
            garmin = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_garmin)));
            polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar = retimeSec(polar,1);
            polar(isnan(polar.rate),:)=[];

            idCp = ismember(polar.time,garmin.time);
            idCg = ismember(garmin.time,polar.time);

            polar(idCp==0,:)=[];
            garmin(idCg==0,:)=[];

            subplot(224),hold on
            plot(polar.time, polar.rate,'-o', Color='red', DisplayName='Polar')
            plot(garmin.time, garmin.rate,'-o', Color='yellow', DisplayName='Garmin')
            legend('Location','northwest')

        end

    end
end

%% Calculate differences and RMSE %TODO: fix here retime polar with new data type
RMSEmat = [];

for idx_user = 1:1%size(users_DirsNames,2)
    userPath = fullfile(dataPath,users_DirsNames(idx_user));
    user_fd = dir(userPath);
    user_Flags = [user_fd.isdir];
    sessions_Dirs = user_fd(user_Flags);
    sessions_DirsNames = {sessions_Dirs(3:end).name};
    sessions_DirsNames = string(sessions_DirsNames);
    sessions_DirsNames(startsWith(sessions_DirsNames,'Questionnaires')) = []; %remove the Questionnaires folder when i iterate sessions

    RMSEmat(idx_user,1) = users_DirsNames(idx_user);

    figure() % a figure for each user
    sgtitle('idUser '+ users_DirsNames(idx_user))

    % Loop for sessions for each user (iterate for session)
    for idx_session = 1: size(sessions_DirsNames,2) %i = 1 : 2
        csvs = dir(fullfile(userPath,sessions_DirsNames(idx_session)));
        % Get only the folder names into a cell array.
        csv_names = {csvs(3:end).name};
        csv_names = string(csv_names);

        tf_polar = startsWith(csv_names,'polar'); %% take polar file name
        tf_fitbit = startsWith(csv_names,'fitbit'); %% take fitbit file name
        if(ismember(1,tf_fitbit) == 1)
            fitbit = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_fitbit)));
            polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar = retimeSec(polar,1);
            polar(isnan(polar.rate),:)=[]; %remove NaN to have a continue plot

            idCp = ismember(polar.time,fitbit.time);
            idCf = ismember(fitbit.time,polar.time);

            polar(idCp==0,:)=[];
            fitbit(idCf==0,:)=[];

            res = (fitbit.rate - polar.rate)./polar.rate; %how much fitbit is lower/higher than polar in %
            subplot(221), hold on
            plot(polar.time,res,'-o',Color='blue');
            yline(0,'--k')
            title('Fitbit - Polar')

            RMSEmat(idx_user,2) = sqrt(immse(polar.rate, fitbit.rate)); %RMSE (root mean square error)
        end

        tf_apple = startsWith(csv_names,'apple'); %% take apple file name
        if(ismember(1,tf_apple) == 1)
            apple = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_apple)));
            polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar = retimeSec(polar,1);
            polar(isnan(polar.rate),:)=[];

            idCp = ismember(polar.time,apple.time);
            idCa = ismember(apple.time,polar.time);

            polar(idCp==0,:)=[];
            apple(idCa==0,:)=[];

            res = (apple.rate - polar.rate)./apple.rate; %how much apple is lower/higher than polar in %

            subplot(222),hold on
            plot(polar.time,res,'-o',Color='black');
            yline(0,'--k')
            title('Apple - Polar')

            RMSEmat(idx_user,3) = sqrt(immse(polar.rate, apple.rate)); %RMSE (root mean square error)

        end
        tf_withings = startsWith(csv_names,'withings'); %% take withings file name
        if(ismember(1,tf_withings) == 1)
            withings = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_withings)));
            polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar = retimeSec(polar,1);
            polar(isnan(polar.rate),:)=[];

            idCp = ismember(polar.time,withings.time);
            idCw = ismember(withings.time,polar.time);

            polar(idCp==0,:)=[];
            withings(idCw==0,:)=[];

            res = (withings.rate - polar.rate)./polar.rate; %how much withings is lower/higher than polar in %

            subplot(223),hold on
            plot(polar.time,res,'-o',Color='green');
            yline(0,'--k')
            title('Fitbit - Withings')

            RMSEmat(idx_user,4) = sqrt(immse(polar.rate, withings.rate)); %RMSE (root mean square error)
        end


        tf_garmin = and(startsWith(csv_names,'garmin'), endsWith(csv_names,'.csv')); %% take garmin file name .csv
        if(ismember(1,tf_garmin) == 1)
            garmin = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_garmin)));
            polar = readtimetable(fullfile(userPath,sessions_DirsNames(idx_session), csv_names(tf_polar)));
            polar = retimeSec(polar,1);
            polar(isnan(polar.rate),:)=[];

            idCp = ismember(polar.time,garmin.time);
            idCg = ismember(garmin.time,polar.time);

            polar(idCp==0,:)=[];
            garmin(idCg==0,:)=[];

            res = (garmin.rate - polar.rate)./polar.rate; %how much garmin is lower/higher than polar in %

            subplot(223),hold on
            plot(polar.time,res,'-o',Color='yellow');
            yline(0,'k--')
            title('Fitbit - Garmin')

            RMSEmat(idx_user,5) = sqrt(immse(polar.rate, garmin.rate)); %RMSE (root mean square error)

        end

    end
end

%%
figure, boxplot(RMSEmat(:,2:end),'Labels',{'Fitbit','Apple','Withings'});
ylabel('RMSE')
RMSE = array2table(RMSEmat);
RMSE.Properties.VariableNames(1:4) = {'ID','Fitbit','Apple','Withings'};



