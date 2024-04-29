function economyScores = evaluate_economy(shiftSchedules, parallel, doPlot)
%EVALUATE_ECONOMY  运行给定仿真对象，评估经济性
%   对传入的仿真结果进行分析，评估经济性得分
%   shiftSchedules: 换挡规律（数组）
%   parallel: 是否并行仿真
%   doPlot: 是否进行绘图

arguments
    shiftSchedules (1, :) ShiftSchedule
    parallel (1, 1) {mustBeNumericOrLogical} = false
    doPlot (1, 1) {mustBeNumericOrLogical} = false
end

%% 创建仿真任务对象
taskCount = length(shiftSchedules);
simIns = simin_factory(shiftSchedules, "WLTC_class_2");

%% 运行仿真
% TODO 加异常处理
if ~parallel || taskCount < 2
    % 串行仿真
    simOut = sim(simIns);
else
    % 并行仿真
    simOut = parsim(simIns);
end

%% 处理仿真结果数据
% 定义变量，预分配内存
economyScores = zeros(1, taskCount);
socData = cell(1, taskCount);
timestamps = cell(1, taskCount);
velocityData = cell(1, taskCount);

for idx = 1:taskCount
    socTimeTable = get(simOut(idx).logsout, "<BattSoc>").Values;
    socData{idx} = socTimeTable.Data;
    timestamps{idx} = socTimeTable.Time;
    velocityData{idx} = get(simOut(idx).logsout, "VehicleVelocity").Values.Data;

    % 计算经济性得分
    % TODO 经济性得分计算方法待优化
    economyScores(idx) = socTimeTable.Data(1) - socTimeTable.Data(end);
end

%% 绘图
if doPlot
    % SOC 曲线
    figure("Name", "SOC曲线")
    hold on
    for idx = 1:taskCount
        plot(timestamps{idx}, socData{idx}, 'DisplayName', ...
            "换挡规律"+num2str(idx))
    end
    grid on
    title("电池 SOC 曲线")
    ylabel("SOC / (%)")
    legend('Location', 'northeast')
    hold off

    % 电机工作点图

end

end
