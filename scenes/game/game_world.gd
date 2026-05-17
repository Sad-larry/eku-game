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

# ========================== 节点引用模块 ==========================
## 区块管理器引用
@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var boundary_container: Node2D = $BoundaryContainer
@onready var ui_layer: CanvasLayer = $UI
@onready var debug_label: Label = $UI/DebugLabel
@onready var height_indicator: ColorRect = $UI/HeightIndicator

@onready var player: Player
var height_gen: NoiseHeightGenerator

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化世界
func _ready() -> void:
	_setup_world()
	if not player and is_instance_valid(Global.player):
		player = Global.player

	RoomManager.room_entered.connect(_on_room_entered)
	RoomManager.room_cleared.connect(_on_room_cleared)

## 功能：每帧更新调试信息
func _process(_delta: float) -> void:
	_update_debug_label()

## 功能：处理输入事件（调试快捷键）
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H:
				var pc :Vector2i = chunk_manager._pixel_to_chunk(player.global_position)
				RoomManager.set_state(pc, RoomManager.RoomState.CLEARED)

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

# ========================== 区块边界管理模块 ==========================
## 功能：玩家进入房间时，为战斗房间生成空气墙边界
## 参数：coord (Vector2i) - 房间坐标；_ring (int) - 房间环数；event_type (String) - 事件类型
func _on_room_entered(coord: Vector2i, _ring: int, event_type: String) -> void:
	if event_type in ["battle", "elite", "boss"]:
		# 已清除的房间不生成边界墙
		if RoomManager.is_cleared(coord):
			return

		# 已有边界的不重复生成
		for child in boundary_container.get_children():
			if child is RoomBoundary and child.chunk_coord == coord:
				return

		var boundary := preload("res://prefabs/environment/room_boundary/room_boundary.tscn").instantiate()
		boundary.setup(coord.x, coord.y, chunk_manager)
		boundary_container.add_child(boundary)
		boundary.lock()

## 功能：房间清除时，查找对应边界并销毁
## 参数：coord (Vector2i) - 房间坐标
func _on_room_cleared(coord: Vector2i) -> void:
	for child in boundary_container.get_children():
		if child is RoomBoundary and child.chunk_coord == coord:
			child.unlock()
			break
