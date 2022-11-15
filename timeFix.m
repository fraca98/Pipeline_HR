function [fixed] = timeFix(time)

a=time;

for i=1:length(time)-1
    flag = false;
    eqidx = [];

    for j=i+1:length(time)
        if(time(i)==time(j))
            if(flag==false)
                eqidx=[eqidx;i];
                flag = true;
            end
            eqidx=[eqidx;j];
        else
            break;
        end
    end
    if (~isempty(eqidx))
        time(eqidx(1)-1)
        time(eqidx(1))
        if(eqidx(1)-1+length(eqidx)+1>size(time,1))
            for k=1:length(eqidx)
                time(eqidx(k)) = time(eqidx(1)-1) + k;
            end
            break
        end

        if(time(eqidx(1)-1)+length(eqidx)+1==time(eqidx(end)+1))
            for k=1:length(eqidx)
                time(eqidx(k)) = time(eqidx(1)-1) + k;
            end
        end
    end


end

[datetime(a,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00'),datetime(time,'ConvertFrom','posixtime', 'Format', 'yyyy-MM-dd HH:mm:ss', 'TimeZone','+01:00')]
fixed = 0;
end

