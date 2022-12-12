function mard = mard(data,dataHat)
%mard function that computes the mean absolute relative difference (MARD) 
%between two heart rate traces (ignores nan values).
%
%Inputs:
%   - data: a timetable with column `time` and `rate` containing a 
%   heart rate data;
%   - dataHat: a timetable with column `time` and `rate` containing the
%   heart rate data to compare with `data`.
%Output:
%   - mard: the computed mean absolute relative difference (%).
%
%Preconditions:
%   - data and dataHat must be a timetable having the same time grid;
%   - data and dataHat must contain a column named `time` and another named `rate`;
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
        error('mard: data must be a timetable.');
    end
    if(~istimetable(data))
        error('mard: dataHat must be a timetable.');
    end
    if(~isequal(data.time,dataHat.time))
        error('rmse: data and dataHat must have the same time grid.')
    end
    if(~any(strcmp(fieldnames(data),'time')))
        error('mard: data must have a column named `time`.')
    end
    if(~any(strcmp(fieldnames(data),'rate')))
        error('mard: data must have a column named `rate`.')
    end
    if(~any(strcmp(fieldnames(dataHat),'time')))
        error('mard: dataHat must have a column named `time`.')
    end
    if(~any(strcmp(fieldnames(dataHat),'rate')))
        error('mard: dataHat must have a column named `rate`.')
    end
    
    %Get indices having no nans in both timetables
    idx = find(~isnan(dataHat.rate) & ~isnan(data.rate));
    
    %Compute metric
    mard = 100 * mean(abs( data.rate(idx) - dataHat.rate(idx) ) ./ data.rate(idx) );
    
end