function dynamicScores = evaluate_dynamic(shiftSchedules, parallel, doPlot)
%EVALUATE_DYNAMIC 评估给定换挡规律的动力性
%   将每个换挡规律代入模型后，进行数种仿真加速实验，
%   最终将将耗时加权后求和作为动力性评分。
%   包含如下数种场景，耗时加权求和作为最终动力性评分：
%   100% AP，0~100km/h加速时间（最大加速能力）、
%   85% AP，50~80km/h加速时间（加速超车工况）、
%   15%、40% AP，0~50km/h加速时间（低AP开度加速工况）
arguments
    shiftSchedules (1, :) ShiftSchedule % 换挡规律/换挡规律数组
    parallel (1, 1) {mustBeNumericOrLogical} = false % 是否并行计算
    doPlot (1, 1) {mustBeNumericOrLogical} = false % 是否绘制结果图
end

%% 配置与构造仿真任务

scheduleCount = length(shiftSchedules); % 待处理的换挡规律个数

simIns = [ ...
              simin_factory_accel(shiftSchedules, 1), ...
              simin_factory_accel(shiftSchedules, 0.85), ...
              simin_factory_accel(shiftSchedules, 0.15), ...
              simin_factory_accel(shiftSchedules, 0.40)
          ];

% 权重系数，用于平衡各加速工况对评分结果的影响
weights = [0.10, 0.40, 0.16, 0.30];

%% 运行仿真

try
    if parallel
        simOuts = parsim(simIns, 'ShowProgress', 'off', ...
            'ShowSimulationManager', 'off');
    else
        simOuts = sim(simIns, 'ShowProgress', 'off', ...
            'ShowSimulationManager', 'off');
    end
catch ME
    disp("仿真运行时出错：" + ME.message + ...
    "，已将 evaEcoSimIn_debug 变量保存至基础工作区，以供调试");
    % 将simIns对象保存到工作区，方便调试
    assignin('base', 'evaEcoSimIn_debug', simIns);
    throw(ME)
end

%% 处理仿真结果数据

dynamicScores = zeros(1, scheduleCount);

for index = 1:scheduleCount
    accTime1 = get_acceleration_time(simOuts(index), 0, 100);
    accTime2 = get_acceleration_time( ...
        simOuts(index + scheduleCount), 50, 80);
    accTime3 = get_acceleration_time( ...
        simOuts(index + scheduleCount * 2), 0, 40);
    accTime4 = get_acceleration_time( ...
        simOuts(index + scheduleCount * 3), 0, 50);
    dynamicScores(index) = ...
        accTime1 * weights(1) + ...
        accTime2 * weights(2) + ...
        accTime3 * weights(3) + ...
        accTime4 * weights(4);
end

%% 绘图

if doPlot
    % 应为每种加速测试场景绘制一张图，每张图上包含所有换挡规律
    % FIXME 此处的绘图中还有不必要的“期望车速”信息，应设法删去
    plot_simout_data(simOuts(1:scheduleCount), "velocity", ...
        [shiftSchedules.Description])
    plot_simout_data(simOuts(scheduleCount + 1:scheduleCount * 2), ...
        "velocity", [shiftSchedules.Description])
    plot_simout_data(simOuts(scheduleCount * 2 + 1:scheduleCount * 3), ...
        "velocity", [shiftSchedules.Description])
    plot_simout_data(simOuts(scheduleCount * 3 + 1:scheduleCount * 4), ...
        "velocity", [shiftSchedules.Description])
end

end
