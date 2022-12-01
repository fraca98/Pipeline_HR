function timeDelay = timeDelay(data,dataHat)
%timeDelay function that computes the delay of two heart rate data signals. 
%The time delay is computed as the time shift necessary to maximize the 
%correlation between the two signals.
%
%Inputs:
%   - data: a timetable with column `time` and `rate` containing a heart rate data;
%   - dataHat: a timetable with column `time` and `rate` containing the heart
%     rate data to compare with `data`;
%Output:
%   - timeDelay: the computed delay (min).
%
%Preconditions:
%   - data and dataHat must be a timetable having an homogeneous time grid;
%   - data and dataHat must contain a column named `time` and another named `rate`;
%   - data and dataHat must start from the same timestamp;
%   - data and dataHat must end with the same timestamp;
%   - data and dataHat must have the same length.
%
% ------------------------------------------------------------------------
% 
% Reference:
%   - AGATA(C) 2020 Giacomo Cappon
%     https://github.com/gcappon/agata
% 
% ------------------------------------------------------------------------
    
    %Check preconditions 
    if(~istimetable(data))
        error('timeDelay: data must be a timetable.');
    end
    if(var(seconds(diff(data.time))) > 0 || isnan(var(seconds(diff(data.time)))))
        error('timeDelay: data must have a homogeneous time grid.')
    end
    if(~istimetable(data))
        error('timeDelay: dataHat must be a timetable.');
    end
    if(var(seconds(diff(data.time))) > 0)
        error('timeDelay: dataHat must have a homogeneous time grid.')
    end
    if(data.time(1) ~= dataHat.time(1))
        error('timeDelay: data and dataHat must start from the same timestamp.')
    end
    if(data.time(end) ~= dataHat.time(end))
        error('timeDelay: data and dataHat must end with the same timestamp.')
    end
    if(height(data) ~= height(dataHat))
        error('timeDelay: data and dataHat must have the same length.')
    end
    if(~any(strcmp(fieldnames(data),'time')))
        error('timeDelay: data must have a column named `time`.')
    end
    if(~any(strcmp(fieldnames(data),'rate')))
        error('timeDelay: data must have a column named `rate`.')
    end
    if(~any(strcmp(fieldnames(dataHat),'time')))
        error('timeDelay: dataHat must have a column named `time`.')
    end
    if(~any(strcmp(fieldnames(dataHat),'rate')))
        error('timeDelay: dataHat must have a column named `rate`.')
    end
    
    %Get indices having no nans in both timetables
    idx = find(~isnan(dataHat.rate) & ~isnan(data.rate));
    
    %Compute metric
    timeDelay = finddelay( data.rate(idx), dataHat.rate(idx)) * minutes(data.time(2)-data.time(1));
    
end