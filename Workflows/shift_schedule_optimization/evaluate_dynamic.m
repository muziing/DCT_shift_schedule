function dynamicScores = evaluate_dynamic(shiftSchedules, parallel, doPlot)
%EVALUATE_DYNAMIC 评估给定换挡规律的动力性
%   将每个换挡规律代入模型后，进行数种仿真加速实验，最终将将耗时加权后求和作为动力性评分
%   目前仅处理了全AP开度下0~100km/h加速这一种场景
arguments
    shiftSchedules (1, :) ShiftSchedule % 换挡规律/换挡规律数组
    parallel (1, 1) {mustBeNumericOrLogical} = false % 是否并行计算
    doPlot (1, 1) {mustBeNumericOrLogical} = false % 是否绘制结果图
end

modelName = "BEV_4DCT_Longitudinal";
simStopTime = "200"; % 仿真停止时间，足以让车速达到稳定即可
simIns = simin_factory(shiftSchedules); % 创建仿真任务对象

for index = 1:length(simIns)

    % 启用标定调试模式，替代原有的驾驶员模型
    simIns(index) = simIns(index).setVariable('CalibrateMode', true, ...
        'Workspace', modelName);

    % 配置AP开度
    simIns(index) = simIns(index).setBlockParameter( ...
        modelName + "/Driver/CalibrateDriver/AccelCmdGain", 'Gain', ...
        num2str(1));

    % 配置其他仿真参数
    simIns(index) = simIns(index).setModelParameter( ...
        'StopTime', simStopTime ...
    );

end

%% 运行仿真
try
    if parallel
        simOuts = parsim(simIns, 'ShowProgress', 'off', ...
            'ShowSimulationManager', 'on');
    else
        simOuts = sim(simIns, 'ShowProgress', 'off', ...
            'ShowSimulationManager', 'on');
    end
catch ME
    disp("仿真运行时出错：" + ME.message + ...
    "，已将 evaEcoSimIn_debug 变量保存至基础工作区，以供调试");
    % 将simIns对象保存到工作区，方便调试
    assignin('base', 'evaEcoSimIn_debug', simIns);
    throw(ME)
end

%% 处理仿真结果数据

dynamicScores = zeros(length(simOuts), 1);

for index = 1:length(simOuts)
    dynamicScores(index) = get_acceleration_time(simOuts(index), 0, 100);
end

%% 绘图
if doPlot
    % 应为每种加速测试场景绘制一张图，每张图上包含所有换挡规律
    % FIXME 此处的绘图中还有不必要的“期望车速”信息，应设法删去
    plot_simout_data(simOuts, "velocity", [shiftSchedules.Description])
end

end
