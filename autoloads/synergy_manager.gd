# ==============================================================================
#   synergy_manager.gd
#   功能：协同管理器（Autoload 单例）。管理技能协同规则和武器技能协同规则，
#        检测条件触发协同效果。
# ==============================================================================
extends Node

# ========================== 信号 ==========================
## 协同触发时发射
signal synergy_triggered(rule_id: String, context: Dictionary)

## 武器技能协同时发射
signal weapon_skill_synergy_triggered(synergy_id: String, weapon_id: String, skill_id: String)

# ========================== 常量 ==========================
## 调试模式开关
const DEBUG_MODE: bool = true
## 协同规则资源目录
const RULES_DIR: String = "res://resources/data/synergy/rules/"

## 武器技能协同规则资源目录
const WEAPON_SYNERGIES_DIR: String = "res://resources/data/weapons/synergies/"

## 协同触发后的全局冷却（秒）
const GLOBAL_COOLDOWN: float = 0.5
## debuff 记录过期时间（毫秒）
const DEBUFF_EXPIRE_TIME: int = 10000

# ========================== 运行时状态 ==========================
## 已加载的技能协同规则
var _rules: Array[SynergyRule] = []
## 已加载的武器技能协同规则
var _weapon_synergies: Array[WeaponSkillSynergy] = []
## 规则冷却计时器 {rule_id: remaining_time}
var _cooldowns: Dictionary = {}
## 武器协同冷却计时器 {synergy_id: remaining_time}
var _weapon_cooldowns: Dictionary = {}
## 全局冷却计时器
var _global_cooldown: float = 0.0
## 最近施加的debuff记录 {target_id: {tag: timestamp}}
var _recent_debuffs: Dictionary = {}
## 本次运行触发次数 {rule_id: count}
var _trigger_counts: Dictionary = {}
## 武器协同触发次数 {synergy_id: count}
var _weapon_trigger_counts: Dictionary = {}

# ========================== 生命周期 ==========================
func _ready() -> void:
	_load_rules()
	_load_weapon_synergies()
	_connect_signals()

func _process(delta: float) -> void:
	# 更新冷却计时器
	if _global_cooldown > 0.0:
		_global_cooldown -= delta

	var expired_keys: Array = []
	for rule_id in _cooldowns:
		_cooldowns[rule_id] -= delta
		if _cooldowns[rule_id] <= 0.0:
			expired_keys.append(rule_id)
	for key in expired_keys:
		_cooldowns.erase(key)

	# 更新武器协同冷却
	expired_keys.clear()
	for synergy_id in _weapon_cooldowns:
		_weapon_cooldowns[synergy_id] -= delta
		if _weapon_cooldowns[synergy_id] <= 0.0:
			expired_keys.append(synergy_id)
	for key in expired_keys:
		_weapon_cooldowns.erase(key)

	# 清理过期的debuff记录（超过10秒的记录）
	_cleanup_old_debuffs()

# ========================== 公共 API ==========================
## 获取所有协同规则
func get_all_rules() -> Array[SynergyRule]:
	return _rules

## 检查规则是否可用（冷却中或达到次数限制则不可用）
func is_rule_available(rule_id: String) -> bool:
	if _cooldowns.has(rule_id):
		return false
	var rule := _get_rule_by_id(rule_id)
	if rule == null:
		return false
	if rule.max_triggers_per_run > 0:
		var count: int = _trigger_counts.get(rule_id, 0)
		if count >= rule.max_triggers_per_run:
			return false
	return true

## 获取规则触发次数
func get_triggered_count(rule_id: String) -> int:
	return _trigger_counts.get(rule_id, 0)

## 重置运行时状态（新运行开始时调用）
func reset_run_state() -> void:
	_cooldowns.clear()
	_weapon_cooldowns.clear()
	_trigger_counts.clear()
	_weapon_trigger_counts.clear()
	_recent_debuffs.clear()
	_global_cooldown = 0.0

## 获取所有武器技能协同规则
func get_all_weapon_synergies() -> Array[WeaponSkillSynergy]:
	return _weapon_synergies

## 检查武器协同是否可用
func is_weapon_synergy_available(synergy_id: String) -> bool:
	if _weapon_cooldowns.has(synergy_id):
		return false
	var synergy := _get_weapon_synergy_by_id(synergy_id)
	if synergy == null:
		return false
	if synergy.max_triggers_per_run > 0:
		var count: int = _weapon_trigger_counts.get(synergy_id, 0)
		if count >= synergy.max_triggers_per_run:
			return false
	return true

## 获取武器协同触发次数
func get_weapon_synergy_triggered_count(synergy_id: String) -> int:
	return _weapon_trigger_counts.get(synergy_id, 0)

# ========================== 内部方法 ==========================
func _load_rules() -> void:
	var dir := DirAccess.open(RULES_DIR)
	if dir == null:
		push_warning("[SynergyManager] 协同规则目录不存在: ", RULES_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(RULES_DIR + file_name)
			if resource is SynergyRule:
				_rules.append(resource)
		file_name = dir.get_next()


	if DEBUG_MODE:
		print("[SynergyManager] 加载了 ", _rules.size(), " 条协同规则")

func _load_weapon_synergies() -> void:
	var dir := DirAccess.open(WEAPON_SYNERGIES_DIR)
	if dir == null:
		# 目录不存在时静默跳过
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(WEAPON_SYNERGIES_DIR + file_name)
			if resource is WeaponSkillSynergy:
				_weapon_synergies.append(resource)
		file_name = dir.get_next()

	if DEBUG_MODE:
		print("[SynergyManager] 加载了 ", _weapon_synergies.size(), " 条武器技能协同规则")

func _connect_signals() -> void:
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.status_effect_applied.connect(_on_status_effect_applied)

func _on_status_effect_applied(target: Node2D, effect: StatusEffectType) -> void:
	# 记录敌人身上的debuff tags
	if target == null or effect == null:
		return

	var target_id: int = target.get_instance_id()
	if not _recent_debuffs.has(target_id):
		_recent_debuffs[target_id] = {}

	# 从effect中提取tags
	var tags: Array[String] = []
	if effect is StatusEffectType:
		tags = effect.tags if effect.get("tags") else []

	for tag in tags:
		_recent_debuffs[target_id][tag] = Time.get_ticks_msec()

func _on_damage_dealt(info: DamageInfo) -> void:
	# 检测协同条件
	if info.skill_data == null or info.target == null:
		return

	if _global_cooldown > 0.0:
		return

	var target_id: int = info.target.get_instance_id()
	var target_debuffs: Dictionary = _recent_debuffs.get(target_id, {})
	var skill_tags: Array[String] = info.skill_data.tags

	# 检查技能协同规则
	for rule in _rules:
		if not is_rule_available(rule.id):
			continue
		if _check_rule(rule, skill_tags, target_debuffs):
			_trigger_synergy(rule, info)

	# 检查武器技能协同规则
	_check_weapon_synergy(info, skill_tags)

func _check_rule(rule: SynergyRule, skill_tags: Array[String], target_debuffs: Dictionary) -> bool:
	# 检查技能tags是否满足
	for required_tag in rule.trigger_skill_tags:
		if required_tag not in skill_tags:
			return false

	# 检查敌人debuff tags是否满足
	for required_tag in rule.required_debuff_tags:
		if required_tag not in target_debuffs:
			return false

	# 检查触发概率
	if rule.trigger_chance < 1.0:
		if randf() > rule.trigger_chance:
			return false

	return true

func _trigger_synergy(rule: SynergyRule, damage_info: DamageInfo) -> void:
	# 应用协同效果
	var effect := rule.synergy_effect
	if effect == null:
		return

	match effect.effect_type:
		SynergyEffect.EffectType.DAMAGE_BONUS:
			_apply_damage_bonus(effect, damage_info)
		SynergyEffect.EffectType.APPLY_STATUS:
			_apply_status_effect(effect, damage_info)
		SynergyEffect.EffectType.HEAL:
			_apply_heal(effect, damage_info)
		SynergyEffect.EffectType.AREA_EFFECT:
			_apply_area_effect(effect, damage_info)

	# 记录触发
	_trigger_counts[rule.id] = _trigger_counts.get(rule.id, 0) + 1
	_cooldowns[rule.id] = rule.cooldown
	_global_cooldown = GLOBAL_COOLDOWN

	# 发射信号
	var context := {
		"rule_id": rule.id,
		"rule_name": rule.display_name,
		"skill_id": damage_info.skill_data.id,
		"target": damage_info.target,
		"damage_info": damage_info
	}
	synergy_triggered.emit(rule.id, context)
	EventBus.synergy_triggered.emit(rule.id, context)

	if DEBUG_MODE:
		print("[SynergyManager] 协同触发: ", rule.display_name)

func _apply_damage_bonus(effect: SynergyEffect, damage_info: DamageInfo) -> void:
	# 伤害加成通过修改 DamageInfo 实现
	damage_info.final_damage *= effect.damage_multiplier

func _apply_status_effect(effect: SynergyEffect, damage_info: DamageInfo) -> void:
	if effect.status_effect == null or damage_info.target == null:
		return
	var player := Global.player
	if player and player.status_effect_component:
		player.status_effect_component.apply_effect(effect.status_effect)

func _apply_heal(effect: SynergyEffect, damage_info: DamageInfo) -> void:
	# 治疗施法者
	var caster = damage_info.source
	if caster and caster.has_method("heal"):
		caster.heal(effect.heal_amount)

func _apply_area_effect(effect: SynergyEffect, damage_info: DamageInfo) -> void:
	# TODO: 实现范围伤害逻辑
	if effect.area_radius <= 0.0 or damage_info.target == null:
		return

# ========================== 武器技能协同 ==========================
func _check_weapon_synergy(info: DamageInfo, skill_tags: Array[String]) -> void:
	# 获取当前装备武器的tags
	var weapon_tags: Array[String] = WeaponManager.get_equipped_stats().get("tags", [])
	if weapon_tags.is_empty():
		return

	var weapon_id: String = ""
	var weapon = WeaponManager.get_equipped_weapon()
	if weapon:
		weapon_id = weapon.id

	for synergy in _weapon_synergies:
		if not is_weapon_synergy_available(synergy.id):
			continue
		if _check_weapon_synergy_rule(synergy, weapon_tags, skill_tags):
			_trigger_weapon_synergy(synergy, info, weapon_id)

func _check_weapon_synergy_rule(synergy: WeaponSkillSynergy, weapon_tags: Array, skill_tags: Array[String]) -> bool:
	# 检查武器tags是否满足
	for required_tag in synergy.required_weapon_tags:
		if required_tag not in weapon_tags:
			return false

	# 检查技能tags是否满足
	for required_tag in synergy.required_skill_tags:
		if required_tag not in skill_tags:
			return false

	# 检查触发概率
	if synergy.trigger_chance < 1.0:
		if randf() > synergy.trigger_chance:
			return false

	return true

func _trigger_weapon_synergy(synergy: WeaponSkillSynergy, damage_info: DamageInfo, weapon_id: String) -> void:
	# 应用伤害加成
	if synergy.damage_multiplier > 1.0:
		if damage_info.get("final_damage"):
			damage_info.final_damage *= synergy.damage_multiplier

	# 应用额外效果
	if synergy.bonus_effect:
		match synergy.bonus_effect.effect_type:
			SynergyEffect.EffectType.DAMAGE_BONUS:
				_apply_damage_bonus(synergy.bonus_effect, damage_info)
			SynergyEffect.EffectType.APPLY_STATUS:
				_apply_status_effect(synergy.bonus_effect, damage_info)
			SynergyEffect.EffectType.HEAL:
				_apply_heal(synergy.bonus_effect, damage_info)
			SynergyEffect.EffectType.AREA_EFFECT:
				_apply_area_effect(synergy.bonus_effect, damage_info)

	# 生成视觉特效
	if synergy.visual_effect and damage_info.target:
		var fx = synergy.visual_effect.instantiate()
		damage_info.target.add_child(fx)

	# 记录触发
	_weapon_trigger_counts[synergy.id] = _weapon_trigger_counts.get(synergy.id, 0) + 1
	_weapon_cooldowns[synergy.id] = synergy.cooldown
	_global_cooldown = GLOBAL_COOLDOWN

	# 发射信号
	var skill_id: String = damage_info.skill_data.id if damage_info.skill_data else ""
	weapon_skill_synergy_triggered.emit(synergy.id, weapon_id, skill_id)
	EventBus.weapon_skill_synergy_triggered.emit(synergy.id, weapon_id, skill_id)

	if DEBUG_MODE:
		print("[SynergyManager] 武器技能协同触发: ", synergy.display_name, " (武器: ", weapon_id, " + 技能: ", skill_id, ")")

func _get_weapon_synergy_by_id(synergy_id: String) -> WeaponSkillSynergy:
	for synergy in _weapon_synergies:
		if synergy.id == synergy_id:
			return synergy
	return null

func _cleanup_old_debuffs() -> void:
	var current_time := Time.get_ticks_msec()
	var expired_targets: Array = []

	for target_id in _recent_debuffs:
		var debuffs: Dictionary = _recent_debuffs[target_id]
		var expired_tags: Array = []
		for tag in debuffs:
			# 超过过期时间的记录清理
			if current_time - debuffs[tag] > DEBUFF_EXPIRE_TIME:
				expired_tags.append(tag)
		for tag in expired_tags:
			debuffs.erase(tag)
		if debuffs.is_empty():
			expired_targets.append(target_id)

	for target_id in expired_targets:
		_recent_debuffs.erase(target_id)

func _get_rule_by_id(rule_id: String) -> SynergyRule:
	for rule in _rules:
		if rule.id == rule_id:
			return rule
	return null
