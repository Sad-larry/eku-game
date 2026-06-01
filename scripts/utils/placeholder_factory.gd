# ==============================================================================
#   placeholder_factory.gd
#   功能：占位图工厂类，用于生成带标签的彩色方框/圆形占位图。
#         在开发阶段替代实际美术资源，快速搭建可玩原型。
# ==============================================================================
class_name PlaceholderFactory

# ========================== 预定义颜色常量 ==========================
## 玩家颜色（蓝色系）
const PLAYER_COLOR: Color = Color(0.2, 0.4, 0.9, 0.8)
## 敌人颜色（红色系）
const ENEMY_COLOR: Color = Color(0.9, 0.2, 0.2, 0.8)
## 精英敌人颜色（橙色系）
const ELITE_COLOR: Color = Color(0.95, 0.5, 0.1, 0.8)
## Boss颜色（紫色系）
const BOSS_COLOR: Color = Color(0.7, 0.1, 0.8, 0.8)
## NPC颜色（绿色系）
const NPC_COLOR: Color = Color(0.2, 0.8, 0.3, 0.8)
## 物品颜色（金色系）
const ITEM_COLOR: Color = Color(0.9, 0.8, 0.2, 0.8)
## 陷阱颜色（暗红色）
const TRAP_COLOR: Color = Color(0.6, 0.1, 0.1, 0.8)
## 传送门颜色（青色）
const PORTAL_COLOR: Color = Color(0.1, 0.8, 0.8, 0.8)

## 房间类型颜色映射
const ROOM_COLORS: Dictionary = {
	"start": Color(0.2, 0.8, 0.2),      # 绿色 - 起点
	"battle": Color(0.8, 0.2, 0.2),      # 红色 - 战斗
	"elite": Color(0.9, 0.5, 0.1),       # 橙色 - 精英
	"boss": Color(0.6, 0.1, 0.6),        # 紫色 - Boss
	"merchant": Color(0.9, 0.8, 0.2),    # 金色 - 商人
	"treasure": Color(0.2, 0.7, 0.7),    # 青色 - 宝箱
	"rest": Color(0.4, 0.9, 0.4),        # 浅绿 - 休息
	"hidden": Color(0.5, 0.5, 0.5),      # 灰色 - 隐藏
	"trap": Color(0.6, 0.1, 0.1),        # 暗红 - 陷阱
	"npc": Color(0.3, 0.6, 0.3),         # 深绿 - NPC
	"teleport": Color(0.1, 0.6, 0.8),    # 蓝色 - 传送
}

# ========================== 静态方法模块 ==========================
## 功能：创建一个带标签的彩色方框占位图
## 参数：
##   size - 方框尺寸 (Vector2)
##   color - 方框颜色 (Color)
##   label_text - 标签文字 (String)
##   label_color - 标签颜色 (Color，默认白色)
## 返回值：Node2D - 包含 ColorRect 和 Label 的占位图节点
static func create_rect_placeholder(
	size: Vector2,
	color: Color,
	label_text: String,
	label_color: Color = Color.WHITE
) -> Node2D:
	var root := Node2D.new()
	root.name = "Placeholder_" + label_text

	# 创建背景方框
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.custom_minimum_size = size
	bg.size = size
	bg.position = -size / 2.0  # 居中
	bg.color = color
	root.add_child(bg)

	# 创建边框（稍大的半透明方框）
	var border := ColorRect.new()
	border.name = "Border"
	border.custom_minimum_size = size + Vector2(2, 2)
	border.size = size + Vector2(2, 2)
	border.position = -size / 2.0 - Vector2(1, 1)
	border.color = Color(1, 1, 1, 0.3)
	root.add_child(border)

	# 将背景移到边框前面
	root.move_child(bg, 1)

	# 创建标签
	var label := Label.new()
	label.name = "Label"
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = size
	label.position = -size / 2.0
	label.add_theme_color_override("font_color", label_color)
	label.add_theme_font_size_override("font_size", 10)
	root.add_child(label)

	return root


## 功能：创建一个带标签的彩色圆形占位图
## 参数：
##   radius - 圆形半径 (float)
##   color - 圆形颜色 (Color)
##   label_text - 标签文字 (String)
##   label_color - 标签颜色 (Color，默认白色)
## 返回值：Node2D - 包含 ColorRect(圆形) 和 Label 的占位图节点
static func create_circle_placeholder(
	radius: float,
	color: Color,
	label_text: String,
	label_color: Color = Color.WHITE
) -> Node2D:
	var root := Node2D.new()
	root.name = "Placeholder_" + label_text

	# 创建圆形（使用 ColorRect + 圆形着色器或直接用 TextureRect）
	# 这里简化为方框，后续可扩展为圆形
	var size := Vector2(radius * 2, radius * 2)

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.custom_minimum_size = size
	bg.size = size
	bg.position = -size / 2.0
	bg.color = color
	root.add_child(bg)

	# 创建标签
	var label := Label.new()
	label.name = "Label"
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = size
	label.position = -size / 2.0
	label.add_theme_color_override("font_color", label_color)
	label.add_theme_font_size_override("font_size", 10)
	root.add_child(label)

	return root


## 功能：根据实体类型创建对应的占位图
## 参数：
##   entity_type - 实体类型字符串 ("player", "enemy", "elite", "boss", "npc", "item", "trap", "portal")
##   size - 占位图尺寸 (Vector2，默认 32x32)
##   custom_label - 自定义标签文字（可选，默认使用类型名）
## 返回值：Node2D - 占位图节点
static func create_entity_placeholder(
	entity_type: String,
	size: Vector2 = Vector2(32, 32),
	custom_label: String = ""
) -> Node2D:
	var color: Color
	var label: String

	match entity_type:
		"player":
			color = PLAYER_COLOR
			label = custom_label if custom_label != "" else "玩家"
		"enemy":
			color = ENEMY_COLOR
			label = custom_label if custom_label != "" else "敌人"
		"elite":
			color = ELITE_COLOR
			label = custom_label if custom_label != "" else "精英"
		"boss":
			color = BOSS_COLOR
			label = custom_label if custom_label != "" else "Boss"
		"npc":
			color = NPC_COLOR
			label = custom_label if custom_label != "" else "NPC"
		"item":
			color = ITEM_COLOR
			label = custom_label if custom_label != "" else "物品"
		"trap":
			color = TRAP_COLOR
			label = custom_label if custom_label != "" else "陷阱"
		"portal":
			color = PORTAL_COLOR
			label = custom_label if custom_label != "" else "传送门"
		_:
			color = Color(0.5, 0.5, 0.5, 0.8)
			label = custom_label if custom_label != "" else entity_type

	return create_rect_placeholder(size, color, label)


## 功能：根据房间类型创建对应的占位图
## 参数：
##   room_type - 房间类型字符串 ("start", "battle", "elite", "boss", "merchant", "treasure", "rest", "hidden", "trap", "npc", "teleport")
##   size - 占位图尺寸 (Vector2，默认 640x360)
## 返回值：Node2D - 房间占位图节点
static func create_room_placeholder(
	room_type: String,
	size: Vector2 = Vector2(640, 360)
) -> Node2D:
	var color: Color = ROOM_COLORS.get(room_type, Color(0.3, 0.3, 0.3))

	var root := Node2D.new()
	root.name = "Room_" + room_type

	# 创建房间背景
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.custom_minimum_size = size
	bg.size = size
	bg.position = -size / 2.0
	bg.color = color
	root.add_child(bg)

	# 创建房间标签
	var label := Label.new()
	label.name = "RoomLabel"
	label.text = room_type.to_upper()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = size
	label.position = -size / 2.0
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 24)
	root.add_child(label)

	# 创建房间边框
	var border := ColorRect.new()
	border.name = "Border"
	border.custom_minimum_size = size + Vector2(4, 4)
	border.size = size + Vector2(4, 4)
	border.position = -size / 2.0 - Vector2(2, 2)
	border.color = Color(1, 1, 1, 0.5)
	root.add_child(border)

	# 确保正确的绘制顺序
	root.move_child(bg, 1)
	root.move_child(label, 2)

	return root


## 功能：创建地板占位图（用于房间地面）
## 参数：
##   size - 地板尺寸 (Vector2)
##   tile_color - 瓦片颜色 (Color)
##   grid_size - 网格大小 (int，默认 32)
## 返回值：Node2D - 地板占位图节点
static func create_floor_placeholder(
	size: Vector2,
	tile_color: Color = Color(0.3, 0.3, 0.3, 0.5),
	grid_size: int = 32
) -> Node2D:
	var root := Node2D.new()
	root.name = "Floor"

	# 创建网格地板
	var tiles_x := int(size.x) / grid_size
	var tiles_y := int(size.y) / grid_size

	for x in tiles_x:
		for y in tiles_y:
			var tile := ColorRect.new()
			tile.custom_minimum_size = Vector2(grid_size, grid_size)
			tile.size = Vector2(grid_size, grid_size)
			tile.position = Vector2(x * grid_size, y * grid_size) - size / 2.0

			# 交替颜色创建棋盘格效果
			if (x + y) % 2 == 0:
				tile.color = tile_color
			else:
				tile.color = tile_color * 0.8

			root.add_child(tile)

	return root


## 功能：创建墙壁占位图（用于房间边界）
## 参数：
##   size - 墙壁尺寸 (Vector2)
##   wall_color - 墙壁颜色 (Color)
##   wall_thickness - 墙壁厚度 (int，默认 16)
## 返回值：Node2D - 墙壁占位图节点
static func create_wall_placeholder(
	size: Vector2,
	wall_color: Color = Color(0.4, 0.4, 0.4, 0.8),
	wall_thickness: int = 16
) -> Node2D:
	var root := Node2D.new()
	root.name = "Walls"

	# 上墙
	var top_wall := ColorRect.new()
	top_wall.custom_minimum_size = Vector2(size.x, wall_thickness)
	top_wall.size = Vector2(size.x, wall_thickness)
	top_wall.position = -size / 2.0
	top_wall.color = wall_color
	root.add_child(top_wall)

	# 下墙
	var bottom_wall := ColorRect.new()
	bottom_wall.custom_minimum_size = Vector2(size.x, wall_thickness)
	bottom_wall.size = Vector2(size.x, wall_thickness)
	bottom_wall.position = Vector2(-size.x / 2.0, size.y / 2.0 - wall_thickness)
	bottom_wall.color = wall_color
	root.add_child(bottom_wall)

	# 左墙
	var left_wall := ColorRect.new()
	left_wall.custom_minimum_size = Vector2(wall_thickness, size.y)
	left_wall.size = Vector2(wall_thickness, size.y)
	left_wall.position = -size / 2.0
	left_wall.color = wall_color
	root.add_child(left_wall)

	# 右墙
	var right_wall := ColorRect.new()
	right_wall.custom_minimum_size = Vector2(wall_thickness, size.y)
	right_wall.size = Vector2(wall_thickness, size.y)
	right_wall.position = Vector2(size.x / 2.0 - wall_thickness, -size.y / 2.0)
	right_wall.color = wall_color
	root.add_child(right_wall)

	return root
