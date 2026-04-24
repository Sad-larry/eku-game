# autoloads/skill_library.gd
# 技能库管理器：加载和管理所有技能资源，提供技能查询接口
# 自动加载配置：在 Project -> Project Settings -> Autoloads 中添加，命名为 SkillLibrary
extends Node

# ========================== 常量定义 ==========================
const SKILLS_DIR_PATH: String = "res://resources/data/skills/"

# 技能分类枚举（与目录结构对应）
enum SkillCategory {
	INITIATOR,      # 起手技
	FINISHER,       # 连携技
	CONTROL,        # 场控技
	SURVIVAL,       # 生存技
	UNKNOWN         # 彩蛋，未知技能
}

# ========================== 技能数据结构 ==========================
class SkillData:
	var id: String
	var name: String
	var description: String
	var category: SkillCategory
	var icon_path: String
	var cooldown: float
	var damage_multiplier: float
	var resource_path: String  # .tres资源路径

	func _init(p_id: String, p_name: String, p_desc: String, p_category: SkillCategory,
			  p_icon: String, p_cd: float, p_dmg: float, p_path: String):
		id = p_id
		name = p_name
		description = p_desc
		category = p_category
		icon_path = p_icon
		cooldown = p_cd
		damage_multiplier = p_dmg
		resource_path = p_path

# ========================== 变量定义 ==========================
var all_skills: Dictionary = {}           # 所有技能: {skill_id: SkillData}
var skills_by_category: Dictionary = {}   # 按分类组织的技能: {category: Array[SkillData]}

# ========================== 初始化 ==========================
func _ready() -> void:
	pass
	# 初始化分类字典
	#for category in SkillCategory.values():
		#skills_by_category[category] = []

	# 加载所有技能
	#load_all_skills()
	#print("SkillLibrary: 技能库初始化完成，加载技能数量: ", all_skills.size())

# ========================== 技能加载核心 ==========================
## 加载所有技能资源
func load_all_skills() -> void:
	# 清空现有数据
	all_skills.clear()
	for category in skills_by_category:
		skills_by_category[category].clear()

	# 遍历技能目录
	var dir = DirAccess.open(SKILLS_DIR_PATH)
	if not dir:
		push_warning("SkillLibrary: 技能目录不存在或无法访问: ", SKILLS_DIR_PATH)
		return

	# 遍历所有子目录（按分类）
	dir.list_dir_begin()
	var subdir_name = dir.get_next()
	while subdir_name != "":
		if dir.current_is_dir() and not subdir_name.begins_with("."):
			_load_skills_from_category(subdir_name)
		subdir_name = dir.get_next()
	dir.list_dir_end()

## 从特定分类目录加载技能
func _load_skills_from_category(category_dir: String) -> void:
	var category_path = SKILLS_DIR_PATH.path_join(category_dir)
	var dir = DirAccess.open(category_path)
	if not dir:
		push_warning("SkillLibrary: 无法访问分类目录: ", category_path)
		return

	# 确定分类枚举
	var category: SkillCategory
	match category_dir:
		"initiator":
			category = SkillCategory.INITIATOR
		"finisher":
			category = SkillCategory.FINISHER
		"control":
			category = SkillCategory.CONTROL
		"survival":
			category = SkillCategory.SURVIVAL
		_:
			push_warning("SkillLibrary: 未知技能分类目录: ", category_dir)
			return

	# 遍历目录中的.tres文件
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var skill_path = category_path.path_join(file_name)
			_load_skill_resource(skill_path, category, file_name.get_basename())
		file_name = dir.get_next()
	dir.list_dir_end()

## 加载单个技能资源文件
func _load_skill_resource(skill_path: String, category: SkillCategory, file_base_name: String) -> void:
	var resource = load(skill_path)
	if not resource:
		push_warning("SkillLibrary: 无法加载技能资源: ", skill_path)
		return

	# 从资源中提取技能数据
	# 这里假设技能资源有特定的属性，可以根据实际资源结构调整
	var skill_id = file_base_name
	var skill_name = resource.get("skill_name") if resource.has("skill_name") else skill_id
	var description = resource.get("description") if resource.has("description") else ""
	var icon_path = resource.get("icon_path") if resource.has("icon_path") else ""
	var cooldown = resource.get("cooldown") if resource.has("cooldown") else 1.0
	var damage_multiplier = resource.get("damage_multiplier") if resource.has("damage_multiplier") else 1.0

	# 创建技能数据对象
	var skill_data = SkillData.new(
		skill_id,
		skill_name,
		description,
		category,
		icon_path,
		cooldown,
		damage_multiplier,
		skill_path
	)

	# 添加到管理结构
	all_skills[skill_id] = skill_data
	skills_by_category[category].append(skill_data)

	print("SkillLibrary: 加载技能 -> ", skill_name, " (", category_dir_from_enum(category), ")")

# ========================== 技能查询接口 ==========================
## 通过ID获取技能数据
func get_skill_by_id(skill_id: String) -> SkillData:
	return all_skills.get(skill_id)

## 获取特定分类的所有技能
func get_skills_by_category(category: SkillCategory) -> Array:
	return skills_by_category.get(category, []).duplicate()

## 获取所有技能ID列表
func get_all_skill_ids() -> Array:
	return all_skills.keys()

## 获取随机技能（可选分类过滤）
func get_random_skill(category: SkillCategory) -> SkillData:
	var candidates = []
	if category >= 0:
		candidates = skills_by_category.get(category, [])
	else:
		candidates = all_skills.values()

	if candidates.is_empty():
		return null

	var random_index = randi() % candidates.size()
	return candidates[random_index]

## 根据分类枚举获取目录名
func category_dir_from_enum(category: SkillCategory) -> String:
	match category:
		SkillCategory.INITIATOR:
			return "initiator"
		SkillCategory.FINISHER:
			return "finisher"
		SkillCategory.CONTROL:
			return "control"
		SkillCategory.SURVIVAL:
			return "survival"
		_:
			return "unknown"

## 根据目录名获取分类枚举
func category_enum_from_dir(dir_name: String) -> SkillCategory:
	match dir_name:
		"initiator":
			return SkillCategory.INITIATOR
		"finisher":
			return SkillCategory.FINISHER
		"control":
			return SkillCategory.CONTROL
		"survival":
			return SkillCategory.SURVIVAL
		_:
			return SkillCategory.UNKNOWN

# ========================== 重新加载与调试 ==========================
## 重新加载所有技能（热重载支持）
func reload_skills() -> void:
	load_all_skills()
	print("SkillLibrary: 技能重新加载完成")

## 打印技能库状态（调试用）
func print_library_status() -> void:
	print("=== 技能库状态 ===")
	print("总技能数量: ", all_skills.size())
	for category in SkillCategory.values():
		var count = skills_by_category.get(category, []).size()
		print(category_dir_from_enum(category), ": ", count, " 个技能")
	print("================")
