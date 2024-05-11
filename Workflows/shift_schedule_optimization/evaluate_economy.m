function economyScores = evaluate_economy(shiftSchedules, parallel, doPlot)
%EVALUATE_ECONOMY  评估给定换挡参数的经济性
%   对传入的换挡规律进行仿真与结果分析以评估经济性得分，值越小经济性越好

arguments
    shiftSchedules (1, :) ShiftSchedule % 换挡规律
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
socData = cell(1, taskCount);
timestamps = cell(1, taskCount);
velocityData = cell(1, taskCount);

try
    for idx = 1:taskCount
        socTimeTable = get(simOut(idx).logsout, "<BattSoc>").Values;
        socData{idx} = socTimeTable.Data;
        timestamps{idx} = socTimeTable.Time;
        velocityData{idx} = get(simOut(idx).logsout, "VehicleVelocity").Values.Data;
        demandSpdData = get(simOut(1).logsout, "DemandSpd").Values.Data;

        % 计算经济性得分
        % 目前直接使用电池SOC消耗作为得分，可以考虑进一步优化
        % 可以考虑将换挡次数折合为一定量的SOC损耗，通过惩罚来抑制换挡次数
        economyScores(idx) = socTimeTable.Data(1) - socTimeTable.Data(end);
    end
catch ME
    disp("处理仿真结果数据时出错：" + ME.message...
        + "，已将 evaEcoSimOut_debug 变量保存至基础工作区，以供调试");
    % 将simOut对象保存到工作区，方便调试
    assignin('base', 'evaEcoSimOut_debug', simOut);
    throw(ME)
end

%% 绘图
if doPlot
    % SOC 曲线
    figure("Name", "SOC曲线")
    hold on
    for idx = 1:taskCount
        plot(timestamps{idx}, socData{idx}, 'DisplayName', ...
            shiftSchedules(idx).Description)
    end
    grid on
    title("电池 SOC 曲线")
    ylabel("SOC / (%)")
    legend('Location', 'northeast')
    hold off

    % 车速跟踪图
    for idx = 1:taskCount
        figure("Name", shiftSchedules(idx).Description + " - 车速曲线")
        hold on
        plot(timestamps{idx}, velocityData{idx}, 'DisplayName', ...
            "实际车速")
        plot(timestamps{idx}, demandSpdData, 'DisplayName', ...
            "期望车速")
        grid on
        title("车速跟踪图")
        xlabel("时间 / (s)")
        ylabel("车速 / (km/h)")
        legend('Location', 'northeast')
        hold off
    end

    % 电机工作点图
    % TODO 实现绘制电机工作点图功能
    % for idx = 1:taskCount
    %     figure("Name", shiftSchedules(idx).Description + " - 电机工作点图")
    %     hold on
    %     % plot(timestamps{idx}, velocityData{idx}, 'DisplayName', ...
    %     %     "实际车速")
    %     % plot(timestamps{idx}, demandSpdData, 'DisplayName', ...
    %     %     "期望车速")
    %     grid on
    %     title("电机工作点图")
    %     hold off
    % end

end

end
