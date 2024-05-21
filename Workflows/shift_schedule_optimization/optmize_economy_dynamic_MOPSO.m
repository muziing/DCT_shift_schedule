% 基于多目标粒子群优化算法（MOPSO）的换挡规律动力性与经济性优化
% 此脚本中包含MOPSO算法的主要流程，Particle 类则由单独文件定义

%% 配置

% 粒子群配置
particleCount = 56; % 粒子群规模（粒子数）
archiveCount = 15; % 全局非支配粒子规模（最优粒子数）
loopCount = 20; % 最大迭代次数
omegaMin = 0.2; % 最小惯性权重ω
omegaMax = 1.2; % 最大惯性权重ω
c1 = 1.6; % 个体学习因子
c2 = 2; % 群体学习因子

% 检查配置参数合理性
if particleCount <= 0 || particleCount > 500 || ...
        loopCount <= 0 || loopCount > 150 || ...
        omegaMin <= 0 || omegaMax <= 0 || omegaMin > omegaMax || ...
        c1 <= 0 || c2 <= 0
    error("配置参数不合理，请检查");
end

% 初始化换挡规律配置
% 使用参数扫描的结果确定上下边界
load("ShiftSchedulesData.mat")
shiftScheduleMin = shiftSchedule_test_min;
shiftScheduleMax = shiftSchedule_test_max;

%% 初始化粒子群

fprintf("[%s] 启动 MOPSO 优化，粒子数[%d]，最大迭代数[%d]\n", ...
    string(datetime), particleCount, loopCount)

% 粒子群
particleArray = Particle.empty(particleCount, 0);
% 全局最优粒子集
archive = Archive(archiveCount);

% 初始化粒子位置、速度、位置边界、速度边界
for pIndex = 1:particleCount
    xMin = shiftScheduleMin;
    xMax = shiftScheduleMax;
    vMax = (xMax - xMin) .* 0.15;
    initX = gen_random_schedule(xMin, xMax, "优化粒子位置");
    initV = gen_random_schedule(xMax .* -0.05, xMax .* 0.05, "优化粒子移动速度");
    particleArray(pIndex) = Particle(initX, initV, vMax, xMin, xMax, c1, c2);
end

% 初始化粒子群适应值
[particleArray, currBestParticles] = update_all_fitness(particleArray);

% 初始化archive
archive.update(currBestParticles);

% 更新粒子位置
for pIndex = 1:particleCount
    particleArray(pIndex) = particleArray(pIndex).update_x( ...
        @ShiftSchedule.limit_strict);
end

fprintf("[%s] 初始化完成\n", string(datetime))

%% 迭代

for loopIndex = 1:loopCount
    % 更新惯性权重与全局最优位置
    omega = update_omega(loopIndex, loopCount, omegaMin, omegaMax);
    gbest = archive.get_gBest();

    % 更新粒子速度
    for pIndex = 1:particleCount
        particleArray(pIndex) = particleArray(pIndex).update_v(omega, gbest, ...
            @ShiftSchedule.limit);
    end

    % 更新粒子位置
    for pIndex = 1:particleCount
        particleArray(pIndex) = particleArray(pIndex).update_x( ...
            @ShiftSchedule.limit_strict);
    end

    % 更新粒子群适应值
    try
        [particleArray, currBestParticles] = update_all_fitness(particleArray);
    catch ME
        disp("优化迭代运行时发生问题，已提前终止迭代，请检查")
        break
    end

    % 更新总非支配解集
    archive.update(currBestParticles);

    % 输出提示信息，便于监控程序运行情况
    fprintf("[%s] 第[%2d]次迭代完成\n", string(datetime), loopIndex)

end

%% 导出结果

finalBestParticles = archive.get_best_particles();

% 绘图，以散点图显示求解出的帕累托前沿
aaa = reshape([finalBestParticles.fitness_value], 2, [])';
figure('Name', "优化结果")
scatter(aaa(:, 1)', aaa(:, 2)')
xlabel("经济性评分")
ylabel("动力性评分")

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
for pIndex = 1:particleCount
    shiftSchedules(pIndex) = particleArray(pIndex).x;
end

% ecoScores = rand(1, particleCount); % 调试用
try
    ecoScores = evaluate_economy(shiftSchedules, true, false);
catch ME
    disp("执行 evaluate_economy 时出错：" + ME.message);
    throw(ME)
end

% dyaScores = rand(1, particleCount); % 调试用
try
    dyaScores = evaluate_dynamic(shiftSchedules, true, false);
catch ME
    disp("执行 evaluate_dynamic 时出错：" + ME.message);
    throw(ME)
end

fitnessValues = [ecoScores', dyaScores'];

% 将更新后的适应值保存到粒子中
for pIndex = 1:particleCount
    particleArray(pIndex) = ...
        particleArray(pIndex).update_fitness(fitnessValues(pIndex, :));
end

% 提取非支配解集
bestParticleArray = get_nondominated_solutions(particleArray);

end
