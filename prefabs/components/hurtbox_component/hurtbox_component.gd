extends Area2D
class_name HurtboxComponent

# 受到伤害时发出信号（携带攻击盒数据）
signal on_damaged(hitbox: HitboxComponent)

# 当进入其他区域时触发
func _on_area_entered(area: Area2D) -> void:
	# 判断碰到的是否是攻击盒
	if area is HitboxComponent:
		# 发送受伤信号
		on_damaged.emit(area)
