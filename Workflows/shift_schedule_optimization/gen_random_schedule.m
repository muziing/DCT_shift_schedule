function randomSchedule = gen_random_schedule(shiftScheduleMin, ...
    shiftScheduleMax, description)
%GEN_RANDOM_SCHEDULE 在给定上下界限制内随机生成换挡规律实例
%   用于粒子群优化算法中随机初始化粒子位置与速度（速度亦用 ShiftSchedule 类表示）
arguments
    shiftScheduleMin (1, 1) ShiftSchedule % 下界
    shiftScheduleMax (1, 1) ShiftSchedule % 上界
    description (1, 1) {mustBeTextScalar} = "随机换挡规律" % 描述信息
end

% 输入检查
shiftScheduleMin.check_other(shiftScheduleMin, shiftScheduleMax)
if shiftScheduleMin > shiftScheduleMax
    error("shiftScheduleMin 必须小于 shiftScheduleMax")
end

% 遍历换挡规律中 upSpds 中的所有维度，对每个维度在给定范围内生成随机数
upSpds = zeros(shiftScheduleMin.UpSpds.size);
for apIdx = 1:width(shiftScheduleMin.upSpds)
    % 最终值 = 最小值 + 0~1随机数 * (最大值 - 最小值)
    upSpds(:, apIdx) = shiftScheduleMin.upSpds(:, apIdx) + ...
        random * (shiftScheduleMax.upSpds(:, apIdx) - ...
        shiftScheduleMin.upSpds(:, apIdx));
end
% 降挡点由 get_downshift_spds() 函数默认配置计算而来，不再随机生成
downSpds = get_downshift_spds(upSpds);

% 创建随机换挡规律实例
randomSchedule = ShiftSchedule;
randomSchedule.upAps = shiftScheduleMin.upAps;
randomSchedule.downAps = shiftScheduleMin.downAps;
randomSchedule.Description = description;
randomSchedule.UpSpds = upSpds;
randomSchedule.DownSpds = downSpds;

% 边界检查
randomSchedule = randomSchedule.limit(shiftScheduleMin, shiftScheduleMax);

end
