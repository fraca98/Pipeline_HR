function dataRetimed = MStoS(data)
%MStoS function that retimes the given `data` timetable to a  
%new timetable with step of 1 sec. It puts nans where heart rate
%datapoints are missing and it uses mean to solve conflicts (i.e., when two
%heart rate datapoints have the same retimed timestamp.
%
%Inputs:
%   - data: a timetable with column `time` and `rate` containing the 
%   heart rate data to retime;
%Output:
%   - dataRetimed: the retimed timetable.
%
%Preconditions:
%   - data must be a timetable;
%   - data must contain a column named `time` and another named `rate`;
%
% ------------------------------------------------------------------------
% 
%Reference:
%   - AGATA(C) 2020 Giacomo Cappon
% 
% ------------------------------------------------------------------------
    
    %Check preconditions 
    if(~istimetable(data))
        error('retimeHR: data must be a timetable.');
    end
    if(~any(strcmp(fieldnames(data),'time')))
        error('retimeHR: data must have a column named `time`.')
    end
    if(~any(strcmp(fieldnames(data),'rate')))
        error('retimeHR: data must have a column named `rate`.')
    end
    
    %Shift to seconds without milliseconds (start)
    data.time = dateshift(data.time, 'start', 'second');

    %Create the new timetable
    newTime = data.time(1):seconds(1):data.time(end); %step as 1 second
    dataRetimed = timetable(nan(length(newTime),1),nan(length(newTime),1),'VariableNames', {'rate','k'}, 'RowTimes', newTime);
    dataRetimed.Properties.DimensionNames{1} = 'time'; %rename column 'Time' to 'time
    
    %Remove nan entries from data
    data = data(~isnan(data.rate),:);
    
    for t = 1:length(data.time)
        
        %Find the nearest timestamp
        distances = abs(data.time(t) - dataRetimed.time);
        nearest = find(min(distances) == distances,1,'first');
        %Manage conflicts computing their average
        if(isnan(dataRetimed.rate(nearest)))
            dataRetimed.rate(nearest) = data.rate(t);
            dataRetimed.k(nearest) = 1;
        else
            dataRetimed.rate(nearest) = dataRetimed.rate(nearest) + data.rate(t);
            dataRetimed.k(nearest) = dataRetimed.k(nearest)+ 1;
        end
        
    end
    
    %Compute the average and remove column 'k'
    dataRetimed.rate = round(dataRetimed.rate ./ dataRetimed.k);
    dataRetimed.k = [];
end



