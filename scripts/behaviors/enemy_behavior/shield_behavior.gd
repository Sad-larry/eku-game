# ==============================================================================
#   shield_behavior.gd
#   功能：护盾行为。为敌人提供额外的护盾生命值。
# ==============================================================================
class_name ShieldBehavior extends EnemyBehavior

@export var shield_hp: int = 20
@export var shield_regen_time: float = 15.0

var _current_shield: int = 0
var _regen_timer: float = 0.0

func _on_setup() -> void:
	_current_shield = shield_hp

func _on_update(delta: float) -> void:
	if _current_shield <= 0 and shield_regen_time > 0:
		_regen_timer -= delta
		if _regen_timer <= 0.0:
			_current_shield = shield_hp
			_regen_timer = shield_regen_time

## 功能：吸收伤害，返回实际穿透的伤害
func absorb_damage(incoming: int) -> int:
	if _current_shield <= 0:
		return incoming
	if incoming >= _current_shield:
		var overflow := incoming - _current_shield
		_current_shield = 0
		_regen_timer = shield_regen_time
		return overflow
	_current_shield -= incoming
	return 0

func has_shield() -> bool:
	return _current_shield > 0
