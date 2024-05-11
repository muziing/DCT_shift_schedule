function plot_simout_data(simOuts, descriptions)
%PLOT_SIMOUT_DATA 处理仿真结果数据，可视化绘图
%   可以传入仿真结果对象数组，将多次仿真结果绘在同一张图上
%   第二个参数为可选参数，字符串数组，用于为每个仿真结果添加描述信息

arguments
    simOuts (1, :) Simulink.SimulationOutput % 仿真结果对象（/数组）
    descriptions (1, :) string = [] % 描述（/数组）
end

simOutCount = length(simOuts);

if isempty(descriptions)
    descriptions = cell(1, simOutCount);
    for idx = 1:simOutCount
        descriptions{idx} = "仿真结果" + num2str(idx);
    end
end

if length(descriptions) ~= simOutCount
    error("仿真结果对象数组与描述数组长度不一致，请检查")
end

%% 提取数据

% 定义变量，预分配内存
timestamps = cell(1, simOutCount); % 时间戳
socData = cell(1, simOutCount); % 电池SOC
velocityData = cell(1, simOutCount); % 车速
motSpdData = cell(1, simOutCount); % 车速
motTrqData = cell(1, simOutCount); % 车速

for idx = 1:simOutCount
    socTimeTable = get(simOuts(idx).logsout, "<BattSoc>").Values;
    timestamps{idx} = socTimeTable.Time;
    socData{idx} = socTimeTable.Data;
    velocityData{idx} = get(simOuts(idx).logsout, "VehicleVelocity").Values.Data;
    demandSpdData = get(simOuts(1).logsout, "DemandSpd").Values.Data;
    motSpdData{idx} = get(simOuts(1).logsout, "MotSpd").Values.Data .* (60 / (2 * pi));
    motTrqData{idx} = get(simOuts(1).logsout, "MotTrq").Values.Data;
end

%% SOC 曲线
figure("Name", "SOC曲线")
hold on
for idx = 1:simOutCount
    plot(timestamps{idx}, socData{idx}, 'DisplayName', ...
        descriptions{idx})
end
grid on
title("电池 SOC 曲线")
ylabel("SOC / (%)")
legend('Location', 'northeast')
hold off

%% 车速跟踪图
figure("Name", "车速曲线")
hold on
plot(timestamps{idx}, demandSpdData, 'DisplayName', ...
"期望车速")
for idx = 1:simOutCount
    plot(timestamps{idx}, velocityData{idx}, 'DisplayName', ...
        "实际车速 - " + descriptions{idx})
end
grid on
title("车速跟踪图")
xlabel("时间 / (s)")
ylabel("车速 / (km/h)")
legend('Location', 'best')
hold off

%% 电机工作点图

% 电机效率
% load("MotorData.mat", "MotorData")
% [gridX, gridY] = meshgrid(MotorData.Efficiency.Drive.Speed, ...
%     MotorData.Efficiency.Drive.Torque);
% levelList = [70, 75, 80, 83, 86, 87:1:91, 91:0.5:95];
% labelLevelList = [70, 75, 80, 83, 86, 88, 90:1:93, 93:0.5:95];

for idx = 1:simOutCount
    % 求电机转速转矩的秒级数据
    for secTime = 1:length(timestamps{idx}) / 1000 - 1
        motSpdDataSec(secTime) = motSpdData{idx}(secTime * 1000);
        motTrqDataSec(secTime) = motTrqData{idx}(secTime * 1000);
    end

    figure("Name", "电机工作点图 - " + descriptions{idx})
    colormap jet
    hold on
    scatter(motSpdDataSec, motTrqDataSec) % 电机工作点
    % [C, h] = contourf(gridX, gridY, MotorData.Efficiency.Drive.Eff, 'LevelList', levelList);
    % clabel(C, h, labelLevelList, 'LabelSpacing', 200)
    grid on
    title("电机工作点图")
    xlabel("转速 / (rpm)")
    ylabel("转矩 / (N·m)")
    hold off
end
end
