# ==============================================================================
#   trap_spike.gd
#   功能：尖刺陷阱。即时伤害，无附加状态效果。
# ==============================================================================
extends TrapBase
class_name TrapSpike

func _ready() -> void:
	super._ready()
	base_damage = 5
	trigger_cooldown = 1.0
