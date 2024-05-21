classdef Particle
%PARTICLE 用于粒子群优化算法的粒子类
%   通过此类的实例管理粒子的位置、速度、历史最优位置等信息

properties
    x % 粒子位置
    pbest % 粒子历史最优位置
    fitness_value (1, :) {mustBeNumeric} % 当前位置对应的适应值（/数组）
    fitness_value_best (1, :) {mustBeNumeric} % 粒子历史最优适应值
end

properties (SetAccess = private)
    x_min % 粒子位置边界
    x_max % 粒子位置边界
    v % 粒子速度
    v_max % 粒子速度最大值
    c1 (1, 1) {mustBeNumeric} % 个体学习因子
    c2 (1, 1) {mustBeNumeric} % 群体学习因子
    moved (1, 1) {mustBeNumericOrLogical} = false % 标记粒子是否已移动
end

methods
    function obj = Particle(initX, initV, vMax, xMin, xMax, c1, c2)
        %PARTICLE 构造函数
        arguments
            initX % 粒子初始位置
            initV % 粒子初始速度
            vMax % 粒子速度最大值
            xMin % 粒子位置下界
            xMax % 粒子位置上界
            c1 (1, 1) {mustBeNumeric} = 1.6 % 个体学习因子
            c2 (1, 1) {mustBeNumeric} = 1.8 % 群体学习因子
        end

        obj.x = initX;
        obj.pbest = obj.x;
        obj.x_min;
        obj.v = initV;
        obj.x_min = xMin;
        obj.x_max = xMax;
        obj.v_max = vMax;
        obj.c1 = c1;
        obj.c2 = c2;
        obj.moved = false;
    end

    function obj = update_v(obj, omega, gbest, vlim_func)
        %UPDATE_V 更新粒子速度
        %   核心公式：
        %   $v_{id}^{k+1} = \omega v_{id}^{k} +
        %   c_1 r_1 (p_{id, \mathrm{pbest}}^k - x_{id}^k) +
        %   c_2 r_2 (p_{d, \mathrm{gbest}}^k - x_{id}^k)$
        %   其中 $r_1, r_2$ 为随机数，$p_{id, \mathrm{pbest}}^k$ 为粒子 $id$
        %   的个体最佳值，$p_{d, \mathrm{gbest}}^k$ 为全局最佳值。
        arguments
            obj (1, 1) Particle
            omega (1, 1) {mustBeNumeric} % 惯性权重
            gbest % 全局最优位置
            vlim_func % 速度限制函数句柄，函数声明应类似于：
            % limited_v = vlim_func(v, vlim_min, vlim_max);
        end

        % 速度更新公式
        next_v = omega .* obj.v + obj.c1 * rand .* (obj.pbest - obj.x) + ...
            obj.c2 * rand .* (gbest - obj.x);

        % 限制速度
        obj.v = vlim_func(next_v, -obj.v_max, obj.v_max);
        obj.moved = false; % 标记“速度已更新，位置对应尚未移动”
    end

    function obj = update_x(obj, xlim_func)
        %UPDATE_X 更新粒子位置
        %   通过外部传入位置约束函数，可以更好地处理位置属性复杂的数据类型、
        %   设计复杂的约束关系；xlim_func的函数声明应类似于：
        %   new_x = xlim_func(new_x, obj.x_min, obj.x_max)
        arguments
            obj (1, 1) Particle
            xlim_func (1, 1) % 位置约束函数句柄
        end

        if ~obj.moved
            new_x = obj.x + obj.v;
            obj.x = xlim_func(new_x, obj.x_min, obj.x_max);
            obj.moved = true;
        else
            warning("试图在更新速度前重复更新位置，已取消操作")
        end

    end

    function obj = update_fitness(obj, fitnessValue)
        %SET.FITNESS_VALUE 更新适应值，并处理个体历史最优信息
        %   在对整个粒子群的适应值进行统一更新（迭代）时，或可通过并行仿真等
        %   方法加速，使总体耗时远小于各粒子单独计算自身适应值耗时之和，故交
        %   由外部计算适应值、此处仅接受并保存新的适应值
        arguments
            obj (1, 1) Particle
            fitnessValue (1, :) {mustBeNumeric} % 粒子适应值/适应值数组
        end

        obj.fitness_value = fitnessValue;

        % 同时处理历史最优位置的更新
        % TODO 可优化：应用于PSO时应用更简化的判断方法，以提高性能
        if obj.judge_dominance(fitnessValue, obj.fitness_value_best)
            % 新值支配旧的历史最优，更新
            obj.pbest = obj.x;
            obj.fitness_value_best = fitnessValue;
        elseif obj.judge_dominance(obj.fitness_value_best, fitnessValue)
            % 旧的历史最优支配新值，不更新
        else
            % 新值与旧历史最优互不支配，随机选择一个作为新最优
            if rand < 0.5
                obj.pbest = obj.x;
                obj.fitness_value_best = fitnessValue;
            end
        end
    end
end

methods (Static)
    function isDominat = judge_dominance(fitnessLeft, fitnessRight)
        %JUDGE_DOMINANCE 判断两个适应值间的支配关系
        %   返回true表示左值支配右值（左值全面优于右值）；
        %   返回false表示左值不支配右值（不能表明右值支配左值）；
        arguments
            fitnessLeft (1, :) {mustBeNumeric} % 粒子适应值数组
            fitnessRight (1, :) {mustBeNumeric} % 粒子适应值数组
        end

        if all(fitnessLeft < fitnessRight)
            isDominat = true;
        else
            isDominat = false;
        end
    end
end

end
