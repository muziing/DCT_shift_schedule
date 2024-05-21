% 基于多目标粒子群优化算法（MOPSO）的换挡规律动力性与经济性优化
% 此脚本中包含MOPSO算法的主要流程，Particle 类则由单独文件定义

%% 配置

% 粒子群配置
particleCount = 70; % 粒子群规模（粒子数）
archiveCount = 10; % 全局非支配粒子规模（最优粒子数）
loopCount = 80; % 最大迭代次数
omegaMin = 0.2; % 最小惯性权重ω
omegaMax = 1.2; % 最大惯性权重ω
c1 = 1.6; % 个体学习因子
c2 = 2; % 群体学习因子
epsilon = 1e-6; % 收敛阈值（连续两轮全局最优解之差小于此阈值则停止迭代完成优化）

% 检查配置参数合理性
if particleCount <= 0 || particleCount > 500 || ...
        loopCount <= 0 || loopCount > 150 || ...
        omegaMin <= 0 || omegaMax <= 0 || omegaMin > omegaMax || ...
        c1 <= 0 || c2 <= 0 || epsilon < 0
    error("配置参数不合理，请检查");
end

% 初始化换挡规律配置
% 使用参数扫描的结果确定上下边界
load("ShiftSchedulesData.mat")
shiftScheduleMin = shiftSchedule_test_min;
shiftScheduleMax = shiftSchedule_test_max;

%% 初始化粒子群

fprintf("[%s] 启动 PSO 优化，粒子数[%d]，最大迭代数[%d]\n", ...
    string(datetime), particleCount, loopCount)

% 粒子群
particleArray = Particle.empty(particleCount, 0);
% 全局最优粒子集
archiveArray = Particle.empty(archiveCount, 0);

% 初始化粒子位置、速度、位置边界、速度边界
for pIdx = 1:particleCount
    xMin = shiftScheduleMin;
    xMax = shiftScheduleMax;
    vMax = (xMax - xMin) .* 0.15;
    initX = gen_random_schedule(xMin, xMax, "优化粒子位置");
    initV = gen_random_schedule(xMax .* -0.05, xMax .* 0.05, "优化粒子移动速度");
    particleArray(pIdx) = Particle(initX, initV, vMax, xMin, xMax, c1, c2);
end

% 初始化粒子群适应值与archive
[particleArray, currBestParticles] = update_all_fitness(particleArray);
if length(currBestParticles) < archiveCount
    archiveArray = currBestParticles;
else
    % TODO 设计archive溢出时的更新方法
end

% TODO 设计获取 gBest 的函数

fprintf("[%s] 初始条件，全局最优解 [%.6f]\n", string(datetime), gBestScore)

% 更新粒子位置
for pIdx = 1:particleCount
    particleArray(pIdx) = particleArray(pIdx).update_x( ...
        @ShiftSchedule.limit_strict);
end

%% 迭代

%% 导出结果

%% 收尾清理

%% 辅助函数

function [particleArray, bestParticleArray] = update_all_fitness(particleArray)
%UPDATE_ALL_FITNESS 更新粒子群适应值
%   处理当前迭代中所有粒子的适应值，并提取非支配解集
arguments
    particleArray (1, :) Particle % 粒子群（一维Particle数组）
end

particleCount = length(particleArray);

shiftSchedules = ShiftSchedule.empty(particleCount, 0);
for pIdx = 1:particleCount
    shiftSchedules(pIdx) = particleArray(pIdx).x;
end

try
    ecoScores = evaluate_economy(shiftSchedules, true, false);
catch ME
    disp("执行 evaluate_economy 时出错：" + ME.message);
    throw(ME)
end

try
    dyaScores = evaluate_dynamic(shiftSchedules, true, false);
catch ME
    disp("执行 evaluate_dynamic 时出错：" + ME.message);
    throw(ME)
end

fitnessValues = [ecoScores', dyaScores'];

% 将更新后的适应值保存到粒子中
for pIdx = 1:particleCount
    particleArray(pIdx) = ...
        particleArray(pIdx).update_fitness(fitnessValues(pIdx, :));
end

% 提取非支配解集
bestParticleArray = get_nondominated_solutions(particleArray);

end

function bestParticleArray = get_nondominated_solutions(particleArray)
%GET_NONDOMINATED_SOLUTIONS 计算非支配解集
%   从给定粒子群中，提取一组非支配解集，并以粒子数组形式返回
arguments
    particleArray (1, :) Particle % 粒子群（一维Particle数组）
end

% 初始化非支配解粒子数组
bestParticleArray = particleArray(1);

for index = 2:length(particleArray)
    particleA = particleArray(index); % 新考察的粒子
    flag = false; % 是否将新粒子加入非支配解集
    deleteingIndex = []; % 需要从非支配解集中删除的粒子索引

    for j = 1:length(bestParticleArray)
        particleB = bestParticleArray(j); % 已在非支配解集中的粒子
        if Particle.judge_dominance( ...
                particleA.fitness_value, particleB.fitness_value)
            % 新考察的粒子支配某个已在非支配解集中的粒子，
            % 将新考察的粒子A加入非支配解集，并从非支配解集中删除另一个粒子B
            flag = true;
            deleteingIndex = [deleteingIndex, j]; %#ok<AGROW>
        elseif Particle.judge_dominance( ...
                particleB.fitness_value, particleA.fitness_value)
            % 新考察的粒子被支配，什么都不做
            continue
        else
            % 新考察的粒子与非支配解集中的粒子都互不支配，
            % 将新考察的粒子加入非支配解集
            flag = true;
        end
    end

    if flag
        % 删去待删除的粒子
        logicIndex = true(size(bestParticleArray));
        logicIndex(deleteingIndex) = false;
        bestParticleArray = bestParticleArray(logicIndex);

        % 将新粒子加入非支配解集
        bestParticleArray = [bestParticleArray, index]; %#ok<AGROW>
    end
end

end

function omega = update_omega(iter, iterMax, omegaMin, omegaMax)
%UPDATE_OMEGA 更新惯性权重ω
%   线性变化策略：随着迭代次数的增加，惯性权重不断减小，从而使得粒子群算法在初期
%   具有较强的全局收敛能力，在后期具有较强的局部收敛能力。
arguments
    iter (1, 1) {mustBeNumeric} % 当前迭代次数
    iterMax (1, 1) {mustBeNumeric} % 最大迭代次数
    omegaMin (1, 1) {mustBeNumeric} = 0.9 % 最小惯性权重
    omegaMax (1, 1) {mustBeNumeric} = 1.8 % 最大惯性权重
end

omega = omegaMax - (omegaMax - omegaMin) * iter / iterMax;
end
