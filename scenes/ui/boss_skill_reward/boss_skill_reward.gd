# ==============================================================================
#   boss_skill_reward.gd
#   功能：BOSS技能奖励UI，显示击败BOSS后获得的技能。
# ==============================================================================
extends Control

## 信号：奖励领取完成
signal reward_claimed

## 技能图标
@onready var skill_icon: TextureRect = $VBoxContainer/SkillIcon
## 技能名称
@onready var skill_name: Label = $VBoxContainer/SkillName
## 技能描述
@onready var skill_description: Label = $VBoxContainer/SkillDescription
## 领取按钮
@onready var claim_button: Button = $VBoxContainer/ClaimButton

## 当前显示的技能
var _current_skill: SkillEffect

func _ready() -> void:
	claim_button.pressed.connect(_on_claim_pressed)
	hide()

## 显示技能奖励
func show_reward(skill: SkillEffect) -> void:
	if skill == null:
		return

	_current_skill = skill

	# 更新UI
	if skill_name:
		skill_name.text = skill.name
	if skill_description:
		skill_description.text = skill.description
	if skill_icon and skill.icon:
		skill_icon.texture = skill.icon

	show()

## 领取按钮点击
func _on_claim_pressed() -> void:
	if _current_skill == null:
		return

	# 解锁技能（后期系统禁用时跳过）
	if SkillUnlockManager.ENABLED:
		SkillUnlockManager.unlock_skill_by_id(_current_skill.id)

	# 隐藏UI
	hide()

	# 发射信号
	reward_claimed.emit()

	if Global.DEBUG_MODE:
		print("[BossSkillReward] 领取技能: ", _current_skill.name)
