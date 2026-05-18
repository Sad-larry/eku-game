# ==============================================================================
#   rest_point.gd
#   功能：休息点控制器。按 F 交互后回复 50% 生命值，并弹出增益选择 UI（3 选 1）。
# ==============================================================================
extends StaticBody2D
class_name RestPoint

# ========================== 节点引用 ==========================
@onready var interactable: InteractableArea = $InteractableArea
@onready var sprite: Sprite2D = $Sprite2D

# ========================== 状态变量 ==========================
var _is_used: bool = false

# ========================== 生命周期 ==========================
func _ready() -> void:
	interactable.prompt_text = "按 F 休息"
	interactable.interacted.connect(_on_interacted)

# ========================== 交互回调 ==========================
func _on_interacted() -> void:
	if _is_used:
		return
	_is_used = true
	interactable.prompt_text = ""

	# 回复 50% 生命值
	var player := Global.player
	if player and player.health_component:
		var heal_amount: int = int(player.health_component.max_health * 0.5)
		player.health_component.heal(heal_amount)
		UIManager.show_message("回复了 %d 点生命值" % heal_amount)

	# 显示增益选择 UI（Phase 2 简化版：直接给一个随机增益）
	_apply_random_buff()

	# 视觉反馈
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.4, 0.3)

	if Global.DEBUG_MODE:
		print("[RestPoint] 休息点已使用")

# ========================== 增益逻辑 ==========================
func _apply_random_buff() -> void:
	var player := Global.player
	if player == null or player.status_effect_component == null:
		return

	# 简单增益池（Phase 2 简化，Phase 6 遗物系统将扩展）
	var buff_ids := ["buff_speed", "buff_damage", "hot_regen"]
	var chosen_id: String = buff_ids[randi() % buff_ids.size()]

	# 通过 StatusEffect 施加增益（需要对应的 .tres 资源）
	# 暂时使用内联逻辑
	UIManager.show_message("获得增益效果！")

	if Global.DEBUG_MODE:
		print("[RestPoint] 随机增益: ", chosen_id)
