# ==============================================================================
#   skill_runner.gd
#   功能：技能运行时容器，管理单个技能实例的冷却计时、伤害计算、特效播放。
#        每个技能实例对应一个独立的 SkillRunner，由玩家或实体持有。
# ==============================================================================
extends Node
class_name SkillRunner

# ========================== 变量定义模块 ==========================
## 技能数据资源（包含冷却、伤害、特效等配置）
var skill_data: SkillEffect

## 上次使用时间（毫秒时间戳，用于冷却判定）
var _last_use_time: int = 0

## 施法者（通常是战斗实体，如玩家）
var caster: Node2D

## 伤害计算器实例（复用减少内存分配）
var _calculator = DamageCalculator.new()

# ========================== 生命周期模块 ==========================
## 功能：初始化技能运行器
## 参数：p_skill_data (SkillEffect) - 技能数据资源；p_caster (Node2D) - 施法者节点
func _init(p_skill_data: SkillEffect, p_caster: Node2D) -> void:
	skill_data = p_skill_data
	caster = p_caster

# ========================== 冷却管理模块 ==========================
## 功能：检查技能是否就绪（未处于冷却中）
## 返回值：bool - true 表示可用，false 表示冷却中
func is_ready() -> bool:
	if skill_data.cooldown <= 0.0:
		return true
	var now = Time.get_ticks_msec()
	return (now - _last_use_time) >= (skill_data.cooldown * 1000.0)

## 功能：开始冷却（通常在技能执行后调用）
func start_cooldown() -> void:
	_last_use_time = Time.get_ticks_msec()

## 功能：获取剩余冷却时间（秒）
## 返回值：float - 剩余冷却秒数，若无需冷却则返回 0.0
func get_remaining_cooldown() -> float:
	if skill_data.cooldown <= 0.0:
		return 0.0
	var now = Time.get_ticks_msec()
	var elapsed = (now - _last_use_time) / 1000.0
	return maxf(0.0, skill_data.cooldown - elapsed)

# ========================== 技能执行模块 ==========================
## 功能：执行技能（对目标造成伤害，播放特效，开始冷却）
## 参数：target (Node) - 目标节点（必须拥有接受伤害的方法或组件），可为 null（空放）
func execute(target: Node = null) -> void:
	# 1. 仅当存在目标时，才应用伤害
	if target:
		_apply_damage(target)
	# 2. 播放特效
	_play_effect(target)
	# 3. 开始冷却
	start_cooldown()

	# 打印日志（适配无目标的情况）
	if target:
		print("[SkillRunner] 技能执行: ", skill_data.name, " 对 ", target.name)
	else:
		print("[SkillRunner] 技能空放执行: ", skill_data.name)

# ========================== 伤害计算模块 ==========================
## 功能：对目标应用伤害
## 参数：target (Node) - 目标节点
func _apply_damage(target: Node) -> void:
	# 计算最终伤害
	var final_damage = _calculator.calculate(
		skill_data.damage,
		skill_data.skill_multiplier,
		0.05,        # TODO: crit_rate 应从施法者属性获取（如 caster.stats.crit_rate）
		1.5          # TODO: crit_damage 应从施法者属性获取（如 caster.stats.crit_damage）
	)["damage"]
	
	# 构建伤害事件字典并通过全局事件总线发送
	var damage_event = {
		"damage": final_damage,
		"source": caster,
		"target": target,
		"skill": skill_data
	}
	EventBus.skill_damage_requested.emit(damage_event)

# ========================== 特效播放模块 ==========================
## 功能：播放技能特效
## 参数：target (Node) - 目标节点（用于定位特效位置）；target_pos (Vector2) - 目标位置（用于 POSITION 类型技能）
## 说明：根据技能配置的 effect_attach_type 决定特效生成位置（施法者/目标/指定坐标）
func _play_effect(target: Node, target_pos: Vector2 = Vector2.ZERO) -> void:
	# 无特效配置时直接跳过
	if not skill_data.fx_scene:
		return
	
	# 实例化特效场景
	var fx = skill_data.fx_scene.instantiate()
	
	# 传递技能数据给特效（特效自主决定表现行为）
	fx.caster = caster
	fx.target = target
	fx.target_pos = target_pos
	fx.skill_data = skill_data
	
	# 根据技能配置的特效挂载类型，确定特效的世界位置
	match skill_data.effect_attach_type:
		# 1. 施法者自身特效（如给自己加 Buff 时的光环）
		SkillEffect.EffectAttachType.CASTER:
			fx.global_position = caster.global_position
		
		# 2. 目标身上的特效（如命中爆炸、给敌人施加 Debuff）
		SkillEffect.EffectAttachType.TARGET:
			if target:
				fx.global_position = target.global_position
		
		# 3. 场地位置特效（如毒圈、AOE 地面技能）
		SkillEffect.EffectAttachType.POSITION:
			if target_pos != null:
				fx.global_position = target_pos
			else:
				# 未传递目标位置时，默认放在施法者面前（防御性处理）
				fx.global_position = caster.global_position
	
	# 将特效添加到当前场景树
	get_tree().current_scene.add_child(fx)
	
	# 如果特效场景有自动销毁逻辑（如 AnimationPlayer 结束后调用 queue_free），则无需额外处理
	# 否则可在特效脚本中实现 auto_destroy() 或此处添加定时器
