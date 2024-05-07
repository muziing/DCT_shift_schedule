function downShiftSpds = get_downshift_spds(upShiftSpds, delaySpeed, delaySpeedFactor)
%GET_DOWNSHIFT_SPDS 由升挡点数组计算降挡点数组
%   upShiftSpds: 升挡点数组，各行代表不同的踏板开度、各列代表不同的挡位
%   delaySpeed: 换挡延迟，(km/h)，一般取 2~8
%   delaySpeedFactor: 换挡延迟系数，决定换挡线类型

% 降挡点由对应升挡点减去【换挡延迟】而来，换挡延迟一般取 2~8 km/h；
% 换挡延迟系数：
%   1 表示【等延迟型】，各AP开度下换挡延迟相同；
%   0~1 表示【收敛型】，换挡延迟随AP开度增大而减小；
%   >1 表示【发散型】，换挡延迟随AP开度的增大而增大
arguments
    upShiftSpds {mustBeNumeric} % 升挡点数组
    delaySpeed (1, 1) {mustBeNumeric, mustBePositive} = 5 % 换挡延迟
    delaySpeedFactor (1, 1) {mustBeNumeric, mustBePositive} = 1 % 换挡延迟系数
end

delaySpeeds = delaySpeed * (delaySpeedFactor .^ (1:width(upShiftSpds)));
downShiftSpds = upShiftSpds - delaySpeeds;
end

