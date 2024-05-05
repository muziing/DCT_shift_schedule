classdef ShiftSchedule
%SHIFTSCHEDULE 换挡规律数据类
%   用于结构化存储换挡规律数据的类
%   通过运算符重载，实现了可相互加减功能，便于优化算法处理

%   关于使用类存储处理结构化数据，参考：
%   https://ww2.mathworks.cn/help/matlab/matlab_oop/example-representing-structured-data.html

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

    function output = uminus(obj)
        %UMINUS 运算符重载 "-"（单目运算符）
        arguments
            obj (1, 1) ShiftSchedule
        end

        output = ShiftSchedule;
        output.UpSpds = -obj.UpSpds;
        output.DownSpds = -obj.DownSpds;
        output.UpAPs = obj.UpAPs;
        output.DownAPs = obj.DownAPs;
        output.Description = obj.Description;
    end
end

methods (Static)
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

    function obj = limit(obj, minSchedule, maxSchedule)
        %LIMIT 限制 ShiftSchedule 中各换挡点速度介于最大最小值之间
        %   注意此函数限制较为宽松，仅适用于 PSO 算法中粒子速度的边界限制
        %   对于严格的换挡规律限制，应使用 ShiftSchedule.limit_strict()
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

    function obj = limit_strict(obj, minSchedule, maxSchedule)
        %LIMIT_STRICT 限制 ShiftSchedule 中各换挡点速度介于最大最小值之间，且满足严格限制
        %   相邻换挡线间无交点、同一挡位的降挡速度小于升挡速度且有适当换挡延迟
        %   对于优化算法中的粒子速度限制，应使用 ShiftSchedule.limit()
        %   对于优化算法中的粒子位置限制，应使用 ShiftSchedule.limit_strict()
        arguments
            obj (1, 1) ShiftSchedule % 待限制的换挡规律
            minSchedule (1, 1) ShiftSchedule % 下界
            maxSchedule (1, 1) ShiftSchedule % 上界
        end

        % FIXME 在PSO算法流程中，在此调用 limit() 无效，暂且将其实现复制一份
        obj.UpSpds(obj.UpSpds < minSchedule.UpSpds) = ...
            minSchedule.UpSpds(obj.UpSpds < minSchedule.UpSpds);
        obj.DownSpds(obj.DownSpds < minSchedule.DownSpds) = ...
            minSchedule.DownSpds(obj.DownSpds < minSchedule.DownSpds);
        obj.UpSpds(obj.UpSpds > maxSchedule.UpSpds) = ...
            maxSchedule.UpSpds(obj.UpSpds > maxSchedule.UpSpds);
        obj.DownSpds(obj.DownSpds > maxSchedule.DownSpds) = ...
            maxSchedule.DownSpds(obj.DownSpds > maxSchedule.DownSpds);

        % 降挡速度应小于对应升挡速度，且差值（换挡延迟）不小于 3km/h
        obj.DownSpds(obj.DownSpds + 3 > obj.UpSpds) = ...
            obj.UpSpds(obj.DownSpds + 3 > obj.UpSpds) - 3;

        % 相邻换挡线间应无交点
        for apIdx = 1:width(obj.UpSpds)
            for shiftIdx = 1:height(obj.UpSpds) - 1
                if obj.UpSpds(shiftIdx, apIdx) + 4 < obj.DownSpds(...
                        shiftIdx + 1, apIdx)
                    continue
                else
                    % 如果出现高挡位换挡速度小于低档位换挡速度，就强制修改高挡位换挡速度
                    obj.DownSpds(shiftIdx + 1, apIdx) = ...
                        obj.UpSpds(shiftIdx, apIdx) + 4;
                    if obj.UpSpds(shiftIdx + 1, apIdx) < ...
                            obj.DownSpds(shiftIdx + 1, apIdx) + 3
                        % 若增大高挡位降挡车速后使 降挡车速+换挡延迟>升挡车速，
                        % 则一并增加升挡车速
                        obj.UpSpds(shiftIdx + 1, apIdx) = ...
                            obj.DownSpds(shiftIdx + 1, apIdx) + 3;
                    end
                end
            end
        end

    end
end

end
