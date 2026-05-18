# ==============================================================================
#   GameWorld.gd
#   功能：游戏世界主入口场景
#         使用 ChunkManager + 噪声地形管线生成动态地图，
#         并注入 RadialGridMap 提供区块的 ring/事件数据。
# ==============================================================================
extends Node2D
class_name GameWorld

# ========================== 导出变量模块 ==========================
## 房间地图配置（菱形网格配置资源，含 chunk_size、max_ring 等）
@export var room_map_config: RadialGridConfig
## 战斗房间配置（用于生成敌人）
@export var battle_config: BattleRoomConfig
## 层级进度配置（定义每层的难度参数）
@export var layer_progression_config: LayerProgressionConfig

# ========================== 常量定义模块 ==========================
## 安全区预制体
const _SAFE_ZONE_SCENE: PackedScene = preload("res://prefabs/environment/safe_zone/safe_zone_marker.tscn")
## 层间传送门预制体
const _LAYER_PORTAL_SCENE: PackedScene = preload("res://prefabs/environment/portal/layer_portal.tscn")

# ========================== 节点引用模块 ==========================
## 区块管理器引用
@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var boundary_container: Node2D = $BoundaryContainer
@onready var enemy_container: Node2D = $EnemyContainer
@onready var ui_layer: CanvasLayer = $UI
@onready var debug_label: Label = $UI/DebugLabel
@onready var height_indicator: ColorRect = $UI/HeightIndicator

@onready var player: Player
var height_gen: NoiseHeightGenerator

## 测试用敌人场景（K/L 调试快捷键）
const _TEST_ENEMY_SCENE: PackedScene = preload("res://prefabs/entities/enemies/common/enemy_skeleton.tscn")

## 已生成敌人的房间坐标（避免重复生成）
var _spawned_rooms: Dictionary = {}
## 房间敌人追踪器
var _room_trackers: Dictionary = {}
## 房间内容生成器
var _room_content_generator: RoomContentGenerator

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化世界
func _ready() -> void:
	# 设置游戏状态为冒险中
	GameManager.set_game_state(GameManager.GameState.IN_GAME)

	# 新冒险时重置当前货币；继续冒险时不重置（保留检查点保存的值）
	if RunManager.run_status != RunManager.RunStatus.IN_PROGRESS:
		CurrencyManager.reset_current()

	_setup_world()
	if not player and is_instance_valid(Global.player):
		player = Global.player

	# 如果是继续冒险，恢复玩家位置
	if RunManager.run_status == RunManager.RunStatus.IN_PROGRESS:
		var checkpoint := SaveManager.get_section("active_run", {})
		var coord_dict: Dictionary = checkpoint.get("current_coord", {"x": 0, "y": 0})
		var spawn_pos := _chunk_to_world_center(coord_dict.get("x", 0), coord_dict.get("y", 0))
		if player:
			player.global_position = spawn_pos

	RoomManager.room_entered.connect(_on_room_entered)
	RoomManager.room_cleared.connect(_on_room_cleared)

## 功能：每帧更新调试信息
func _process(_delta: float) -> void:
	_update_debug_label()

## 功能：场景卸载前的清理钩子（由 SceneLoader 调用）
func on_before_scene_unload() -> void:
	# 如果运行仍在进行中（暂停/保存退出），保存检查点
	if RunManager.run_status == RunManager.RunStatus.IN_PROGRESS:
		RunManager.pause_run()
	elif RunManager.run_status == RunManager.RunStatus.PAUSED:
		# 已经暂停，不需要额外操作
		pass

## 功能：处理输入事件（调试快捷键）
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				var pc :Vector2i = chunk_manager._pixel_to_chunk(player.global_position)
				RoomManager.set_state(pc, RoomManager.RoomState.CLEARED)
			KEY_K:
				# 测试：在玩家附近生成一个敌人
				var enemy: Enemy = _TEST_ENEMY_SCENE.instantiate()
				enemy.global_position = player.global_position + Vector2(randf_range(80, 150), randf_range(-30, 30))
				add_child(enemy)
			KEY_L:
				# 测试：杀死场景中第一个存活的敌人
				for child in get_children():
					if child is Enemy and child.health_component.current_health > 0:
						child.health_component.take_damage(9999)
						break

# ========================== 调试信息模块 ==========================
## 功能：更新调试标签显示当前区块信息
func _update_debug_label() -> void:
	var pc :Vector2i = chunk_manager._pixel_to_chunk(player.global_position)
	var ring := chunk_manager.get_ring(pc.x, pc.y)
	var event_type := chunk_manager.get_event_type(pc.x, pc.y)
	var state := RoomManager.get_state(pc)
	var biome := _get_biome_name(ring)

	var state_names := ["未访问", "激活中", "已清除"]
	var info := "区块: (%d, %d)\nring: %d  |  生态: %s\n事件: %s  |  状态: %s\n已加载区块: %d" % [
		pc.x, pc.y, ring, biome,
		event_type if event_type != "" else "-", state_names[state],
		chunk_manager.get_loaded_chunk_count(),
	]

	debug_label.text = info

## 根据 ring 获取生态名称
func _get_biome_name(ring: int) -> String:
	var gen := chunk_manager.generator as TerrainGenerator
	if gen == null:
		return "?"
	var biome := gen._get_biome(ring)
	if biome != null:
		return biome.biome_name
	return "默认"

# ========================== 私有方法模块 ==========================
## 功能：初始化整个世界
## 1. 生成菱形网格地图数据（ring + 事件）
## 2. 配置噪声地形管线
## 3. 注入 ChunkManager
func _setup_world() -> void:
	if room_map_config == null:
		print("[error] GameWorld: room_map_config 未设置")
		return

	# ---- 0. 应用层级配置 ----
	_apply_layer_config()

	# ---- 1. 生成地图数据（ring + 事件类型） ----
	var grid_gen := RadialGridGenerator.new()
	var map_data := grid_gen.generate(room_map_config)

	# ---- 2. 配置噪声地形管线 ----
	height_gen = NoiseHeightGenerator.new()
	height_gen.frequency = 0.05
	height_gen.fractal_octaves = 3
	height_gen.height_scale = 1.0

	var terrain_gen := TerrainGenerator.new()
	terrain_gen.height_generator = height_gen
	terrain_gen.height_rules = TerrainHeightRules.new()
	terrain_gen.default_biome = room_map_config.default_biome
	for entry in room_map_config.ring_biomes:
		terrain_gen.ring_biomes[entry.ring_index] = entry.biome

	chunk_manager.generator = terrain_gen
	chunk_manager.map_data = map_data

	# 同步随机种子（确保地图生成和地形生成使用相同的种子）
	if room_map_config.world_seed != 0:
		chunk_manager.world_seed = room_map_config.world_seed

	# ---- 3. 初始化房间内容生成器 ----
	_room_content_generator = RoomContentGenerator.new()
	_room_content_generator.setup(self)

	# ---- 4. 玩家出生点定位 ----
	_place_player_at_start()

## 功能：根据当前层数应用层级配置到 room_map_config
func _apply_layer_config() -> void:
	if layer_progression_config == null:
		return
	var layer := RunManager.current_layer
	# 根据层数调整 max_ring
	var layer_max_ring := layer_progression_config.get_max_ring(layer)
	room_map_config.max_ring = layer_max_ring
	# 使用 RunManager 的种子（如果有）
	if RunManager.run_seed != 0:
		room_map_config.world_seed = RunManager.run_seed
	if Global.DEBUG_MODE:
		print("[GameWorld] 层级配置已应用 | 层数: ", layer, " | max_ring: ", layer_max_ring)

## 功能：将玩家放置到 start 坐标 (0,0) 的世界中心位置
func _place_player_at_start() -> void:
	# 等待一帧确保玩家已就绪
	await get_tree().process_frame
	if not player and is_instance_valid(Global.player):
		player = Global.player
	if player:
		var start_pos := _chunk_to_world_center(0, 0)
		player.global_position = start_pos
		if Global.DEBUG_MODE:
			print("[GameWorld] 玩家已放置到出生点: ", start_pos)

# ========================== 事件分发模块 ==========================
## 功能：玩家进入房间时的事件分发器
## 参数：coord (Vector2i) - 房间坐标；ring (int) - 房间环数；event_type (String) - 事件类型
func _on_room_entered(coord: Vector2i, ring: int, event_type: String) -> void:
	if _room_content_generator:
		_room_content_generator.generate_room(coord, ring, event_type)

## 功能：处理战斗事件（battle/elite）— 由 BattleSpawner / EliteSpawner 调用
func _handle_combat_event(coord: Vector2i, ring: int, event_type: String) -> void:
	# 已清除的房间不生成边界墙和敌人
	if RoomManager.is_cleared(coord):
		return

	_ensure_boundary(coord)

	# 生成敌人（未生成过且有配置）
	if not _spawned_rooms.has(coord) and battle_config != null:
		_spawn_enemies_for_room(coord, event_type)
		_spawned_rooms[coord] = true

## 功能：处理 Boss 事件
func _handle_boss_event(coord: Vector2i, ring: int) -> void:
	# 已清除的房间不生成
	if RoomManager.is_cleared(coord):
		return

	_ensure_boundary(coord)

	# 生成 Boss（使用 BossConfig 或回退到普通敌人）
	if not _spawned_rooms.has(coord):
		var boss_config := _get_boss_config_for_layer()
		if boss_config and boss_config.boss_scene:
			_spawn_boss(coord, boss_config)
		elif battle_config:
			_spawn_enemies_for_room(coord, "boss")
		_spawned_rooms[coord] = true

## 功能：处理 start 事件（安全区）
func _handle_start_event(coord: Vector2i) -> void:
	# 避免重复生成
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true

	# 在安全区生成标记
	var safe_zone := _SAFE_ZONE_SCENE.instantiate() as SafeZoneMarker
	safe_zone.position = _chunk_to_world_center(coord.x, coord.y)
	add_child(safe_zone)

	if Global.DEBUG_MODE:
		print("[GameWorld] 安全区已生成于: ", coord)

## 功能：处理商人事件（占位实现，S7 扩展）
func _handle_merchant_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
	if Global.DEBUG_MODE:
		print("[GameWorld] 商人房间（占位）: ", coord)

## 功能：处理宝箱事件 — 给予随机金币
func _handle_treasure_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	var ring := chunk_manager.get_ring(coord.x, coord.y)
	var bonus_coins: int = (ring + 1) * 10
	CurrencyManager.add_coin(bonus_coins)
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
	if Global.DEBUG_MODE:
		print("[GameWorld] 宝箱房间: +", bonus_coins, " 金币")

## 功能：处理休息事件 — 回复玩家生命值
func _handle_rest_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	if player and player.health_component:
		var heal_amount: int = int(player.health_component.max_health * 0.5)
		player.health_component.heal(heal_amount)
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
	if Global.DEBUG_MODE:
		print("[GameWorld] 休息房间: 回复 50% 生命值")

## 功能：处理陷阱事件 — 对玩家造成伤害
func _handle_trap_event(coord: Vector2i, ring: int) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	if player and player.health_component:
		var trap_damage: int = 2 + ring
		player.health_component.take_damage(trap_damage)
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
	if Global.DEBUG_MODE:
		print("[GameWorld] 陷阱房间: 受到 ", trap_damage, " 点伤害")

## 功能：处理随机事件（随机选择子事件执行）
func _handle_random_event(coord: Vector2i, ring: int) -> void:
	var sub_events := ["battle", "treasure", "rest", "trap"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)
	var chosen := sub_events[rng.randi() % sub_events.size()]
	_on_room_entered(coord, ring, chosen)

## 功能：处理 NPC 事件（占位实现，S7 扩展）
func _handle_npc_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
	if Global.DEBUG_MODE:
		print("[GameWorld] NPC 房间（占位）: ", coord)

## 功能：处理隐藏事件 — 给予额外奖励
func _handle_hidden_event(coord: Vector2i, ring: int) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	# 隐藏房间给予双倍金币奖励
	var bonus_coins: int = (ring + 1) * 20
	CurrencyManager.add_coin(bonus_coins)
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
	if Global.DEBUG_MODE:
		print("[GameWorld] 隐藏房间: +", bonus_coins, " 金币")

## 功能：处理传送门事件 — 传送到随机已访问房间
func _handle_teleport_event(coord: Vector2i) -> void:
	if _spawned_rooms.has(coord):
		return
	_spawned_rooms[coord] = true
	RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
	# TODO: S7 实现随机传送逻辑
	if Global.DEBUG_MODE:
		print("[GameWorld] 传送门（占位）: ", coord)

# ========================== 辅助方法模块 ==========================
## 功能：确保房间有边界墙
func _ensure_boundary(coord: Vector2i) -> void:
	# 已有边界的不重复生成
	for child in boundary_container.get_children():
		if child is RoomBoundary and child.chunk_coord == coord:
			return

	var boundary := preload("res://prefabs/environment/room_boundary/room_boundary.tscn").instantiate()
	boundary.setup(coord.x, coord.y, chunk_manager)
	boundary_container.add_child(boundary)
	boundary.lock()

## 功能：获取当前层的 Boss 配置
func _get_boss_config_for_layer() -> BossConfig:
	if layer_progression_config:
		var layer_config := layer_progression_config.get_config_for_layer(RunManager.current_layer)
		if layer_config and layer_config.boss_config:
			return layer_config.boss_config as BossConfig
	return null

## 功能：生成 Boss 实体
func _spawn_boss(coord: Vector2i, boss_config: BossConfig) -> void:
	var room_center := _chunk_to_world_center(coord.x, coord.y)
	var boss := boss_config.boss_scene.instantiate() as EnemyBoss
	boss.global_position = room_center
	boss.setup_boss(boss_config, coord)
	enemy_container.add_child(boss)

	# 创建 Boss 清场追踪器
	var tracker := RoomEnemyTracker.new()
	tracker.name = "BossTracker_%d_%d" % [coord.x, coord.y]
	enemy_container.add_child(tracker)
	tracker.setup(coord, [boss])
	tracker.all_enemies_defeated.connect(func() -> void:
		RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
		# Boss 击败后生成层间传送门
		var portal: LayerPortal = _LAYER_PORTAL_SCENE.instantiate()
		portal.position = _chunk_to_world_center(coord.x, coord.y)
		add_child(portal)
		if Global.DEBUG_MODE:
			print("[GameWorld] Boss 已击败，传送门已生成！")
	)
	_room_trackers[coord] = tracker

## 功能：房间清除时，查找对应边界并销毁
## 参数：coord (Vector2i) - 房间坐标
func _on_room_cleared(coord: Vector2i) -> void:
	for child in boundary_container.get_children():
		if child is RoomBoundary and child.chunk_coord == coord:
			child.unlock()
			break

# ========================== 敌人生成模块 ==========================
## 功能：为指定房间生成敌人
## 参数：coord (Vector2i) - 房间坐标；event_type (String) - 事件类型
func _spawn_enemies_for_room(coord: Vector2i, event_type: String) -> void:
	if battle_config == null or battle_config.enemy_entries.is_empty():
		return

	# 计算房间中心位置（等距坐标转世界坐标）
	var room_center: Vector2 = _chunk_to_world_center(coord.x, coord.y)

	# 使用房间坐标作为随机种子
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)

	var spawned_enemies: Array[Enemy] = []
	var used_positions: Array[Vector2] = []

	for entry in battle_config.enemy_entries:
		if entry.enemy_scene == null:
			continue
		for i in entry.count:
			var enemy := entry.enemy_scene.instantiate() as Enemy
			# 随机位置生成，避让玩家起点
			var pos := _get_random_enemy_position(room_center, used_positions, rng)
			enemy.global_position = pos
			used_positions.append(pos)
			enemy_container.add_child(enemy)
			spawned_enemies.append(enemy)

	# 创建清场追踪器
	if not spawned_enemies.is_empty():
		var tracker := RoomEnemyTracker.new()
		tracker.name = "Tracker_%d_%d" % [coord.x, coord.y]
		enemy_container.add_child(tracker)
		tracker.setup(coord, spawned_enemies)
		tracker.all_enemies_defeated.connect(func() -> void:
			RoomManager.set_state(coord, RoomManager.RoomState.CLEARED)
		)
		_room_trackers[coord] = tracker

## 功能：获取房间内随机敌人生成位置
## 参数：center (Vector2) - 房间中心；used_positions (Array[Vector2]) - 已使用位置；rng (RandomNumberGenerator) - 随机数生成器
## 返回值：Vector2 - 生成位置
func _get_random_enemy_position(center: Vector2, used_positions: Array[Vector2], rng: RandomNumberGenerator) -> Vector2:
	var room_half_size: float = 150.0
	var min_from_center: float = 80.0
	var min_between: float = 30.0

	for _attempt in 20:
		var pos := center + Vector2(
			rng.randf_range(-room_half_size, room_half_size),
			rng.randf_range(-room_half_size, room_half_size)
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
	return center + Vector2(rng.randf_range(-room_half_size, room_half_size), rng.randf_range(-room_half_size, room_half_size))

## 功能：区块坐标转世界中心坐标（等距投影）
## 参数：cx (int) - 区块 X 坐标；cy (int) - 区块 Y 坐标
## 返回值：Vector2 - 世界中心坐标
func _chunk_to_world_center(cx: int, cy: int) -> Vector2:
	var tile_size: Vector2i = chunk_manager._tile_size
	var half_w: float = tile_size.x * 0.5
	var half_h: float = tile_size.y * 0.5
	var world_x: float = (cx - cy) * half_w * chunk_manager.chunk_size
	var world_y: float = (cx + cy) * half_h * chunk_manager.chunk_size
	return Vector2(world_x, world_y)
