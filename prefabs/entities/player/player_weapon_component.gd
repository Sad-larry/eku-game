# ==============================================================================
#   player_weapon_component.gd
#   功能：玩家武器组件，管理武器的装备状态、属性计算和武器技能释放。
#        从 player.gd 拆出的独立组件，与 WeaponManager 协作。
# ==============================================================================
extends Node
class_name PlayerWeaponComponent

# ========================== 变量定义模块 ==========================
## 当前装备的武器运行时属性缓存
var _current_stats: Dictionary = {}

## 武器技能冷却计时器
var _weapon_skill_cooldown: float = 0.0

## 武器技能冷却总时长
var _weapon_skill_total_cooldown: float = 0.0

# ========================== 生命周期模块 ==========================
func _ready() -> void:
	# 连接武器管理器信号
	EventBus.weapon_equipped.connect(_on_weapon_equipped)
	EventBus.weapon_unequipped.connect(_on_weapon_unequipped)
	EventBus.weapon_upgraded.connect(_on_weapon_upgraded)
	EventBus.weapon_enchanted.connect(_on_weapon_enchanted)

	# 初始化当前武器属性
	_refresh_stats()

func _process(delta: float) -> void:
	# 更新武器技能冷却
	if _weapon_skill_cooldown > 0.0:
		_weapon_skill_cooldown -= delta

# ========================== 公共 API 模块 ==========================
## 功能：获取当前武器的有效伤害值
## 返回值：float - 有效伤害值
func get_effective_damage() -> float:
	return _current_stats.get("damage", 0.0)

## 功能：获取当前武器的有效攻击速度
## 返回值：float - 有效攻击速度
func get_effective_attack_speed() -> float:
	return _current_stats.get("attack_speed", 1.0)

## 功能：获取当前武器的有效暴击率
## 返回值：float - 有效暴击率
func get_effective_crit_rate() -> float:
	return _current_stats.get("crit_rate", 0.0)

## 功能：获取当前武器的有效暴击伤害倍率
## 返回值：float - 有效暴击伤害倍率
func get_effective_crit_damage() -> float:
	return _current_stats.get("crit_damage", 1.5)

## 功能：获取当前武器的有效攻击范围
## 返回值：float - 有效攻击范围
func get_effective_attack_range() -> float:
	return _current_stats.get("attack_range", 50.0)

## 功能：获取当前武器的标签列表
## 返回值：Array - 武器标签列表
func get_weapon_tags() -> Array:
	return _current_stats.get("tags", [])

## 功能：检查武器技能是否就绪
## 返回值：bool - true 表示技能可用
func is_weapon_skill_ready() -> bool:
	return _weapon_skill_cooldown <= 0.0 and _current_stats.has("weapon_skill")

## 功能：尝试使用武器技能
## 返回值：SkillEffect - 武器技能数据，不可用返回 null
func try_use_weapon_skill() -> SkillEffect:
	if not is_weapon_skill_ready():
		return null

	var skill_data: SkillEffect = _current_stats.get("weapon_skill")
	if skill_data == null:
		return null

	# 启动冷却
	_weapon_skill_total_cooldown = _current_stats.get("weapon_skill_cooldown", 10.0)
	_weapon_skill_cooldown = _weapon_skill_total_cooldown
	EventBus.weapon_skill_used.emit(WeaponManager.get_equipped_weapon().id if WeaponManager.get_equipped_weapon() else "")

	return skill_data

## 功能：获取武器技能冷却进度（0.0-1.0）
## 返回值：float - 冷却进度，1.0 表示就绪
func get_weapon_skill_cooldown_progress() -> float:
	if _weapon_skill_total_cooldown <= 0.0:
		return 1.0
	return 1.0 - clampf(_weapon_skill_cooldown / _weapon_skill_total_cooldown, 0.0, 1.0)

## 功能：获取武器技能冷却剩余时间
## 返回值：float - 剩余秒数
func get_weapon_skill_cooldown_remaining() -> float:
	return maxf(0.0, _weapon_skill_cooldown)

## 功能：检查是否装备了武器
## 返回值：bool - true 表示已装备武器
func has_weapon() -> bool:
	return _current_stats.size() > 0

## 功能：获取武器显示名称
## 返回值：String - 武器名称
func get_weapon_display_name() -> String:
	var weapon = WeaponManager.get_equipped_weapon()
	return weapon.display_name if weapon else ""

# ========================== 内部方法模块 ==========================
## 功能：刷新当前武器属性缓存
func _refresh_stats() -> void:
	_current_stats = WeaponManager.get_equipped_stats()
	if _current_stats.is_empty():
		_weapon_skill_cooldown = 0.0
		_weapon_skill_total_cooldown = 0.0

# ========================== 信号回调模块 ==========================
## 功能：武器装备时刷新属性
func _on_weapon_equipped(_weapon_id: String) -> void:
	_refresh_stats()
	_weapon_skill_cooldown = 0.0

## 功能：武器卸下时清空属性
func _on_weapon_unequipped(_weapon_id: String) -> void:
	_current_stats.clear()
	_weapon_skill_cooldown = 0.0
	_weapon_skill_total_cooldown = 0.0

## 功能：武器升级时刷新属性
func _on_weapon_upgraded(_weapon_id: String, _new_level: int) -> void:
	_refresh_stats()

## 功能：武器附魔时刷新属性
func _on_weapon_enchanted(_weapon_id: String, _enchant_id: String) -> void:
	_refresh_stats()
