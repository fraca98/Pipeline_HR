clear
close all
clc
%%
topLevelFolder = pwd;
disp(topLevelFolder);
files = dir(topLevelFolder);
dirFlags = [files.isdir];
% Extract only those that are directories.
subDirs = files(dirFlags);
% Get only the folder names into a cell array.
subDirsNames = {subDirs(3:end).name};

%% Lop for sessions
for i = 1: size(subDirsNames,2) %i = 1 : 2
    csvs = dir(fullfile(topLevelFolder,subDirsNames{1,i}));
    csv_names = {csvs(3:end).name};
    csv_names = string(csv_names);

    figure(i),hold on

    tf_intervals = startsWith(csv_names, 'intervals');
    if(ismember(1,tf_intervals) == 1)
        intervals = readtable(fullfile(topLevelFolder, subDirsNames{1,i},csv_names(tf_intervals)));
        for k=1:size(intervals,2)
            xline(intervals.startimesamp(k),'HandleVisibility','off')
            xline(intervals.endtimestamp(k),'HandleVisibility','off')
        end
        for k=1:size(intervals,2)-1
            x_fill=[intervals.endtimestamp(k),intervals.endtimestamp(k),intervals.startimesamp(k+1),intervals.startimesamp(k+1)];
            y_fill=[0,250,250,0];
            a = fill(x_fill,y_fill,'yellow','HandleVisibility','off');
            a.FaceAlpha = 0.5;
        end
    end


    tf_polar = startsWith(csv_names,'polar'); %% take polar file name
    if(ismember(1,tf_polar) == 1)
        polar = readtable(fullfile(topLevelFolder, subDirsNames{1,i},csv_names(tf_polar)));
        plot(polar.timestamp, polar.value, Color='red', DisplayName='Polar')
    end

    tf_fitbit = startsWith(csv_names,'fitbit'); %% take fitbit file name
    if(ismember(1,tf_fitbit) == 1)
        fitbit = readtable(fullfile(topLevelFolder, subDirsNames{1,i},csv_names(tf_fitbit)));
        plot(fitbit.timestamp, fitbit.value, Color='blue', DisplayName='Fitbit')
    end
    tf_apple = startsWith(csv_names,'Apple'); %% take apple file name
    if(ismember(1,tf_apple) == 1)
        apple = readtable(fullfile(topLevelFolder, subDirsNames{1,i},csv_names(tf_apple)));
        apple.time.TimeZone = '+01:00'; %specify correct timezone
        apple_timestamp = posixtime(apple.time);
        idx_timestamp = find(apple_timestamp >= intervals.startimesamp(1) & apple_timestamp <= intervals.endtimestamp(end));
        %apple_res = apple(idx_timestamp,:);
        plot(apple_timestamp(idx_timestamp), apple.rate(idx_timestamp), Color='black', DisplayName='Apple')
    end
    tf_withings = startsWith(csv_names,'withings'); %% take withings file name
    if(ismember(1,tf_withings) == 1)
        withings = readtable(fullfile(topLevelFolder, subDirsNames{1,i},csv_names(tf_withings)));
        plot(withings.timestamp, withings.value, Color='green', DisplayName='Withings')
    end

    tf_garmin = startsWith(csv_names,'garmin'); %% take garmin file name
    if(ismember(1,tf_garmin) == 1)
        garmin = readtable(fullfile(topLevelFolder, subDirsNames{1,i},csv_names(tf_garmin)));
        plot(garmin.timestamp, garmin.value, Color='magenta', DisplayName='Garmin')
    end
    ylim([35 200]);
    %ticks = polar.timestamp-polar.timestamp(1);
    %xticks(ticks(1:10:end));
    set(gca,'FontSize',13)
    legend('Location','eastoutside')
    %hold off

end