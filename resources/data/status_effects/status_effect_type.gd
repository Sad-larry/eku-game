# ==============================================================================
#   status_effect_type.gd
#   功能：状态效果类型定义资源，描述一种状态效果的全部数据属性。
#        作为 Resource 可在编辑器中配置为 .tres 文件复用。
# ==============================================================================
class_name StatusEffectType extends Resource

# ========================== 枚举定义 ==========================
## 叠加策略：控制重复施加同类型效果时的行为
enum StackPolicy {
	REFRESH,        ## 刷新持续时间，层数不变
	STACK,          ## 增加层数，持续时间不变
	REFRESH_OR_STACK, ## 刷新持续时间并增加层数（已达上限则仅刷新）
}

## 效果标签：用于分类过滤
enum Tag {
	BUFF,           ## 增益效果
	DEBUFF,         ## 减益效果
	DOT,            ## 持续伤害
	HOT,            ## 持续回复
	CONTROL,        ## 控制效果（眩晕等）
	ENVIRONMENT,    ## 环境效果（地形等）
}

# ========================== 导出变量 ==========================
## 效果唯一标识符
@export var id: String = ""
## 显示名称（UI 用）
@export var display_name: String = ""
## 效果图标
@export var icon: Texture2D
## 效果标签
@export var tag: Tag = Tag.DEBUFF
## 持续时间（秒），0 = 永久效果
@export var duration: float = 5.0
## Tick 间隔（秒），仅 DOT/HOT 等需要持续触发的效果使用
@export var tick_interval: float = 1.0
## 最大叠加层数
@export var max_stacks: int = 1
## 叠加策略
@export var stack_policy: StackPolicy = StackPolicy.REFRESH
## 效果执行策略脚本（引用具体的 Strategy 子类）
@export var strategy_script: Script
## 策略参数字典（传递给策略脚本的配置数据）
@export var strategy_params: Dictionary = {}
## 是否为减益效果（用于 purge_debuffs 等过滤）
@export var is_debuff: bool = false
