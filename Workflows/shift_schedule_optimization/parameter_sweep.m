% 参数扫描脚本
% 通过二维（ramp、offset）参数扫描，获取换挡规律变化过程中经济性动力性变化情况
% 通过参数扫描，可以大致估计最优经济性/动力性换挡规律区间，为优化算法提供初始条件，
% 加快优化迭代收敛速度。

%% 配置

load("ShiftSchedulesData.mat")
refShiftSchedule = shiftSchedule_test_min;
rampArray = -1:1:8;
offsetArray = -2:2:22;

taskCount = length(rampArray) * length(offsetArray);
scheduleArray = ShiftSchedule.empty(taskCount, 0);
idx = 1;
for rampIdx = 1:length(rampArray)
    for offsetIdx = 1:length(offsetArray)
        scheduleArray(idx) = get_ramp_offset_schedule( ...
            refShiftSchedule, rampArray(rampIdx), offsetArray(offsetIdx));
        idx = idx + 1;
    end
end

%% 评估经济性

ecoScores = evaluate_economy(scheduleArray, true, false);
economyScores = reshape(ecoScores, length(offsetArray), length(rampArray));

%% 评估动力性

dyaScores = evaluate_dynamic(scheduleArray, true, false);
dynamicScores = reshape(dyaScores, length(offsetArray), length(rampArray));

%% 结果可视化绘图

figure('Name', "参数扫描-经济性评估")
surf(rampArray, offsetArray, economyScores)
title("参数扫描-经济性评估")
xlabel("Ramp")
ylabel("Offset")
zlabel("Economy Score")

figure('Name', "参数扫描-动力性评估")
surf(rampArray, offsetArray, dynamicScores)
title("参数扫描-动力性评估")
xlabel("Ramp")
ylabel("Offset")
zlabel("Dynamic Score")

%% 清理收尾

clear taskCount idx scheduleArray rampIdx  offsetIdx 
clear ecoScores dyaScores
