function dataRetimed = retimeHR(data, timestep,startdate,enddate)
%retimeHR function that retimes the given `data` timetable to a  
%new timetable with homogeneous `timestep`. If defined `startdate` and `enddate`
%the new time grid will be created with the following dates at start and end.
%It puts nans where heart rate datapoints are missing and it uses mean to solve
%conflicts (i.e., when two heart rate datapoints have the same retimed timestamp)S.
%
%Inputs:
%   - data: a timetable with column `time` and `rate` containing the 
%   heart rate data to retime;
%   - timestep: an integer (in seconds) defining the timestep to use in the new timetable.
%   - startdate: a date defining the initial date of the new time grid.
%   Optional
%   - enddate: a date defining the final date of the new time grid. Optional 
%Output:
%   - dataRetimed: the retimed timetable.
%
%Preconditions:
%   - data must be a timetable;
%   - data must contain a column named `time` and another named `rate`;
%   - timestep must be an integer.
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
    if( ~( isnumeric(timestep) && ((timestep - round(timestep)) == 0) ) )
        error('retimeHR: timestep must be an integer.')
    end

    %Create the new timetable
    if (nargin == 2)
        newTime = data.time(1):seconds(timestep):data.time(end);
        %TODO? check if date.time(end) contained else add newTime = [newTime, data.time(end)]
    elseif (nargin == 4)
        newTime = startdate:seconds(timestep):enddate;
    else
        error('retimeHR: wrong input arguments.')
    end

    dataRetimed = timetable(nan(length(newTime),1),nan(length(newTime),1),'VariableNames', {'rate','k'}, 'RowTimes', newTime);
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



