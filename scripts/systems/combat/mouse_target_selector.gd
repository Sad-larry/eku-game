# ==============================================================================
#   mouse_target_selector.gd
#   功能：鼠标目标选择器，根据鼠标位置在指定半径内查找最近的敌人。
#        用于对敌 debuff 类技能的鼠标位置判定。
# ==============================================================================
extends RefCounted
class_name MouseTargetSelector

## 功能：查找鼠标位置附近的所有敌人
## 参数：mouse_pos (Vector2) - 鼠标世界坐标；radius (float) - 搜索半径（像素）
## 返回值：Array[Enemy] - 范围内的敌人列表（按距离排序）
static func find_enemies_near_mouse(mouse_pos: Vector2, radius: float = 100.0) -> Array:
	var result: Array = []
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return result

	for node in tree.get_nodes_in_group("enemy"):
		if node is Enemy and is_instance_valid(node):
			var dist := node.global_position.distance_to(mouse_pos)
			if dist <= radius:
				result.append(node)

	# 按距离排序（最近的在前）
	result.sort_custom(func(a, b): return a.global_position.distance_to(mouse_pos) < b.global_position.distance_to(mouse_pos))
	return result

## 功能：查找鼠标位置最近的单个敌人
## 参数：mouse_pos (Vector2) - 鼠标世界坐标；radius (float) - 搜索半径（像素）
## 返回值：Enemy 或 null
static func find_nearest_enemy(mouse_pos: Vector2, radius: float = 100.0) -> Enemy:
	var enemies := find_enemies_near_mouse(mouse_pos, radius)
	return enemies[0] if enemies.size() > 0 else null
