function simIn = simin_factory(shiftSchedule, drivingCycle)
%SIMIN_FACTORY 工厂函数，根据给定的换挡规律（/数组）、驾驶循环生成仿真任务对象
%   shiftSchedule: 换挡规律/换挡规律数组
%   drivingCycle: 行驶循环名称
%   根据传入的换挡规律、驾驶循环，构造对应的 Simulink.SimulationInput 并返回
%   若传入多组换挡规律，则对应返回仿真输入对象数组

arguments
    shiftSchedule (1, :) ShiftSchedule
    drivingCycle (1, 1) {mustBeNonzeroLengthText} = "WLTC_class_2"
end

% 初始化
modelName = "BEV_4DCT_Longitudinal";
shiftBlock = "BEV_4DCT_Longitudinal/TCU/TCU/Shift Logic";
load_system(modelName);

taskCount = length(shiftSchedule); % 换挡参数数量（仿真任务数）
simIn(1:taskCount) = Simulink.SimulationInput(modelName);

for idx = 1:taskCount
    % 处理换挡规律
    % 创建Simulink.LookupTable对象备用
    % https://ww2.mathworks.cn/help/simulink/ug/configure-instance-specific-data-for-lookup-tables1.html
    upShiftLookupTable = Simulink.LookupTable;
    upShiftLookupTable.Table.Value = shiftSchedule(idx).UpSpds';
    upShiftLookupTable.Breakpoints(1).Value = shiftSchedule(idx).UpAPs;
    upShiftLookupTable.Breakpoints(2).Value = 1:height(shiftSchedule(idx).UpSpds);
    upShiftLookupTable.StructTypeInfo.Name = "UpShiftLookupTable";
    downShiftLookupTable = Simulink.LookupTable;
    downShiftLookupTable.Table.Value = shiftSchedule(idx).DownSpds';
    downShiftLookupTable.Breakpoints(1).Value = shiftSchedule(idx).DownAPs;
    downShiftLookupTable.Breakpoints(2).Value = ...
        2:height(shiftSchedule(idx).DownSpds) + 1;
    downShiftLookupTable.StructTypeInfo.Name = "DownShiftLookupTable";

    % 将新创建的查表对象设置到模型工作区中
    simIn(idx) = simIn(idx).setVariable('upShiftLookupTable', upShiftLookupTable, ...
        'Workspace', modelName);
    simIn(idx) = simIn(idx).setVariable('downShiftLookupTable', downShiftLookupTable, ...
        'Workspace', modelName);

    % 通过修改模型引用的实例属性，使引用实例使用父模型工作区中的LookupTable
    instSpecParams = get_param(shiftBlock, 'InstanceParameters');
    instSpecParams(1).Value = 'downShiftLookupTable';
    instSpecParams(2).Value = 'upShiftLookupTable';
    simIn(idx) = simIn(idx).setBlockParameter(shiftBlock, 'InstanceParameters', ...
        instSpecParams);

    % 处理驾驶循环
    drivingCycleDict = dictionary( ...
        "WLTC_class_1", "1022", ...
        "WLTC_class_2", "1477", ...
        "WLTC_class_3", "1800", ...
        "NEDC", "1180", ...
        "CLTC-C", "1800", ...
        "CLTC-P", "1800", ...
        "FTP-75", "2477", ...
        "UDDS", "1369");
    simIn(idx) = simIn(idx).setVariable('DrivingCycle', drivingCycle, ...
        'Workspace', modelName);
    simIn(idx) = simIn(idx).setModelParameter('StopTime', drivingCycleDict(drivingCycle));
end

end
