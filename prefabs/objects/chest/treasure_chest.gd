# ==============================================================================
#   treasure_chest.gd
#   功能：宝箱控制器。按 F 交互开启，给予随机奖励（金币/生命/遗物）。
# ==============================================================================
extends StaticBody2D
class_name TreasureChest

# ========================== 枚举 ==========================
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

# ========================== 导出变量 ==========================
## 奖励稀有度（由 Spawner 根据 ring 设置）
@export var rarity: Rarity = Rarity.COMMON

# ========================== 节点引用 ==========================
@onready var interactable: InteractableArea = $InteractableArea
@onready var sprite: Sprite2D = $Sprite2D

# ========================== 状态变量 ==========================
var _is_opened: bool = false

# ========================== 稀有度权重表 ==========================
static var _rarity_weights: Dictionary = {
	Rarity.COMMON: 50.0,
	Rarity.UNCOMMON: 30.0,
	Rarity.RARE: 15.0,
	Rarity.EPIC: 4.0,
	Rarity.LEGENDARY: 1.0,
}

# ========================== 生命周期 ==========================
func _ready() -> void:
	interactable.prompt_text = "按 F 开启宝箱"
	interactable.interacted.connect(_on_interacted)

# ========================== 交互回调 ==========================
func _on_interacted() -> void:
	if _is_opened:
		return
	_is_opened = true
	interactable.prompt_text = ""

	# 播放开启动画（简单缩放效果）
	var tween := create_tween()
	tween.tween_property(sprite, "scale:y", 0.6, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_give_reward)

# ========================== 奖励发放 ==========================
func _give_reward() -> void:
	match rarity:
		Rarity.COMMON:
			CurrencyManager.add_coin(randi_range(5, 15))
		Rarity.UNCOMMON:
			CurrencyManager.add_coin(randi_range(15, 30))
		Rarity.RARE:
			CurrencyManager.add_coin(randi_range(30, 60))
		Rarity.EPIC:
			CurrencyManager.add_coin(randi_range(60, 100))
		Rarity.LEGENDARY:
			CurrencyManager.add_coin(randi_range(100, 200))

	UIManager.show_message("获得 %s 级奖励！" % _rarity_to_string(rarity))

	if Global.DEBUG_MODE:
		print("[TreasureChest] 开启，稀有度: ", _rarity_to_string(rarity))

# ========================== 静态方法 ==========================
## 功能：根据 ring 数选择随机稀有度（ring 越高，高稀有度权重越高）
static func roll_rarity(ring: int) -> Rarity:
	var adjusted_weights := _rarity_weights.duplicate()
	# ring 提升高稀有度权重
	var bonus: float = ring * 3.0
	adjusted_weights[Rarity.UNCOMMON] += bonus * 0.5
	adjusted_weights[Rarity.RARE] += bonus * 0.3
	adjusted_weights[Rarity.EPIC] += bonus * 0.15
	adjusted_weights[Rarity.LEGENDARY] += bonus * 0.05

	var total_weight: float = 0.0
	for w in adjusted_weights.values():
		total_weight += w

	var roll := randf() * total_weight
	var cumulative := 0.0
	for rarity_val in adjusted_weights:
		cumulative += adjusted_weights[rarity_val]
		if roll < cumulative:
			return rarity_val
	return Rarity.COMMON

static func _rarity_to_string(r: Rarity) -> String:
	match r:
		Rarity.COMMON: return "普通"
		Rarity.UNCOMMON: return "优良"
		Rarity.RARE: return "稀有"
		Rarity.EPIC: return "史诗"
		Rarity.LEGENDARY: return "传说"
	return "未知"
