extends Resource
class_name SkillEffect

## 技能类别
enum SkillType {
	INITIATOR,  # 起手技
	FINISHER,   # 连携技
	CONTROL,    # 场控技
	SURVIVAL    # 生存技
}


## 技能名
@export var name: String
## 技能图标
@export var icon: Texture2D
## 技能冷却
@export var cooldown := 1.0
## 技能伤害
@export var damage := 1.0
## 技能所属类型：起手技/连携技/场控技/生存技
@export var type: SkillType
## 关联特效路径
@export var linked_effect_path: String
