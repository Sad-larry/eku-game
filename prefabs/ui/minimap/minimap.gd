# ==============================================================================
#   minimap.gd
#   功能：等距风格小地图，显示已探索房间的网格布局。
#        使用等距投影坐标转换，每个房间用菱形色块表示。
# ==============================================================================
# [重构注释] 2.5D等距地图相关代码已暂时禁用
# extends Control
# class_name Minimap
#
# # ========================== 常量定义模块 ==========================
# ## 等距投影矩阵（复用 IsometricCamera 的坐标转换）
# const ISO_MATRIX: Transform2D = Transform2D(
# 	Vector2(1.0, 0.5),
# 	Vector2(-1.0, 0.5),
# 	Vector2.ZERO
# )
#
# ## 房间色块大小（等距菱形半径）
# const CELL_SIZE: float = 20.0
# ## 网格间距
# const GRID_SPACING: float = 2.0
#
# ## 事件类型颜色映射
# const EVENT_COLORS: Dictionary = {
# 	"start": Color(0.2, 0.8, 0.2),     # 绿色 - 起点
# 	"battle": Color(0.8, 0.2, 0.2),     # 红色 - 战斗
# 	"elite": Color(0.9, 0.5, 0.1),      # 橙色 - 精英
# 	"boss": Color(0.6, 0.1, 0.6),       # 紫色 - Boss
# 	"merchant": Color(0.9, 0.8, 0.2),   # 金色 - 商人
# 	"treasure": Color(0.2, 0.7, 0.7),   # 青色 - 宝箱
# 	"rest": Color(0.4, 0.9, 0.4),       # 浅绿 - 休息
# 	"hidden": Color(0.5, 0.5, 0.5),     # 灰色 - 隐藏
# }
#
# # ========================== 变量定义模块 ==========================
# ## 已探索的房间数据：key = "x,y" -> CellData
# var _explored_rooms: Dictionary = {}
#
# # ========================== 生命周期模块 ==========================
# func _ready() -> void:
# 	# 连接房间信号
# 	RoomManager.room_entered.connect(_on_room_entered)
# 	RoomManager.room_cleared.connect(_on_room_cleared)
# 	# 监听导航管理器的房间切换
# 	RoomNavigationManager.room_transition_requested.connect(_on_room_transition)
#
# func _draw() -> void:
# 	_draw_grid()
#
# # ========================== 绘制方法 ==========================
# func _draw_grid() -> void:
# 	var center := size / 2.0
# 	var current_coord := RoomNavigationManager.current_coord
#
# 	for key in _explored_rooms:
# 		var cell: CellData = _explored_rooms[key]
# 		var coord := cell.get_coord_vec()
# 		# 计算相对坐标
# 		var rel := Vector2(coord - current_coord)
# 		# 等距投影
# 		var screen_pos := center + ISO_MATRIX * rel * (CELL_SIZE + GRID_SPACING)
# 		# 获取颜色
# 		var color := _get_cell_color(cell)
# 		# 绘制菱形
# 		_draw_diamond(screen_pos, CELL_SIZE, color)
# 		# 高亮当前房间
# 		if coord == current_coord:
# 			_draw_diamond(screen_pos, CELL_SIZE + 2, Color.WHITE, false)
#
# func _draw_diamond(pos: Vector2, size: float, color: Color, filled: bool = true) -> void:
# 	var points: PackedVector2Array = [
# 		pos + Vector2(0, -size * 0.5),     # 上
# 		pos + Vector2(size * 0.5, 0),      # 右
# 		pos + Vector2(0, size * 0.5),      # 下
# 		pos + Vector2(-size * 0.5, 0),     # 左
# 	]
# 	if filled:
# 		draw_colored_polygon(points, color)
# 	else:
# 		points.append(points[0])
# 		draw_polyline(points, color, 2.0)
#
# func _get_cell_color(cell: CellData) -> Color:
# 	if RoomManager.is_cleared(cell.get_coord_vec()):
# 		return Color(0.3, 0.3, 0.3)  # 已清除 - 暗灰
# 	return EVENT_COLORS.get(cell.event_type, Color(0.6, 0.6, 0.6))  # 默认灰色
#
# # ========================== 信号回调 ==========================
# func _on_room_entered(coord: Vector2i, _ring: int, _event_type: String) -> void:
# 	var key := "%d,%d" % [coord.x, coord.y]
# 	if not _explored_rooms.has(key):
# 		# 从地图数据获取 CellData
# 		var cell := _get_cell_data(coord)
# 		if cell:
# 			_explored_rooms[key] = cell
# 	queue_redraw()
#
# func _on_room_cleared(_coord: Vector2i) -> void:
# 	queue_redraw()
#
# func _on_room_transition(_target_coord: Vector2i) -> void:
# 	queue_redraw()
#
# func _get_cell_data(coord: Vector2i) -> CellData:
# 	# 通过 RoomNavigationManager 的地图数据获取
# 	if RoomNavigationManager._map_data:
# 		return RoomNavigationManager._map_data.get_cell(coord.x, coord.y)
# 	return null
