function cod = cod(data,dataHat)
%cod function that computes the coefficient of determination (COD) between 
%two heart rate traces (ignores nan values).
%
%Inputs:
%   - data: a timetable with column `time` and `rate` containing the 
%   heart rate data;
%   - dataHat: a timetable with column `time` and `rate` containing the 
%   heart rate data to compare with `data`.
%Output:
%   - cod: the computed coefficient of determination (%).
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
        error('cod: data must be a timetable.');
    end
    if(var(seconds(diff(data.time))) > 0 || isnan(var(seconds(diff(data.time)))))
        error('cod: data must have a homogeneous time grid.')
    end
    if(~istimetable(data))
        error('cod: dataHat must be a timetable.');
    end
    if(var(seconds(diff(data.time))) > 0)
        error('cod: dataHat must have a homogeneous time grid.')
    end
    if(data.time(1) ~= dataHat.time(1))
        error('cod: data and dataHat must start from the same timestamp.')
    end
    if(data.time(end) ~= dataHat.time(end))
        error('cod: data and dataHat must end with the same timestamp.')
    end
    if(height(data) ~= height(dataHat))
        error('cod: data and dataHat must have the same length.')
    end
    if(~any(strcmp(fieldnames(data),'time')))
        error('cod: data must have a column named `time`.')
    end
    if(~any(strcmp(fieldnames(data),'rate')))
        error('cod: data must have a column named `rate`.')
    end
    if(~any(strcmp(fieldnames(dataHat),'time')))
        error('cod: dataHat must have a column named `time`.')
    end
    if(~any(strcmp(fieldnames(dataHat),'rate')))
        error('cod: dataHat must have a column named `rate`.')
    end
    
    %Get indices having no nans in both timetables
    idx = find(~isnan(dataHat.rate) & ~isnan(data.rate));
    
    %Compute residuals
    residuals = data.rate(idx) - dataHat.rate(idx);
    
    %Compute metric
    cod = 100 * ( 1 - norm(residuals,2)^2 ./ norm( data.rate(idx) - mean(data.rate(idx)), 2)^2 );
    
end