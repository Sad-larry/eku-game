# ==============================================================================
#   RoomBase.gd
#   功能：房间基类，管理房间的激活/休眠、敌人波次生成、出口门控制、清理检测等。
#        支持通过 RoomConfig 资源进行数据驱动配置（地形布局、生成点、敌人波次）。
# ==============================================================================
extends Node2D
class_name RoomBase

# ========================== 枚举定义模块 ==========================
## 房间状态枚举
enum RoomState {
	INACTIVE,    ## 未激活（休眠状态）
	ACTIVATING,  ## 激活中（正在生成敌人）
	ACTIVE,      ## 活跃中（战斗中）
	CLEARING,    ## 清理中（波次切换间隙）
	COMPLETED    ## 已完成（敌人全清，出口门打开）
}

# ========================== 导出变量模块 ==========================
## 关卡配置资源（包含地形布局、波次数据、生成点覆盖等）
@export var room_config: RoomConfig

## 出口门节点（初始关闭，房间清理完成后打开）
@export var exit_door: Node2D

## 房间唯一标识（保留用于向后兼容，但优先从 room_config.room_id 读取）
@export var room_id: String = "empty_room_01"

## 是否为战斗房间（保留用于向后兼容，但优先从 room_config.room_type 判断）
@export var is_battle_room: bool = false

# ========================== 节点引用模块 ==========================
## 碰撞容器节点（用于启用/禁用房间碰撞）
@onready var collision_container: Node2D = $Collision

## 瓦片地图根节点（存放地形 TileMap 或 TileMapLayer）
@onready var tilemap_root: Node2D = $TileMap

## 生成点根节点（存放所有生成点 Marker2D）
@onready var spawn_points_root: Node2D = $SpawnPoints

# ========================== 内部状态变量模块 ==========================
## 当前房间状态
var state: RoomState = RoomState.INACTIVE

## 生成的敌人实例列表
var _enemies: Array[Node] = []

## 当前波次索引
var _current_wave: int = 0

# ========================== 信号声明模块 ==========================
## 触发时机：房间被激活时
## 参数：room (RoomBase) - 被激活的房间实例
signal room_activated(room: RoomBase)

## 触发时机：房间被清理完成时（所有敌人生成完毕且全部死亡）
## 参数：room (RoomBase) - 被清理完成的房间实例
signal room_cleared(room: RoomBase)

## 触发时机：敌人被生成时
## 参数：enemy (Node) - 生成的敌人实例
signal enemy_spawned(enemy: Node)

## 触发时机：敌人死亡时
## 参数：enemy (Node) - 死亡的敌人实例
signal enemy_died(enemy: Node)

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时进行初始化，从 RoomConfig 加载配置并注册到 RoomManager
func _ready() -> void:
	# 从 Resource 数据驱动初始化
	if room_config:
		_apply_layout(room_config.layout)
		_setup_spawn_markers(room_config)
		# 用配置覆盖导出变量
		if not room_config.room_id.is_empty():
			room_id = room_config.room_id
		is_battle_room = room_config.has_combat()

	# 初始关闭出口门
	if exit_door:
		exit_door.visible = false
		if exit_door.has_method("close"):
			exit_door.close()

	# 注册到房间管理器
	RoomManager.register_room(self)
	# 监听游戏状态变化（用于暂停时禁用碰撞）
	GameManager.game_state_changed.connect(_on_game_state_changed)

## 功能：节点退出场景树时断开信号连接
func _exit_tree() -> void:
	GameManager.game_state_changed.disconnect(_on_game_state_changed)

# ========================== 数据驱动初始化模块 ==========================
## 功能：应用地形布局，从 RoomLayout 加载地形到场景中
## 参数：layout (RoomLayout) - 房间布局资源
func _apply_layout(layout: RoomLayout) -> void:
	if not layout:
		push_warning("RoomBase[%s]: room_config 没有指定 layout" % name)
		return

	# 清空旧地形
	_clear_terrain()

	if layout.terrain_scene:
		# 方式 A：实例化纯地形场景
		var terrain: Node2D = layout.terrain_scene.instantiate()
		tilemap_root.add_child(terrain)
	elif layout.tilemap_data.size() > 0:
		# 方式 B：从序列化数据填充（备选方案）
		var tilemap_layer: TileMapLayer = tilemap_root.get_child(0)
		if tilemap_layer:
			tilemap_layer.tile_map_data = layout.tilemap_data
		else:
			push_error("RoomBase[%s]: 方式B需要 TileMapLayer 作为 $TileMap 的第一个子节点" % name)

## 功能：根据 RoomConfig 创建生成点 Marker2D
## 参数：config (RoomConfig) - 房间配置资源
func _setup_spawn_markers(config: RoomConfig) -> void:
	if not config or not config.layout:
		return

	# 清除旧的生成点
	_clear_spawn_markers()

	# 遍历 layout 中的 marker 模板，为每个模板创建 Marker2D
	for template in config.layout.spawn_marker_templates:
		var marker := Marker2D.new()
		marker.name = "Marker_%s" % template.marker_id
		marker.position = template.local_position
		spawn_points_root.add_child(marker)

		# 存储元数据供 _spawn_enemies_from_points 使用
		marker.set_meta("marker_group", template.marker_group)

		# 检查是否有生成点覆盖配置（SpawnOverride）
		var override := config.find_override(template.marker_id)
		if override:
			marker.set_meta("enemy_scene", override.enemy_scene)
			marker.set_meta("spawn_weight", override.spawn_weight)

# ========================== 清理辅助模块 ==========================
## 功能：清除地形子节点
func _clear_terrain() -> void:
	for child in tilemap_root.get_children():
		child.queue_free()

## 功能：清除所有生成点 Marker
func _clear_spawn_markers() -> void:
	for child in spawn_points_root.get_children():
		child.queue_free()

# ========================== 游戏状态响应模块 ==========================
## 功能：游戏状态变化时的回调（用于暂停时禁用房间碰撞）
## 参数：new_state (GameManager.GameState) - 新游戏状态；_old_state - 旧状态（未使用）
func _on_game_state_changed(new_state: GameManager.GameState, _old_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.IN_GAME:
			collision_container.process_mode = Node.PROCESS_MODE_INHERIT
		GameManager.GameState.PAUSED:
			collision_container.process_mode = Node.PROCESS_MODE_DISABLED
		_:
			pass

# ========================== 房间激活/休眠模块 ==========================
## 功能：激活房间（生成敌人、启用碰撞、设置为当前房间）
func activate_room() -> void:
	visible = true
	collision_container.process_mode = Node.PROCESS_MODE_INHERIT
	RoomManager.set_current_room(room_id)

	if state != RoomState.INACTIVE:
		return
	state = RoomState.ACTIVATING
	print("[Room] 激活房间: ", name)

	# 从 room_config 获取波次数据
	if room_config and not room_config.waves.is_empty():
		_start_wave(_current_wave)
	else:
		_spawn_enemies_from_points()

	state = RoomState.ACTIVE
	room_activated.emit(self)

## 功能：休眠房间（隐藏、禁用碰撞、清理敌人和掉落物）
func deactivate_room() -> void:
	visible = false
	collision_container.process_mode = Node.PROCESS_MODE_DISABLED
	if state == RoomState.INACTIVE:
		return
	print("[Room] 休眠房间: ", name)
	_clear_enemies()
	_clear_drops()
	state = RoomState.INACTIVE


## 功能：判断房间是否已完成
## 返回值：bool - true 表示已完成
func is_completed() -> bool:
	return state == RoomState.COMPLETED

# ========================== 敌人生成模块 ==========================
## 功能：根据生成点动态生成敌人（无波次配置时使用）
## 说明：遍历 $SpawnPoints 下的所有 Marker2D，根据元数据生成对应敌人
func _spawn_enemies_from_points() -> void:
	for marker in spawn_points_root.get_children():
		if not marker is Marker2D:
			continue
		if marker.get_meta("marker_group", "") != "enemy":
			continue

		var enemy_scene: PackedScene = marker.get_meta("enemy_scene", null)
		if not enemy_scene:
			# 从 room_config 的第一波中随机取默认敌人
			if room_config and room_config.waves.size() > 0:
				enemy_scene = _pick_enemy_from_waves()
			if not enemy_scene:
				continue

		var enemy: Node2D = enemy_scene.instantiate()
		enemy.global_position = marker.global_position
		add_child(enemy)
		_enemies.append(enemy)
		_connect_enemy_signals(enemy)
		enemy_spawned.emit(enemy)

## 功能：从 room_config 的第一波中随机选择一个敌人场景
## 返回值：PackedScene - 敌人场景，若无波次配置则返回 null
func _pick_enemy_from_waves() -> PackedScene:
	if not room_config or room_config.waves.is_empty():
		return null
	var first_wave: WaveData = room_config.waves[0]
	return first_wave.get_random_unit_scene()

# ========================== 波次系统模块 ==========================
## 功能：开始指定索引的敌人波次
## 参数：wave_index (int) - 波次索引
func _start_wave(wave_index: int) -> void:
	if not room_config or wave_index >= room_config.waves.size():
		push_error("Room[%s]: 波次索引 %d 超出范围" % [name, wave_index])
		return

	var wave: WaveData = room_config.waves[wave_index]
	for unit_data in wave.units:
		var enemy_scene: PackedScene = unit_data.unit_scene
		var enemy: Node2D = enemy_scene.instantiate()
		enemy.global_position = global_position + Vector2(
			randf_range(-100, 100),
			randf_range(-100, 100)
		)
		add_child(enemy)
		_enemies.append(enemy)
		_connect_enemy_signals(enemy)
		enemy_spawned.emit(enemy)

# ========================== 清理模块 ==========================
## 功能：清理所有敌人
func _clear_enemies() -> void:
	for enemy in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()

## 功能：清理所有掉落物（通过组 "room_drops" 或 "drop" 查找）
func _clear_drops() -> void:
	var drops = get_tree().get_nodes_in_group("room_drops")
	for drop in drops:
		if drop and is_instance_valid(drop):
			drop.queue_free()
	for child in get_children():
		if child.is_in_group("drop") or child.has_method("collect"):
			child.queue_free()

# ========================== 敌人信号管理模块 ==========================
## 功能：连接敌人的死亡信号
## 参数：enemy (Node) - 敌人实例
func _connect_enemy_signals(enemy: Node) -> void:
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(enemy))
	elif enemy.has_signal("health_depleted"):
		enemy.health_depleted.connect(_on_enemy_died.bind(enemy))
	else:
		var health = enemy.get_node_or_null("HealthComponent")
		if health and health.has_signal("unit_died"):
			health.unit_died.connect(_on_enemy_died.bind(enemy))

## 功能：敌人死亡时的回调
## 参数：enemy (Node) - 死亡的敌人实例
func _on_enemy_died(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return
	var idx: int = _enemies.find(enemy)
	if idx != -1:
		_enemies.remove_at(idx)
	enemy_died.emit(enemy)
	_check_room_cleared()

# ========================== 房间完成模块 ==========================
## 功能：检查房间是否已清理完毕（所有敌人死亡）
func _check_room_cleared() -> void:
	if not _enemies.is_empty():
		return
	# 若有后续波次，则启动下一波
	if room_config and _current_wave + 1 < room_config.waves.size():
		_current_wave += 1
		_start_wave(_current_wave)
	else:
		_complete_room()

## 功能：完成房间（打开出口门、发射信号、通知事件总线）
func _complete_room() -> void:
	if state == RoomState.COMPLETED:
		return
	state = RoomState.COMPLETED
	print("[Room] 房间清理完成: ", name)
	
	if exit_door:
		exit_door.visible = true
		if exit_door.has_method("open"):
			exit_door.open()
		else:
			var collision = exit_door.get_node_or_null("CollisionShape2D")
			if collision:
				collision.disabled = true
	
	room_cleared.emit(self)
	EventBus.room_completed.emit(self)
