classdef Archive < handle
%ARCHIVE 用于MOPSO算法中管理最优粒子集合的类
%   此类中保存与管理着全局的非支配解集，外部可以通过 get_best_particles() 获取
%   通过 update() 方法将新的非支配解集加入，内部将自动处理溢出时的裁剪
%   可以通过 get_gBest() 获取唯一的全局最优解（当前迭代的群体领导者）

properties (SetAccess = private)
    max_length {mustBeNumeric, mustBePositive} % 能够存储的最大粒子数
    best_particles (1, :) Particle % 最优粒子集合
    crowd_distances (1, :) {mustBeNumeric} % 粒子的拥挤距离
end

methods
    function obj = Archive(maxLength)
        %ARCHIVE 构造此类的实例
        %   此处显示详细说明
        obj.max_length = maxLength;
    end

    function update(obj, newParticles)
        % UPDATE 更新归档
        %   将原有粒子与新粒子合并后，再进行一次非支配筛选
        %   筛选后，如最优粒子数量超出限制，则通过算法删除部分粒子
        arguments
            obj (1, 1) Archive
            newParticles (1, :) Particle % 粒子集
        end

        % 将新传入的粒子与原有粒子合并，再求一次非支配解集
        allNonDominated = get_nondominated_solutions( ...
            [obj.best_particles, newParticles]);

        % 发生溢出时，裁剪掉部分粒子
        while length(allNonDominated) > obj.max_length
            % 求解拥挤距离，删除拥挤距离最小的粒子（亦可使用自适应网格法等）
            crowdDistances = get_crowd_distance(reshape([allNonDominated.fitness_value], 2, [])');
            allNonDominated(crowdDistances == min(crowdDistances)) = [];
        end

        % 更新拥挤距离
        crowdDistances = get_crowd_distance(reshape([allNonDominated.fitness_value], 2, [])');
        obj.crowd_distances = crowdDistances;

        % 更新非支配解集
        obj.best_particles = allNonDominated;

    end

    function gBestParticleX = get_gBest(obj)
        %GET_GBEST 返回一个全局最优粒子的位置
        %   根据算法，从存储的所有最优粒子中适当选取一个

        % 在拥挤距离较大的前 20% 解中随机选择全局最优
        if floor(0.2 * length(obj.best_particles)) < 1
            index = 1;
        else
            index = randi([1, floor(0.2 * length(obj.best_particles))]);
        end
        % 还可以通过自适应网格法等其他方式实现粒子选取

        gBestParticleX = obj.best_particles(index).x;

    end

    function output = get_best_particles(obj)
        %GET_BEST_PARTICLES 返回所有最优粒子
        %   出于安全考虑，best_particles属性为私有，
        %   外界只能通过此方法获取而无法修改；
        output = obj.best_particles;
    end
end
end
