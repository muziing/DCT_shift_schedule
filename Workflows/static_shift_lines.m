% 经典静态双参数换挡规律设计
% 基于汽车行驶方程静态计算出的车辆运行情况，设计计算【最佳动力性换挡规律】、
% 【最佳经济性换挡规律】以及二者拼接而成的简易【综合换挡规律】

% TODO 定义一套换挡点导出的数据类型格式，并实现导出，并在模型端实现导入……

static_analysis
close all

%% 加速踏板标定

% 在 VCU 中，需要标定设计【加速踏板开度-电机转矩请求】对应关系
% 此处使用最为简单的线性关系，即请求转矩 = 踏板开度百分比 × 当前电机转速下最大转矩

% TODO 通过双列数组指明这种对应关系

accelPedalValues = [15, 30, 50, 90, 100]; % 待处理的加速踏板开度列表

%% 计算：动力型换挡规律

% 存储各挡位升挡点，行数为挡位数-1、列数为踏板开度数量+1（额外包含一列开度为0的情况）
upShiftSpds_acc = zeros(length(Driveline.ig) - 1, length(accelPedalValues) + 1);

for apIdx = 1:length(accelPedalValues)
    % 计算在该AP开度下，各挡位行驶加速度曲线
    accelerations = ((F_t * accelPedalValues(apIdx) / 100) - (F_f + F_w + F_i)) ./ ...
        (delta * VehicleData.NoLoad.Mass);
    accelerations(accelerations < 0) = NaN; % 舍弃计算出的负值加速度

    for gearIdx = 1:(length(Driveline.ig) - 1)
        % 求解相邻挡位加速度曲线交点
        [shiftSpd, ~] = intersections(u_a(:, gearIdx), ...
            accelerations(:, gearIdx), u_a(:, gearIdx + 1), ...
            accelerations(:, gearIdx + 1), false);

        if isnan(shiftSpd)
            % 如果两个相邻挡位曲线没有交点，则将升挡点设置为接近低挡位的最高车速
            shiftSpd = u_a(end, gearIdx) * 0.9;
        end

        upShiftSpds_acc(gearIdx, apIdx + 1) = shiftSpd;
    end
end

% AP开度数组最前面补0，对应升挡速度与原最小AP开度对应速度相同
% accelPedalValues = [0, accelPedalValues];
upShiftSpds_acc(:, 1) = upShiftSpds_acc(:, 2);

downShiftSpds_acc = get_downshift_spds(upShiftSpds_acc, 4);

% 绘图
plot_shift_lines([0, accelPedalValues], upShiftSpds_acc, downShiftSpds_acc, ...
"动力型换挡规律")

clear apIdx gearIdx accelerations shiftSpd

%% 计算：经济型换挡规律

% -------------------处理效率 MAP 图-------------------
motSpdArray = MotorData.Efficiency.RawData.Drive.speed;
motTorArray = MotorData.Efficiency.RawData.Drive.torque;
motEffArray = MotorData.Efficiency.RawData.Drive.systemEfficiency;

% 设置网格
motSpds = min(motSpdArray):100:max(motSpdArray);
motTors = linspace(min(motTorArray), max(motTorArray), 200);
[gridX, gridY] = meshgrid(motSpds, motTors);
% 将原始实验数据通过插值，调整到网格中
motEffs = griddata(motSpdArray, motTorArray, motEffArray, gridX, gridY);

% 删去临时变量，减小干扰
clear motSpdArray motTorArray motEffArray gridX gridY

% % 绘图：电机效率MAP图（三维）
% figure("Name","电机系统效率MAP图")
% colormap jet
% surf(motSpds, motTors, motEffs, 'EdgeColor', 'none');
% title("电机系统效率 MAP 图")
% xlabel("转速(rpm)")
% ylabel("转矩(N·m)")
% zlabel("电机效率(%)")

% -----------处理【电机转速-车速】、【电机转矩-AP踏板开度】映射-----------
gearRatio = Driveline.i0 .* Driveline.ig; % 总传动比
vehicleSpds = motSpds * (Wheel.UnloadedRadius * 2 * pi * 3.6) ./ ...
    (60 * gearRatio');
apGrid = linspace(0, 100, length(motTors));

% -----------绘图：各挡位行驶工况效率图-----------
figure("Name", "行驶工况效率图")
colors = [0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980; ...
              0.9290, 0.6940, 0.1250; 0.4940, 0.1840, 0.5560];
for gearIdx = 1:length(Driveline.ig)
    surf(vehicleSpds(gearIdx, :), apGrid, motEffs, ...
        'EdgeColor', 'none', ...
        'FaceColor', colors(gearIdx, :), ...
        'DisplayName', num2str(gearIdx) + "挡")
    hold on
end
title("电机系统效率 MAP 图")
xlabel("车速(km/h)")
ylabel("加速踏板开度(%)")
zlabel("电机效率(%)")
legend
hold off

% -----------求换挡点-----------
% TODO 实现曲面交线求解代码等
% 马上中期报告实在来不及了，先用观察法直接写出换挡点数值，后续再回来补编程实现吧
upShiftSpds_eco = [47.74, 47.74, 41.14, 35.04, 26.92, 18.28; ...
                       76.35, 76.35, 65.88, 56.00, 45.29, 29.65; ...
                       110.15, 110.15, 93.87, 83.68, 68.84, 45.06; ];
downShiftSpds_eco = get_downshift_spds(upShiftSpds_eco, 4);

plot_shift_lines([0, accelPedalValues], upShiftSpds_eco, downShiftSpds_eco, ...
"经济型换挡规律")

%% 函数

function downShiftSpds = get_downshift_spds(upShiftSpds, delaySpeed, ...
    delaySpeedFactor)
% 由升挡点数组计算降挡点数组
% :param upShiftSpds: 升挡点数组，各行代表不同的踏板开度、各列代表不同的挡位
% :param delaySpeed: 换挡延迟，(km/h)，一般取 2~8
% :param delaySpeedFactor: 换挡延迟系数，决定换挡线类型

% 降挡点由对应升挡点减去【换挡延迟】而来，换挡延迟一般取 2~8 km/h；
% 换挡延迟系数：
%  - 1 表示【等延迟型】，各AP开度下换挡延迟相同；
%  - 0~1 表示【收敛型】，换挡延迟随AP开度增大而减小；
%  - >1 表示【发散型】，换挡延迟随AP开度的增大而增大

arguments
    upShiftSpds {mustBeNumeric}
    delaySpeed (1, 1) {mustBeNumeric, mustBePositive} = 5
    delaySpeedFactor (1, 1) {mustBeNumeric, mustBePositive} = 1
end

delaySpeeds = delaySpeed * (delaySpeedFactor .^ (1:width(upShiftSpds)));
downShiftSpds = upShiftSpds - delaySpeeds;

% end of get_downshift_spds()
end

function plot_shift_lines(accelPedalValues, upShiftSpds, downShiftSpds, ...
    figTitle)
% 绘制换挡线

figure('Name', figTitle)
hold on

% 一组较为美观的预设颜色
colors = [0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980; ...
              0.9290, 0.6940, 0.1250; 0.4940, 0.1840, 0.5560; ...
              0.4660, 0.6740, 0.1880; 0.3010, 0.7450, 0.9330; ...
              0.6350, 0.0780, 0.1840];

for gearIdx = 1:height(upShiftSpds)
    plot(upShiftSpds(gearIdx, :), accelPedalValues, 'Color', ...
        colors(gearIdx, :), 'DisplayName', ...
        num2str(gearIdx) + "-" + num2str(gearIdx + 1) + "升挡线")
    plot(downShiftSpds(gearIdx, :), accelPedalValues, '--', 'Color', ...
        colors(gearIdx, :), 'DisplayName', ...
        num2str(gearIdx + 1) + "-" + num2str(gearIdx) + "降挡线")
end

grid on
title(figTitle)
xlabel("车速 / (km/h)")
ylabel("加速踏板开度 / (%)")
legend('Location', 'best')
hold off

% end of plot_shift_lines()
end
