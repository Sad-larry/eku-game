# ==============================================================================
#   trap_stun.gd
#   功能：闪电陷阱。造成少量伤害并附加眩晕效果。
# ==============================================================================
extends TrapBase
class_name TrapStun

func _ready() -> void:
	super._ready()
	base_damage = 1
	trigger_cooldown = 3.0
