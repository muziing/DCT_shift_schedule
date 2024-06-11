% 基于粒子群优化算法（PSO）的换挡规律经济性优化
% 此脚本中包含PSO算法的主要流程，Particle 类则由单独文件定义

%% 配置

% 粒子群配置
particleCount = 70; % 粒子群规模（粒子数）
loopCount = 80; % 最大迭代次数
omegaMin = 0.2; % 最小惯性权重ω
omegaMax = 1.2; % 最大惯性权重ω
c1 = 2.0; % 个体学习因子
c2 = 2.2; % 群体学习因子
epsilon = 1e-6; % 收敛阈值（连续两轮全局最优解之差小于此阈值则停止迭代完成优化）

% 检查配置参数合理性
if particleCount <= 0 || particleCount > 500 || ...
        loopCount <= 0 || loopCount > 150 || ...
        omegaMin <= 0 || omegaMax <= 0 || omegaMin > omegaMax || ...
        c1 <= 0 || c2 <= 0 || epsilon < 0
    error("配置参数不合理，请检查");
end

% 初始化换挡规律配置
% 目前仅为验证PSO算法可行性而临时拼凑的上下界，应使用参数扫描的结果确定更优上下界
load("ShiftSchedulesData.mat")
shiftScheduleMin = shiftSchedule_test_min;
shiftScheduleMax = shiftSchedule_test_max;

%% 初始化粒子群

fprintf("[%s] 启动 PSO 优化，粒子数[%d]，最大迭代数[%d]\n", ...
    string(datetime), particleCount, loopCount)

particleArray = Particle.empty(particleCount, 0);

% 初始化粒子位置、速度、位置边界、速度边界
for pIdx = 1:particleCount
    xMin = shiftScheduleMin;
    xMax = shiftScheduleMax;
    vMax = (xMax - xMin) .* 0.15;
    initX = gen_random_schedule(xMin, xMax, "优化粒子位置");
    initV = gen_random_schedule(xMax .* -0.05, xMax .* 0.05, "优化粒子移动速度");
    particleArray(pIdx) = Particle(initX, initV, vMax, xMin, xMax, c1, c2);
end

% 初始化粒子群适应值
[particleArray, gBestScore, gbest] = update_eco_scores(particleArray);
lastBestScore = gBestScore;
fprintf("[%s] 初始条件，全局最优解 [%.6f]\n", string(datetime), gBestScore)

% 更新粒子位置
for pIdx = 1:particleCount
    particleArray(pIdx) = particleArray(pIdx).update_x( ...
        @ShiftSchedule.limit_strict);
end

%% 迭代

converged = false; % 收敛标志

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
        particleArray(pIdx) = particleArray(pIdx).update_x( ...
            @ShiftSchedule.limit_strict);
    end

    % 更新粒子群适应值
    try
        [particleArray, currBestScore, currGBest] = ...
            update_eco_scores(particleArray);
    catch ME
        disp("优化迭代运行时发生问题，已提前终止迭代，请检查")
        break
    end

    if abs(lastBestScore - currBestScore) < epsilon
        % 判断是否收敛
        converged = true;
    end

    if currBestScore < gBestScore
        % 如果当前迭代次中获得的全局最优解优于历史全局最优解，则更新
        gbest = currGBest;
        gBestScore = currBestScore;
    end

    % plot_shift_lines(gbest) % 调试用

    % 输出提示信息，便于监控程序运行情况
    fprintf("[%s] 第[%2d]次迭代，本次最优解 [%.6f]，全局最优解 [%.4f]\n", ...
        string(datetime), loopIdx, currBestScore, gBestScore)

    % 由是否收敛判断是否继续迭代
    if converged
        disp("已收敛，迭代结束")
        break
    end

    % 将当前轮最优值记录，便于与下一轮最优值比较
    lastBestScore = currBestScore;
end

fprintf("[%s] 优化结束，全局最优解 [%.4f]\n", string(datetime), gBestScore)

%% 导出结果

shiftSchedule_eco_pso = gbest;
shiftSchedule_eco_pso.Description = "经济型换挡规律（PSO优化）";
plot_shift_lines(shiftSchedule_eco_pso);

shiftSchedules_eco_pso = [shiftSchedules_eco_pso, shiftSchedule_eco_pso];
save("ShiftSchedulesData.mat", "shiftSchedules_eco_pso", '-append')

%% 收尾清理

clear shiftScheduleMax shiftScheduleMin
clear initX initV pIdx loopIdx economyScores currBestScore currGBest
clear vMax xMax xMin particleArray omega lastBestScore

%% 辅助函数

function [particleArray, bestScore, bestX] = update_eco_scores(particleArray)
%UPDATE_ECO_SCORES 批量计算并更新所有粒子的经济性得分（适应值）
%   返回全局最优适应值与全局最优解
arguments
    particleArray (1, :) Particle % 粒子群（一维Particle数组）
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
    disp("执行 evaluate_economy 时出错：" + ME.message);
    throw(ME)
end

% 提取最优解
[~, bestParticleIdx] = min(ecoScores);
bestScore = ecoScores(bestParticleIdx);
bestX = shiftSchedules(bestParticleIdx(1));

% 将更新后的适应值保存到粒子中
for pIdx = 1:particleCount
    particleArray(pIdx) = particleArray(pIdx).update_fitness(ecoScores(pIdx));
end
end
