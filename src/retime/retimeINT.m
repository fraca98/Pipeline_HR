function retimedArray = retimeINT(time, timestep)
%retimeINT function that retimes the given array of times to new array of times  
% with homogeneous `timestep`.
%
%Inputs:
%   - time: an array of datetimes (times) of intervals;
%   - timestep: an integer (in seconds) defining the timestep to use in the new time array.
%Output:
%   - dataRetimed: the retimed timetable.
%
%Preconditions:
%   - time must be a datetime array;
%   - timestep must be an integer.
%
% ------------------------------------------------------------------------
% 
%Reference:
%   - AGATA(C) 2020 Giacomo Cappon
% 
% ------------------------------------------------------------------------
    
    %Check preconditions 
    if(~isdatetime(time))
        error('retimeHR: data must be a datetime.');
    end

    data = timetable(time,ones(length(time),1));
    data.Properties.VariableNames = {'rate'};  

    %Create the new timetable
    newTime = data.time(1):seconds(timestep):data.time(end);

    dataRetimed = timetable(nan(length(newTime),1),'VariableNames', {'rate'}, 'RowTimes', newTime);
    dataRetimed.Properties.DimensionNames{1} = 'time'; %rename column 'Time' to 'time'
    
    %Remove nan entries from data
    data = data(~isnan(data.rate),:);
    
    for t = 1:length(data.time)
        %Find the nearest timestamp
        distances = abs(data.time(t) - dataRetimed.time);
        nearest = find(min(distances) == distances,1,'first');
        %Manage conflicts computing their average
        if(isnan(dataRetimed.rate(nearest)))
            dataRetimed.rate(nearest) = data.rate(t);
        else
            dataRetimed.rate(nearest) = dataRetimed.rate(nearest) + data.rate(t);
        end
        
    end
    
    %Compute the new array times (the rate refers the number of
    %intervals times that are equal in the new grid)
    %To maintain the number of intervals (length time/2)
    retimed = dataRetimed(~isnan(dataRetimed.rate),:);
    retimedArray = NaT(length(time)/2,1);
    k=1;
    for i=1:size(retimed,1)
        for j=1:retimed.rate(i)
            retimedArray(k)=retimed.time(i);
            k=k+1;
        end
    end    
end


