% 模型数据
% 由于尚处模型早期开发阶段，大量模型中的参数仍需调试修改，暂通过m脚本方式
% 保存数据；后续考虑将数据从基础工作区移动至模型工作区中。

%% 电池与电机子系统

BatteryData.ChrgMax = -50000;  % 电池最大充电功率，(W)
BatteryData.DischrgMax = 50000;  % 电池最大放电功率，(W)

%% 传动系子系统

% 轴连接器
axle_k = 5000;  % 扭转刚度，(N*m/rad)
axle_b = 10;  % 扭转阻尼，(N*m*s/rad)
bevAxle_wc = 300;  % 阻尼截止频率，(rad/s)

% 开放式差速器
OpenDifferential.TransRatio = 37/7;  % 主减速器传动比
OpenDifferential.Efficiency = 0.98;  % 传动效率因数（常量固定值）
OpenDifferential.CarrierInertia = 0.025;  % 输入轴转动惯量，(kg*m²)
OpenDifferential.CarrierDamping = 1e-3;  % 输入轴阻尼，(N*m*s/rad)
OpenDifferential.AxleInertia = 0.01;  % 输出轴转动惯量，(kg*m²)
OpenDifferential.AxleDamping = 1e-3;  % 输出轴阻尼，(N*m*s/rad)

%% 车轮车身子系统

% -----------------整车------------------------

VehicleData.Wheelbase = 4.390;  % 轴距，(m)
VehicleData.TrackwidthF = 1.918;  % 前轴轮距，(m)
VehicleData.TrackwidthR = 1.958;  % 后轴轮距，(m)
VehicleData.FrontalArea = 4.64;  % 迎风面积，(m²)
VehicleData.Cd = 0.372;  % 风阻系数

% 空载
VehicleData.Mass.NoLoad.Mass = 4617;  % 空载质量，(kg)
VehicleData.Mass.NoLoad.a = 2.667;  % 空载时质心到前轴距离，(m)
VehicleData.Mass.NoLoad.b = VehicleData.Wheelbase - ...
    VehicleData.Mass.NoLoad.a;  % 空载时质心到后轴距离，(m)
VehicleData.Mass.NoLoad.hg = 0.895;  % 空载时质心高度，(m)
VehicleData.Mass.NoLoad.Iyy = 3500;  % *空载绕y轴转动惯量，(kg*m²)

% 满载
VehicleData.Mass.Full.Mass = 6342;  % 满载质量，(kg)
VehicleData.Mass.Full.a = 2.357;  % 满载时质心到前轴距离，(m)
VehicleData.Mass.Full.b = VehicleData.Wheelbase - ...
    VehicleData.Mass.Full.a;  % 满载时质心到后轴距离，(m)
VehicleData.Mass.Full.hg = 0.910;  % 满载时质心高度，(m)
VehicleData.Mass.Full.Iyy = 3500;  % *满载绕y轴转动惯量，(kg*m²)

% -----------------车轮------------------------

VehicleData.Wheel.LoadedRadius = 0.357;  % 负载半径，(m)
VehicleData.Wheel.UnloadedRadius = 0.370;  % 无负载半径，(m)
VehicleData.Wheel.RelaxationLength = 0.5;  % *松弛长度，(m)
VehicleData.Wheel.AxleViscousDampingCoefficient = 0.001;  % *轴粘滞阻尼系数，(N*m*s/rad)
VehicleData.Wheel.Inertia = 0.8;  % *转动惯量，(kg*m²)
VehicleData.Wheel.Pressure = 98 * 6894.75729;  % 胎压，(Pa)
% *魔术公式（附着良好路面）
VehicleData.Wheel.Dx = 1;
VehicleData.Wheel.Cx = 1.65;
VehicleData.Wheel.Bx = 10;
VehicleData.Wheel.Ex = 0.01;

% -----------------制动器------------------------

%% 环境

EnvironmentData.AirTemp = 273.15 + 20;  % 环境温度，(k)
EnvironmentData.GravitationalAcceleration = 9.81;  % 重力加速度，(m/s²)

%% 写入模型工作区

% mdlWrkSps = get_param("Dual_Clutch_Trans", 'modelworkspace');