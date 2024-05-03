function result = get_consec_below_thold(data, threshold)
%GET_CONSEC_BELOW_THOLD  查找一维向量的值自何项之后都小于给定阈值
%   若找到则返回索引，否则返回 NaN

arguments
    data (1, :) {mustBeNumeric} % 待查找向量
    threshold (1, 1) {mustBeNumeric} % 阈值
end

if isempty(data)
    warning("Input data is empty.")
end

% 初始化结果为NaN
result = NaN;

% 获取所有小于阈值项的索引
below_threshold_indices = find(data < threshold);

% 如果没有元素小于阈值，直接返回
if isempty(below_threshold_indices)
    return
end

for idx = below_threshold_indices
    % 如果从当前索引到末尾的所有元素都小于阈值，则返回该索引
    if all(data(idx + 1:end) < threshold)
        result = idx;
        return
    end
end

% 如果没有找到符合条件的索引，则维持原结果NaN不变
end
