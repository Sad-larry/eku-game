# ==============================================================================
#   chunk_pool.gd
#   功能：TileMapLayer 对象池。当区块卸载时回收节点并清除数据，
#        新区块加载时优先从池中取用，避免反复构造/析构的开销。
#   用法：作为 ChunkManager 的同级子节点（命名为 ChunkPool），
#        ChunkManager 会自动检测并使用。
# ==============================================================================
extends Node
class_name ChunkPool

# ========================== 导出配置模块 ==========================
## 池最大容量（防止无限制增长）
@export var max_pool_size: int = 64

# ========================== 内部变量模块 ==========================
## 空闲 TileMapLayer 队列
var _pool: Array[TileMapLayer] = []

# ========================== 公共 API 模块 ==========================
## 功能：从池中借出一个 TileMapLayer。若池为空则新建一个。
## 返回值：TileMapLayer - 已清空的图层节点
func borrow() -> TileMapLayer:
	var layer: TileMapLayer
	if _pool.is_empty():
		layer = TileMapLayer.new()
	else:
		layer = _pool.pop_back()

	# 确保节点处于可复用的干净状态
	layer.tile_set = null
	return layer

## 功能：将使用完的 TileMapLayer 归还池中。
## 会清除所有瓦片数据并从父节点移除。
## 参数：layer (TileMapLayer) - 待回收的图层节点
func return_chunk(layer: TileMapLayer) -> void:
	if _pool.size() >= max_pool_size:
		layer.free()
		return

	# 清理瓦片数据
	layer.clear()
	layer.tile_set = null
	layer.name = "Chunk_Pooled"

	# 断开所有信号连接
	if layer.is_inside_tree():
		layer.remove_from_tree()

	# 重置变换
	layer.position = Vector2.ZERO
	layer.scale = Vector2.ONE
	layer.rotation = 0.0

	_pool.append(layer)

## 功能：预创建指定数量的 TileMapLayer 到池中
## 参数：count (int) - 预创建数量
func prewarm(count: int) -> void:
	var to_create := mini(count, max_pool_size - _pool.size())
	for _i in to_create:
		var layer := TileMapLayer.new()
		_pool.append(layer)

## 功能：获取池中当前空闲节点数
func get_pooled_count() -> int:
	return _pool.size()

## 功能：清空对象池
func clear_pool() -> void:
	for layer in _pool:
		layer.free()
	_pool.clear()
