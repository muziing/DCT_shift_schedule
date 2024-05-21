function I = get_crowd_distance(fitnessValue)
%GET_CROWD_DISTANCE 求pareto解集中所有个体的拥挤距离
arguments
    fitnessValue (:, 2) {mustBeNumeric} % 适应值，只能处理2维矩阵（双优化目标）
end

[N, M] = size(fitnessValue); %N为解的数量，M为目标个数
I = zeros(1, N); %初始化拥挤距离
Fmax = max(fitnessValue, [], 1); %目标函数最大值
Fmin = min(fitnessValue, [], 1); %目标函数最小值
for i = 1:M
    [~, rank1] = sortrows(fitnessValue(:, i));
    I(rank1(1)) = inf;
    if length(rank1) > 2
        I(rank1(end)) = I(rank1(end)) + (fitnessValue(rank1(end - 1), i) - fitnessValue(rank1(end - 2), i)) / (Fmax(i) - Fmin(i));
    else
        I(rank1(end)) = inf;
    end
    for j = 2:N - 1
        I(rank1(j)) = I(rank1(j)) + (fitnessValue(rank1(j + 1), i) - fitnessValue(rank1(j - 1), i)) / (Fmax(i) - Fmin(i));
    end
end
end
