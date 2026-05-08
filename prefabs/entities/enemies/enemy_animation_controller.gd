# ==============================================================================
#   EnemyAnimationController.gd
#   功能：敌人动画控制器（当前为占位实现），负责将状态机状态名称映射为具体动画名称
#        并控制 Sprite2D 播放对应动画。待后续根据实际动画资源完善映射逻辑。
# ==============================================================================
extends Node
class_name EnemyAnimationController

# ========================== 信号声明模块 ==========================
## 触发时机：动画播放完成时触发（用于状态机感知动画结束）
## 参数：state_name (String) - 动画对应的状态名称（如 "dead"、"attack"）
signal anim_finished(state_name: String)

# ========================== 节点引用模块 ==========================
@onready var anim_player: AnimationPlayer = %AnimationPlayer
## 敌人精灵引用
@onready var sprite: Sprite2D = %Sprite2D

# ========================== 常量定义模块 ==========================
## 翻转朝向的速度阈值，低于此值不翻转（防止受击时微抖动）
const FLIP_THRESHOLD: float = 5.0

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时获取动画播放控制器并连接动画完成信号
func _ready() -> void:
	anim_player.animation_finished.connect(_on_anim_finished)

# ========================== 公共 API 模块 ==========================
## 功能：根据状态名称播放对应动画
## 参数：_state_name (String) - 状态机状态名称（如 "idle"、"move"、"attack" 等）
func play_state(state_name: String) -> void:
	if anim_player.has_animation(state_name):
		anim_player.play(state_name)

## 功能：根据水平速度方向翻转精灵朝向
## 参数：velocity_x (float) - 当前水平速度（正数朝右，负数朝左）
func update_flip(velocity_x: float) -> void:
	if absf(velocity_x) < FLIP_THRESHOLD:
		return  # 速度太小时保持当前朝向，防止抖动
	if velocity_x < 0:
		sprite.scale.x = absf(sprite.scale.x) * -1.0
	else:
		sprite.scale.x = absf(sprite.scale.x)
		
# ========================== 信号回调模块 ==========================
## 功能：动画完成时的回调（解析动画名称并发射 anim_finished 信号）
## 参数：anim_name (StringName) - 完成的动画名称
func _on_anim_finished(anim_name: StringName) -> void:
	anim_finished.emit(anim_name)
