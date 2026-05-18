# ==============================================================================
#   coin_data.gd
#   功能：货币数据资源定义，用于配置不同类型的货币属性，
#        包括标识、名称、图标、价值、飘字颜色。
# ==============================================================================
extends Resource
class_name CoinData

# ========================== 导出变量模块 ==========================
## 货币唯一标识（如 "coin_copper", "coin_gold"）
@export var id: String = "coin_"

## 显示名称（如 "尘元", "稀有尘元"）
@export var display_name: String = "尘元"

## 图标/精灵纹理（用于 UI 显示和地面精灵，需为水平排列的 spritesheet）
@export var icon: Texture2D

## 每个货币的价值（默认 1）
@export var value: int = 1

## spritesheet 水平帧数（默认 6）
@export var hframes: int = 6

## 飘字颜色（默认黑色）
@export var color: Color = Color(0.0, 0.0, 0.0, 1.0)
