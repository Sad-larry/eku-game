# ==============================================================================
#   RadialGridMap.gd
#   功能：生成完成后的完整地图数据——可直接序列化存档
#         包含菱形网格的所有单元格数据、坐标索引、邻居查询及圈层操作
# ==============================================================================

class_name RadialGridMap
extends Resource

# ========================== 导出变量 ==========================

## 地图生成时使用的配置资源
@export var config: RadialGridConfig

## 所有单元格数据的数组
@export var cells: Array[CellData]

## 最大圈层数（0 为起点，1~N 为向外扩散的圈）
@export var max_ring: int

## 单元格总数
@export var total_cells: int

# ========================== 内部索引 ==========================

## 运行时索引：格式 "x,y" → CellData，用于快速坐标查询
var _cell_by_coord: Dictionary = {}

# ========================== 索引构建 ==========================

## 功能：构建坐标索引，生成或反序列化后需显式调用
## 将 cells 数组中的所有单元格按坐标字符串存入字典，提升查询性能
func _build_index() -> void:
	_cell_by_coord.clear()
	for cell in cells:
		_cell_by_coord["%d,%d" % [cell.coord.x, cell.coord.y]] = cell

# ========================== 查询方法 ==========================

## 功能：获取指定坐标的单元格
## 参数：x - X 坐标，y - Y 坐标
## 返回值：CellData - 找到的单元格数据，不存在返回 null
func get_cell(x: int, y: int) -> CellData:
	return _cell_by_coord.get("%d,%d" % [x, y], null)

## 功能：获取指定坐标的四个正交邻居（存在则返回）
## 参数：x - X 坐标，y - Y 坐标
## 返回值：Array[CellData] - 存在的邻居单元格数组（顺序：右、左、下、上）
func get_neighbors(x: int, y: int) -> Array[CellData]:
	var result: Array[CellData] = []
	# 四个正交方向：[右, 左, 下, 上]
	for dir_data in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
		var neighbor := get_cell(x + dir_data[0], y + dir_data[1])
		if neighbor != null:
			result.append(neighbor)
	return result

## 功能：获取指定圈层的所有单元格
## 参数：ring - 圈层索引（0 为起点圈，1~N 为外层）
## 返回值：Array[CellData] - 该圈层包含的所有单元格数组
func get_ring_cells(ring: int) -> Array[CellData]:
	var result: Array[CellData] = []
	for cell in cells:
		if cell.ring == ring:
			result.append(cell)
	return result

## 功能：获取指定坐标已访问过的邻居（用于地图显示）
## 参数：x - X 坐标，y - Y 坐标
## 返回值：Array[CellData] - 已访问的邻居单元格数组
func get_visited_neighbors(x: int, y: int) -> Array[CellData]:
	var result: Array[CellData] = []
	for n in get_neighbors(x, y):
		if n.is_visited:
			result.append(n)
	return result

## 功能：获取指定坐标可通行的邻居（未被阻挡）
## 参数：x - X 坐标，y - Y 坐标
## 返回值：Array[CellData] - 可通行的邻居单元格数组
func get_accessible_neighbors(x: int, y: int) -> Array[CellData]:
	var result: Array[CellData] = []
	for n in get_neighbors(x, y):
		if not _is_blocked(n):
			result.append(n)
	return result

# ========================== 辅助判断 ==========================

## 功能：判断单元格是否被阻挡（如未解锁的 Boss 房）
## 参数：_cell - 待判断的单元格数据
## 返回值：bool - 是否被阻挡（当前恒返回 false，预留扩展）
static func _is_blocked(_cell: CellData) -> bool:
	return false

# ========================== 距离计算 ==========================

## 功能：计算从中心到目标单元格的实际路径距离（以步数计）
## 参数：x - X 坐标，y - Y 坐标
## 返回值：int - 曼哈顿距离（即 |x| + |y|）
func calculate_distance(x: int, y: int) -> int:
	return abs(x) + abs(y)
