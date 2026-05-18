# ==============================================================================
#   skill_unlock_data.gd
#   功能：技能解锁状态的运行时数据容器，由 SkillUnlockManager 动态构建。
#        不作为 .tres 资源序列化，仅在内存中存在。
# ==============================================================================
extends RefCounted
class_name SkillUnlockData

# ========================== 数据字段 ==========================
## 技能唯一标识符（与 SkillEffect.id 对应）
var skill_id: String = ""
## 解锁所需尘元费用
var unlock_cost: int = 0
## 前置技能列表（需全部解锁后才能解锁本技能）
var prerequisite_skills: Array[String] = []
## 当前是否已解锁
var is_unlocked: bool = false

# ========================== 构造函数 ==========================
func _init(
	p_skill_id: String = "",
	p_cost: int = 0,
	p_unlocked: bool = false,
	p_prerequisites: Array[String] = []
) -> void:
	skill_id = p_skill_id
	unlock_cost = p_cost
	is_unlocked = p_unlocked
	prerequisite_skills = p_prerequisites
