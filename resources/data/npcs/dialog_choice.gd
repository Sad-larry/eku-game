# ==============================================================================
#   dialog_choice.gd
#   功能：对话选项数据。定义一个可选择的对话分支。
# ==============================================================================
class_name DialogChoice extends Resource

## 选项类型枚举
enum ChoiceType {
	TRADE,  ## 交易（消耗金币获得物品/服务）
	QUEST,  ## 任务（接受/完成任务）
	INFO,   ## 信息（获取情报）
	GIFT,   ## 赠礼（获得奖励）
	LEAVE,  ## 离开对话
}

# ========================== 导出变量模块 ==========================
## 选项显示文本（玩家看到的按钮文字）
@export var text: String = ""
## 选项类型（决定对话分支的行为逻辑）
@export var choice_type: ChoiceType = ChoiceType.LEAVE
## 金币消耗（TRADE 类型专用，0 表示免费）
@export var cost: int = 0
## 奖励金币数量
@export var reward_coin: int = 0
## 奖励回血百分比（0.0 - 1.0，如 0.3 = 回复 30% 最大生命值）
@export var reward_heal_pct: float = 0.0
