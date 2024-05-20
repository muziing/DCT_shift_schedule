function accTime = get_acceleration_time(simOut, startSpeed, endSpeed)
%GET_ACCELERATION_TIME 获取给定车速区间内的加速时间
%   分析仿真结果，计算给定车速区间的加速时间(s)
arguments
    simOut (1, 1) Simulink.SimulationOutput % 仿真结果对象
    startSpeed (1, 1) {mustBeNumeric, mustBeNonnegative} % 起始车速，km/h
    endSpeed (1, 1) {mustBeNumeric, mustBeNonnegative} % 结束车速，km/h
end

velocityTimeTable = get(simOut.logsout, "VehicleVelocity").Values;
timestamps = velocityTimeTable.Time; % duration 类型

% 使用移动平均值对速度简单滤波
smoothedVelocities = smooth(velocityTimeTable.Data, 'moving', 20);

% 计算加速时间
startIndex = get_consec_below_thold(-smoothedVelocities, -startSpeed);
endIndex = get_consec_below_thold(-smoothedVelocities, -endSpeed);

if isnan(endIndex)
    warning("未能达到指定车速")
    accTime = NaN;
else
    accTime = seconds(timestamps(endIndex) - timestamps(startIndex));
end

end
