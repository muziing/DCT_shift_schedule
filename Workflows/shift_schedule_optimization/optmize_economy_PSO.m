% 基于粒子群优化算法（PSO）的换挡规律经济性优化
% 此脚本中包含PSO算法的主要流程，Particle 类则由单独文件定义

%% 配置

particleCount = 10; % 粒子群规模（粒子数）
loopCount = 80; % 最大迭代次数
omegaMin = 1.2; % 最小惯性权重ω
omegaMax = 1.8; % 最大惯性权重ω
c1 = 1.6; % 个体学习因子
c2 = 1.8; % 群体学习因子

%% 初始化粒子群

particleArray = Particle.empty(particleCount, 0);

% 初始化粒子位置、速度、位置边界、速度边界
for pIdx = 1:particleCount
    % TODO 设计良好的位置、速度随机初始化方法
    initX = ShiftSchedule();
    initV = ShiftSchedule();
    vMax = ShiftSchedule();
    xMin = ShiftSchedule();
    xMax = ShiftSchedule();
    particleArray(pIdx) = Particle(initX, initV, vMax, xMin, xMax, c1, c2);
end

% 初始化粒子群适应值
[gbest, gbestX] = update_eco_scores(particleArray);

% 更新粒子位置
for pIdx = 1:particleCount
    particleArray(pIdx) = particleArray(pIdx).update_x(@ShiftSchedule.limit);
end

%% 迭代

for loopIdx = 1:loopCount

    % 更新惯性权重
    omega = update_omega(loopIdx, loopCount, omegaMin, omegaMax);

    % 更新粒子速度
    for pIdx = 1:particleCount
        particleArray(pIdx) = particleArray(pIdx).update_v(omega, gbest, ...
            @ShiftSchedule.limit);
    end

    % 更新粒子位置
    for pIdx = 1:particleCount
        particleArray(pIdx) = particleArray(pIdx).update_x(@ShiftSchedule.limit);
    end

    % 更新粒子群适应值
    [gbest, gbestX] = update_eco_scores(particleArray);

    % 输出提示信息，便于监控程序运行情况
    disp("第 "+num2str(loopIdx) + " 次迭代，全局最优解 gbest = "+num2str(gbest))

    % TODO 设计中断迭代条件
end

%% 输出

shiftSchedule_eco_pso = gbestX;
save(Data \ pso_result.mat, 'shiftSchedule_eco_pso')

%% 辅助函数

function [bestEcoScore, bestX] = update_eco_scores(particleArray)
%UPDATE_ECO_SCORES 批量计算并更新所有粒子的经济性得分（适应值）
%   返回全局最优适应值与全局最优解
arguments
    particleArray (1, :) Particle
end

particleCount = length(particleArray);

shiftSchedules = ShiftSchedule.empty(particleCount, 0);
for pIdx = 1:particleCount
    shiftSchedules(pIdx) = particleArray(pIdx).x;
end

try
    % evaluate_economy() 内部应实现并行，以显著提高速度
    ecoScores = evaluate_economy(shiftSchedules, true, false);
catch ME
    disp(['Error when evaluating economy: ' ME.message]);
    return
end

% 提取最优解
[~, bestParticleIdx] = min(ecoScores);
bestEcoScore = ecoScores(bestParticleIdx);
bestX = shiftSchedules(bestParticleIdx(1)).x;

% 将更新后的适应值保存到粒子中
for pIdx = 1:particleCount
    particleArray(pIdx) = particleArray(pIdx).update_fitness(ecoScores(pIdx));
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
