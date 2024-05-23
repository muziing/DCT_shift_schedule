function simIns = simin_factory_accel(shiftSchedules, apValue, gearNumber)
%SIMIN_FACTORY_ACCEL 工厂函数，根据给定的换挡规律（/数组），生成测试整车加速性能的仿真任务对象
%   快速生成测试整车加速性能的仿真任务对象，可用于动力性评估等
arguments
    shiftSchedules (1, :) ShiftSchedule % 换挡规律/换挡规律数组
    apValue (1, 1) {mustBeNumeric, mustBePositive} = 1 % 加速踏板开度
    gearNumber (1, 1) {mustBeNumeric} = 0 % 挡位号，0表示自动变速
end

if apValue > 1
    error("加速踏板开度必须介于0~1之间")
end

modelName = "BEV_4DCT_Longitudinal";
simIns = simin_factory(shiftSchedules);

% 仿真停止时间，足以让车速达到稳定即可
if apValue > 0.8
    simStopTime = "100";
elseif apValue > 0.5
    simStopTime = "120";
elseif apValue >= 0.1
    simStopTime = "140";
else
    simStopTime = "300";
end

for index = 1:length(simIns)

    % 启用标定调试模式，替代原有的驾驶员模型
    simIns(index) = simIns(index).setVariable('CalibrateMode', true, ...
        'Workspace', modelName);

    % 处理挡位
    if ~gearNumber
        % 使用自动变速模式
        simIns(index) = simIns(index).setVariable('ConstantGearMode', false, ...
            'Workspace', modelName);
    else
        % 使用固定挡位
        simIns(index) = simIns(index).setVariable('ConstantGearMode', true, ...
            'Workspace', modelName);
        simIns(index) = simIns(index).setBlockParameter( ...
            modelName + "/TCU/ConstantGear/GearConstant", 'Value', num2str(gearNumber));

    end

    % 配置AP开度
    simIns(index) = simIns(index).setBlockParameter( ...
        modelName + "/Driver/CalibrateDriver/AccelCmdGain", 'Gain', ...
        num2str(apValue));

    % 配置其他仿真参数
    simIns(index) = simIns(index).setModelParameter( ...
        'StopTime', simStopTime ...
    );

end

end
