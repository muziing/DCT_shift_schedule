% 标定静态换挡点

% 工况：从静止一直加速到最大车速，期间加速踏板开度为某一固定值、制动踏板开度为 0
%
% 将各种AP开度在各挡位下分别运行仿真，得到【车速-时间】曲线，进而绘制
% 【加速度-车速】曲线与【电机效率-车速】曲线，取相邻挡位曲线交点分别作为
% 对应AP开度下的【动力性升挡点】与【经济性升挡点】
%
% 降档点由对应升档点减去【换挡延迟】而来，换挡延迟一般取 2~8 km/h；
% 【换挡延迟系数】为 1 表示【等延迟型】，
% 各AP开度下换挡延迟相同；0~1 表示【收敛型】，换挡延迟随AP开度增大而减小；>1 表示
% 【发散型】，换挡延迟随AP开度的增大而增大

%% 配置

accelPedalValues = [10, 20, 50, 80, 100] / 100; % 加速踏板开度列表
gearNumbers = 1:4; % 挡位数

% 加速度截止值，当加速度绝对值小于此值时认为车速已经稳定，舍弃此时刻后面的数据
accelThreshold = 0.05;

% 根据经验，仿真开始的一小段时间内求解尚未完全稳定，容易出现值突变，舍去（待优化）
startIndex = 1001;

%% 创建、配置并运行仿真任务

simTaskCount = length(accelPedalValues) * length(gearNumbers); % 仿真任务总数
index = 1;

% 为每个仿真任务设置不同的AP开度与挡位
for apIndex = 1:length(accelPedalValues)
    for gear = gearNumbers
        simIn(index) = simin_factory_accel( ...
            shiftSchedule_acc, accelPedalValues(apIndex), gear);
        index = index + 1;
    end
end

% 运行仿真
% （注意，建议在物理内存充足的电脑上使用并行仿真，
% 低内存机器使用并行仿真，会频繁使用硬盘交换分区、反而可能极大拖慢仿真速度）
simOut = parsim(simIn, 'ShowSimulationManager', 'on');

%% 数据后处理

result = cell(simTaskCount, 1);
index = 1;

for apIndex = 1:length(accelPedalValues)
    for gear = gearNumbers

        velocityTimeTable = get(simOut(index).logsout, "VehicleVelocity").Values;
        timestamps = velocityTimeTable.Time; % duration 类型

        % 因差分会显著放大噪声，使用移动平均值对速度简单滤波
        smoothedVelocities = smooth(velocityTimeTable.Data, 'moving', 50);

        % 差分得到加速度
        accelerations = diff(smoothedVelocities ./ 3.6) ./ diff(seconds(timestamps));
        jerks = diff(accelerations) ./ diff(seconds(timestamps(1:end - 1)));

        % 获取电机转速转矩，查效率MAP图获取对应工作点效率
        motorSpds_radps = get(simOut(index).logsout, "MotSpd").Values.Data;
        motorSpds = motorSpds_radps * (60 / (2 * pi)); % rad/s -> rpm
        motorTrqs = get(simOut(index).logsout, "MotTrq").Values.Data;
        motorEffs = interp2(MotorData.Efficiency.Drive.Speed, ...
            MotorData.Efficiency.Drive.Torque, ...
            MotorData.Efficiency.Drive.Eff, ...
            motorSpds, motorTrqs); % 通过插值获取电机效率值

        % 截取求解已稳定、车速已稳定（加速度很小、且不再超过阈值）之间的数据
        % TODO 优化末尾截断方法，以跃度突变作为截断标志，而不只是加速度值很小
        endIndex = get_consec_below_thold(abs(accelerations), accelThreshold);
        if isnan(endIndex)
            warning("未能确定车速稳定时刻，请检查模型、仿真时间与加速度阈值！")
            endIndex = length(accelerations);
        end
        timestamps = timestamps(startIndex:endIndex);
        smoothedVelocities = smoothedVelocities(startIndex:endIndex);
        accelerations = accelerations(startIndex:endIndex);
        jerks = jerks(startIndex:endIndex);
        motorEffs = motorEffs(startIndex:endIndex);

        % plot(timestamps, smoothedVelocities) % 【车速-时间】曲线，调试用
        % plot(timestamps, accelerations) % 【加速度-时间】曲线，调试用
        % plot(timestamps, jerks)
        % plot(timestamps, motorEffs)

        % 将处理后的数据重新整理至一张 timetable 中
        dataTable = timetable(smoothedVelocities, accelerations, motorEffs, ...
            'RowTimes', timestamps);

        % 通过一维插值，计算【加速度-车速】、【电机效率-车速】曲线
        equispacedVelocities = 0:0.001:max(smoothedVelocities);
        accel2velocitie = interp1(smoothedVelocities, accelerations, ...
            equispacedVelocities); % FIXME 解决可能存在相同车速的导致采样点不唯一的问题
        eff2velocitie = interp1(smoothedVelocities, motorEffs, ...
            equispacedVelocities);

        % 将处理后的结果数据保存到结构体数组中
        result{index}.AccelPedal = accelPedalValues(apIndex);
        result{index}.Gear = gear;
        result{index}.PostedData = dataTable;
        result{index}.EquispacedVelocities = equispacedVelocities;
        result{index}.Accel2Velocities = accel2velocitie;
        result{index}.Eff2Velocities = eff2velocitie;

        index = index + 1;
    end
end

clear index apIndex gear velocityTimeTable
clear timestamps  startIndex endIndex
clear smoothedVelocities accelerations jerks
clear equispacedVelocities accel2velocitie eff2velocitie
clear motorSpds_radps motorSpds motorTrqs motorEffs

% 保存仿真结果，以备日后检查排错
% save("calibrate_result.mat", "simIn", "simOut", "result")

%% 绘图与计算升降档点

index = 1;

for apIndex = 1:length(accelPedalValues)

    figure("Name", num2str(accelPedalValues(apIndex) * 100) + "%")
    hold on

    for gearIdx = 1:length(gearNumbers)
        plot(result{index + gearIdx - 1}.EquispacedVelocities, ...
            result{index + gearIdx - 1}.Accel2Velocities, ...
            'DisplayName', num2str(gearNumbers(gearIdx)) + "挡")
    end

    xlabel("车速 / (km/h)")
    ylabel("加速度 / (m/s^2)")
    title("加速踏板开度："+num2str(accelPedalValues(apIndex) * 100) + "%")
    legend('Location', 'best')

    hold off

    index = index + length(gearNumbers);
end

clear index

%% 导出标定结果

modelVersion = simOut(1).SimulationMetadata.ModelInfo.ModelVersion;

%% 收尾清理

clear modelVersion gearNumbers simTaskCount result
