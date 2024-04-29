classdef ShiftSchedule
%SHIFTSCHEDULE 换挡规律数据类
%   用于结构化存储换挡规律数据的类
%   https://ww2.mathworks.cn/help/matlab/matlab_oop/example-representing-structured-data.html

properties
    UpSpds
    DownSpds
    UpAPs
    DownAPs
    Description
end

methods

    function obj = set.UpAPs(obj, upAps)
        if (all(upAps >= 0 & upAps <= 100) && max(upAps) > 1)
            obj.UpAPs = upAps;
        else
            error("upAps 中的数值应介于 0-100 之间")
        end
    end

    function obj = set.DownAPs(obj, downAPs)
        if (all(downAPs >= 0 & downAPs <= 100) && max(downAPs) > 1)
            obj.DownAPs = downAPs;
        else
            error("downAPs 中的数值应介于 0-100 之间")
        end
    end
end

end
