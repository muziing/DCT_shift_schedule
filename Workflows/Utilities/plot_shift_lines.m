function plot_shift_lines(shiftSchedule)
%PLOT_SHIFT_LINES 绘制换挡线
%   根据给定换挡规律，绘制换挡线
arguments
    shiftSchedule (1, 1) ShiftSchedule % 换挡规律
end

figure('Name', shiftSchedule.Description)
hold on

% 一组较为美观的预设颜色
colors = [0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980; ...
              0.9290, 0.6940, 0.1250; 0.4940, 0.1840, 0.5560; ...
              0.4660, 0.6740, 0.1880; 0.3010, 0.7450, 0.9330; ...
              0.6350, 0.0780, 0.1840];

if height(shiftSchedule.UpSpds) > height(colors)
    error("预设颜色数不足，无法绘图")
end

for gearIdx = 1:height(shiftSchedule.UpSpds)
    plot(shiftSchedule.UpSpds(gearIdx, :), shiftSchedule.UpAPs, 'Color', ...
        colors(gearIdx, :), 'DisplayName', ...
        sprintf("%d-%d升挡线", gearIdx, gearIdx + 1))
    plot(shiftSchedule.DownSpds(gearIdx, :), shiftSchedule.DownAPs, '--', ...
        'Color', colors(gearIdx, :), 'DisplayName', ...
        sprintf("%d-%d降挡线", gearIdx + 1, gearIdx))
end

grid on
title(shiftSchedule.Description)
xlabel("车速 / (km/h)")
ylabel("加速踏板开度 / (%)")
legend('Location', 'best')
hold off

end
