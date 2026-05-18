# ==============================================================================
#   trap_poison.gd
#   功能：毒雾陷阱。造成即时伤害并附加 DOT 持续伤害效果。
# ==============================================================================
extends TrapBase
class_name TrapPoison

func _ready() -> void:
	super._ready()
	base_damage = 2
	trigger_cooldown = 2.0
