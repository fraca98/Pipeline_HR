function mae = mae(data,dataHat)
%mae function that computes the mean absolute error (MAE) between 
%two heart rate traces (ignores nan values).
%
%Inputs:
%   - data: a timetable with column `time` and `rate` containing the 
%   heart rate data;
%   - dataHat: a timetable with column `time` and `rate` containing the 
%   heart rate data to compare with `data`.
%Output:
%   - mae: the mean absolute error.
%
%Preconditions:
%   - data and dataHat must be a timetable having the same time grid;
%   - data and dataHat must contain a column named `time` and another named `rate`;
%
% ------------------------------------------------------------------------
% 
% Reference:
%   - https://en.wikipedia.org/wiki/Mean_absolute_error
%     (Accessed: 2022-12-01)
% 
% ------------------------------------------------------------------------
    
    %Check preconditions 
    if(~istimetable(data))
        error('mae: data must be a timetable.');
    end
    if(~istimetable(data))
        error('mae: dataHat must be a timetable.');
    end
    if(~isequal(data.time,dataHat.time))
        error('rmse: data and dataHat must have the same time grid.')
    end
    if(~any(strcmp(fieldnames(data),'time')))
        error('mae: data must have a column named `time`.')
    end
    if(~any(strcmp(fieldnames(data),'rate')))
        error('mae: data must have a column named `rate`.')
    end
    if(~any(strcmp(fieldnames(dataHat),'time')))
        error('mae: dataHat must have a column named `time`.')
    end
    if(~any(strcmp(fieldnames(dataHat),'rate')))
        error('mae: dataHat must have a column named `rate`.')
    end
    
    %Get indices having no nans in both timetables
    idx = find(~isnan(dataHat.rate) & ~isnan(data.rate));
    
    %Compute metric
    mae = (mean(abs( data.rate(idx) - dataHat.rate(idx) )));
    
end