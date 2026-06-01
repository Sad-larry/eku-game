# ==============================================================================
#   room_placeholder.gd
#   功能：房间占位图组件，用于显示房间的占位图视觉。
#         根据房间类型显示不同颜色的背景和标签。
# ==============================================================================
extends Node2D
class_name RoomPlaceholder

# ========================== 导出变量模块 ==========================
## 房间类型 ("start", "battle", "elite", "boss", "merchant", "treasure", "rest", "hidden", "trap", "npc", "teleport")
@export var room_type: String = "battle":
	set(value):
		room_type = value
		_update_visual()

## 房间坐标（用于显示标签）
@export var room_coord: Vector2i = Vector2i.ZERO:
	set(value):
		room_coord = value
		_update_visual()

## 房间尺寸
@export var room_size: Vector2 = Vector2(640, 360):
	set(value):
		room_size = value
		_update_visual()

## 是否显示网格地板
@export var show_floor: bool = true:
	set(value):
		show_floor = value
		_update_visual()

## 地板网格大小
@export var floor_grid_size: int = 32:
	set(value):
		floor_grid_size = value
		_update_visual()

## 是否显示墙壁
@export var show_walls: bool = true:
	set(value):
		show_walls = value
		_update_visual()

## 墙壁厚度
@export var wall_thickness: int = 16:
	set(value):
		wall_thickness = value
		_update_visual()

# ========================== 节点引用模块 ==========================
@onready var floor_node: Node2D = $Floor
@onready var walls_node: Node2D = $Walls
@onready var room_label: Label = $RoomLabel
@onready var coord_label: Label = $CoordLabel

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	_update_visual()

# ========================== 更新方法 ==========================
## 功能：更新房间视觉显示
func _update_visual() -> void:
	# 如果节点还未就绪，等待就绪后再更新
	if not is_inside_tree():
		return

	# 获取房间颜色
	var color: Color = PlaceholderFactory.ROOM_COLORS.get(room_type, Color(0.3, 0.3, 0.3))

	# 更新房间背景
	_update_background(color)

	# 更新地板
	if show_floor:
		_update_floor(color * 0.8)
	else:
		if floor_node:
			floor_node.visible = false

	# 更新墙壁
	if show_walls:
		_update_walls(color * 1.2)
	else:
		if walls_node:
			walls_node.visible = false

	# 更新标签
	_update_labels()

## 功能：更新房间背景
func _update_background(color: Color) -> void:
	# 清除旧的背景
	for child in get_children():
		if child.name.begins_with("Background"):
			child.queue_free()

	# 创建新背景
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.custom_minimum_size = room_size
	bg.size = room_size
	bg.position = -room_size / 2.0
	bg.color = color
	add_child(bg)

	# 确保背景在最底层
	move_child(bg, 0)

## 功能：更新地板显示
func _update_floor(color: Color) -> void:
	if not floor_node:
		floor_node = Node2D.new()
		floor_node.name = "Floor"
		add_child(floor_node)

	# 清除旧的地板
	for child in floor_node.get_children():
		child.queue_free()

	# 创建地板网格
	var tiles_x := int(room_size.x) / floor_grid_size
	var tiles_y := int(room_size.y) / floor_grid_size

	for x in tiles_x:
		for y in tiles_y:
			var tile := ColorRect.new()
			tile.custom_minimum_size = Vector2(floor_grid_size, floor_grid_size)
			tile.size = Vector2(floor_grid_size, floor_grid_size)
			tile.position = Vector2(x * floor_grid_size, y * floor_grid_size) - room_size / 2.0

			# 交替颜色创建棋盘格效果
			if (x + y) % 2 == 0:
				tile.color = color
			else:
				tile.color = color * 0.9

			floor_node.add_child(tile)

	floor_node.visible = true

## 功能：更新墙壁显示
func _update_walls(color: Color) -> void:
	if not walls_node:
		walls_node = Node2D.new()
		walls_node.name = "Walls"
		add_child(walls_node)

	# 清除旧的墙壁
	for child in walls_node.get_children():
		child.queue_free()

	# 创建墙壁
	# 上墙
	var top_wall := ColorRect.new()
	top_wall.custom_minimum_size = Vector2(room_size.x, wall_thickness)
	top_wall.size = Vector2(room_size.x, wall_thickness)
	top_wall.position = -room_size / 2.0
	top_wall.color = color
	walls_node.add_child(top_wall)

	# 下墙
	var bottom_wall := ColorRect.new()
	bottom_wall.custom_minimum_size = Vector2(room_size.x, wall_thickness)
	bottom_wall.size = Vector2(room_size.x, wall_thickness)
	bottom_wall.position = Vector2(-room_size.x / 2.0, room_size.y / 2.0 - wall_thickness)
	bottom_wall.color = color
	walls_node.add_child(bottom_wall)

	# 左墙
	var left_wall := ColorRect.new()
	left_wall.custom_minimum_size = Vector2(wall_thickness, room_size.y)
	left_wall.size = Vector2(wall_thickness, room_size.y)
	left_wall.position = -room_size / 2.0
	left_wall.color = color
	walls_node.add_child(left_wall)

	# 右墙
	var right_wall := ColorRect.new()
	right_wall.custom_minimum_size = Vector2(wall_thickness, room_size.y)
	right_wall.size = Vector2(wall_thickness, room_size.y)
	right_wall.position = Vector2(room_size.x / 2.0 - wall_thickness, -room_size.y / 2.0)
	right_wall.color = color
	walls_node.add_child(right_wall)

	walls_node.visible = true

## 功能：更新标签显示
func _update_labels() -> void:
	# 更新房间类型标签
	if room_label:
		room_label.text = room_type.to_upper()
		room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		room_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		room_label.size = room_size
		room_label.position = -room_size / 2.0
		room_label.add_theme_color_override("font_color", Color.WHITE)
		room_label.add_theme_font_size_override("font_size", 32)

	# 更新坐标标签
	if coord_label:
		coord_label.text = "(%d, %d)" % [room_coord.x, room_coord.y]
		coord_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		coord_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		coord_label.size = Vector2(room_size.x, 30)
		coord_label.position = Vector2(-room_size.x / 2.0, room_size.y / 2.0 - 30)
		coord_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		coord_label.add_theme_font_size_override("font_size", 14)

# ========================== 公共 API ==========================
## 功能：设置房间类型并更新显示
## 参数：type (String) - 房间类型
func set_room_type(type: String) -> void:
	room_type = type

## 功能：设置房间坐标
## 参数：coord (Vector2i) - 房间坐标
func set_room_coord(coord: Vector2i) -> void:
	room_coord = coord

## 功能：设置房间尺寸
## 参数：size (Vector2) - 房间尺寸
func set_room_size(size: Vector2) -> void:
	room_size = size

## 功能：获取当前房间颜色
## 返回值：Color - 当前房间类型的颜色
func get_room_color() -> Color:
	return PlaceholderFactory.ROOM_COLORS.get(room_type, Color(0.3, 0.3, 0.3))
