function economyScores = evaluate_economy(shiftSchedules, parallel, doPlot)
%EVALUATE_ECONOMY  评估给定换挡参数的经济性
%   对传入的换挡规律进行仿真与结果分析以评估经济性得分，值越小经济性越好

arguments
    shiftSchedules (1, :) ShiftSchedule % 换挡规律/换挡规律数组
    parallel (1, 1) {mustBeNumericOrLogical} = false % 是否并行仿真
    doPlot (1, 1) {mustBeNumericOrLogical} = false % 是否进行绘图
end

%% 创建仿真任务对象
taskCount = length(shiftSchedules);
simIns = simin_factory(shiftSchedules, "WLTC_class_2");

%% 运行仿真
try
    if ~parallel || taskCount < 2
        % 串行仿真
        simOut = sim(simIns);
    else
        % 并行仿真
        simOut = parsim(simIns, 'ShowProgress', 'off');
    end
catch ME
    disp("仿真运行时出错：" + ME.message + ...
    "，已将 evaEcoSimIn_debug 变量保存至基础工作区，以供调试");
    % 将simIns对象保存到工作区，方便调试
    assignin('base', 'evaEcoSimIn_debug', simIns);
    throw(ME)
end

%% 处理仿真结果数据
% 定义变量，预分配内存
economyScores = zeros(1, taskCount);
timestamps = cell(1, taskCount); % 时间戳
socData = cell(1, taskCount); % 电池SOC

try
    for idx = 1:taskCount
        socTimeTable = get(simOut(idx).logsout, "<BattSoc>").Values;
        timestamps{idx} = socTimeTable.Time;
        socData{idx} = socTimeTable.Data;

        % 计算经济性得分
        % 目前直接使用电池SOC消耗作为得分，可以考虑进一步优化
        % 可以考虑将换挡次数折合为一定量的SOC损耗，通过惩罚来抑制换挡次数
        economyScores(idx) = socTimeTable.Data(1) - socTimeTable.Data(end);
    end
catch ME
    disp("处理仿真结果数据时出错：" + ME.message ...
        + "，已将 evaEcoSimOut_debug 变量保存至基础工作区，以供调试");
    % 将simOut对象保存到工作区，方便调试
    assignin('base', 'evaEcoSimOut_debug', simOut);
    throw(ME)
end

%% 绘图
if doPlot
    plot_simout_data(simOut, [shiftSchedules.Description])
end

end
