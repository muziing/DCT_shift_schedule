function plot_simout_data(simOuts, figureTypes, descriptions)
%PLOT_SIMOUT_DATA 处理仿真结果数据，可视化绘图
%   可以传入仿真结果对象数组，将多次仿真结果绘在同一张图上
%   第二个参数为绘图类型，"soc"、"velocity"、"gear"、"motor" 组成的数组
%   第三个参数为可选参数，字符串数组，用于为每个仿真结果添加描述信息

arguments
    simOuts (1, :) Simulink.SimulationOutput % 仿真结果对象（/数组）
    figureTypes (1, :) string % 绘图类型（/数组）
    descriptions (1, :) string = [] % 描述（/数组）
end

%% 参数检查

simOutCount = length(simOuts);

if isempty(descriptions)
    descriptions = strings(1, simOutCount);
    for idx = 1:simOutCount
        descriptions(idx) = sprintf("仿真结果%d", idx);
    end
end

if length(descriptions) ~= simOutCount
    warning("仿真结果对象数组与描述数组长度不一致，将使用默认文本")
    descriptions = strings(1, simOutCount);
    for idx = 1:simOutCount
        descriptions(idx) = sprintf("仿真结果%d", idx);
    end
end

%% 提取数据

% 定义变量，预分配内存
timestamps = cell(1, simOutCount); % 时间戳
socData = cell(1, simOutCount); % 电池SOC， %
velocityData = cell(1, simOutCount); % 车速，km/h
gearData = cell(1, simOutCount); % 挡位
motSpdData = cell(1, simOutCount); % 电机转速，rpm
motTrqData = cell(1, simOutCount); % 电机转矩，Nm

for idx = 1:simOutCount
    socTimeTable = get(simOuts(idx).logsout, "<BattSoc>").Values;
    timestamps{idx} = socTimeTable.Time;
    socData{idx} = socTimeTable.Data;
    velocityData{idx} = ...
        get(simOuts(idx).logsout, "VehicleVelocity").Values.Data;
    demandSpdData = get(simOuts(1).logsout, "DemandSpd").Values.Data;
    gearData{idx} = get(simOuts(idx).logsout, "<TransGear>").Values.Data;
    motSpdData{idx} = ...
        get(simOuts(1).logsout, "MotSpd").Values.Data .* (60 / (2 * pi));
    motTrqData{idx} = get(simOuts(1).logsout, "MotTrq").Values.Data;
end

%% 绘图
for figureType = figureTypes
    switch figureType
        case "soc"
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

        case "velocity"
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
            title("车速曲线")
            xlabel("时间 / (s)")
            ylabel("车速 / (km/h)")
            legend('Location', 'best')
            hold off

        case "gear"
            %% 挡位变化图
            for idx = 1:simOutCount
                shiftCount = sum(diff(gearData{idx}) ~= 0) - 1;
                figure("Name", "挡位 - " + descriptions{idx})
                plot(timestamps{idx}(502:end), gearData{idx}(502:end), ...
                    'DisplayName', descriptions{idx})
                grid on
                title("换挡情况曲线 - " + descriptions{idx} + ...
                    "，换挡次数：" + num2str(shiftCount))
                xlabel("时间 / (s)")
                ylabel("挡位")
                legend('Location', 'best')
            end

        case "motor"
            %% 电机工作点图
            % 电机效率
            load("MotorData.mat", "MotorData")
            [gridX, gridY] = meshgrid(MotorData.Efficiency.Drive.Speed, ...
                MotorData.Efficiency.Drive.Torque);
            levelList = [70, 75, 80, 83, 86, 87:1:91, 91:0.5:95];
            labelLevelList = [70, 75, 80, 83, 86, 88, 90:1:93, 93:0.5:95];

            for idx = 1:simOutCount
                % 电机转速转矩的秒级数据
                timestamp = seconds(timestamps{idx}); % 转为double类型
                sampleIndex = mod(timestamp, 1) == 0; % 按指定秒级间隔重采样
                motSpdDataSec = motSpdData{idx}(sampleIndex);
                motTrqDataSec = motTrqData{idx}(sampleIndex);

                figure("Name", "电机工作点图 - " + descriptions{idx})
                colormap jet
                hold on

                [C, h] = contourf(gridX, gridY, ...
                    MotorData.Efficiency.Drive.Eff, ...
                    'LevelList', levelList);
                clabel(C, h, labelLevelList, 'LabelSpacing', 200)

                scatter(motSpdDataSec, motTrqDataSec) % 电机工作点

                grid on
                title("电机工作点图 - " + descriptions{idx})
                xlabel("转速 / (rpm)")
                ylabel("转矩 / (N·m)")
                hold off
            end

        otherwise
            warning("绘图类型无效")
    end
end

end
