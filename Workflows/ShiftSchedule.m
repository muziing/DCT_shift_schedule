classdef ShiftSchedule
%SHIFTSCHEDULE 换挡规律数据类
%   用于结构化存储换挡规律数据的类
%   https://ww2.mathworks.cn/help/matlab/matlab_oop/example-representing-structured-data.html
%   通过运算符重载，实现了可相互加减功能，便于优化算法处理

properties
    UpSpds {mustBeNumeric}
    DownSpds {mustBeNumeric}
    UpAPs (1, :) {mustBeNumeric}
    DownAPs (1, :) {mustBeNumeric}
    Description (1, 1) = ""
end

methods

    function obj = set.UpAPs(obj, upAps)
        %SET.UPAPS 设置 UpAPs 属性时的检查与限制
        if (all(upAps >= 0 & upAps <= 100) && max(upAps) > 1)
            obj.UpAPs = upAps;
        else
            error("upAps 中的数值应介于 0-100 之间")
        end
    end

    function obj = set.DownAPs(obj, downAPs)
        %SET.DOWNAPS 设置 DownAPs 属性时的检查与限制
        if (all(downAPs >= 0 & downAPs <= 100) && max(downAPs) > 1)
            obj.DownAPs = downAPs;
        else
            error("downAPs 中的数值应介于 0-100 之间")
        end
    end

    function output = plus(obj, other)
        %PLUS 运算符重载
        arguments
            obj (1, 1) ShiftSchedule
            other (1, 1) ShiftSchedule
        end

        if ~isequal(obj.UpAPs, other.UpAPs) || ~isequal(obj.DownAPs, other.DownAPs)
            error("UpAPs 或 DownAPs 不一致")
        end
        if size(obj.UpSpds) ~= size(other.UpSpds) | size(obj.DownSpds) ~= size(other.DownSpds)
            error("UpSpds 或 DownSpds 数组大小不一致")
        end

        output = ShiftSchedule;
        output.UpSpds = obj.UpSpds + other.UpSpds;
        output.DownSpds = obj.DownSpds + other.DownSpds;
        output.UpAPs = obj.UpAPs;
        output.DownAPs = obj.DownAPs;
        if (obj.Description ~= other.Description)
            output.Description = "";
        else
            output.Description = obj.Description;
        end
    end

    function output = minus(obj, other)
        %MINUS 运算符重载
        arguments
            obj (1, 1) ShiftSchedule
            other (1, 1) ShiftSchedule
        end

        if ~isequal(obj.UpAPs, other.UpAPs) || ~isequal(obj.DownAPs, other.DownAPs)
            error("UpAPs 或 DownAPs 不一致")
        end
        if size(obj.UpSpds) ~= size(other.UpSpds) | size(obj.DownSpds) ~= size(other.DownSpds)
            error("UpSpds 或 DownSpds 数组大小不一致")
        end

        output = ShiftSchedule;
        output.UpSpds = obj.UpSpds - other.UpSpds;
        output.DownSpds = obj.DownSpds - other.DownSpds;
        output.UpAPs = obj.UpAPs;
        output.DownAPs = obj.DownAPs;
        if (obj.Description ~= other.Description)
            output.Description = "";
        else
            output.Description = obj.Description;
        end
    end
end

end
