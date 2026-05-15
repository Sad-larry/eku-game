# ==============================================================================
#   skill_runner.gd
#   功能：技能运行时容器，管理单个技能实例的冷却计时、伤害计算、特效播放。
#        每个技能实例对应一个独立的 SkillRunner，由玩家或实体持有。
#   设计原则：冷却倒计时在此处计算，通过信号逐帧通知外部（如 HUD），
#            外部仅做展示，不重复计算。
# ==============================================================================
extends Node
class_name SkillRunner

# ========================== 信号声明模块 ==========================
## 触发时机：冷却进度更新（每帧发射，供 HUD 等 UI 实时显示冷却进度）
## 参数：remaining (float) - 剩余冷却时间（秒）；total (float) - 总冷却时间（秒）
signal cooldown_updated(remaining: float, total: float)

## 触发时机：冷却结束
signal cooldown_finished()

# ========================== 变量定义模块 ==========================
## 技能数据资源（包含冷却、伤害、特效等配置）
var skill_data: SkillEffect

## 施法者（通常是战斗实体，如玩家）
var caster: Node2D

## 伤害计算器实例（复用减少内存分配）
var _calculator = DamageCalculator.new()

## 剩余冷却时间（秒），0 表示无冷却
var _cooldown_remaining: float = 0.0

# ========================== 生命周期模块 ==========================
## 功能：初始化技能运行器。
## 参数：p_skill_data (SkillEffect) - 技能数据资源；p_caster (Node2D) - 施法者节点
func _init(p_skill_data: SkillEffect, p_caster: Node2D) -> void:
	skill_data = p_skill_data
	caster = p_caster

## 功能：节点就绪时启用帧处理。
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	set_process(true)

## 功能：每帧更新冷却倒计时并发射进度信号。
## 说明：冷却计算集中在此处完成，HUD 等外部模块仅监听信号做展示。
##       暂停状态下不更新冷却计时。
## 参数：delta (float) - 帧间隔时间（秒）
func _process(delta: float) -> void:
	if get_tree() and get_tree().paused:
		return
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
		cooldown_updated.emit(_cooldown_remaining, skill_data.cooldown)
		if _cooldown_remaining <= 0.0:
			_cooldown_remaining = 0.0
			cooldown_finished.emit()

# ========================== 冷却管理模块 ==========================
## 功能：检查技能是否就绪（未处于冷却中）。
## 返回值：bool - true 表示可用，false 表示冷却中
func is_ready() -> bool:
	if skill_data.cooldown <= 0.0:
		return true
	return _cooldown_remaining <= 0.0

## 功能：开始冷却，通常在技能执行后调用。
## 说明：立即将剩余冷却时间设为技能总冷却时间，并发射首次进度信号。
func start_cooldown() -> void:
	if skill_data.cooldown > 0.0:
		_cooldown_remaining = skill_data.cooldown
		cooldown_updated.emit(_cooldown_remaining, skill_data.cooldown)

## 功能：获取剩余冷却时间（秒）。
## 返回值：float - 剩余冷却秒数，若无需冷却则返回 0.0
func get_remaining_cooldown() -> float:
	return maxf(0.0, _cooldown_remaining)

# ========================== 技能执行模块 ==========================
## 功能：执行技能（对目标造成伤害，播放特效）。
## 参数：target (Node) - 目标节点；auto_cooldown (bool) - 是否立即开始冷却，默认为 true
## 返回值：bool - 是否成功执行技能
func execute(target: Node = null, auto_cooldown: bool = true) -> bool:
	if target:
		_apply_damage(target)
	_play_effect(target)
	if auto_cooldown:
		start_cooldown()

	if target:
		print("[SkillRunner] 技能执行: ", skill_data.name, " 对 ", target.name)
	else:
		print("[SkillRunner] 技能空放执行: ", skill_data.name)
	return true

# ========================== 伤害计算模块 ==========================
## 功能：对目标应用伤害，通过事件总线发送伤害事件。
## 参数：target (Node) - 目标节点
func _apply_damage(target: Node) -> void:
	var final_damage = _calculator.calculate(
		skill_data.damage,
		skill_data.skill_multiplier,
		0.05,        # TODO: 暴击率应从施法者属性获取（如 caster.stats.crit_rate）
		1.5          # TODO: 暴击伤害应从施法者属性获取（如 caster.stats.crit_damage）
	)["damage"]

	var damage_event = {
		"damage": final_damage,
		"source": caster,
		"target": target,
		"skill": skill_data
	}
	EventBus.skill_damage_requested.emit(damage_event)

# ========================== 特效播放模块 ==========================
## 功能：播放技能特效。
## 参数：target (Node) - 目标节点（用于定位特效位置）；target_pos (Vector2) - 目标位置（用于 POSITION 类型技能）
## 说明：根据技能配置的 effect_attach_type 决定特效生成位置（施法者/目标/指定坐标）。
func _play_effect(target: Node, target_pos: Vector2 = Vector2.ZERO) -> void:
	if not skill_data.fx_scene:
		return

	var fx = skill_data.fx_scene.instantiate()

	fx.caster = caster
	fx.target = target
	fx.target_pos = target_pos
	fx.skill_data = skill_data

	match skill_data.effect_attach_type:
		SkillEffect.EffectAttachType.CASTER:
			fx.global_position = caster.global_position
		SkillEffect.EffectAttachType.TARGET:
			if target:
				fx.global_position = target.global_position
		SkillEffect.EffectAttachType.POSITION:
			if target_pos != null:
				fx.global_position = target_pos
			else:
				fx.global_position = caster.global_position

	get_tree().current_scene.add_child(fx)
