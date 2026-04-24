extends Area2D
class_name  HitboxComponent

# 击中受伤盒时发出信号（携带受伤盒对象）
signal on_hit_hurtbox(hurtbox: HurtboxComponent)

var damage := 1.0          # 基础伤害值
var critical := false      # 是否暴击
var source: Node2D         # 伤害来源（攻击者：玩家/敌人）

# 启用攻击盒（开启检测）
func enable() -> void:
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

# 禁用攻击盒（关闭检测）
func disable() -> void:
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

# 统一配置伤害数据（攻击时调用）
func setup(damage_args: float, critical_args: bool, source_args: Node2D) -> void:
	self.damage = damage_args
	self.critical = critical_args
	self.source = source_args

			
# 当进入其他区域时触发
func _on_area_entered(area: Area2D) -> void:
	# 判断碰到的是否是受伤盒
	if area is HurtboxComponent:
		# 发送击中信号
		on_hit_hurtbox.emit(area)
		
