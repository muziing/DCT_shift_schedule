classdef Particle
%PARTICLE 用于粒子群优化算法的粒子类
%   通过此类的实例管理粒子的位置、速度、历史最优位置等信息

properties
    pbest % 粒子历史最优位置
    fitness_value_best % 粒子历史最优适应值
end

properties (SetAccess = private)
    x % 粒子位置
    x_min % 粒子位置边界
    x_max % 粒子位置边界
    fitness_value (1, 1) {mustBeNumeric} % 当前位置对应适应值
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
        obj.x_min
        obj.v = initV;
        obj.x_min = xMin;
        obj.x_max = xMax;
        obj.v_max = vMax;
        obj.c1 = c1;
        obj.c2 = c2;
    end

    function obj = update_v(obj, omega, gbest, vlim_func)
        %UPDATE_V 更新粒子速度
        %   核心公式：
        %   $v_{id}^{k+1} = \omega v_{id}^{k} +
        %   c_1 r_1 (p_{id, \mathrm{pbest}}^k - x_{id}^k) +
        %   c_2 r_2 (p_{d, \mathrm{gbest}}^k - x_{id}^k)$
        %   其中 $r_1, r_2$ 为随机数，$p_{id, \mathrm{pbest}}^k$ 为粒子 $id$ 的
        %   个体最佳值，$p_{d, \mathrm{gbest}}^k$ 为全局最佳值。
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
        next_v = vlim_func(next_v, -obj.v_max, obj.v_max);
        % 速度的限制和位置的限制函数非常相似，考虑如何优化

        obj.v = next_v;
        obj.moved = false; % 标记“速度已更新，位置对应尚未移动”
    end

    function obj = update_x(obj, xlim_func)
        %UPDATE_X 更新粒子位置
        %   通过外部传入位置约束函数，可以更好地处理位置属性复杂的数据类型、设计
        %   复杂的约束关系；xlim_func的函数声明应类似于：
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
        %SET.FITNESS_VALUE 更新适应值
        %   在对整个粒子群的适应值进行统一更新（迭代）时，或可通过并行仿真等方法
        %   加速，使总体耗时远小于各粒子单独计算自身适应值耗时之和，故交由外部
        %   计算适应值、此处仅接受并保存新的适应值
        arguments
            obj (1, 1) Particle
            fitnessValue (1, 1) {mustBeNumeric} % 粒子适应值
        end

        obj.fitness_value = fitnessValue;

        % 同时处理历史最优位置的更新
        if fitnessValue < obj.fitness_value_best
            obj.pbest = obj.x;
            obj.fitness_value_best = fitnessValue;
        end
    end
end

end
