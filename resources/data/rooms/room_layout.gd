# ==============================================================================
#   room_layout.gd
#   功能：地形布局资源，定义房间的"骨架"（地形 + 碰撞 + 生成点占位符）。
#        多个 RoomConfig 可以引用同一个 RoomLayout 实例，实现地形复用。
# ==============================================================================
extends Resource
class_name RoomLayout

# ========================== 导出变量模块 ==========================
# ----- 地形配置（二选一，推荐方式 A）-----
## 方式 A：指向一个纯地形场景（.tscn）
## 该场景只包含 TileMap、碰撞体，不包含任何实体（敌人、道具等）
@export var terrain_scene: PackedScene

## 方式 B：直接序列化 TileMapLayer 数据（备选方案，方式 A 不可用时使用）
@export var tilemap_data: PackedByteArray

# ----- 生成点模板 -----
## 定义房间中所有可能的生成位置（占位符）
## 具体房间配置（RoomConfig）可以通过 spawn_overrides 覆盖每个位置的具体内容
@export var spawn_marker_templates: Array[SpawnMarkerTemplate]

# ----- 相机边界（可选）-----
## 相机在此房间内的限制边界（最小 X、最小 Y、宽度、高度）
@export var camera_limits: Rect2

# ========================== 内嵌类定义模块 ==========================
## 生成点模板 — 定义单个生成点的位置和类型
class SpawnMarkerTemplate:
	extends Resource
	
	## 唯一标识符，如 "enemy_01"、"player_start"、"exit_point"
	@export var marker_id: String
	
	## 生成点在房间局部坐标系中的位置
	@export var local_position: Vector2
	
	## 生成点分组，可选值："enemy"（敌人）、"player"（玩家起始）、"exit"（出口）、"item"（道具）
	@export var marker_group: String

# ========================== 辅助方法模块 ==========================
## 功能：根据 marker_id 查找模板索引
## 参数：marker_id (String) - 生成点唯一标识符
## 返回值：int - 模板在数组中的索引，未找到返回 -1
func find_template_index(marker_id: String) -> int:
	for i in spawn_marker_templates.size():
		if spawn_marker_templates[i].marker_id == marker_id:
			return i
	return -1

## 功能：根据 marker_group 筛选所有匹配的模板
## 参数：group (String) - 生成点分组名称（如 "enemy"、"player"）
## 返回值：Array[SpawnMarkerTemplate] - 匹配的模板数组
func get_templates_by_group(group: String) -> Array[SpawnMarkerTemplate]:
	var result: Array[SpawnMarkerTemplate] = []
	for t in spawn_marker_templates:
		if t.marker_group == group:
			result.append(t)
	return result
