# ==============================================================================
#   IsoMovement.gd
#   功能：等距移动辅助类，提供标准四方向输入（WASD）到等距坐标系移动方向的转换，
#        以及屏幕坐标到等距世界坐标的转换（另一种实现）。
# ==============================================================================
extends RefCounted
class_name IsoMovement

# ========================== 静态方法模块 ==========================
## 功能：将标准四方向输入向量映射为等距移动方向
## 参数：input (Vector2) - 原始输入向量（x: 左负右正，y: 上负下正）
## 返回值：Vector2 - 等距坐标系下的单位移动方向向量
## 映射规则（标准 2:1 等距）：
##   - 右（+x）   -> 右下方向（iso_x = +1, iso_y = +0.5）
##   - 左（-x）   -> 左上方向（iso_x = -1, iso_y = -0.5）
##   - 上（-y）   -> 右上方向（iso_x = +1, iso_y = -0.5）
##   - 下（+y）   -> 左下方向（iso_x = -1, iso_y = +0.5）
## 公式推导：
##   iso_x = input.x - input.y
##   iso_y = (input.x + input.y) * 0.5
static func map_input_to_iso(input: Vector2) -> Vector2:
	var iso_x: float = input.x - input.y
	var iso_y: float = (input.x + input.y) * 0.5
	return Vector2(iso_x, iso_y).normalized()

## 功能：将屏幕坐标转换为等距世界坐标（2:1 等距逆向变换）
## 参数：screen_pos (Vector2) - 屏幕坐标（像素单位）
## 返回值：Vector2 - 等距世界坐标
## 说明：此变换基于 2:1 等距投影公式，与 IsometricCamera.world_to_screen 互为逆运算
## 公式推导：
##   world_x = screen_x / 2 + screen_y
##   world_y = screen_y - screen_x / 2
static func screen_to_world_position(screen_pos: Vector2) -> Vector2:
	var world_x: float = (screen_pos.x / 2.0) + screen_pos.y
	var world_y: float = screen_pos.y - (screen_pos.x / 2.0)
	return Vector2(world_x, world_y)
