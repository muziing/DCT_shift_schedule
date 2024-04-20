% 基于汽车行驶方程式的简单静态分析计算

clear
clc

%% 车辆数据

% 整车外廓
VehicleData.Wheelbase = 4.390; % 轴距，(m)
VehicleData.TrackwidthF = 1.918; % 前轴轮距，(m)
VehicleData.TrackwidthR = 1.958; % 后轴轮距，(m)
VehicleData.FrontalArea = 4.64; % 迎风面积，(m²)
VehicleData.Cd = 0.372; % 风阻系数

% 空载
VehicleData.NoLoad.Mass = 4617; % 空载质量，(kg)
VehicleData.NoLoad.a = 2.667; % 空载时质心到前轴距离，(m)
VehicleData.NoLoad.b = VehicleData.Wheelbase - ...
    VehicleData.NoLoad.a; % 空载时质心到后轴距离，(m)
VehicleData.NoLoad.hg = 0.895; % 空载时质心高度，(m)

% 满载
VehicleData.Full.Mass = 6342; % 满载质量，(kg)
VehicleData.Full.a = 2.357; % 满载时质心到前轴距离，(m)
VehicleData.Full.b = VehicleData.Wheelbase - ...
    VehicleData.Full.a; % 满载时质心到后轴距离，(m)
VehicleData.Full.hg = 0.910; % 满载时质心高度，(m)

% 车轮
Wheel.LoadedRadius = 0.357; % 负载半径，(m)
Wheel.UnloadedRadius = 0.370; % 无负载半径，(m)
Wheel.Inertia = 0.8; % 转动惯量，(kg*m²)
Wheel.Pressure = 98 * 6894.75729; % 胎压，(Pa)
% 车轮魔术公式（附着良好路面）
Wheel.Dx = 1;
Wheel.Cx = 1.65;
Wheel.Bx = 10;
Wheel.Ex = 0.01;

% 传动系
Driveline.i0 = 37/7; % 主减速器传动比
Driveline.ig = [55/16, 53/25, 53/38, 46/45] * 65/43; % 变速器各挡位传动比
Driveline.EffEta = 0.88; % 总传动效率
Driveline.Str = ["1挡", "2挡", "3挡", "4挡"];

% 电机外特性
load("../Data/MotorData.mat")
MotorSpds = MotorData.ExternalCharacteristics.Peak.rpm'; % 电机转速
MotorTrqs = MotorData.ExternalCharacteristics.Peak.torque'; % 电机转矩

% 环境
g = 9.81; % 重力加速度，(m/s²)
RoadSlope = 0; % 道路坡度，(deg)

% 静态轴荷
% $F_{Zs1} =G (\frac{b}{L} \cos\alpha - \frac{h_g}{L} \sin\alpha)$
% $F_{Zs2} =G (\frac{a}{L} \cos\alpha - \frac{h_g}{L} \sin\alpha)$
G = VehicleData.NoLoad.Mass * g; % 整车重力
W_front = G * ...
    (VehicleData.NoLoad.b / VehicleData.Wheelbase * cos(RoadSlope) - ...
    VehicleData.NoLoad.hg / VehicleData.Wheelbase * sin(RoadSlope));
W_rear = G * ...
    (VehicleData.NoLoad.a / VehicleData.Wheelbase * cos(RoadSlope) + ...
    VehicleData.NoLoad.hg / VehicleData.Wheelbase * sin(RoadSlope));

%% 驱动力

% $F_t = \frac{T_{tq} i_g i_0 \eta_T}{r}$

F_t = (MotorTrqs' .* Driveline.ig .* Driveline.i0 .* Driveline.EffEta) ...
    ./ Wheel.LoadedRadius; % 驱动力数组（二维）
u_a = 0.377 * (Wheel.UnloadedRadius * MotorSpds') ./ ...
    (Driveline.ig .* Driveline.i0); % 车速数组（二维）
u_a_1d = sort(u_a(:)); % 将二维数组 u_a 转成有序的一维数组，便于后续使用

%% 滚动阻力

% 车轮滚动时，轮胎与路面的接触区域产生法向、切向的相互作用力以及相应的轮胎和支承
% 路面的变形。当弹性轮胎在硬路面上滚动时，由于轮胎有内部摩擦产生的弹性迟滞损失，
% 使轮胎变形时对它做的功不能全部回收。迟滞损失表现为阻碍车轮滚动的一种阻力偶

% $F_f = W f$

% 滚动阻力系数估算（经验公式）
rollingResistance_f = 0.0076 + 0.000056 * u_a;

F_f = W_front * rollingResistance_f + W_rear * rollingResistance_f;

% 另一种滚动阻力估算经验公式：SAE J2542 胎压与车速经验公式
% $F = (\frac{P}{P_0})^\alpha (\frac{N}{N_0})^\beta N_0 \cdot
% (A + B |v_{hub}| + C {v_{hub}}^2)$

%% 空气阻力

% 汽车直线行驶时受到的空气作用力在行驶方向上的分力称为空气阻力
% 一般公式：$F_w = 1/2 C_D A \rho u_r^2$
% 无风条件、u_a单位km/h、A单位m^2：$F_w = \frac{C_D A u_a^2}{21.15}$

F_w = VehicleData.Cd * VehicleData.FrontalArea * (u_a .^ 2) / 21.15;

%% 坡度阻力

% 当汽车上坡行驶时，汽车重力沿坡道的分力表现为汽车坡度阻力
% $F_i = G \sin(\alpha)$

F_i = VehicleData.NoLoad.Mass * g * sin(RoadSlope);

%% 加速阻力

% 汽车加速行驶时，需要克服其质量加速运动时的惯性力，就是加速阻力 F_j
% $F_j = \delta m \frac{\mathrm{d}u}{\mathrm{d}t}$

% 其中，δ为汽车旋转质量换算系数，实现将旋转质量（如车轮）的惯性力偶转化为
% 平移质量的惯性力，便于计算

delta = [1.29, 1.14, 1.07, 1.05]; % 旋转质量换算系数δ，由查表得到估计值
% F_j = delta * VehicleData.NoLoad.Mass * acceleration;

%% 绘图：驱动力-行驶阻力平衡图

figure('Name', "驱动力-行驶阻力平衡图")

hold on

plot(u_a, F_t)
plot(u_a_1d, sort(F_f(:) + F_w(:)), 'DisplayName', "F_f + F_w")

% 求驱动力曲线与行驶阻力曲线交点坐标，并绘制在图上
[maxSpd, maxSpd_F] = intersections(u_a(end, :), ...
    F_t(end, :), sort(u_a(:)), sort(F_f(:) + F_w(:)), false);
scatter(maxSpd, maxSpd_F, 'DisplayName', "{u_a}_{max}")

title("驱动力-行驶阻力平衡图")
xlabel("u_a / (km/h)")
ylabel("F_t / N")
xlim tight
legend([Driveline.Str, "F_f + F_w", "{u_a}_{max}"], ...
    'Location', 'northeast')
hold off

%% 绘图：行驶加速度曲线

% 由汽车行驶方程式得：
% $\frac{\mathrm{d}u}{\mathrm{d}t} =
% \frac{1}{\delta m} [F_t - (F_f + F_w + F_i)]$

accelerations = (F_t - (F_f + F_w + F_i)) ./ ...
    (delta * VehicleData.NoLoad.Mass);
accelerations(accelerations < 0) = NaN; % 舍弃计算出的负值加速度

figure('Name', "行驶加速度曲线图")
hold on

plot(u_a, accelerations)

% 遍历求解所有换挡点速度
% 换挡点求解详情见 <static_shift_lines.m>
% gear_spd = zeros(length(Driveline.ig) - 1, 1);
% gear_acc = zeros(length(Driveline.ig) - 1, 1);
% for gearIdx = 1:(length(Driveline.ig) - 1)
%     [gear_spd(gearIdx), gear_acc(gearIdx)] = intersections(u_a(:, gearIdx), ...
%         acceleration(:, gearIdx), u_a(:, gearIdx + 1), ...
%         acceleration(:, gearIdx + 1), false);
% end
%
% scatter(gear_spd, gear_acc)

title("行驶加速度曲线")
xlabel("u_a / (km/h)")
ylabel("a / (m/s^2)")
legend(Driveline.Str, 'Location', 'northeast')

hold off
