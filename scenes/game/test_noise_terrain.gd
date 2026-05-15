# ==============================================================================
#   test_noise_terrain.gd
#   功能：噪声高度图地形生成测试场景。
#         使用场景中已有的 ChunkManager 和 Player 节点。
#         WASD 移动，H 查看高度信息，R 重新生成。
# ==============================================================================
extends Node2D

# ========================== 节点引用模块 ==========================
@onready var chunk_manager: ChunkManager = $ChunkManager
@onready var player: Player = $Player
@onready var ui_layer: CanvasLayer = $UI
@onready var debug_label: Label = $UI/Label

var height_indicator: ColorRect

# ========================== 变量定义模块 ==========================
var _gen: TerrainGenerator
var _cached_noise: FastNoiseLite
var _ref_layer: TileMapLayer

# 区块跟踪
const CHUNK_CHECK_INTERVAL: float = 0.25
var _check_timer: float = 0.0
var _last_chunk: Vector2i = Vector2i(999999, 999999)

# 高度叠加显示开关
var _show_height_overlay: bool = false
var _height_overlay: TileMapLayer = null
var _last_overlay_chunk: Vector2i = Vector2i(999999, 999999)

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	# 配置 ChunkManager（场景中已设置 tileset）
	chunk_manager.world_seed = randi()

	_create_ui()
	_setup_terrain_pipeline()
	_setup_biome_map()

	# 挂载生成器到 ChunkManager
	chunk_manager.generator = _gen

	# 用于坐标转换的参考层（不加入场景树）
	_ref_layer = TileMapLayer.new()
	_ref_layer.tile_set = chunk_manager.tileset

	# 初始化区块加载
	var pc := _get_player_chunk()
	chunk_manager._load_chunks_around(pc)
	_last_chunk = pc

	print("测试场景就绪")
	print("  WASD = 移动 | H = 高度信息 | R = 重新生成")

func _process(_delta: float) -> void:
	_pass()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_H: _toggle_height_info()
			KEY_R: _regenerate_terrain()

# ========================== UI 创建模块 ==========================
func _create_ui() -> void:
	# 配置场景中已有的 Label
	debug_label.add_theme_font_size_override("font_size", 14)
	debug_label.add_theme_color_override("font_color", Color.WHITE)
	debug_label.add_theme_color_override("shadow_color", Color.BLACK)
	debug_label.add_theme_constant_override("shadow_outline_size", 1)

	# 高度指示方块
	height_indicator = ColorRect.new()
	height_indicator.name = "HeightIndicator"
	height_indicator.size = Vector2(16, 16)
	height_indicator.position = Vector2(10, 140)
	height_indicator.hide()
	ui_layer.add_child(height_indicator)

# ========================== 地形管线配置模块 ==========================
func _setup_terrain_pipeline() -> void:
	var height_gen := NoiseHeightGenerator.new()
	height_gen.frequency = 0.05
	height_gen.fractal_octaves = 3
	height_gen.height_scale = 1.0

	_gen = TerrainGenerator.new()
	_gen.height_generator = height_gen
	_gen.height_rules = TerrainHeightRules.new()

	# 缓存噪声实例用于调试采样
	_cached_noise = FastNoiseLite.new()
	_cached_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_cached_noise.frequency = height_gen.frequency
	_cached_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_cached_noise.fractal_octaves = height_gen.fractal_octaves

func _setup_biome_map() -> void:
	# 使用程序化创建的 BiomeConfig，统一 source_id = 1
	# 注意：不直接加载 .tres 文件，因为它们的 source_id 指向不同的图集源
	var bm := BiomeMap.new()

	var biome_names := ["深水", "浅水", "沙地", "泥地", "草地", "花地", "石地", "山地", "岩石", "雪地"]
	var biome_thresholds := [-0.2, -0.1, 0.0, 0.05, 0.25, 0.65, 0.8, 0.83, 0.9, 1.0]

	for i in 10:
		var cfg := BiomeConfig.new()
		cfg.biome_name = biome_names[i]
		cfg.source_id = 1  # 统一使用 grassland 图集（source 1）
		bm.add_biome(biome_thresholds[i], cfg)

	_gen.biome_map = bm

# ========================== 玩家移动 & 区块跟踪模块 ==========================
func _pass() -> void:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir != Vector2.ZERO:
		player.global_position += dir.normalized() * 200.0 * get_process_delta_time()

	# 区块动态加载跟踪
	_check_timer += get_process_delta_time()
	if _check_timer >= CHUNK_CHECK_INTERVAL:
		_check_timer = 0.0
		var pc := _get_player_chunk()
		if pc != _last_chunk:
			_last_chunk = pc
			chunk_manager._load_chunks_around(pc)

	_update_debug_label()

func _get_player_chunk() -> Vector2i:
	var tile := _world_to_tile(player.global_position)
	return Vector2i(
		_floor_div(tile.x, chunk_manager.chunk_size),
		_floor_div(tile.y, chunk_manager.chunk_size)
	)

func _floor_div(a: int, b: int) -> int:
	if b == 0:
		return 0
	return int(floor(float(a) / float(b)))

func _world_to_tile(world_pos: Vector2) -> Vector2i:
	return _ref_layer.local_to_map(world_pos)

# ========================== 调试信息模块 ==========================
func _update_debug_label() -> void:
	var tile := _world_to_tile(player.global_position)
	var pc := _get_player_chunk()

	var info := "区块: (%d, %d)\n瓦片: (%d, %d)  │ 已加载: %d" % [
		pc.x, pc.y, tile.x, tile.y,
		chunk_manager.get_loaded_chunk_count(),
	]

	_cached_noise.seed = chunk_manager.world_seed
	var h := _cached_noise.get_noise_2d(tile.x, tile.y)
	var terrain_type := _gen.height_rules.get_terrain_type(h)
	var terrain_name := _gen.height_rules.get_terrain_name(terrain_type)
	info += "\n高度: %+.4f" % h
	info += "\n地形: %s" % terrain_name

	debug_label.text = info

	height_indicator.color = _height_to_color(h)
	height_indicator.show()

## 高度值 [-1, 1] → 颜色映射（蓝→青→绿→黄→红）
func _height_to_color(h: float) -> Color:
	var t := clampf((h + 1.0) * 0.5, 0.0, 1.0)
	if t < 0.25:
		return Color(0.0, t * 4.0, 1.0)
	elif t < 0.5:
		return Color(0.0, 1.0, (0.5 - t) * 4.0)
	elif t < 0.75:
		return Color((t - 0.5) * 4.0, 1.0, 0.0)
	else:
		return Color(1.0, (1.0 - t) * 4.0, 0.0)

# ========================== 交互控制模块 ==========================
func _toggle_height_info() -> void:
	_show_height_overlay = not _show_height_overlay

	if _show_height_overlay:
		_build_height_overlay()
		print("=== 高度图可视化: 开启 ===")
	else:
		_clear_height_overlay()
		print("=== 高度图可视化: 关闭 ===")

	# 打印当前区块高度统计
	var pc := _get_player_chunk()
	_cached_noise.seed = chunk_manager.world_seed
	var sum: float = 0.0
	var min_h: float = 999.0
	var max_h: float = -999.0
	var count: int = 0
	for dx in chunk_manager.chunk_size:
		for dy in chunk_manager.chunk_size:
			var v := _cached_noise.get_noise_2d(pc.x * chunk_manager.chunk_size + dx, pc.y * chunk_manager.chunk_size + dy)
			sum += v
			min_h = min(min_h, v)
			max_h = max(max_h, v)
			count += 1
	print("当前区块高度统计: min=%.4f  max=%.4f  mean=%.4f" % [min_h, max_h, sum / count])

func _build_height_overlay() -> void:
	if _height_overlay != null:
		_height_overlay.queue_free()

	var pc := _get_player_chunk()
	_height_overlay = TileMapLayer.new()
	_height_overlay.name = "HeightOverlay"
	_height_overlay.tile_set = chunk_manager.tileset
	_height_overlay.z_index = 0
	_height_overlay.modulate = Color(1, 1, 1, 0.4)
	add_child(_height_overlay)

	_cached_noise.seed = chunk_manager.world_seed
	var size := chunk_manager.chunk_size
	for lx in size:
		for ly in size:
			var gx := pc.x * size + lx
			var gy := pc.y * size + ly
			var h := _cached_noise.get_noise_2d(gx, gy)
			var t := _gen.height_rules.get_terrain_type(h)
			_height_overlay.set_cell(Vector2i(lx, ly), 1, Vector2i(t, 0))

	var origin := chunk_manager._tile_to_local(pc.x * size, pc.y * size)
	_height_overlay.global_position = origin
	_last_overlay_chunk = pc

func _clear_height_overlay() -> void:
	if _height_overlay != null:
		_height_overlay.queue_free()
		_height_overlay = null

func _regenerate_terrain() -> void:
	var keys := chunk_manager._loaded_chunks.keys()
	for key in keys:
		chunk_manager._unload_chunk(key)
	_last_chunk = Vector2i(999999, 999999)

	chunk_manager.world_seed = randi()

	var pc := _get_player_chunk()
	chunk_manager._load_chunks_around(pc)
	_last_chunk = pc

	if _show_height_overlay:
		_build_height_overlay()

	print("地形已重新生成 | 新种子: %d" % chunk_manager.world_seed)
