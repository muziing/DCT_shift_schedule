function result = get_consec_below_thold(data, threshold)
    % 查找一维向量的值自何项之后都小于给定阈值
    % 若找到则返回索引，否则返回 NaN

    if isempty(data)
        error("Input data is empty.")
    end

    if ~isvector(data) || ~isscalar(threshold)
        error("Input data must be a vector and threshold must be a scalar.");
    end

    result = NaN;

    % 获取所有小于阈值项的索引
    below_threshold_indices = find(data < threshold);

    % 如果没有元素小于阈值，直接返回
    if isempty(below_threshold_indices)
        return
    end

    while ~isempty(below_threshold_indices)

        % 找到第一个满足条件的索引
        first_below_threshold_index = min(below_threshold_indices);

        if all(data(first_below_threshold_index + 1:end) < threshold)
            % 如果从首个小于阈值的索引到末尾的所有元素都满足条件，则返回该索引
            result = first_below_threshold_index;
            return
        else
            % 否则从候选索引中删除该项，重新寻找
            below_threshold_indices = below_threshold_indices(...
                below_threshold_indices > first_below_threshold_index);
        end

    end

end
