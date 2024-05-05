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
ShiftSchedule.check_other(shiftScheduleMin, shiftScheduleMax)
if shiftScheduleMin > shiftScheduleMax
    error("shiftScheduleMin 必须严格小于 shiftScheduleMax")
end

% 遍历换挡规律中 upSpds 中的所有维度，对每个维度在给定范围内生成随机数
upSpds = zeros(size(shiftScheduleMin.UpSpds));
for apIdx = 1:width(shiftScheduleMin.UpSpds)
    % 最终值 = 最小值 + 0~1随机数 * (最大值 - 最小值)
    upSpds(:, apIdx) = shiftScheduleMin.UpSpds(:, apIdx) + ...
        rand * (shiftScheduleMax.UpSpds(:, apIdx) - ...
        shiftScheduleMin.UpSpds(:, apIdx));
end
% 降挡点由 get_downshift_spds() 函数默认配置计算而来，不再随机生成
downSpds = get_downshift_spds(upSpds);

% 创建随机换挡规律实例
randomSchedule = ShiftSchedule;
randomSchedule.UpAPs = shiftScheduleMin.UpAPs;
randomSchedule.DownAPs = shiftScheduleMin.DownAPs;
randomSchedule.Description = description;
randomSchedule.UpSpds = upSpds;
randomSchedule.DownSpds = downSpds;

% 边界检查
randomSchedule = ShiftSchedule.limit(randomSchedule, ...
    shiftScheduleMin, shiftScheduleMax);
end
