# ==============================================================================
#   trap_slow.gd
#   功能：荆棘陷阱。造成少量伤害并附加减速效果。
# ==============================================================================
extends TrapBase
class_name TrapSlow

func _ready() -> void:
	super._ready()
	base_damage = 1
	trigger_cooldown = 1.5
