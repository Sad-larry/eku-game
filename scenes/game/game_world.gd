# ==============================================================================
#   GameWorld.gd
#   功能：游戏世界主入口场景
#         负责初始化房间地图系统，生成菱形网格地图并传递给区块加载器
# ==============================================================================

extends Node2D
class_name GameWorld

# ========================== 导出变量 ==========================

## 房间地图配置（菱形网格配置资源）
@export var room_map_config: RadialGridConfig

# ========================== 节点引用 ==========================

## 区块加载器节点引用
@onready var chunk_loader: ChunkLoader = $ChunkLoader

# ========================== 生命周期 ==========================

## 功能：节点进入场景树时调用
## 执行房间系统的初始化设置
func _ready() -> void:
	_setup_room_system()

# ========================== 私有方法 ==========================

## 功能：初始化房间地图系统
## 检查配置有效性，生成地图数据并注入到 ChunkLoader 中
func _setup_room_system() -> void:
	# 校验配置资源是否存在
	if room_map_config == null:
		print("[error] GameWorld: room_map_config 未设置")
		return
	
	# 生成地图数据并注入 ChunkLoader
	var generator := RadialGridGenerator.new()
	var map_data := generator.generate(room_map_config)
	chunk_loader.map_data = map_data
