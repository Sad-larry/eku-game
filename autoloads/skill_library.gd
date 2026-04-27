# autoloads/skill_library.gd
# 技能库管理器：加载和管理所有技能资源，提供技能查询接口
# 自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 SkillLibrary
extends Node

# ========================== 常量定义 ==========================
const DEBUG_MODE: bool = true
const SKILLS_DIR_PATH: String = "res://resources/data/skills/"

# ========================== 变量定义 ==========================
var all_skills: Dictionary = {}           # 所有技能: {skill_id: SkillEffect}
var skills_by_type: Dictionary = {}   # 按分类组织的技能: {type: Array[SkillEffect]}

# ========================== 初始化 ==========================
func _ready() -> void:
	# 初始化分类字典
	_initialize_type_dict()
	# 加载所有技能
	_load_all_skills()
	print("SkillLibrary: 技能库初始化完成，加载技能数量: ", all_skills.size())


func _initialize_type_dict() -> void:
	var type_names = SkillEffect.SkillType.keys()
	for type_name in type_names:
		var type_value = SkillEffect.SkillType[type_name]
		skills_by_type[type_value] = []
		
# ========================== 技能加载核心 ==========================
## 加载所有技能资源
func _load_all_skills() -> void:
	# 清空现有数据
	all_skills.clear()
	for type in skills_by_type:
		skills_by_type[type].clear()

	# 遍历技能目录
	var dir = DirAccess.open(SKILLS_DIR_PATH)
	if not dir:
		push_warning("[SkillLibrary] 技能目录不存在或无法访问: ", SKILLS_DIR_PATH)
		return
		
	_recursive_load_skills(dir, SKILLS_DIR_PATH)
	
func _recursive_load_skills(dir: DirAccess, current_path: String) -> void:
	dir.list_dir_begin()
	var item = dir.get_next()
	while item != "":
		var full_path = current_path.path_join(item)
		if dir.current_is_dir() and not item.begins_with("."):
			var sub_dir = DirAccess.open(full_path)
			if sub_dir:
				_recursive_load_skills(sub_dir, full_path)
		elif item.ends_with(".tres") or item.ends_with(".res"):
			_load_skill_resource(full_path)
		item = dir.get_next()
	dir.list_dir_end()
	
func _load_skill_resource(path: String) -> void:
	var resource = load(path) as SkillEffect
	if not resource:
		push_warning("[SkillLibrary] 无法加载技能资源: ", path)
		return
	if resource.id.is_empty():
		push_warning("[SkillLibrary] 技能资源缺少 id 字段，跳过: ", path)
		return
	# 使用资源自身的 id 作为键
	if all_skills.has(resource.id):
		push_warning("[SkillLibrary] 重复的技能 id: ", resource.id, " (", path, ")")
		return
	all_skills[resource.id] = resource
	skills_by_type[resource.type].append(resource)
	if DEBUG_MODE:
		print("[SkillLibrary] 加载技能 -> ", resource.name, " (ID: ", resource.id, ", 类型: ", SkillEffect.SkillType.keys()[resource.type], ")")

# ========================== 技能查询接口 ==========================
## 通过ID获取技能数据
func get_skill_by_id(skill_id: String) -> SkillEffect:
	return all_skills.get(skill_id)

## 获取特定分类的所有技能
func get_skills_by_type(type: SkillEffect.SkillType) -> Array:
	return skills_by_type.get(type, []).duplicate()

## 获取所有技能
func get_all_skills() -> Dictionary:
	return all_skills.duplicate()

## 判断是否有技能
func has_skill(skill_id: String) -> bool:
	return all_skills.has(skill_id)
	
## 获取技能数量
func get_skill_count() -> int:
	return all_skills.size()

## 获取所有技能ID列表
func get_all_skill_ids() -> Array:
	return all_skills.keys()

## 获取随机技能（可选分类过滤）
## @param type: 技能类型，若为 -1 或 null 则从所有技能中随机
func get_random_skill(type: int = -1) -> SkillEffect:
	var candidates: Array = []
	if type >= 0 and skills_by_type.has(type):
		candidates = skills_by_type[type]
	else:
		candidates = all_skills.values()

	if candidates.is_empty():
		return null

	var random_index = randi() % candidates.size()
	return candidates[random_index]

## 根据分类枚举获取目录名
func type_dir_from_enum(type: SkillEffect.SkillType) -> String:
	match type:
		SkillEffect.SkillType.INITIATOR:
			return "initiator"
		SkillEffect.SkillType.FINISHER:
			return "finisher"
		SkillEffect.SkillType.CONTROL:
			return "control"
		SkillEffect.SkillType.SURVIVAL:
			return "survival"
		_:
			return "unknown"

## 根据目录名获取分类枚举
func type_enum_from_dir(dir_name: String) -> SkillEffect.SkillType:
	match dir_name:
		"initiator":
			return SkillEffect.SkillType.INITIATOR
		"finisher":
			return SkillEffect.SkillType.FINISHER
		"control":
			return SkillEffect.SkillType.CONTROL
		"survival":
			return SkillEffect.SkillType.SURVIVAL
		_:
			return SkillEffect.SkillType.UNKNOWN

# ========================== 重新加载与调试 ==========================
## 重新加载所有技能（热重载支持）
func reload_skills() -> void:
	_load_all_skills()
	print("[SkillLibrary] 技能重新加载完成")
