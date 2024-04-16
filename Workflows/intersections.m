function [x0, y0, iout, jout] = intersections(x1, y1, x2, y2, robust)
%INTERSECTIONS 计算两条曲线的交叉点。
%   计算两条曲线相交的 (x,y) 位置。
%   曲线可以被 NaN 打断，也可以有垂直线段。
%
% 示例：
%   [X0,Y0] = intersections(X1,Y1,X2,Y2,ROBUST);
%
% 其中，X1 和 X2 是包含至少两个点且等长的向量，表示曲线 1。同样的，X2 和 Y2 表示
% 曲线2。返回值中的 X0 和 Y0 则是包含两条曲线交点坐标的列向量。
%
% ROBUST（可选参数）设置为 1 或 true，则表示使用算法的微小变化版本，
% 可能会返回某些交叉点的重复点，然后删除这些重复点。默认值为 true，但由于该算法
% 速度稍慢，如果知道曲线不会在任何线段边界相交，可以将其设置为 false。
% 此外，鲁棒版本还能正确处理平行和重叠的线段。
%
% 算法可以返回两个额外的向量，表示哪些线段对包含交叉点以及交叉点在哪里：
%
%   [X0,Y0,I,J] = intersections(X1,Y1,X2,Y2,ROBUST);
%
% 对于向量 I 的每个元素，I(k) = ((X1,Y1)的线段编号) + (交点位于该线段的多远处)。
% 例如，如果 I(k) = 45.25，则交点位于连接 (X1(45), Y1(45)) 和 (X1(46), Y1(46))
% 的线段之间四分之一处。同样，向量 J 和 (X2,Y2) 中的线段亦是如此。
%
% 你还可以获取一条曲线与自身的交点。只需传入一条曲线，即：
%
%   [X0,Y0] = intersections(X1,Y1,ROBUST);
%
% 像上面一样，其中的 ROBUST 是可选参数。

% -----------版权信息，务必保留-----------
% Version: 2.0, 25 May 2017
% Author:  Douglas M. Schwarz
% Email:   dmschwarz@ieee.org, dmschwarz@urgrad.rochester.edu
% Link:    https://ww2.mathworks.cn/matlabcentral/fileexchange/11837
% --------------------------------------


% 工作原理：
%
% 给定两条线段 L1 与 L2：
%
%   L1 端点:  (x1(1),y1(1)) and (x1(2),y1(2))
%   L2 端点:  (x2(1),y2(1)) and (x2(2),y2(2))
%
% 我们可以用四个未知数写出四个方程，然后求解。四个未知数分别是 t1、t2、x0 和 y0，
% 其中 (x0,y0) 是 L1 和 L2 的交点，t1 是相对于 L1 的长度从 L1 的起点到交点的距离
% ，t2 是相对于 L2 的长度从 L2 的起点到交点的距离。
%
% 所以，这四个方程是
%
%    (x1(2) - x1(1))*t1 = x0 - x1(1)
%    (x2(2) - x2(1))*t2 = x0 - x2(1)
%    (y1(2) - y1(1))*t1 = y0 - y1(1)
%    (y2(2) - y2(1))*t2 = y0 - y2(1)
%
% 重新排列并以矩阵形式书写，
%
%  [x1(2)-x1(1)       0       -1   0;      [t1;      [-x1(1);
%        0       x2(2)-x2(1)  -1   0;   *   t2;   =   -x2(1);
%   y1(2)-y1(1)       0        0  -1;       x0;       -y1(1);
%        0       y2(2)-y2(1)   0  -1]       y0]       -y2(1)]
%
% 将其称之为 A*T = B。可以用 T = A\B 求出 T。
%
% 得到解后，只需查看 t1 和 t2，确定 L1 和 L2 是否相交。
% 如果 0 <= t1 < 1，0 <= t2 < 1，那么两条线段相交，
% 我们就可以在输出中包含 (x0,y0)。
%
% 原则上，我们必须对输入数据中的每一对线段进行计算。线段对的数量可能相当大，
% 因此我们将通过简单的初步检查来消除不可能交叉的线段对，从而减少计算量。
% 检查的方法是查看每对线段的最小包围矩形（边平行于坐标轴），看它们是否重叠。
% 如果重叠，我们就必须（通过 A\B）计算 t1 和 t2 来检查线段是否交叉。如果不重叠，
% 则线段不会交叉。
% 在典型应用场景中，这种技巧可以消除大部分潜在的线段对。


%% 输入检查与预处理
if verLessThan('matlab','7.13')
    error(nargchk(2,5,nargin)) %#ok<NCHKN>
else
    narginchk(2,5)
end

% 根据参数数量进行调整。
switch nargin
    case 2
        robust = true;
        x2 = x1;
        y2 = y1;
        self_intersect = true;
    case 3
        robust = x2;
        x2 = x1;
        y2 = y1;
        self_intersect = true;
    case 4
        robust = true;
        self_intersect = false;
    case 5
        self_intersect = false;
end

% x1 和 y1 必须是点数相同（至少 2 点）的向量。
if sum(size(x1) > 1) ~= 1 || sum(size(y1) > 1) ~= 1 || ...
        length(x1) ~= length(y1)
    error('X1 and Y1 must be equal-length vectors of at least 2 points.')
end

% x2 和 y2 必须是点数相同（至少 2 点）的向量。
if sum(size(x2) > 1) ~= 1 || sum(size(y2) > 1) ~= 1 || ...
        length(x2) ~= length(y2)
    error('X2 and Y2 must be equal-length vectors of at least 2 points.')
end


% 将所有输入强制成列向量。
x1 = x1(:);
y1 = y1(:);
x2 = x2(:);
y2 = y2(:);

% 计算每条曲线上的线段数以及稍后会用到的一些差值。
n1 = length(x1) - 1;
n2 = length(x2) - 1;
xy1 = [x1 y1];
xy2 = [x2 y2];
dxy1 = diff(xy1);
dxy2 = diff(xy2);


%% 确定 i 和 j 的组合
% 其中曲线 1 的第 i 条线段所围成的矩形与曲线 2 的第 j 条线段所围成的矩形重叠。

% 根据每条曲线的线段数选择算法。希望避免在线段数量较多的情况下形成较大的矩阵。
if n1 > 1000 || n2 > 1000
    % 判断哪条曲线的线段最多。
    if n1 >= n2
        % 曲线 1 的线段数更多，在曲线 2 的线段上循环。
        ijc = cell(1,n2);
        min_x1 = mvmin(x1);
        max_x1 = mvmax(x1);
        min_y1 = mvmin(y1);
        max_y1 = mvmax(y1);
        for k = 1:n2
            k1 = k + 1;
            ijc{k} = find( ...
                min_x1 <= max(x2(k),x2(k1)) & max_x1 >= min(x2(k),x2(k1)) & ...
                min_y1 <= max(y2(k),y2(k1)) & max_y1 >= min(y2(k),y2(k1)));
            ijc{k}(:,2) = k;
        end
        ij = vertcat(ijc{:});
        i = ij(:,1);
        j = ij(:,2);
    else
        % 曲线 2 的线段数更多，在曲线 1 的线段上循环。
        ijc = cell(1,n1);
        min_x2 = mvmin(x2);
        max_x2 = mvmax(x2);
        min_y2 = mvmin(y2);
        max_y2 = mvmax(y2);
        for k = 1:n1
            k1 = k + 1;
            ijc{k}(:,2) = find( ...
                min_x2 <= max(x1(k),x1(k1)) & max_x2 >= min(x1(k),x1(k1)) & ...
                min_y2 <= max(y1(k),y1(k1)) & max_y2 >= min(y1(k),y1(k1)));
            ijc{k}(:,1) = k;
        end
        ij = vertcat(ijc{:});
        i = ij(:,1);
        j = ij(:,2);
    end

else
    % 使用隐式展开。
    [i,j] = find( ...
        mvmin(x1) <= mvmax(x2).' & mvmax(x1) >= mvmin(x2).' & ...
        mvmin(y1) <= mvmax(y2).' & mvmax(y1) >= mvmin(y2).');
end


%% 查找至少有一个顶点 = NaN 的线段对，并将其删除。
% 这一行是查找此类线段对的快速方法。利用 NaN 会在计算中传播这一事实，特别是减法（
% 在计算 dxy1 和 dxy2 时，无论如何都需要）和加法。
% 同时，在寻找直线与直线本身的交点时，我们可以删除 i 和 j 的多余组合。
if self_intersect
    remove = isnan(sum(dxy1(i,:) + dxy2(j,:),2)) | j <= i + 1;
else
    remove = isnan(sum(dxy1(i,:) + dxy2(j,:),2));
end
i(remove) = [];
j(remove) = [];

%% 初始化矩阵。
% 将把 T 和 B 放入矩阵，每次使用一列。AA 是 A 的三维扩展，将每次使用一个平面。
n = length(i);
T = zeros(4,n);
AA = zeros(4,4,n);
AA([1 2],3,:) = -1;
AA([3 4],4,:) = -1;
AA([1 3],1,:) = dxy1(i,:).';
AA([2 4],2,:) = dxy2(j,:).';
B = -[x1(i) x2(j) y1(i) y2(j)].';

%% 循环可能项
% 捕捉奇异（singularity）警告，然后使用 Lastwarn 查看 AA 平面是否接近奇异。
% 处理任何这样的线段对，以确定它们是共线（重叠）还是仅仅平行。
% 该测试包括检查曲线 2 线段的一个端点是否位于曲线 1 线段上。通过检查叉积来实现。
%
%   (x1(2),y1(2)) - (x1(1),y1(1)) x (x2(2),y2(2)) - (x1(1),y1(1)).
%
% 如果该值接近于零，则表示线段重叠。

% 如果 robust 选项为 false，我们就假设没有两个线段对是平行的，并直接进行计算。
% 如果 A 是奇异的，则会出现警告。这种方法速度更快，但显然只有在知道不会出现重叠或
% 平行线段对时才能使用。

if robust
    overlap = false(n,1);
    warning_state = warning('off','MATLAB:singularMatrix');

    % 使用 try-catch 保证能够恢复原来的警告状态。
    try
        lastwarn('')
        for k = 1:n
            T(:,k) = AA(:,:,k)\B(:,k);
            [unused,last_warn] = lastwarn; %#ok<ASGLU>
            lastwarn('')
            if strcmp(last_warn,'MATLAB:singularMatrix')
                % 将 in_range(k) 强制为 false
                T(1,k) = NaN;
                % 确定这些线段是否重叠或只是平行。
                overlap(k) = rcond([dxy1(i(k),:);xy2(j(k),:) - xy1(i(k),:)]) < eps;
            end
        end
        warning(warning_state)
    catch err
        warning(warning_state)
        rethrow(err)
    end

    % 找出 t1 和 t2 在 0 和 1 之间的位置，并返回相应的 x0 和 y0 值。
    in_range = (T(1,:) >= 0 & T(2,:) >= 0 & T(1,:) <= 1 & T(2,:) <= 1).';

    % 对于重叠的线段对，算法将返回位于重叠区域中心的交点
    if any(overlap)
        ia = i(overlap);
        ja = j(overlap);
        % 将 x0 和 y0 设为重叠区域的中间位置
        T(3,overlap) = (max(min(x1(ia),x1(ia+1)),min(x2(ja),x2(ja+1))) + ...
            min(max(x1(ia),x1(ia+1)),max(x2(ja),x2(ja+1)))).'/2;
        T(4,overlap) = (max(min(y1(ia),y1(ia+1)),min(y2(ja),y2(ja+1))) + ...
            min(max(y1(ia),y1(ia+1)),max(y2(ja),y2(ja+1)))).'/2;
        selected = in_range | overlap;
    else
        selected = in_range;
    end
    xy0 = T(3:4,selected).';

    % 删除重复的交叉点
    [xy0,index] = unique(xy0,'rows');
    x0 = xy0(:,1);
    y0 = xy0(:,2);

    % 计算每条线段的交点距离
    if nargout > 2
        sel_index = find(selected);
        sel = sel_index(index);
        iout = i(sel) + T(1,sel).';
        jout = j(sel) + T(2,sel).';
    end

else
    % 非 robust 情况
    for k = 1:n
        [L,U] = lu(AA(:,:,k));
        T(:,k) = U\(L\B(:,k));
    end

    % 找出 t1 和 t2 在 0 和 1 之间的位置，并返回相应的 x0 和 y0 值。
    in_range = (T(1,:) >= 0 & T(2,:) >= 0 & T(1,:) < 1 & T(2,:) < 1).';
    x0 = T(3,in_range).';
    y0 = T(4,in_range).';

    % 计算每条线段的交点距离。
    if nargout > 2
        iout = i(in_range) + T(1,in_range).';
        jout = j(in_range) + T(2,in_range).';
    end
end

%% 绘制结果（调试时建议取消注释来启用这个功能）
% plot(x1,y1,x2,y2,x0,y0,'ok');

function y = mvmin(x)
% 当 k = 1 时，movmin(x,k) 的执行速度更快。
y = min(x(1:end-1),x(2:end));

function y = mvmax(x)
% 当 k = 1 时，movmax(x,k) 的执行速度更快。
y = max(x(1:end-1),x(2:end));
