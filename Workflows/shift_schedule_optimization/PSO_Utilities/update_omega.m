function omega = update_omega(iter, iterMax, omegaMin, omegaMax)
%UPDATE_OMEGA 更新惯性权重ω
%   线性变化策略：随着迭代次数的增加，惯性权重不断减小，从而使得粒子群算法在初期
%   具有较强的全局收敛能力，在后期具有较强的局部收敛能力。
arguments
    iter (1, 1) {mustBeNumeric} % 当前迭代次数
    iterMax (1, 1) {mustBeNumeric} % 最大迭代次数
    omegaMin (1, 1) {mustBeNumeric} = 0.9 % 最小惯性权重
    omegaMax (1, 1) {mustBeNumeric} = 1.8 % 最大惯性权重
end

omega = omegaMax - (omegaMax - omegaMin) * iter / iterMax;
end
