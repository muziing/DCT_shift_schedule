classdef ShiftSchedule
%SHIFTSCHEDULE 换挡规律数据类
%   用于结构化存储换挡规律数据的类
%   https://ww2.mathworks.cn/help/matlab/matlab_oop/example-representing-structured-data.html
%   通过运算符重载，实现了可相互加减功能，便于优化算法处理

properties
    UpSpds {mustBeNumeric} % 升档速度值二维数组
    DownSpds {mustBeNumeric} % 降档速度值二维数组
    UpAPs (1, :) {mustBeNumeric} % 升挡加速踏板开度数组
    DownAPs (1, :) {mustBeNumeric} % 降档加速踏板开度数组
    Description (1, 1) = "" % 描述
end

methods
    function obj = set.UpAPs(obj, upAps)
        %SET.UPAPS 设置 UpAPs 属性时的检查与限制
        arguments
            obj (1, 1) ShiftSchedule
            upAps (1, :) {mustBeNumeric}
        end

        if (all(upAps >= 0 & upAps <= 100) && max(upAps) > 1)
            obj.UpAPs = upAps;
        else
            error("upAps 中的数值应介于 0-100 之间")
        end
    end

    function obj = set.DownAPs(obj, downAPs)
        %SET.DOWNAPS 设置 DownAPs 属性时的检查与限制
        arguments
            obj (1, 1) ShiftSchedule
            downAPs (1, :) {mustBeNumeric}
        end

        if (all(downAPs >= 0 & downAPs <= 100) && max(downAPs) > 1)
            obj.DownAPs = downAPs;
        else
            error("downAPs 中的数值应介于 0-100 之间")
        end
    end

    function output = plus(obj, other)
        %PLUS 运算符重载 "+"
        arguments
            obj (1, 1) ShiftSchedule
            other (1, 1) ShiftSchedule
        end

        ShiftSchedule.check_other(obj, other)

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
        %MINUS 运算符重载 "-"
        arguments
            obj (1, 1) ShiftSchedule
            other (1, 1) ShiftSchedule
        end

        ShiftSchedule.check_other(obj, other)

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

    function output = lt(obj, other)
        %LT 运算符重载 "<"
        arguments
            obj (1, 1) ShiftSchedule
            other (1, 1) ShiftSchedule
        end

        ShiftSchedule.check_other(obj, other)

        if any(obj.UpSpds < other.UpSpds, 'all') || ...
                any(obj.DownSpds < other.DownSpds, 'all')
            output = true;
        else
            output = false;
        end
    end

    function output = gt(obj, other)
        %GT 运算符重载 ">"
        arguments
            obj (1, 1) ShiftSchedule
            other (1, 1) ShiftSchedule
        end

        ShiftSchedule.check_other(obj, other)

        if any(obj.UpSpds > other.UpSpds, 'all') || ...
                any(obj.DownSpds > other.DownSpds, 'all')
            output = true;
        else
            output = false;
        end
    end

    function output = times(left, right)
        %TIMES 运算符重载 ".*"
        if isa(left, "ShiftSchedule") && isnumeric(right)
            obj = left;
            scalar = right;
        elseif isa(right, "ShiftSchedule") && isnumeric(left)
            obj = right;
            scalar = left;
        else
            error("无法处理")
        end

        output = ShiftSchedule;
        output.UpSpds = obj.UpSpds .* scalar;
        output.DownSpds = obj.DownSpds .* scalar;
        output.UpAPs = obj.UpAPs;
        output.DownAPs = obj.DownAPs;
        output.Description = obj.Description;
    end
end

methods (Access = private, Static)
    function check_other(obj, other)
        %CHECK_OTHER 运算符重载检查函数
        %   对于 "+" "<" 等运算，只有两个换挡规律有相同的加速踏板开度列表和换挡
        %   表大小相同时才有意义，故设计此检查函数，对输入进行处理
        arguments
            obj (1, 1) ShiftSchedule
            other (1, 1) ShiftSchedule
        end

        if ~isequal(obj.UpAPs, other.UpAPs) || ...
                ~isequal(obj.DownAPs, other.DownAPs)
            error("UpAPs 或 DownAPs 不一致，无法处理")
        end
        if ~isequal(size(obj.UpSpds), size(other.UpSpds)) || ...
                ~isequal(size(obj.DownSpds), size(other.DownSpds))
            error("UpSpds 或 DownSpds 数组大小不一致，无法处理")
        end
    end
end

methods (Static)
    function obj = limit(obj, minSchedule, maxSchedule)
        %LIMIT 限制 ShiftSchedule 中各换挡点速度介于最大最小值之间
        arguments
            obj (1, 1) ShiftSchedule % 待限制的换挡规律
            minSchedule (1, 1) ShiftSchedule % 下界
            maxSchedule (1, 1) ShiftSchedule % 上界
        end

        % 输入检查
        if minSchedule > maxSchedule
            error('minSchedule 必须小于 maxSchedule')
        end
        ShiftSchedule.check_other(minSchedule, maxSchedule)
        ShiftSchedule.check_other(obj, minSchedule)

        % 已在边界值范围内则直接返回
        if obj > minSchedule && obj < maxSchedule
            return
        end

        % 按维度限制，只将值超出范围的那些维度限制为边界值，其他维度不变
        obj.UpSpds(obj.UpSpds < minSchedule.UpSpds) = ...
            minSchedule.UpSpds(obj.UpSpds < minSchedule.UpSpds);
        obj.DownSpds(obj.DownSpds < minSchedule.DownSpds) = ...
            minSchedule.DownSpds(obj.DownSpds < minSchedule.DownSpds);
        obj.UpSpds(obj.UpSpds > maxSchedule.UpSpds) = ...
            maxSchedule.UpSpds(obj.UpSpds > maxSchedule.UpSpds);
        obj.DownSpds(obj.DownSpds > maxSchedule.DownSpds) = ...
            maxSchedule.DownSpds(obj.DownSpds > maxSchedule.DownSpds);
    end
end

end
