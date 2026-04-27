extends Resource
class_name SkillEffect

## 技能类别
enum SkillType {
	UNKNOWN,    # 彩蛋，未知技能
	INITIATOR,  # 起手技
	FINISHER,   # 连携技
	CONTROL,    # 场控技
	SURVIVAL    # 生存技
}

# 特效挂载类型
enum EffectAttachType {
	CASTER,       # 1. 特效在施法者（给自己BUFF）
	TARGET,       # 2. 特效在目标（打敌人、给敌人BUFF）
	POSITION,     # 3. 特效在指定位置（毒圈、AOE、地面技能）
}

## 技能id
@export var id: String
## 技能名
@export var name: String
## 技能图标
@export var icon: Texture2D
## 技能描述
@export var description: String
## 技能冷却
@export var cooldown := 1.0
## 技能伤害
@export var damage := 1.0
## 技能倍率
@export var skill_multiplier := 1.0
## 技能所属类型：起手技/连携技/场控技/生存技
@export var type: SkillType
## 技能时长
@export var skill_duration := 0.0
## 技能后摇时间
@export var recovery_duration := 0.0
## 关联特效路径
@export var fx_scene: PackedScene
## 特效挂载类型，挂载位置
@export var effect_attach_type: EffectAttachType = EffectAttachType.CASTER
## 技能动画基础名（用于构建动画名称: skill_{anim_base_name}_{direction}）
@export var anim_base_name: String = ""
