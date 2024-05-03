classdef Particle
%PARTICLE 用于粒子群优化算法的粒子类
%   通过此类的实例管理粒子的位置、速度、历史最优位置等信息

properties
    pbest % 粒子历史最优位置
    fitness_value_best % 粒子历史最优适应值
end

properties (SetAccess = private)
    x % 粒子位置
    fitness_value (1, 1) {mustBeNumeric} % 当前位置对应适应值
    v % 粒子速度
    v_max % 粒子速度最大值
    c1 (1, 1) {mustBeNumeric} % 学习因子1
    c2 (1, 1) {mustBeNumeric} % 学习因子2
end

methods
    function obj = Particle(initX, initV, vMax, c1, c2)
        %PARTICLE 构造函数

        arguments
            initX % 粒子初始位置
            initV % 粒子初始速度
            vMax % 粒子速度最大值
            c1 (1, 1) {mustBeNumeric} % 学习因子1
            c2 (1, 1) {mustBeNumeric} % 学习因子2
        end

        obj.x = initX;
        obj.pbest = obj.x;
        obj.v = initV;
        obj.v_max = vMax;
        obj.c1 = c1;
        obj.c2 = c2;
    end

    function obj = update_v(obj, omega, gbest)
        %UPDATE_V 更新粒子速度
        %   v_{id}^{k+1} = \omega v_{id}^{k} +
        %   c_1 r_1 (p_{id, \mathrm{pbest}}^k - x_{id}^k) +
        %   c_2 r_2 (p_{d, \mathrm{gbest}}^k - x_{id}^k)

        arguments
            obj (1, 1) Particle
            omega (1, 1) {mustBeNumeric} % 惯性权重
            gbest % 全局最优位置
        end

        % 速度更新公式
        next_v = omega .* obj.v + obj.c1 * rand * (obj.pbest - obj.x) + ...
            obj.c2 * rand * (gbest - obj.x);

        % 限制速度
        if next_v > obj.v_max
            % FIXME 按维度限制速度，仅将超限的一个维度设为最大值
            next_v = obj.v_max;
        elseif next_v < -obj.v_max
            next_v = -obj.v_max;
        end

        obj.v = next_v;
    end

    function obj = update_x(obj, xlim_func)
        %UPDATE_X 更新粒子位置
        %   通过外部传入位置约束函数，可以更好地处理位置属性复杂的数据类型、设计
        %   复杂的约束关系；xlim_func的函数声明应类似于：
        %   new_x = xlim_func(current_x, v)

        arguments
            obj (1, 1) Particle
            xlim_func (1, 1) % 位置约束函数句柄
        end

        obj.x = xlim_func(obj.x, obj.v);

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
