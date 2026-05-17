# ==============================================================================
#   skill_library.gd
#   功能：技能库管理器（Autoload 单例），负责从资源目录递归加载所有 SkillEffect 资源，
#        提供技能查询、分类筛选、随机获取等接口，支持热重载。
#   自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 SkillLibrary
# ==============================================================================
extends Node

# ========================== 常量定义模块 ==========================
## 调试模式开关（开启后输出更多调试信息）
const DEBUG_MODE: bool = true
## 技能资源根目录路径
const SKILLS_DIR_PATH: String = "res://resources/data/skills/"

# ========================== 变量定义模块 ==========================
## 所有技能的字典：{skill_id (String): SkillEffect}
var all_skills: Dictionary = {}
## 按分类组织的技能字典：{type (SkillEffect.SkillType): Array[SkillEffect]}
var skills_by_type: Dictionary = {}

# ========================== 生命周期模块 ==========================
## 功能：节点就绪时初始化分类字典并加载所有技能资源
func _ready() -> void:
	# 初始化分类字典
	_initialize_type_dict()
	# 加载所有技能
	_load_all_skills()
	print("SkillLibrary: 技能库初始化完成，加载技能数量: ", all_skills.size())

# ========================== 初始化辅助模块 ==========================
## 功能：初始化 skills_by_type 字典，为每个技能类型创建空数组
func _initialize_type_dict() -> void:
	var type_names = SkillEffect.SkillType.keys()
	for type_name in type_names:
		var type_value = SkillEffect.SkillType[type_name]
		skills_by_type[type_value] = []

# ========================== 技能加载核心模块 ==========================
## 功能：递归加载目录下所有技能资源（.tres / .res）
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

## 功能：递归遍历目录并加载技能资源
## 参数：dir (DirAccess) - 目录访问器；current_path (String) - 当前路径
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

## 功能：加载单个技能资源文件
## 参数：path (String) - 资源文件路径
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

# ========================== 技能查询接口模块 ==========================
## 功能：通过技能 ID 获取技能数据
## 参数：skill_id (String) - 技能唯一标识符
## 返回值：SkillEffect - 技能资源，若未找到返回 null
func get_skill_by_id(skill_id: String) -> SkillEffect:
	return all_skills.get(skill_id)

## 功能：获取特定分类的所有技能
## 参数：type (SkillEffect.SkillType) - 技能类型枚举
## 返回值：Array[SkillEffect] - 该类型下的技能数组（副本）
func get_skills_by_type(type: SkillEffect.SkillType) -> Array:
	return skills_by_type.get(type, []).duplicate()

## 功能：获取所有技能的字典
## 返回值：Dictionary - 所有技能的拷贝
func get_all_skills() -> Dictionary:
	return all_skills.duplicate()

## 功能：判断是否包含指定 ID 的技能
## 参数：skill_id (String) - 技能唯一标识符
## 返回值：bool - true 表示存在
func has_skill(skill_id: String) -> bool:
	return all_skills.has(skill_id)

## 功能：获取技能库中的技能总数
## 返回值：int - 技能数量
func get_skill_count() -> int:
	return all_skills.size()

## 功能：获取所有技能 ID 的列表
## 返回值：Array[String] - 技能 ID 数组
func get_all_skill_ids() -> Array:
	return all_skills.keys()

## 功能：随机获取一个技能（可选分类过滤）
## 参数：type (int) - 技能类型枚举值，若为 -1 则从所有技能中随机
## 返回值：SkillEffect - 随机技能资源，若无可用技能返回 null
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

## 功能：根据技能类型枚举获取对应的目录名称
## 参数：type (SkillEffect.SkillType) - 技能类型
## 返回值：String - 目录名称（如 "initiator"、"finisher"）
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

## 功能：根据目录名称推导对应的技能类型枚举
## 参数：dir_name (String) - 目录名称
## 返回值：SkillEffect.SkillType - 对应的技能类型，未匹配返回 UNKNOWN
func type_enum_from_dir(dir_name: String) -> SkillEffect.SkillType:
	for type in SkillEffect.SkillType.values():
		if SkillEffect.SkillType.keys()[type].to_lower() == dir_name:
			return type
	return SkillEffect.SkillType.UNKNOWN

# ========================== 重新加载与调试模块 ==========================
## 功能：重新加载所有技能（支持热重载）
func reload_skills() -> void:
	_load_all_skills()
	print("[SkillLibrary] 技能重新加载完成")
