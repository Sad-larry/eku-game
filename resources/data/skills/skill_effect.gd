# ==============================================================================
#   skill_effect.gd
#   功能：技能效果资源类，定义技能的所有属性（冷却、能耗、伤害、倍率、特效挂载、
#        动画名称等），用于技能系统的数据驱动配置。
# ==============================================================================
extends Resource
class_name SkillEffect

# ========================== 枚举定义模块 ==========================
## 技能类别枚举
enum SkillType {
	## 未知/彩蛋技能
	UNKNOWN,
	## 起手技（连击起始）
	INITIATOR,
	## 连携技（连击终结）
	FINISHER,
	## 场控技（控制效果）
	CONTROL,
	## 生存技（防御/回复）
	SURVIVAL
}

## 特效挂载位置枚举
enum EffectAttachType {
	## 特效挂在施法者身上（如自身增益 Buff）
	CASTER, 
	## 特效挂在目标身上（如攻击命中敌人特效）
	TARGET,
	## 特效挂在指定世界坐标（如毒圈、AOE 地面技能）
	POSITION
}

# ========================== 导出变量模块 ==========================
## 技能唯一标识符（用于技能运行器查询）
@export var id: String
## 技能显示名称
@export var name: String
## 技能图标纹理
@export var icon: Texture2D
## 技能描述文本
@export var description: String
## 技能冷却时间（秒）
@export var cooldown := 1.0
## 技能消耗能量值
@export var energy_cost: int = 10
## 技能基础伤害值
@export var damage := 1.0
## 技能倍率（与基础伤害相乘得到最终伤害）
@export var skill_multiplier := 1.0
## 技能所属类型（起手技/连携技/场控技/生存技）
@export var type: SkillType
## 技能主动画持续时间（秒），决定技能状态在主动画阶段停留时长
@export var skill_duration := 0.0
## 技能后摇时间（秒），主动画结束后进入后摇状态的时长
@export var recovery_duration := 0.0
## 关联的特效场景（PackedScene），实例化后用于视觉表现
@export var fx_scene: PackedScene
## 特效挂载类型，决定特效生成在施法者、目标还是指定位置
@export var effect_attach_type: EffectAttachType = EffectAttachType.CASTER
## 技能动画基础名称（用于构建完整动画名：skill_{anim_base_name}_{direction}）
## 例如：anim_base_name = "slash" -> 动画名可能为 "skill_slash_down"、"skill_slash_up" 等
@export var anim_base_name: String = ""
## 释放技能时玩家能否移动
@export var can_move_while_casting: bool = false
## 释放技能时玩家的移速倍率（仅 can_move_while_casting 为 true 时生效）
@export var move_speed_multiplier: float = 1.0
## 技能标签（用于协同系统匹配、图鉴分类等）
## 示例标签：["fire", "projectile"], ["ice", "aoe", "control"], ["melee", "slash"]
## 命名规范：
##   元素类: fire, ice, lightning, poison, holy, dark, wind, physical
##   形态类: projectile, aoe, melee, beam, nova, summon
##   行为类: dot, slow, stun, knockback, heal, shield, lifesteal
##   类型标记: initiator, finisher, control, survival
@export var tags: Array[String] = []
