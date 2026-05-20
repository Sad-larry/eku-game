# ==============================================================================
#   heal_allies_behavior.gd
#   功能：治疗友军行为。定期治疗范围内的友方单位。
# ==============================================================================
class_name HealAlliesBehavior extends TriggerableBehavior

@export var heal_radius: float = 150.0
@export var heal_amount: int = 5

func _execute_behavior() -> void:
	if enemy == null or enemy.get_tree() == null:
		return

	var all_enemies := enemy.get_tree().get_nodes_in_group("enemy")
	for node in all_enemies:
		if node == enemy:
			continue
		if node is Enemy and node.global_position.distance_to(enemy.global_position) <= heal_radius:
			if node.health_component and node.health_component.current_health > 0:
				node.health_component.heal(heal_amount)
