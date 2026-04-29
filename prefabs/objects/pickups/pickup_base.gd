# ==============================================================================
#   PickupBase.gd
#   功能：拾取物基类，提供金币、生命球、能量球三种拾取类型的通用逻辑，
#        包括进入玩家区域触发效果、自动生命周期消逝、淡出销毁动画。
# ==============================================================================
extends Area2D
class_name PickupBase

# ========================== 枚举定义模块 ==========================
## 拾取物类型枚举
enum PickupType {
	COIN,         ## 金币（增加货币数量）
	HEALTH_ORB,   ## 生命回复球（恢复生命值）
	ENERGY_ORB    ## 能量回复球（恢复能量值）
}

# ========================== 导出变量模块 ==========================
## 拾取物类型（决定触碰后的效果）
@export var pickup_type: PickupType = PickupType.COIN

## 拾取物数值（金币数量 / 回复量）
@export var value: float = 1.0

## 向玩家移动的速度（像素/秒）
@export var move_speed: float = 60.0

## 自动消失时间（秒），超时后淡出销毁
@export var lifetime: float = 10.0

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时连接碰撞信号并启动生命周期倒计时
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# 设置自动销毁定时器
	var timer: SceneTreeTimer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_timeout)

# ========================== 信号回调模块 ==========================
## 功能：当玩家进入拾取范围时触发效果
## 参数：body (Node2D) - 进入区域的实体（需为玩家）
## 说明：根据拾取物类型触发对应的全局事件或组件方法，并销毁自身
func _on_body_entered(body: Node2D) -> void:
	# 仅玩家可以拾取
	if not body.is_in_group("player"):
		return
	
	match pickup_type:
		PickupType.COIN:
			# 发送金币收集信号
			EventBus.coin_collected.emit(value)
		PickupType.HEALTH_ORB:
			# TODO: 实现生命值恢复逻辑（需从玩家获取 HealthComponent 并调用 heal）
			# var health: HealthComponent = HealthComponent.find_from(body)
			# if health:
			#     health.heal(value)
			pass
		PickupType.ENERGY_ORB:
			# TODO: 实现能量值恢复逻辑（需从玩家获取 EnergyComponent 并调用 restore）
			# var energy: EnergyComponent = EnergyComponent.find_from(body)
			# if energy:
			#     energy.restore(value)
			pass
	
	# 拾取后销毁自身
	queue_free()

## 功能：生命周期超时回调，执行淡出动画后销毁
func _on_timeout() -> void:
	# 淡出动画（透明度 1 → 0，耗时 0.5 秒）
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
