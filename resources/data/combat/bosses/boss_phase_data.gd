# ==============================================================================
#   boss_phase_data.gd
#   功能：Boss阶段数据资源类，定义每个阶段的属性变化。
#        行为（技能）现在通过 Enemy.behaviors 数组 + PhaseTrigger 配置。
# ==============================================================================
extends Resource
class_name BossPhaseData

## 阶段索引（从0开始）
@export var phase_index: int = 0
## 血量阈值（低于此值时进入本阶段）
@export var health_threshold: float = 0.5

# ========================== 阶段特性 ==========================
## 伤害倍率
@export var damage_multiplier: float = 1.0
## 移速倍率
@export var speed_multiplier: float = 1.0
## 护甲加成
@export var armor_bonus: float = 0.0
## 是否无敌阶段
@export var is_invincible: bool = false
## 无敌持续时间（秒）
@export var invincible_duration: float = 0.0

# ========================== 视觉效果 ==========================
## 阶段转换特效场景
@export var phase_transition_effect: PackedScene
## 阶段光环颜色
@export var aura_color: Color = Color.WHITE
## 阶段转换音效
@export var transition_sound: AudioStream
