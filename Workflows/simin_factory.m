function simIn = simin_factory(shiftSchedule, drivingCycle)
%SIMIN_FACTORY 工厂函数，用于生成仿真任务对象
%   根据传入的换挡规律、驾驶循环，构造对应的 Simulink.SimulationInput 并返回

arguments
    shiftSchedule
    drivingCycle (1, 1) {mustBeNonzeroLengthText} = "WLTC_class_2"
end

%% 初始化
modelName = "Dual_Clutch_Trans";
shiftBlock = "Dual_Clutch_Trans/TCU/TCU/Shift Logic";
load_system(modelName);
simIn = Simulink.SimulationInput(modelName);

%% 处理换挡规律
% 创建Simulink.LookupTable对象备用
% https://ww2.mathworks.cn/help/simulink/ug/configure-instance-specific-data-for-lookup-tables1.html
upShiftLookupTable = Simulink.LookupTable;
upShiftLookupTable.Table.Value = shiftSchedule.upSpds';
upShiftLookupTable.Breakpoints(1).Value = shiftSchedule.upAPs;
upShiftLookupTable.Breakpoints(2).Value = 1:height(shiftSchedule.upSpds);
upShiftLookupTable.StructTypeInfo.Name = "UpShiftLookupTable";
downShiftLookupTable = Simulink.LookupTable;
downShiftLookupTable.Table.Value = shiftSchedule.downSpds';
downShiftLookupTable.Breakpoints(1).Value = shiftSchedule.downAPs;
downShiftLookupTable.Breakpoints(2).Value = ...
    2:height(shiftSchedule.downSpds) + 1;
downShiftLookupTable.StructTypeInfo.Name = "DownShiftLookupTable";


% 将新创建的查表对象设置到模型工作区中
simIn = simIn.setVariable('upShiftLookupTable', upShiftLookupTable, ...
    'Workspace', modelName);
simIn = simIn.setVariable('downShiftLookupTable', downShiftLookupTable, ...
    'Workspace', modelName);

% 通过修改模型引用的实例属性，使引用实例使用Dual_Clutch_Trans模型工作区中的查表
instSpecParams = get_param(shiftBlock, 'InstanceParameters');
instSpecParams(1).Value = 'downShiftLookupTable';
instSpecParams(2).Value = 'upShiftLookupTable';
simIn = simIn.setBlockParameter(shiftBlock, 'InstanceParameters', ...
    instSpecParams);

%% 处理驾驶循环
simIn = simIn.setVariable('DrivingCycle', drivingCycle, ...
    'Workspace', modelName);
simIn = simIn.setModelParameter('StopTime', "1477"); % FIXME 暂时写死

end
