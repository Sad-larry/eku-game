# ==============================================================================
#   room_event_spawner.gd
#   功能：根据单元格的事件类型在房间内生成内容（敌人、道具、NPC 等）
#         支持预制体映射、默认敌人池、出生点标记等机制
# ==============================================================================
extends Node
class_name RoomEventSpawner

# ========================== 导出变量模块 ==========================
## 每种事件类型的预制体映射
## 键：事件类型字符串，值：对应的 PackedScene 资源
@export var event_scenes: Dictionary = {
	"battle": null,
	"elite": null,
	"boss": null,
	"merchant": null,
	"treasure": null,
	"rest": null,
}

## 战斗事件通用敌人波次配置（无独立预制体时备用）
@export var default_enemy_pool: Array[PackedScene]

# ========================== 公共 API 模块 ==========================
## 功能：根据 CellData 为指定房间生成内容
## 参数：room (ChunkRoom) - 目标房间实例；cell (CellData) - 单元格数据（包含事件类型）
func spawn_for_room(room: ChunkRoom, cell: CellData) -> void:
	# 清空房间事件容器中的原有内容
	_clear_container(room.event_container)

	# 根据事件类型分发到对应的生成函数
	match cell.event_type:
		"battle":
			_spawn_battle(room, cell)
		"elite":
			_spawn_elite(room, cell)
		"boss":
			_spawn_boss(room, cell)
		"merchant":
			_spawn_merchant(room)
		"treasure":
			_spawn_treasure(room)
		"rest":
			_spawn_rest(room)
		"start":
			_spawn_start(room)

# ========================== 私有方法模块（容器清理） ==========================
## 功能：清空指定容器中的所有子节点
## 参数：container (Node2D) - 目标容器节点（可为 null）
func _clear_container(container: Node2D) -> void:
	if container == null:
		return
	for child in container.get_children():
		if is_instance_valid(child):
			child.queue_free()

# ========================== 私有方法模块（事件类型生成） ==========================
## 功能：生成普通战斗事件
## 参数：room (ChunkRoom) - 房间实例；cell (CellData) - 单元格数据（用于难度调整和随机种子）
func _spawn_battle(room: ChunkRoom, cell: CellData) -> void:
	var scene := event_scenes.get("battle", null) as PackedScene
	if scene != null:
		_instantiate_in_container(room.event_container, scene)
	else:
		# 无专用预制体时使用默认敌人池（生成 3 个敌人）
		_spawn_default_enemies(room, cell, 3)

## 功能：生成精英战斗事件
## 参数：room (ChunkRoom) - 房间实例；cell (CellData) - 单元格数据
func _spawn_elite(room: ChunkRoom, cell: CellData) -> void:
	var scene := event_scenes.get("elite", null) as PackedScene
	if scene != null:
		_instantiate_in_container(room.event_container, scene)
	else:
		# 无专用预制体时使用默认敌人池（生成 1 个精英强度敌人）
		_spawn_default_enemies(room, cell, 1)

## 功能：生成 BOSS 战斗事件
## 参数：room (ChunkRoom) - 房间实例；_cell (CellData) - 单元格数据（暂未使用）
func _spawn_boss(room: ChunkRoom, _cell: CellData) -> void:
	var scene := event_scenes.get("boss", null) as PackedScene
	if scene != null:
		_instantiate_in_container(room.event_container, scene)

## 功能：生成商人事件
## 参数：room (ChunkRoom) - 房间实例
func _spawn_merchant(room: ChunkRoom) -> void:
	var scene := event_scenes.get("merchant", null) as PackedScene
	if scene != null:
		_instantiate_in_container(room.event_container, scene)

## 功能：生成宝藏事件
## 参数：room (ChunkRoom) - 房间实例
func _spawn_treasure(room: ChunkRoom) -> void:
	var scene := event_scenes.get("treasure", null) as PackedScene
	if scene != null:
		_instantiate_in_container(room.event_container, scene)

## 功能：生成休息事件
## 参数：room (ChunkRoom) - 房间实例
func _spawn_rest(room: ChunkRoom) -> void:
	var scene := event_scenes.get("rest", null) as PackedScene
	if scene != null:
		_instantiate_in_container(room.event_container, scene)

## 功能：生成起点事件（通常为空或传送点）
## 参数：_room (ChunkRoom) - 房间实例（暂未使用）
func _spawn_start(_room: ChunkRoom) -> void:
	pass

# ========================== 私有方法模块（默认敌人生成） ==========================
## 功能：生成默认敌人（当事件类型无专用预制体时使用）
## 参数：room (ChunkRoom) - 房间实例；cell (CellData) - 单元格数据（用于随机种子）；count (int) - 生成敌人数量
func _spawn_default_enemies(room: ChunkRoom, cell: CellData, count: int) -> void:
	if default_enemy_pool.is_empty():
		return

	# 使用单元格坐标作为随机种子，确保可重现
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cell.coord)

	# 获取房间内的出生点标记
	var spawn_points := _get_spawn_points(room)

	for i in count:
		# 从默认敌人池中随机选择一个预制体
		var scene := default_enemy_pool[rng.randi() % default_enemy_pool.size()]
		var enemy := scene.instantiate() as Node2D

		# 分配到对应的出生点位置（超出范围则跳过位置设置）
		if spawn_points.size() > i:
			enemy.global_position = spawn_points[i].global_position

		room.event_container.add_child(enemy)

## 功能：获取房间内所有敌人出生点标记节点
## 参数：room (ChunkRoom) - 房间实例
## 返回值：Array[Marker2D] - 名称以 "Spawn_" 开头的 Marker2D 节点数组
func _get_spawn_points(room: ChunkRoom) -> Array[Marker2D]:
	var points: Array[Marker2D] = []
	for child in room.get_children():
		if child is Marker2D and child.name.begins_with("Spawn_"):
			points.append(child)
	return points

# ========================== 私有方法模块（预制体实例化） ==========================
## 功能：将预制体实例化并添加到指定容器中
## 参数：container (Node2D) - 目标容器节点；scene (PackedScene) - 待实例化的预制体
func _instantiate_in_container(container: Node2D, scene: PackedScene) -> void:
	var instance := scene.instantiate()
	container.add_child(instance)
