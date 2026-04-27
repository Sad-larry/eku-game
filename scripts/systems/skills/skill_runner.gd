# systems/skill_runner.gd
# 技能运行时容器：管理单个技能实例的冷却、伤害、特效
extends Node   # 或 Node，根据需求选择
class_name SkillRunner

## 技能数据资源
var skill_data: SkillEffect
## 上次使用时间（毫秒）
var _last_use_time: int = 0
## 施法者（通常是战斗实体）
var caster: Node2D
var _calculator = DamageCalculator.new()

## 初始化
func _init(p_skill_data: SkillEffect, p_caster: Node2D) -> void:
	skill_data = p_skill_data
	caster = p_caster

## 检查技能是否就绪（未冷却）
func is_ready() -> bool:
	if skill_data.cooldown <= 0.0:
		return true
	var now = Time.get_ticks_msec()
	return (now - _last_use_time) >= (skill_data.cooldown * 1000.0)

## 开始冷却（通常在使用技能后调用）
func start_cooldown() -> void:
	_last_use_time = Time.get_ticks_msec()

## 执行技能（对目标造成伤害，播放特效，支持空放）
## target: 目标节点（必须拥有 health_component 或类似伤害接口）
func execute(target: Node = null) -> void:
	# 1. 仅当存在目标时，才应用伤害
	if target:
		_apply_damage(target)
	# 2. 播放特效
	_play_effect(target)
	# 3. 开始冷却
	start_cooldown()

	# 适配无目标的日志打印
	if target:
		print("[SkillRunner] 技能执行: ", skill_data.name, " 对 ", target.name)
	else:
		print("[SkillRunner] 技能空放执行: ", skill_data.name)

## 伤害计算（可直接调用目标组件，或通过信号）
func _apply_damage(target: Node) -> void:
	var final_damage = _calculator.calculate(
		  skill_data.damage,
		  skill_data.skill_multiplier,
		  0.05,                   # crit_rate（可以从 caster 的 stats 获取）
		  1.5                     # crit_damage（同上）
	  )["damage"]
	
	# 发射全局信号（需提前连接）
	var damage_event = {
		"damage": final_damage,
		"source": caster,
		"target": target,
		"skill": skill_data
	}
	EventBus.skill_damage_requested.emit(damage_event)


## 播放特效
func _play_effect(target: Node, target_pos: Vector2 = Vector2.ZERO) -> void:
	# 无特效直接跳过
	if not skill_data.fx_scene:
		return
	# 1. 加载特效
	var fx = skill_data.fx_scene.instantiate()
	# 2. 只传递数据！不控制逻辑！
	fx.caster = caster
	fx.target = target
	fx.target_pos = target_pos
	fx.skill_data = skill_data
	
	# 添加到场景树（可以是当前场景或世界）
	get_tree().current_scene.add_child(fx)
	# 通常特效跟随目标位置，或施法者位置
	# TODO 特效有多种，给自己上BUFF的特效，特效位置就是自身，给敌人上BUFF的特效，特效位置就是敌人
	# 还有场地上的技能特效，特效位置在指定位置
	# ==============================
	# 核心：根据技能配置决定特效位置
	# ==============================
	match skill_data.effect_attach_type:
		# 1. 给自己BUFF → 放自己身上
		SkillEffect.EffectAttachType.CASTER:
			fx.global_position = caster.global_position
		# 2. 打敌人/给敌人BUFF → 放目标身上
		SkillEffect.EffectAttachType.TARGET:
			if target:
				fx.global_position = target.global_position
		# 3. 场地技能（毒圈、AOE）→ 放指定位置
		SkillEffect.EffectAttachType.POSITION:
			if target_pos != null:
				fx.global_position = target_pos
			else:
				# 没传位置就默认放施法者面前（防报错）
				fx.global_position = caster.global_position
	# 如果特效场景有自动销毁逻辑（如 AnimationPlayer 结束后 queue_free），则无需处理
	# 否则可以添加一个定时器自动销毁

## 获取剩余冷却时间（秒）
func get_remaining_cooldown() -> float:
	if skill_data.cooldown <= 0.0:
		return 0.0
	var now = Time.get_ticks_msec()
	var elapsed = (now - _last_use_time) / 1000.0
	return maxf(0.0, skill_data.cooldown - elapsed)
