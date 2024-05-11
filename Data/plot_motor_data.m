% 电机数据处理与绘图

%% 加载数据
load("MotorData.mat");

%% 外特性曲线

motSpeed = MotorData.ExternalCharacteristics.Rated.rpm;
ratedTorque = MotorData.ExternalCharacteristics.Rated.torque;
ratedPower = MotorData.ExternalCharacteristics.Rated.power;
peakTorque = MotorData.ExternalCharacteristics.Peak.torque;
peakPower = MotorData.ExternalCharacteristics.Peak.power;

figure('Name', "大轿车电机外特性曲线")

hold on

xlabel("转速 (rpm)")
xlim([0, max(motSpeed) + 400])
xticks(0:800:max(motSpeed))

yyaxis left
plot(motSpeed, ratedTorque, "-", 'DisplayName', "额定转矩")
plot(motSpeed, peakTorque, "--", 'DisplayName', "峰值转矩")
ylabel("转矩 (N·m)")
ylim([0, 480])
yticks(0:40:480)

yyaxis right
plot(motSpeed, ratedPower, "-", 'DisplayName', "额定功率")
plot(motSpeed, peakPower, "--", 'DisplayName', "峰值功率")
ylabel("功率 (kW)")
ylim([0, 260])
yticks(0:20:260)

grid on
legend('Location', 'best')
title("驱动电机外特性曲线图")

hold off

clear peakPower peakTorque ratedPower ratedTorque motSpeed

%% 效率 MAP 图（电动）

motSpdArray = MotorData.Efficiency.RawData.Drive.speed;
motTorArray = MotorData.Efficiency.RawData.Drive.torque;
motEffArray = MotorData.Efficiency.RawData.Drive.systemEfficiency;

% 设置网格与插值
[gridX, gridY] = meshgrid(min(motSpdArray):10:max(motSpdArray), ...
    min(motTorArray) - 20:2:max(motTorArray) + 20);
motEff = griddata(motSpdArray, motTorArray, motEffArray, gridX, gridY);

% 根据具体情况调整等高线层级与标签层级
levelList = [70, 75, 80, 83, 86, 87:1:91, 91:0.5:95];
labelLevelList = [70, 75, 80, 83, 86, 88, 90:1:93, 93:0.5:95];

figure("Name", "电机系统效率MAP图（电动）")
colormap jet

[C, h] = contourf(gridX, gridY, motEff, 'LevelList', levelList);
clabel(C, h, labelLevelList, 'LabelSpacing', 200)

title("电机系统效率 MAP 图（电动）")
xlabel("转速(rpm)")
ylabel("转矩(N·m)")

clear motSpdArray motTorArray motEffArray gridX gridY
clear motEff levelList labelLevelList C h

%% 效率 MAP 图（馈电）
motSpdArray = MotorData.Efficiency.RawData.Feed.speed;
motTorArray = MotorData.Efficiency.RawData.Feed.torque;
motEffArray = MotorData.Efficiency.RawData.Feed.systemEfficiency;

% 设置网格与插值
[gridX, gridY] = meshgrid(min(motSpdArray):10:max(motSpdArray), ...
    min(motTorArray) - 20:1:max(motTorArray) + 20);
motEff = griddata(motSpdArray, motTorArray, motEffArray, gridX, gridY);

% 根据具体情况调整等高线层级
levelList = [70, 75, 80, 83, 86, 88:1:90, 91:0.5:93.5, 94, 95];
labelLevelList = [70, 75, 80, 83, 86, 88:1:93, 94, 95];

figure("Name", "电机系统效率MAP图（馈电）")
colormap jet

[C, h] = contourf(gridX, gridY, motEff, 'LevelList', levelList);
clabel(C, h, labelLevelList, 'LabelSpacing', 200)

title("电机系统效率 MAP 图（馈电）")
xlabel("转速(rpm)")
ylabel("转矩(N·m)")

clear motSpdArray motTorArray motEffArray gridX gridY
clear motEff levelList labelLevelList C h

%% 模型数据绘图
% 绘制 MappedMotor 模块实际使用数据

% 外特性（与直接读取peek有微小区别）
motSpdArray = unique(MotorData.Efficiency.RawData.Drive.speed)';
motTorArray = zeros(1, length(motSpdArray));

for index = 1:length(motSpdArray)
    motTorArray(index) = max( ...
        MotorData.Efficiency.RawData.Drive{ ...
                                           MotorData.Efficiency.RawData.Drive.speed == motSpdArray(index), 5});
end

% 效率
[gridX, gridY] = meshgrid(MotorData.Efficiency.Drive.Speed, ...
    MotorData.Efficiency.Drive.Torque);
levelList = [70, 75, 80, 83, 86, 87:1:91, 91:0.5:95];
labelLevelList = [70, 75, 80, 83, 86, 88, 90:1:93, 93:0.5:95];

% 绘图
figure("Name", "MappedMotor 建模数据")
colormap jet
hold on
plot(motSpdArray, motTorArray)
plot(motSpdArray, -motTorArray)
[C, h] = contourf(gridX, gridY, MotorData.Efficiency.Drive.Eff, 'LevelList', levelList);
clabel(C, h, labelLevelList, 'LabelSpacing', 200)
[C, h] = contourf(gridX, -gridY, MotorData.Efficiency.Drive.Eff, 'LevelList', levelList);
clabel(C, h, labelLevelList, 'LabelSpacing', 200)
hold off
