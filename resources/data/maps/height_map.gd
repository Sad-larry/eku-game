# ==============================================================================
#   height_map.gd
#   功能：高度图数据结构，存储二维高度场的一维展平数组。
#         与区块瓦片网格 1:1 映射（区块 N×N 瓦片 → 高度图 N×N 采样点）。
#   用法：由 NoiseHeightGenerator 生成，或手动创建后通过 set_height() 赋值。
# ==============================================================================
extends RefCounted
class_name HeightMap

# ========================== 属性模块 ==========================
## 宽度（采样点数，通常 = 区块瓦片列数）
var width: int

## 高度（采样点数，通常 = 区块瓦片行数）
var height: int

## 一维展平数据数组，索引 = y * width + x
var _data: Array[float]

# ========================== 生命周期模块 ==========================
func _init(w: int, h: int) -> void:
	width = w
	height = h
	_data.resize(w * h)
	_data.fill(0.0)

# ========================== 读写接口模块 ==========================

## (x, y) 处的高度值
func get_height(x: int, y: int) -> float:
	if not _is_valid(x, y):
		return 0.0
	return _data[y * width + x]

## 设置 (x, y) 处的高度值
func set_height(x: int, y: int, value: float) -> void:
	if not _is_valid(x, y):
		return
	_data[y * width + x] = value

## 返回 [-1, 1] 范围内的高度值（与噪声输出直接衔接）
func get_normalized(x: int, y: int) -> float:
	return clampf(get_height(x, y), -1.0, 1.0)

## 计算 (x, y) 处的坡度方向（中心差分）
## 返回值：Vector2，指向坡度上升方向，可用于后续过渡瓦片选择
func get_gradient(x: int, y: int) -> Vector2:
	var left := get_height(max(x - 1, 0), y)
	var right := get_height(min(x + 1, width - 1), y)
	var top := get_height(x, max(y - 1, 0))
	var bottom := get_height(x, min(y + 1, height - 1))
	return Vector2(right - left, bottom - top) * 0.5

## 改变高度图尺寸
## interpolate = true 时使用双线性插值，否则使用最近邻
func resize(new_w: int, new_h: int, interpolate: bool = false) -> void:
	if new_w == width and new_h == height:
		return

	var new_data: Array[float] = []
	new_data.resize(new_w * new_h)

	for ny in new_h:
		for nx in new_w:
			if interpolate:
				new_data[ny * new_w + nx] = _sample_bilinear(nx, ny, new_w, new_h)
			else:
				var ox :int = int(float(nx) * width / new_w)
				var oy :int = int(float(ny) * height / new_h)
				new_data[ny * new_w + nx] = _data[oy * width + ox]

	width = new_w
	height = new_h
	_data = new_data

# ========================== 序列化模块 ==========================

## 序列化为 Dictionary（用于存档）
func serialize() -> Dictionary:
	return {
		"width": width,
		"height": height,
		"data": _data.duplicate(),
	}

## 从 Dictionary 反序列化恢复
func deserialize(data: Dictionary) -> void:
	width = data["width"]
	height = data["height"]
	_data = data["data"].duplicate()

# ========================== 工具方法模块 ==========================

## 坐标是否在有效范围内
func _is_valid(x: int, y: int) -> bool:
	return x >= 0 and x < width and y >= 0 and y < height

## 双线性插值采样（resize 插值模式用）
func _sample_bilinear(nx: int, ny: int, new_w: int, new_h: int) -> float:
	var sx := float(width) / new_w
	var sy := float(height) / new_h
	var fx := nx * sx
	var fy := ny * sy
	var ix := int(fx)
	var iy := int(fy)
	var frac_x := fx - ix
	var frac_y := fy - iy

	var x0 :int = clamp(ix, 0, width - 1)
	var x1 :int = clamp(ix + 1, 0, width - 1)
	var y0 :int = clamp(iy, 0, height - 1)
	var y1 :int = clamp(iy + 1, 0, height - 1)

	var v00 := _data[y0 * width + x0]
	var v10 := _data[y0 * width + x1]
	var v01 := _data[y1 * width + x0]
	var v11 := _data[y1 * width + x1]

	var v0 := lerpf(v00, v10, frac_x)
	var v1 := lerpf(v01, v11, frac_x)
	return lerpf(v0, v1, frac_y)
