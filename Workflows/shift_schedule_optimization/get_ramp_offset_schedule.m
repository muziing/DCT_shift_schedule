function newSchedule = get_ramp_offset_schedule(referSchedule, ramp, offset)
%GET_RAMP_OFFSET_SCHEDULE 根据给定参考换挡规律与 ramp、offset 参数，创建新的换挡规律
%   以输入的换挡规律作为参考，返回根据 ramp、offset 参数创建新的换挡规律。
%   此函数旨在将确定换挡规律边界时使用的参数维度降低至二维。
%   将从传入的参考换挡规律中提取AP开度列表、最低AP开度对应换挡车速等信息。
%   ramp 为坡度变化系数，影响换挡速度随AP开度变化而变化的程度。ramp 的值越大，
%   每条换挡线越"倾斜"。一般取正值，以满足大AP开度下的动力性需求。
%   offset 为速度偏移系数，影响相邻挡位间换挡速度的差值。值越大，换挡线之间
%   的间距越大，越"分散"。一般取小正值或零，取负值时需谨慎。

arguments
    referSchedule (1, 1) ShiftSchedule % 输入换挡规律
    ramp (1, 1) {mustBeNumeric} % 坡度变化系数
    offset (1, 1) {mustBeNumeric} % 速度偏移系数
end

% TODO 设计与验证参数取值范围。比如是否允许 offset 取负值。

pedalPos = referSchedule.UpAPs ./ 100;
newUpSpds = zeros(size(referSchedule.UpSpds));
newUpSpds(:, 1) = referSchedule.UpSpds(:, 1);

% 处理ramp
for apIdx = 2:width(newUpSpds)
    newUpSpds(:, apIdx) = newUpSpds(:, 1) + ramp * (apIdx - 1) * pedalPos(apIdx)';
end

% 处理offset
for gearIdx = 2:height(newUpSpds)
    newUpSpds(gearIdx, :) = newUpSpds(gearIdx, :) + offset * (gearIdx - 1);
end

% 简化起见，降挡速度直接用升挡速度计算
newDownSpds = get_downshift_spds(newUpSpds);

% 构造新换挡规律实例
newSchedule = ShiftSchedule;
newSchedule.UpSpds = newUpSpds;
newSchedule.DownSpds = newDownSpds;
newSchedule.UpAPs = referSchedule.UpAPs;
newSchedule.DownAPs = referSchedule.UpAPs;
newSchedule.Description = "ramp-offset 换挡规律";

end
