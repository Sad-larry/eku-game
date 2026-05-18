# ==============================================================================
#   room_enemy_tracker.gd
#   功能：追踪房间内存活敌人，当所有敌人死亡时发射清场信号。
# ==============================================================================
extends Node
class_name RoomEnemyTracker

# ========================== 信号模块 ==========================
## 所有敌人被击败时触发
signal all_enemies_defeated

# ========================== 内部变量模块 ==========================
## 房间坐标
var _room_coord: Vector2i
## 存活敌人列表
var _alive_enemies: Array[Enemy] = []

# ========================== 公共 API 模块 ==========================
## 功能：初始化追踪器
## 参数：coord (Vector2i) - 房间坐标；enemies (Array[Enemy]) - 初始敌人列表
func setup(coord: Vector2i, enemies: Array[Enemy]) -> void:
	_room_coord = coord
	_alive_enemies = enemies.duplicate()
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.health_component:
			enemy.health_component.unit_died.connect(_on_enemy_died.bind(enemy))

## 功能：添加敌人到追踪列表
## 参数：enemy (Enemy) - 要追踪的敌人
func track_enemy(enemy: Enemy) -> void:
	if not _alive_enemies.has(enemy):
		_alive_enemies.append(enemy)
		if is_instance_valid(enemy) and enemy.health_component:
			enemy.health_component.unit_died.connect(_on_enemy_died.bind(enemy))

## 功能：获取当前存活敌人数量
func get_alive_count() -> int:
	return _alive_enemies.size()

# ========================== 信号回调模块 ==========================
## 功能：敌人死亡时的回调
func _on_enemy_died(enemy: Enemy) -> void:
	_alive_enemies.erase(enemy)
	if _alive_enemies.is_empty():
		all_enemies_defeated.emit()
