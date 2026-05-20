# ==============================================================================
#   loot_system.gd
#   功能：掉落系统，当敌人死亡时在指定位置尝试生成战利品（金币、生命球、能量球），
#        掉落概率可通过导出变量调整，物品生成位置添加随机偏移。
# ==============================================================================
extends Node
class_name LootSystem

# ========================== 导出变量模块 ==========================
## 金币掉落物场景（需预先创建金币 PackedScene）
@export var coin_scene: PackedScene
## 生命回复球掉落物场景
@export var health_orb_scene: PackedScene
## 能量回复球掉落物场景
@export var energy_orb_scene: PackedScene
## 金币掉落概率（0.0 - 1.0），默认 25%
@export var coin_drop_rate: float = 0.25
## 生命球掉落概率（0.0 - 1.0），默认 10%
@export var health_orb_drop_rate: float = 0.1
## 能量球掉落概率（0.0 - 1.0），默认 8%
@export var energy_orb_drop_rate: float = 0.08

# ========================== 公共 API 模块 ==========================
## 功能：在敌人死亡位置尝试生成掉落物
## 参数：death_position (Vector2) - 敌人死亡的世界坐标
## 说明：根据概率逐个判定各类掉落物是否生成，每个物品独立判定互不影响。
func try_drop(death_position: Vector2) -> void:
	# 金币掉落判定
	if randf() < coin_drop_rate:
		var coin: Node2D = coin_scene.instantiate() as Node2D
		add_child(coin)
		coin.global_position = death_position + _random_offset()

	# 生命球掉落判定
	if randf() < health_orb_drop_rate:
		var orb: Node2D = health_orb_scene.instantiate() as Node2D
		add_child(orb)
		orb.global_position = death_position + _random_offset()

	# 能量球掉落判定
	if randf() < energy_orb_drop_rate:
		var orb: Node2D = energy_orb_scene.instantiate() as Node2D
		add_child(orb)
		orb.global_position = death_position + _random_offset()

# ========================== 辅助方法模块 ==========================
## 功能：生成随机偏移向量（用于掉落物位置微调，避免完全重叠）
## 返回值：Vector2 - 偏移量，范围 X/Y 均为 -30 ~ 30 像素
func _random_offset() -> Vector2:
	return Vector2(randf_range(-30, 30), randf_range(-30, 30))
