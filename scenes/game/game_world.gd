# ==============================================================================
#   GameWorld.gd
#   功能：游戏世界主入口场景（2D 横版模式）
#         使用 RadialGridGenerator 生成地图数据，
#         通过 RoomNavigationManager + RoomLoader 管理房间导航和动态加载。
# ==============================================================================
extends Node2D
class_name GameWorld

# ========================== 导出变量模块 ==========================
## 房间地图配置（菱形网格配置资源，含 max_ring 等）
@export var room_map_config: RadialGridConfig
## 战斗房间配置（用于生成敌人）
@export var battle_config: BattleRoomConfig
## 层级进度配置（定义每层的难度参数）
@export var layer_progression_config: LayerProgressionConfig

# ========================== 常量定义模块 ==========================
## 层间传送门预制体
const _LAYER_PORTAL_SCENE: PackedScene = preload("res://prefabs/environment/portal/layer_portal.tscn")
## 测试用敌人场景
const _TEST_ENEMY_SCENE: PackedScene = preload("res://prefabs/entities/enemies/common/enemy_skeleton.tscn")
## 房间尺寸（像素）
const ROOM_SIZE: Vector2 = Vector2(640, 360)

# ========================== 节点引用模块 ==========================
@onready var room_container: Node2D = $RoomContainer
@onready var boundary_container: Node2D = $BoundaryContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var ui_layer: CanvasLayer = $UI
@onready var debug_label: Label = $UI/DebugLabel

@onready var player: Player

# ========================== 变量定义模块 ==========================
## 地图数据
var _map_data: RadialGridMap
## 房间加载器
var _room_loader: RoomLoader
## 房间内容生成器
var _room_content_generator: RoomContentGenerator
## 已生成敌人的房间坐标
var _spawned_rooms: Dictionary = {}
## 房间敌人追踪器
var _room_trackers: Dictionary = {}

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	GameManager.set_game_state(GameManager.GameState.IN_GAME)

	if RunManager.run_status != RunManager.RunStatus.IN_PROGRESS:
		CurrencyManager.reset_current()

	_setup_world()

	if not player and is_instance_valid(Global.player):
		player = Global.player

	# 连接信号
	RoomManager.room_entered.connect(_on_room_entered)
	RoomManager.room_cleared.connect(_on_room_cleared)
	RoomNavigationManager.room_transition_requested.connect(_on_room_transition)

func _process(_delta: float) -> void:
	_update_debug_label()

func on_before_scene_unload() -> void:
	if RunManager.run_status == RunManager.RunStatus.IN_PROGRESS:
		RunManager.pause_run()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				RoomManager.set_state(RoomNavigationManager.current_coord, RoomManager.RoomState.CLEARED)
			KEY_K:
				if player:
					var enemy: Enemy = _TEST_ENEMY_SCENE.instantiate()
					enemy.global_position = player.global_position + Vector2(randf_range(80, 150), randf_range(-30, 30))
					enemy_container.add_child(enemy)
			KEY_L:
				for child in enemy_container.get_children():
					if child is Enemy and child.health_component.current_health > 0:
						child.health_component.take_damage(9999)
						break

# ========================== 调试信息模块 ==========================
func _update_debug_label() -> void:
	if not debug_label:
		return
	var coord := RoomNavigationManager.current_coord
	var ring := RoomNavigationManager.get_current_ring()
	var state := RoomManager.get_state(coord)
	var state_names := ["未访问", "激活中", "已清除"]
	var axis := RoomNavigationManager.active_axis

	debug_label.text = "房间: (%d, %d)\nring: %d\n轴: %s\n事件: %s\n状态: %s" % [
		coord.x, coord.y, ring, axis.to_upper(),
		_get_current_event_type(), state_names[state],
	]

func _get_current_event_type() -> String:
	var coord := RoomNavigationManager.current_coord
	if _map_data:
		var cell: CellData = _map_data.get_cell(coord.x, coord.y)
		if cell:
			return cell.event_type
	return "-"

# ========================== 世界初始化 ==========================
func _setup_world() -> void:
	# 暂时注释掉地图生成器相关配置检查
	# if room_map_config == null:
	# 	push_error("GameWorld: room_map_config 未设置")
	# 	return

	_apply_layer_config()

	# 暂时注释掉地图生成器
	# var grid_gen := RadialGridGenerator.new()
	# _map_data = grid_gen.generate(room_map_config)

	# 暂时注释掉导航管理器初始化
	# RoomNavigationManager.setup(_map_data, room_map_config.max_ring)

	# 暂时注释掉房间加载器初始化
	# _room_loader = RoomLoader.new()
	# _room_loader.name = "RoomLoader"
	# add_child(_room_loader)
	# _room_loader.setup(_map_data, room_container)
	# _room_loader.main_room_changed.connect(_on_main_room_changed)

	# 暂时注释掉房间内容生成器初始化
	# _room_content_generator = RoomContentGenerator.new()
	# _room_content_generator.setup(self)

	# 暂时注释掉加载起始房间
	# _room_loader.load_start_room(Vector2i.ZERO)

	# 创建测试房间占位图（开发阶段）
	_create_test_rooms()

	# 6. 玩家出生点定位
	_place_player_at_start()

func _apply_layer_config() -> void:
	if layer_progression_config == null:
		return
	var layer := RunManager.current_layer
	var layer_max_ring := layer_progression_config.get_max_ring(layer)
	room_map_config.max_ring = layer_max_ring
	if RunManager.run_seed != 0:
		room_map_config.world_seed = RunManager.run_seed

## 功能：创建测试房间占位图（开发阶段使用）
## 说明：生成几个测试房间，用于验证房间系统和玩家移动
func _create_test_rooms() -> void:
	# 创建起始房间
	var start_room := RoomPlaceholder.new()
	start_room.name = "StartRoom"
	start_room.room_type = "start"
	start_room.room_coord = Vector2i.ZERO
	start_room.room_size = ROOM_SIZE
	start_room.position = Vector2.ZERO
	room_container.add_child(start_room)

	# 创建战斗房间（右边）
	var battle_room := RoomPlaceholder.new()
	battle_room.name = "BattleRoom1"
	battle_room.room_type = "battle"
	battle_room.room_coord = Vector2i(1, 0)
	battle_room.room_size = ROOM_SIZE
	battle_room.position = Vector2(ROOM_SIZE.x, 0)
	room_container.add_child(battle_room)

	# 创建宝箱房间（上边）
	var treasure_room := RoomPlaceholder.new()
	treasure_room.name = "TreasureRoom"
	treasure_room.room_type = "treasure"
	treasure_room.room_coord = Vector2i(0, -1)
	treasure_room.room_size = ROOM_SIZE
	treasure_room.position = Vector2(0, -ROOM_SIZE.y)
	room_container.add_child(treasure_room)

	# 创建Boss房间（右上）
	var boss_room := RoomPlaceholder.new()
	boss_room.name = "BossRoom"
	boss_room.room_type = "boss"
	boss_room.room_coord = Vector2i(1, -1)
	boss_room.room_size = ROOM_SIZE
	boss_room.position = Vector2(ROOM_SIZE.x, -ROOM_SIZE.y)
	room_container.add_child(boss_room)

	print("GameWorld: 已创建测试房间占位图")

func _place_player_at_start() -> void:
	await get_tree().process_frame
	if not player and is_instance_valid(Global.player):
		player = Global.player
	# 暂时注释掉房间加载器相关逻辑，使用场景中预设的玩家位置
	# if player:
	# 	var main_room := _room_loader.get_main_room()
	# 	if main_room:
	# 		player.global_position = main_room.get_spawn_position()

# ========================== 房间切换模块 ==========================
func _on_room_transition(target_coord: Vector2i) -> void:
	# 判断玩家从哪个方向离开
	var old_coord := RoomNavigationManager.current_coord
	var dx := target_coord.x - old_coord.x
	var dy := target_coord.y - old_coord.y
	var from_side := "left" if (dx < 0 or dy < 0) else "right"

	# 通知 RoomManager
	var cell: CellData = _map_data.get_cell(target_coord.x, target_coord.y)
	if cell:
		RoomManager.enter_room(target_coord, cell.ring, cell.event_type)

	# 切换房间
	_room_loader.transition_to_room(target_coord, from_side)

func _on_main_room_changed(coord: Vector2i) -> void:
	# 定位玩家到入口位置
	if player:
		var main_room := _room_loader.get_main_room()
		if main_room:
			var from_side := "right"  # 默认
			# 根据移动方向判断入口
			var exits := RoomNavigationManager.get_exit_coords()
			player.global_position = main_room.get_player_entry_position(from_side)

	# 设置摄像机边界
	var cam := get_viewport().get_camera_2d()
	if cam is SideScrollCamera and _room_loader.get_main_room():
		var bounds := _room_loader.get_main_room().get_bounds()
		cam.set_bounds(bounds.position.x, bounds.position.y, bounds.end.x, bounds.end.y)

# ========================== 事件分发模块 ==========================
func _on_room_entered(coord: Vector2i, ring: int, event_type: String) -> void:
	if _room_content_generator:
		_room_content_generator.generate_room(coord, ring, event_type)

func _handle_combat_event(coord: Vector2i, ring: int, event_type: String) -> void:
	if RoomManager.is_cleared(coord):
		return
	_ensure_boundary(coord)
	if not _spawned_rooms.has(coord) and battle_config != null:
		_spawn_enemies_for_room(coord, event_type)
		_spawned_rooms[coord] = true

func _handle_boss_event(coord: Vector2i, ring: int) -> void:
	if RoomManager.is_cleared(coord):
		return
	_ensure_boundary(coord)
	if not _spawned_rooms.has(coord):
		var boss_config := _get_boss_config_for_layer()
		if boss_config and boss_config.boss_scene:
			_spawn_boss(coord, boss_config)
		elif battle_config:
			_spawn_enemies_for_room(coord, "boss")
		_spawned_rooms[coord] = true

func _handle_start_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	var safe_zone := Global.SAFE_ZONE_SCENE.instantiate() as SafeZoneMarker
	safe_zone.position = _get_room_center(coord)
	room_container.add_child(safe_zone)

func _handle_merchant_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)

func _handle_treasure_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	var ring :int = abs(coord.x) + abs(coord.y)
	var bonus_coins: int = (ring + 1) * 10
	CurrencyManager.add_coin(bonus_coins)
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)

func _handle_rest_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	if player and player.health_component:
		var heal_amount: int = int(player.health_component.max_health * 0.5)
		player.health_component.heal(heal_amount)
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)

func _handle_trap_event(coord: Vector2i, ring: int) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	if player and player.health_component:
		var trap_damage: int = 2 + ring
		player.health_component.take_damage(trap_damage)
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)

func _handle_random_event(coord: Vector2i, ring: int) -> void:
	var sub_events := ["battle"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)
	var chosen: String = sub_events[rng.randi() % sub_events.size()]
	_on_room_entered(coord, ring, chosen)

func _handle_npc_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)

func _handle_hidden_event(coord: Vector2i, ring: int) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	var bonus_coins: int = (ring + 1) * 20
	CurrencyManager.add_coin(bonus_coins)
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)

func _handle_teleport_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)

# ========================== 辅助方法 ==========================
func _ensure_boundary(coord: Vector2i) -> void:
	for child in boundary_container.get_children():
		if child is RoomBoundary and child.chunk_coord == coord:
			return
	var boundary := preload("res://prefabs/environment/room_boundary/room_boundary.tscn").instantiate()
	# 使用简化的矩形边界设置
	var center := _get_room_center(coord)
	boundary.position = center
	boundary_container.add_child(boundary)
	boundary.lock()

func _get_boss_config_for_layer() -> BossConfig:
	if layer_progression_config:
		var layer_config := layer_progression_config.get_config_for_layer(RunManager.current_layer)
		if layer_config and layer_config.boss_config:
			return layer_config.boss_config as BossConfig
	return null

func _spawn_boss(coord: Vector2i, boss_config: BossConfig) -> void:
	var room_center := _get_room_center(coord)
	var boss := boss_config.boss_scene.instantiate() as EnemyBoss
	boss.global_position = room_center
	boss.setup_boss(boss_config, coord)
	enemy_container.add_child(boss)

	var tracker := RoomEnemyTracker.new()
	tracker.name = "BossTracker_%d_%d" % [coord.x, coord.y]
	enemy_container.add_child(tracker)
	tracker.setup(coord, [boss])
	tracker.all_enemies_defeated.connect(func() -> void:
		RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
		var portal: LayerPortal = _LAYER_PORTAL_SCENE.instantiate()
		portal.position = _get_room_center(coord)
		add_child(portal)
	)
	_room_trackers[coord] = tracker

func _on_room_cleared(coord: Vector2i) -> void:
	for child in boundary_container.get_children():
		if child is RoomBoundary and child.chunk_coord == coord:
			child.unlock()
			break

# ========================== 敌人生成模块 ==========================
func _spawn_enemies_for_room(coord: Vector2i, event_type: String) -> void:
	if battle_config == null or battle_config.enemy_entries.is_empty():
		return

	var room_center := _get_room_center(coord)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)

	var spawned_enemies: Array[Enemy] = []
	var used_positions: Array[Vector2] = []

	for entry in battle_config.enemy_entries:
		if entry.enemy_scene == null:
			continue
		for i in entry.count:
			var enemy := entry.enemy_scene.instantiate() as Enemy
			var pos := _get_random_enemy_position(room_center, used_positions, rng)
			enemy.global_position = pos
			used_positions.append(pos)
			enemy_container.add_child(enemy)
			spawned_enemies.append(enemy)

	if not spawned_enemies.is_empty():
		var tracker := RoomEnemyTracker.new()
		tracker.name = "Tracker_%d_%d" % [coord.x, coord.y]
		enemy_container.add_child(tracker)
		tracker.setup(coord, spawned_enemies)
		tracker.all_enemies_defeated.connect(func() -> void:
			RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
		)
		_room_trackers[coord] = tracker

func _get_random_enemy_position(center: Vector2, used_positions: Array[Vector2], rng: RandomNumberGenerator) -> Vector2:
	# 横版房间：水平范围大，垂直范围小
	var room_half_x: float = 250.0
	var room_half_y: float = 100.0
	var min_from_center: float = 80.0
	var min_between: float = 30.0

	for _attempt in 20:
		var pos := center + Vector2(
			rng.randf_range(-room_half_x, room_half_x),
			rng.randf_range(-room_half_y, room_half_y)
		)
		if pos.distance_to(center) < min_from_center:
			continue
		var valid: bool = true
		for used in used_positions:
			if pos.distance_to(used) < min_between:
				valid = false
				break
		if valid:
			return pos
	return center + Vector2(rng.randf_range(-room_half_x, room_half_x), rng.randf_range(-room_half_y, room_half_y))

## 功能：获取房间中心世界坐标（网格布局）
func _get_room_center(coord: Vector2i) -> Vector2:
	return Vector2(coord.x * ROOM_SIZE.x, coord.y * ROOM_SIZE.y) + ROOM_SIZE * 0.5
