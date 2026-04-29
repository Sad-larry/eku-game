# ==============================================================================
#   IsometricCamera.gd
#   功能：等距视角摄像机控制器，提供等距坐标系与屏幕坐标之间的相互转换，
#        并自动跟随 Global.player 玩家对象移动。
# ==============================================================================
extends Camera2D
class_name IsometricCamera

# ========================== 常量定义模块 ==========================
## 等距变换矩阵：将世界坐标映射到屏幕坐标
## 标准 2:1 等距投影（俯角约 26.565°）
## 公式：屏幕坐标 = 世界坐标 × ISO_MATRIX
## 说明：
##   - X 轴方向（Vector2(1.0, 0.5)）：世界坐标 X 增加时，屏幕坐标向右下移动
##   - Y 轴方向（Vector2(-1.0, 0.5)）：世界坐标 Y 增加时，屏幕坐标向左下移动
const ISO_MATRIX: Transform2D = Transform2D(
	Vector2(1.0, 0.5),   # X 轴映射：世界右 = 屏幕右 + 0.5 个单位向下
	Vector2(-1.0, 0.5),  # Y 轴映射：世界下 = 屏幕左 + 0.5 个单位向下
	Vector2.ZERO         # 原点偏移（无偏移）
)

## 反向变换矩阵：将屏幕坐标映射回等距世界坐标
## 公式：世界坐标 = 屏幕坐标 × ISO_INVERSE
const ISO_INVERSE: Transform2D = Transform2D(
	Vector2(0.5, -0.5),  # X 轴逆映射
	Vector2(0.5, 0.5),   # Y 轴逆映射
	Vector2.ZERO          # 原点偏移
)

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化摄像机参数并添加到指定组
func _ready() -> void:
	# 固定俯角，不旋转摄像机
	rotation_degrees = 0
	# 开启位置平滑跟随（减少抖动）
	position_smoothing_enabled = true
	# 添加到等距摄像机组，供其他系统识别
	add_to_group("isometric_camera")

## 功能：每帧更新摄像机位置，跟随玩家
## 参数：_delta (float) - 帧间隔时间（未直接使用）
func _process(_delta: float) -> void:
	# 玩家存在时，让摄像机位置实时跟随玩家
	if is_instance_valid(Global.player):
		global_position = Global.player.global_position

# ========================== 公共静态方法模块（坐标转换）==========================
## 功能：将等距世界坐标转换为屏幕坐标
## 参数：world_pos (Vector2) - 等距世界坐标
## 返回值：Vector2 - 屏幕坐标（像素单位，受摄像机缩放影响前）
static func world_to_screen(world_pos: Vector2) -> Vector2:
	return ISO_MATRIX * world_pos

## 功能：将屏幕坐标转换为等距世界坐标
## 参数：screen_pos (Vector2) - 屏幕坐标
## 返回值：Vector2 - 等距世界坐标
static func screen_to_world(screen_pos: Vector2) -> Vector2:
	return ISO_INVERSE * screen_pos
