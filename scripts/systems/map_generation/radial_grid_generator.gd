# ==============================================================================
#   RadialGridGenerator.gd
#   功能：菱形网格地图生成器——从 RadialGridConfig 生成完整的 RadialGridMap
#         负责坐标生成、保证事件放置、权重填充及调试输出
# ==============================================================================
extends RefCounted
class_name RadialGridGenerator

# ========================== 公共 API 模块 ==========================
## 功能：主入口：生成完整地图数据
## 参数：config - 菱形网格配置资源（包含圈数、种子、事件池等）
## 返回值：RadialGridMap - 生成完成的地图数据对象
func generate(config: RadialGridConfig) -> RadialGridMap:
	# 初始化随机数生成器
	var rng := RandomNumberGenerator.new()
	if config.world_seed != 0:
		rng.seed = config.world_seed

	# 创建地图容器
	var map := RadialGridMap.new()
	map.config = config
	map.max_ring = config.max_ring

	# 生成所有网格坐标点
	_generate_coords(map, config.max_ring)
	map._build_index()

	# 放置固定保证事件（起点、Boss、配置的特殊事件）
	_place_guaranteed_events(map, config, rng)

	# 填充剩余未分配的格子（按圈层权重随机）
	_fill_remaining_cells(map, config, rng)

	# 调试输出网格信息
	#print_grid_pretty(map, config.max_ring)

	map.total_cells = map.cells.size()
	return map

# ========================== 私有方法模块 ==========================
## 功能：在菱形区域内生成所有坐标 (abs(x) + abs(y) <= max_ring)
## 参数：map - 目标地图对象，max_ring - 最大圈层数
func _generate_coords(map: RadialGridMap, max_ring: int) -> void:
	for x in range(-max_ring, max_ring + 1):
		for y in range(-max_ring, max_ring + 1):
			# 菱形范围判定：曼哈顿距离不超过最大圈层
			if abs(x) + abs(y) <= max_ring:
				var cell := CellData.new()
				cell.coord = {"x": x, "y": y}
				cell.ring = abs(x) + abs(y)
				map.cells.append(cell)

## 功能：放置保证事件（起点、Boss、固定圈层的特殊事件）
## 参数：map - 地图对象，config - 配置资源，rng - 随机数生成器
func _place_guaranteed_events(map: RadialGridMap, config: RadialGridConfig, rng: RandomNumberGenerator) -> void:
	# 1. 中心格始终为起点
	var center := _find_cell(map, 0, 0)
	if center != null:
		center.event_type = "start"

	# 2. 最外圈放置 Boss 房
	var outer_cells := map.get_ring_cells(config.max_ring)
	if not outer_cells.is_empty():
		var boss_cell := outer_cells[rng.randi() % outer_cells.size()]
		boss_cell.event_type = "boss"

	# 3. 按配置放置各圈层的保证事件
	for ge in config.guaranteed_events:
		# 跳过起点圈层（ring_index < 1）和最外圈（已设置 Boss）
		if ge.ring_index < 1 or ge.ring_index >= config.max_ring:
			continue

		var ring_cells := map.get_ring_cells(ge.ring_index)

		# 收集该圈层中尚未分配事件的格子
		var unassigned: Array[CellData] = []
		for c in ring_cells:
			if c.event_type.is_empty():
				unassigned.append(c)

		if unassigned.is_empty():
			continue

		# 随机选择一个未分配格子放置保证事件
		var idx := rng.randi() % unassigned.size()
		unassigned[idx].event_type = GuaranteedEventInfo.type_to_string(ge.event_type)

	# 4. 剩余未分配的标记为 "unassigned" 以待后续填充
	for cell in map.cells:
		if cell.event_type.is_empty():
			cell.event_type = "unassigned"

## 功能：用圈层权重表填充所有未分配的格子
## 参数：map - 地图对象，config - 配置资源，rng - 随机数生成器
func _fill_remaining_cells(map: RadialGridMap, config: RadialGridConfig, rng: RandomNumberGenerator) -> void:
	for cell in map.cells:
		# 仅处理标记为 "unassigned" 的格子
		if cell.event_type != "unassigned":
			continue

		var pool := _find_pool(config, cell.ring)
		if pool == null:
			# 无权重池时默认使用战斗事件
			cell.event_type = "battle"
		else:
			cell.event_type = pool.pick_event(rng)

## 功能：查找指定圈层的事件权重池
## 参数：config - 配置资源，ring - 圈层索引
## 返回值：RingEventPool - 找到的权重池，无匹配返回 null
static func _find_pool(config: RadialGridConfig, ring: int) -> RingEventPool:
	for pool in config.ring_event_pools:
		if pool.ring_index == ring:
			return pool
	return null

## 功能：在地图中查找指定坐标的单元格
## 参数：map - 地图对象，x - X 坐标，y - Y 坐标
## 返回值：CellData - 找到的格子数据，不存在返回 null
static func _find_cell(map: RadialGridMap, x: int, y: int) -> CellData:
	return map.get_cell(x, y)

## 功能：自适应任意大小 + 等宽对齐 + 美观排版打印网格信息
## 参数：map - 地图对象，mxmy - 最大半径（用于确定边界范围）
func print_grid_pretty(map: RadialGridMap, mxmy: int) -> void:
	var cell_array = map.cells
	var cell_map = {}
	var all_coords = []

	# 构建坐标到格子的映射表
	for cell in cell_array:
		var vec = cell.get_coord_vec()
		cell_map[vec] = cell
		all_coords.append(vec)

	if all_coords.is_empty():
		print("网格为空")
		return

	# 确定打印边界
	var min_x = -mxmy
	var max_x = mxmy
	var min_y = -mxmy
	var max_y = mxmy

	const CELL_WIDTH = 10

	print("\n========== 坐标网格 ==========")

	# 逐行打印网格（包含坐标标识和事件类型）
	for y in range(min_y, max_y + 1):
		var line = ""

		# 第一行：坐标字符串
		for x in range(min_x, max_x + 1):
			var text = "(%d,%d)" % [x, y] if cell_map.has(Vector2i(x, y)) else ""
			line += text.rpad(CELL_WIDTH)
		line += "\n"

		# 第二行：事件类型
		for x in range(min_x, max_x + 1):
			var pos = Vector2i(x, y)
			var text = str("[", cell_map[pos].event_type, "]") if cell_map.has(pos) else ""
			line += text.rpad(CELL_WIDTH)

		print(line)
