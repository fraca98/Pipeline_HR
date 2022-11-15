function dataRetimed = retimeHR(data, timestep)
%retimeHR function that retimes the given `data` timetable to a  
%new timetable with homogeneous `timestep`. It puts nans where heart rate
%datapoints are missing and it uses mean to solve conflicts (i.e., when two
%heart rate datapoints have the same retimed timestamp.
%
%Inputs:
%   - data: a timetable with column `Time` and `rate` containing the 
%   heart rate data to retime;
%   - timestep: an integer (in seconds) defining the timestep to use in the new timetable. 
%Output:
%   - dataRetimed: the retimed timetable.
%
%Preconditions:
%   - data must be a timetable;
%   - data must contain a column named `Time` and another named `rate`;
%   - timestep must be an integer.
%
% ------------------------------------------------------------------------
% 
% Reference:
%   - None
% 
% ------------------------------------------------------------------------
%
% Copyright of the original script part of AGATA(C) 2020 Giacomo Cappon
%
% https://github.com/gcappon/agata/blob/master/src/processing/retimeGlucose.m
%
% ---------------------------------------------------------------------
    
    %Check preconditions 
    if(~istimetable(data))
        error('retimeHR: data must be a timetable.');
    end
    if(~any(strcmp(fieldnames(data),'Time')))
        error('retimeHR: data must have a column named `Time`.')
    end
    if(~any(strcmp(fieldnames(data),'rate')))
        error('retimeHR: data must have a column named `rate`.')
    end
    if( ~( isnumeric(timestep) && ((timestep - round(timestep)) == 0) ) )
        error('retimeHR: timestep must be an integer.')
    end
    
    
    %Create the new timetable
    %data.Time.Second(1) = round(data.Time.Second(1)/60)*60; % starting
    %from 0 seconds for newTime
    newTime = data.Time(1):seconds(timestep):data.Time(end); %step as seconds
    dataRetimed = timetable(nan(length(newTime),1),nan(length(newTime),1),'VariableNames', {'rate','k'}, 'RowTimes', newTime);
    
    %Remove nan entries from data
    data = data(~isnan(data.rate),:);
    
    for t = 1:length(data.Time)
        
        %Find the nearest timestamp
        distances = abs(data.Time(t) - dataRetimed.Time);
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

