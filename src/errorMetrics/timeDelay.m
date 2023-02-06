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
%   - timeDelay: the computed delay (s).
%
%Preconditions:
%   - data and dataHat must be a timetable the same time grid;
%   - data and dataHat must contain a column named `time` and another named `rate`;
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
    if(~istimetable(data))
        error('timeDelay: dataHat must be a timetable.');
    end
    if(~isequal(data.time,dataHat.time))
        error('rmse: data and dataHat must have the same time grid.')
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



    %If i have only NAN i can't compare, so output NaN
    if (isempty(data.rate(idx)))
        timeDelay = NaN;
        return
    end

    
    %Compute metric
    timeDelay = finddelay(data.rate(idx), dataHat.rate(idx)); %sistemare
    
end