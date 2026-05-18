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

## 战斗房间配置（优先使用，按配置生成敌人）
@export var battle_config: BattleRoomConfig

## 战斗事件通用敌人波次配置（无独立预制体且无 battle_config 时备用）
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
	elif battle_config != null and not battle_config.enemy_entries.is_empty():
		# 使用 BattleRoomConfig 生成敌人
		_spawn_from_config(room, cell, battle_config)
	else:
		# 无专用预制体时使用默认敌人池（生成 3 个敌人）
		_spawn_default_enemies(room, cell, 3)
	# 设置清场追踪
	_setup_room_tracker(room, cell)

## 功能：生成精英战斗事件
## 参数：room (ChunkRoom) - 房间实例；cell (CellData) - 单元格数据
func _spawn_elite(room: ChunkRoom, cell: CellData) -> void:
	var scene := event_scenes.get("elite", null) as PackedScene
	if scene != null:
		_instantiate_in_container(room.event_container, scene)
	else:
		# 无专用预制体时使用默认敌人池（生成 1 个精英强度敌人）
		_spawn_default_enemies(room, cell, 1)
	# 设置清场追踪
	_setup_room_tracker(room, cell)

## 功能：生成 BOSS 战斗事件
## 参数：room (ChunkRoom) - 房间实例；cell (CellData) - 单元格数据
func _spawn_boss(room: ChunkRoom, cell: CellData) -> void:
	var scene := event_scenes.get("boss", null) as PackedScene
	if scene != null:
		_instantiate_in_container(room.event_container, scene)
	# 设置清场追踪
	_setup_room_tracker(room, cell)

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

# ========================== 私有方法模块（清场追踪） ==========================
## 功能：为战斗房间设置敌人清场追踪
## 参数：room (ChunkRoom) - 房间实例；cell (CellData) - 单元格数据
func _setup_room_tracker(room: ChunkRoom, cell: CellData) -> void:
	# 收集房间内所有敌人
	var enemies: Array[Enemy] = []
	for child in room.event_container.get_children():
		if child is Enemy:
			enemies.append(child)

	if enemies.is_empty():
		return

	# 创建追踪器
	var tracker := RoomEnemyTracker.new()
	tracker.name = "RoomEnemyTracker"
	room.add_child(tracker)
	tracker.setup(cell.get_coord_vec(), enemies)
	# 清场时更新 RoomManager 状态
	tracker.all_enemies_defeated.connect(func() -> void:
		RoomManager.set_state(cell.get_coord_vec(), RoomManager.RoomState.CLEARED)
	)

# ========================== 私有方法模块（默认敌人生成） ==========================
## 功能：从 BattleRoomConfig 生成敌人
## 参数：room (ChunkRoom) - 房间实例；cell (CellData) - 单元格数据；config (BattleRoomConfig) - 战斗配置
func _spawn_from_config(room: ChunkRoom, cell: CellData, config: BattleRoomConfig) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cell.coord)

	var spawn_points := _get_spawn_points(room)
	var used_positions: Array[Vector2] = []
	var spawn_index: int = 0

	for entry in config.enemy_entries:
		if entry.enemy_scene == null:
			continue
		for i in entry.count:
			var enemy := entry.enemy_scene.instantiate() as Node2D
			# 优先使用 Spawn_ 标记
			if spawn_index < spawn_points.size():
				enemy.global_position = spawn_points[spawn_index].global_position
			else:
				# 随机位置生成，避让玩家起点
				enemy.global_position = _get_random_spawn_position(room, used_positions, rng)
			used_positions.append(enemy.global_position)
			room.event_container.add_child(enemy)
			spawn_index += 1

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
	var used_positions: Array[Vector2] = []

	for i in count:
		# 从默认敌人池中随机选择一个预制体
		var scene := default_enemy_pool[rng.randi() % default_enemy_pool.size()]
		var enemy := scene.instantiate() as Node2D

		# 分配到对应的出生点位置（超出范围则随机生成）
		if i < spawn_points.size():
			enemy.global_position = spawn_points[i].global_position
		else:
			enemy.global_position = _get_random_spawn_position(room, used_positions, rng)
		used_positions.append(enemy.global_position)
		room.event_container.add_child(enemy)

## 功能：获取房间内随机生成位置（避让玩家起点和已有敌人）
## 参数：room (ChunkRoom) - 房间实例；used_positions (Array[Vector2]) - 已使用的位置；rng (RandomNumberGenerator) - 随机数生成器
## 返回值：Vector2 - 生成位置
func _get_random_spawn_position(room: ChunkRoom, used_positions: Array[Vector2], rng: RandomNumberGenerator) -> Vector2:
	# 房间中心作为玩家起点参考
	var center: Vector2 = room.global_position
	var room_half_size: float = 200.0  # 房间半径（像素）
	var min_from_center: float = 80.0  # 距离玩家起点最小距离
	var min_between: float = 30.0      # 敌人间最小间距

	for _attempt in 20:
		var pos := center + Vector2(
			rng.randf_range(-room_half_size, room_half_size),
			rng.randf_range(-room_half_size, room_half_size)
		)
		# 检查距离玩家起点
		if pos.distance_to(center) < min_from_center:
			continue
		# 检查距离已有敌人
		var valid: bool = true
		for used in used_positions:
			if pos.distance_to(used) < min_between:
				valid = false
				break
		if valid:
			return pos
	# 兜底：返回随机位置
	return center + Vector2(rng.randf_range(-room_half_size, room_half_size), rng.randf_range(-room_half_size, room_half_size))

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
