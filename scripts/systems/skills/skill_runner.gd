# ==============================================================================
#   skill_runner.gd
#   功能：技能运行时容器，管理单个技能实例的生命周期和冷却。
#        生命周期：READY → ACTIVE → COOLDOWN → READY
#        - READY:   技能可用，可被调用 execute()
#        - ACTIVE:  技能效果存在于场景中（飞行/引导/蓄力等），冷却尚未开始
#        - COOLDOWN:技能已"出手"（执行完成），冷却倒计时中
#   职责边界：
#        - 冷却管理、伤害计算、生命周期流转 ← SkillRunner 负责
#        - 动画表现、命中判定、视觉特效     ← 技能脚本（fx_*.gd）负责
#   通信方式：
#        - 技能脚本通过 on_hit() / on_execution_complete() 等事件告知 SkillRunner
#        - SkillRunner 通过这些事件驱动生命周期流转和冷却启动
# ==============================================================================
extends Node
class_name SkillRunner

# ========================== 枚举定义模块 ==========================
enum RunnerState {
	READY,     # 技能可用
	ACTIVE,    # 技能效果正在运行（冷却尚未开始）
	COOLDOWN,  # 冷却中
}

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

## 冷却剩余时间（秒），0 表示无冷却
var _cooldown_remaining: float = 0.0

## 当前生命周期状态
var _state: RunnerState = RunnerState.READY

## 已实例化的技能场景引用
var _fx_instance: Node2D = null

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
## 说明：暂停状态下不更新冷却计时。
## 参数：delta (float) - 帧间隔时间（秒）
func _process(delta: float) -> void:
	if get_tree() and get_tree().paused:
		return
	if _state == RunnerState.COOLDOWN and _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
		cooldown_updated.emit(_cooldown_remaining, skill_data.cooldown)
		if _cooldown_remaining <= 0.0:
			_cooldown_remaining = 0.0
			_state = RunnerState.READY
			cooldown_finished.emit()

# ========================== 公共查询 API ==========================
## 功能：技能是否就绪（处于 READY 状态，可被调用 execute()）。
func is_ready() -> bool:
	return _state == RunnerState.READY

## 功能：技能是否处于冷却中。
func is_on_cooldown() -> bool:
	return _state == RunnerState.COOLDOWN

## 功能：技能效果是否正在运行中。
func is_active() -> bool:
	return _state == RunnerState.ACTIVE

## 功能：获取剩余冷却时间（秒）。
func get_remaining_cooldown() -> float:
	return maxf(0.0, _cooldown_remaining)

# ========================== 技能执行（Player 层调用） ==========================
## 功能：执行技能，实例化技能场景（fx_scene）并进入 ACTIVE 状态。
## 说明：此方法仅在 Player 层完成能量/冷却检查后调用。不在此处做伤害计算。
## 参数：target (Node2D) - 可选的目标节点
## 返回值：Node2D - 实例化的技能场景，调用者可按需操作
func execute(target: Node2D = null) -> Node2D:
	_state = RunnerState.ACTIVE

	if skill_data.fx_scene:
		_fx_instance = skill_data.fx_scene.instantiate() as Node2D
		_fx_instance.runner = self
		_fx_instance.caster = caster
		_fx_instance.target = target
		_fx_instance.skill_data = skill_data

		match skill_data.effect_attach_type:
			SkillEffect.EffectAttachType.CASTER:
				_fx_instance.global_position = caster.global_position if caster else Vector2.ZERO
			SkillEffect.EffectAttachType.TARGET:
				if target:
					_fx_instance.global_position = target.global_position
				else:
					_fx_instance.global_position = caster.global_position if caster else Vector2.ZERO
			SkillEffect.EffectAttachType.POSITION:
				_fx_instance.global_position = caster.global_position if caster else Vector2.ZERO

		get_tree().current_scene.add_child(_fx_instance)

	return _fx_instance

# ========================== 技能生命周期事件（技能脚本调用） ==========================
## 功能：技能脚本告知"技能已经出手/执行完成"。
## 说明：SkillRunner 收到此事件后启动冷却。不同技能调用时机不同：
##       - 火球术：出手瞬间（start() 中立即调用）
##       - 蓄力技能：蓄力完成、释放出去的瞬间
##       - 引导技能：引导结束时
func on_execution_complete() -> void:
	_start_cooldown()

## 功能：技能脚本命中目标时回调，在此计算伤害并发出 DamageInfo。
## 参数：target (Node2D) - 被命中的目标节点
## 返回值：DamageInfo - 包含计算后的伤害数据
func on_hit(target: Node2D) -> DamageInfo:
	var result = _calculator.calculate(
		skill_data.damage,
		skill_data.skill_multiplier,
		caster.stats_resource.crit_rate,
		caster.stats_resource.crit_damage
	)

	var info := DamageInfo.new()
	info.final_damage = result["damage"]
	info.is_crit = result["is_crit"]
	info.source = caster
	info.target = target
	info.skill_data = skill_data

	EventBus.damage_dealt.emit(info)
	return info

## 功能：技能被中断时由 PlayerSkillState 调用。
## 说明：SkillRunner 负责清理 fx_instance 并重置状态。
##       若需要惩罚冷却（防止玩家频繁取消技能），可在此处实现短冷却。
func on_interrupted() -> void:
	_cleanup_fx()
	_state = RunnerState.READY

## 功能：FxBoot._exit_tree() 通知特效已被销毁时回调。
##       清除 _fx_instance 引用。若技能仍处于 ACTIVE（即脚本未调用
##       on_execution_complete() 就自行销毁），回退到 READY 避免卡死。
func on_fx_destroyed() -> void:
	_fx_instance = null
	if _state == RunnerState.ACTIVE:
		push_warning("SkillRunner: '%s' fx destroyed without on_execution_complete" % skill_data.id)
		_state = RunnerState.READY

# ========================== 内部方法模块 ==========================
func _start_cooldown() -> void:
	_state = RunnerState.COOLDOWN
	if skill_data.cooldown > 0.0:
		_cooldown_remaining = skill_data.cooldown
		cooldown_updated.emit(_cooldown_remaining, skill_data.cooldown)
	else:
		# 无冷却的技能立即回到 READY
		_state = RunnerState.READY
		cooldown_finished.emit()

func _cleanup_fx() -> void:
	if _fx_instance and is_instance_valid(_fx_instance):
		_fx_instance.queue_free()
		_fx_instance = null
